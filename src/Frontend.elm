module Frontend exposing (app, init, update, updateFromBackend, view)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Domain exposing (Comment(..), Event, EventDraft, EventId, Person(..), Recurrence(..))
import Html exposing (Html, button, div, h1, h2, h3, header, input, label, main_, node, p, span, text, textarea)
import Html.Attributes as Attr
import Html.Events exposing (onClick, onInput)
import Lamdera
import String
import Types exposing (..)
import Url


type alias Model =
    FrontendModel


app =
    Lamdera.frontend
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = \_ -> Sub.none
        , view = view
        }


init : Url.Url -> Nav.Key -> ( Model, Cmd FrontendMsg )
init _ key =
    ( { key = key
      , events = []
      , form = emptyForm
      , editor = EditorClosed
      , personFilter = AllPeople
      , recurrenceFilter = AllRecurrences
      , search = ""
      , formError = Nothing
      , syncState = Loading
      , notice = Nothing
      , pendingDelete = Nothing
      }
    , Lamdera.sendToBackend RequestEvents
    )


emptyForm : EventForm
emptyForm =
    { title = ""
    , startDate = ""
    , startTime = "09:00"
    , endDate = ""
    , endTime = "10:00"
    , recurrence = OneTime
    , assignee = PersonA
    , comment = ""
    }


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                External url ->
                    ( model, Nav.load url )

        UrlChanged _ ->
            ( model, Cmd.none )

        OpenCreateEditor ->
            ( { model
                | editor = CreatingEvent
                , form = emptyForm
                , formError = Nothing
                , notice = Nothing
              }
            , Cmd.none
            )

        OpenEditEditor eventId ->
            case findEvent eventId model.events of
                Just event ->
                    ( { model
                        | editor = EditingEvent eventId
                        , form = formFromEvent event
                        , formError = Nothing
                        , notice = Nothing
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( { model | notice = Just "Der Termin wurde nicht gefunden." }, Cmd.none )

        CloseEditor ->
            ( { model | editor = EditorClosed, formError = Nothing }, Cmd.none )

        ChangeTitle value ->
            ( updateForm (\form -> { form | title = value }) model, Cmd.none )

        ChangeStartDate value ->
            let
                updateDates form =
                    { form
                        | startDate = value
                        , endDate =
                            if String.isEmpty form.endDate then
                                value

                            else
                                form.endDate
                    }
            in
            ( updateForm updateDates model, Cmd.none )

        ChangeStartTime value ->
            ( updateForm (\form -> { form | startTime = value }) model, Cmd.none )

        ChangeEndDate value ->
            ( updateForm (\form -> { form | endDate = value }) model, Cmd.none )

        ChangeEndTime value ->
            ( updateForm (\form -> { form | endTime = value }) model, Cmd.none )

        ChangeRecurrence value ->
            ( updateForm (\form -> { form | recurrence = value }) model, Cmd.none )

        ChangeAssignee value ->
            ( updateForm (\form -> { form | assignee = value }) model, Cmd.none )

        ChangeComment value ->
            ( updateForm (\form -> { form | comment = value }) model, Cmd.none )

        SubmitEvent ->
            case formToDraft model.form of
                Err problem ->
                    ( { model | formError = Just problem }, Cmd.none )

                Ok draft ->
                    case model.editor of
                        EditorClosed ->
                            ( model, Cmd.none )

                        CreatingEvent ->
                            ( savingModel model
                            , Lamdera.sendToBackend (CreateEvent draft)
                            )

                        EditingEvent eventId ->
                            ( savingModel model
                            , Lamdera.sendToBackend (UpdateEvent eventId draft)
                            )

        ChangePersonFilter value ->
            ( { model | personFilter = value }, Cmd.none )

        ChangeRecurrenceFilter value ->
            ( { model | recurrenceFilter = value }, Cmd.none )

        ChangeSearch value ->
            ( { model | search = value }, Cmd.none )

        ResetFilters ->
            ( { model
                | personFilter = AllPeople
                , recurrenceFilter = AllRecurrences
                , search = ""
              }
            , Cmd.none
            )

        AskDelete eventId ->
            ( { model | pendingDelete = Just eventId, notice = Nothing }, Cmd.none )

        CancelDelete ->
            ( { model | pendingDelete = Nothing }, Cmd.none )

        ConfirmDelete eventId ->
            ( { model | pendingDelete = Nothing, syncState = Saving }
            , Lamdera.sendToBackend (DeleteEvent eventId)
            )

        DismissNotice ->
            ( { model | notice = Nothing }, Cmd.none )


savingModel : Model -> Model
savingModel model =
    { model
        | editor = EditorClosed
        , form = emptyForm
        , formError = Nothing
        , syncState = Saving
        , notice = Nothing
    }


updateForm : (EventForm -> EventForm) -> Model -> Model
updateForm change model =
    { model | form = change model.form, formError = Nothing }


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        EventsLoaded events ->
            ( { model | events = events, syncState = Synced }, Cmd.none )

        EventsChanged events message ->
            ( { model
                | events = events
                , syncState = Synced
                , notice = Just message
              }
            , Cmd.none
            )

        ChangeRejected problem ->
            ( { model | syncState = SyncFailed problem, notice = Just problem }, Cmd.none )


formToDraft : EventForm -> Result String EventDraft
formToDraft form =
    if String.isEmpty (String.trim form.title) then
        Err "Bitte einen Titel für den Termin angeben."

    else
        fieldResult "Beginn" (Domain.dateFromIso form.startDate)
            |> Result.andThen
                (\startDate ->
                    fieldResult "Beginn" (Domain.timeFromIso form.startTime)
                        |> Result.andThen
                            (\startTime ->
                                fieldResult "Ende" (Domain.dateFromIso form.endDate)
                                    |> Result.andThen
                                        (\endDate ->
                                            fieldResult "Ende" (Domain.timeFromIso form.endTime)
                                                |> Result.andThen
                                                    (\endTime ->
                                                        Domain.timeWindow startDate startTime endDate endTime
                                                            |> Result.map
                                                                (\window ->
                                                                    { title = String.trim form.title
                                                                    , window = window
                                                                    , recurrence = form.recurrence
                                                                    , assignee = form.assignee
                                                                    , comment = Domain.commentFromString form.comment
                                                                    }
                                                                )
                                                    )
                                        )
                            )
                )


fieldResult : String -> Result String value -> Result String value
fieldResult fieldName result =
    Result.mapError (\problem -> fieldName ++ ": " ++ problem) result


formFromEvent : Event -> EventForm
formFromEvent event =
    let
        start =
            Domain.windowStart event.window

        end =
            Domain.windowEnd event.window
    in
    { title = event.title
    , startDate = Domain.dateToIso (Domain.momentDate start)
    , startTime = Domain.timeToIso (Domain.momentTime start)
    , endDate = Domain.dateToIso (Domain.momentDate end)
    , endTime = Domain.timeToIso (Domain.momentTime end)
    , recurrence = event.recurrence
    , assignee = event.assignee
    , comment = Domain.commentToString event.comment
    }


findEvent : EventId -> List Event -> Maybe Event
findEvent eventId events =
    List.filter (\event -> event.id == eventId) events
        |> List.head


view : Model -> Browser.Document FrontendMsg
view model =
    { title = "PraxisPlan — Terminmanagement"
    , body =
        [ node "style" [] [ text styles ]
        , div [ Attr.class "app-shell" ]
            [ viewHeader model
            , main_ [ Attr.class "page" ]
                [ viewHero model
                , viewStats model
                , viewEventSection model
                ]
            , viewNotice model.notice
            , viewEditor model
            , viewDeleteDialog model
            ]
        ]
    }


viewHeader : Model -> Html FrontendMsg
viewHeader model =
    header [ Attr.class "topbar" ]
        [ div [ Attr.class "brand" ]
            [ div [ Attr.class "brand-mark", Attr.attribute "aria-hidden" "true" ]
                [ span [] [ text "P" ] ]
            , div []
                [ div [ Attr.class "brand-name" ] [ text "PraxisPlan" ]
                , div [ Attr.class "brand-subtitle" ] [ text "BERICHT · ORGANISATION" ]
                ]
            ]
        , div [ Attr.class "topbar-actions" ]
            [ viewSyncState model.syncState
            , button
                [ Attr.class "button button-primary"
                , onClick OpenCreateEditor
                ]
                [ span [ Attr.class "button-plus", Attr.attribute "aria-hidden" "true" ] [ text "+" ]
                , text "Termin planen"
                ]
            ]
        ]


viewSyncState : SyncState -> Html msg
viewSyncState syncState =
    case syncState of
        Loading ->
            div [ Attr.class "sync-state" ]
                [ span [ Attr.class "sync-dot is-busy" ] [], text "Wird geladen" ]

        Saving ->
            div [ Attr.class "sync-state" ]
                [ span [ Attr.class "sync-dot is-busy" ] [], text "Speichert" ]

        Synced ->
            div [ Attr.class "sync-state hide-mobile" ]
                [ span [ Attr.class "sync-dot" ] [], text "Synchronisiert" ]

        SyncFailed _ ->
            div [ Attr.class "sync-state sync-error" ]
                [ span [ Attr.class "sync-dot" ] [], text "Fehler" ]


viewHero : Model -> Html FrontendMsg
viewHero model =
    div [ Attr.class "hero" ]
        [ div [ Attr.class "eyebrow" ]
            [ span [ Attr.class "eyebrow-line" ] []
            , text "PRAXISBERICHT · TERMINMANAGEMENT"
            ]
        , div [ Attr.class "hero-row" ]
            [ h1 []
                [ text "Alle wichtigen Zeitfenster."
                , Html.br [] []
                , span [] [ text "Klare Zuständigkeiten." ]
                ]
            , p [ Attr.class "hero-copy" ]
                [ text "Plane einmalige und wiederkehrende Ereignisse, halte Aufgaben direkt am Termin fest und verteile sie eindeutig auf A oder B." ]
            ]
        , if List.isEmpty model.events then
            div [ Attr.class "hero-hint" ]
                [ span [ Attr.class "hint-icon" ] [ text "↗" ]
                , text "Beginne mit dem ersten relevanten Zeitfenster für deinen Praxisbericht."
                ]

          else
            text ""
        ]


viewStats : Model -> Html FrontendMsg
viewStats model =
    let
        countFor person =
            List.filter (\event -> event.assignee == person) model.events |> List.length

        recurringCount =
            List.filter (\event -> event.recurrence /= OneTime) model.events |> List.length
    in
    div [ Attr.class "stats-grid" ]
        [ statCard "Termine" (String.fromInt (List.length model.events)) "gesamt geplant" "calendar"
        , statCard "Wiederkehrend" (String.fromInt recurringCount) "Semester & Jahr" "repeat"
        , div [ Attr.class "stat-card people-stat" ]
            [ div [ Attr.class "stat-heading" ] [ text "Zuständigkeit" ]
            , div [ Attr.class "people-counts" ]
                [ div []
                    [ personAvatar PersonA
                    , span [] [ text (String.fromInt (countFor PersonA)) ]
                    , smallText "Termine"
                    ]
                , div [ Attr.class "people-divider" ] []
                , div []
                    [ personAvatar PersonB
                    , span [] [ text (String.fromInt (countFor PersonB)) ]
                    , smallText "Termine"
                    ]
                ]
            ]
        ]


statCard : String -> String -> String -> String -> Html msg
statCard heading number detail iconClass =
    div [ Attr.class "stat-card" ]
        [ div [ Attr.class "stat-top" ]
            [ div [ Attr.class "stat-heading" ] [ text heading ]
            , div [ Attr.class ("stat-icon " ++ iconClass), Attr.attribute "aria-hidden" "true" ]
                [ text
                    (if iconClass == "repeat" then
                        "↻"

                     else
                        "□"
                    )
                ]
            ]
        , div [ Attr.class "stat-number" ] [ text number ]
        , div [ Attr.class "stat-detail" ] [ text detail ]
        ]


smallText : String -> Html msg
smallText value =
    span [ Attr.class "small-text" ] [ text value ]


viewEventSection : Model -> Html FrontendMsg
viewEventSection model =
    let
        events =
            visibleEvents model
    in
    div [ Attr.class "events-section" ]
        [ div [ Attr.class "section-title-row" ]
            [ div []
                [ div [ Attr.class "section-kicker" ] [ text "ZEITPLAN" ]
                , h2 [] [ text "Geplante Ereignisse" ]
                ]
            , div [ Attr.class "result-count" ]
                [ text (String.fromInt (List.length events) ++ " angezeigt") ]
            ]
        , viewFilters model
        , case model.syncState of
            Loading ->
                viewLoading

            _ ->
                if List.isEmpty events then
                    viewEmptyState model

                else
                    div [ Attr.class "event-list" ] (List.map viewEventCard events)
        ]


viewFilters : Model -> Html FrontendMsg
viewFilters model =
    div [ Attr.class "filterbar" ]
        [ div [ Attr.class "search-wrap" ]
            [ span [ Attr.class "search-icon", Attr.attribute "aria-hidden" "true" ] [ text "⌕" ]
            , input
                [ Attr.class "search-input"
                , Attr.placeholder "Termine und Kommentare durchsuchen …"
                , Attr.value model.search
                , Attr.attribute "aria-label" "Termine durchsuchen"
                , onInput ChangeSearch
                ]
                []
            ]
        , div [ Attr.class "filter-groups" ]
            [ div [ Attr.class "filter-pills", Attr.attribute "aria-label" "Nach Person filtern" ]
                [ filterButton (model.personFilter == AllPeople) (ChangePersonFilter AllPeople) "Alle"
                , filterButton (model.personFilter == AssignedTo PersonA) (ChangePersonFilter (AssignedTo PersonA)) "A"
                , filterButton (model.personFilter == AssignedTo PersonB) (ChangePersonFilter (AssignedTo PersonB)) "B"
                ]
            , div [ Attr.class "filter-pills recurrence-pills", Attr.attribute "aria-label" "Nach Wiederholung filtern" ]
                [ filterButton (model.recurrenceFilter == AllRecurrences) (ChangeRecurrenceFilter AllRecurrences) "Alle Arten"
                , filterButton (model.recurrenceFilter == OnlyRecurrence OneTime) (ChangeRecurrenceFilter (OnlyRecurrence OneTime)) "Einmalig"
                , filterButton (model.recurrenceFilter == OnlyRecurrence EverySemester) (ChangeRecurrenceFilter (OnlyRecurrence EverySemester)) "Semester"
                , filterButton (model.recurrenceFilter == OnlyRecurrence EveryYear) (ChangeRecurrenceFilter (OnlyRecurrence EveryYear)) "Jahr"
                ]
            ]
        ]


filterButton : Bool -> msg -> String -> Html msg
filterButton isActive message caption =
    button
        [ Attr.class
            (if isActive then
                "filter-pill is-active"

             else
                "filter-pill"
            )
        , onClick message
        ]
        [ text caption ]


visibleEvents : Model -> List Event
visibleEvents model =
    model.events
        |> List.filter (matchesPerson model.personFilter)
        |> List.filter (matchesRecurrence model.recurrenceFilter)
        |> List.filter (matchesSearch model.search)
        |> List.sortBy eventSortKey


matchesPerson : PersonFilter -> Event -> Bool
matchesPerson filter event =
    case filter of
        AllPeople ->
            True

        AssignedTo person ->
            event.assignee == person


matchesRecurrence : RecurrenceFilter -> Event -> Bool
matchesRecurrence filter event =
    case filter of
        AllRecurrences ->
            True

        OnlyRecurrence recurrence ->
            event.recurrence == recurrence


matchesSearch : String -> Event -> Bool
matchesSearch search event =
    let
        needle =
            String.toLower (String.trim search)

        haystack =
            String.toLower (event.title ++ " " ++ Domain.commentToString event.comment)
    in
    String.isEmpty needle || String.contains needle haystack


eventSortKey : Event -> String
eventSortKey event =
    let
        start =
            Domain.windowStart event.window
    in
    Domain.dateToIso (Domain.momentDate start) ++ Domain.timeToIso (Domain.momentTime start)


viewLoading : Html msg
viewLoading =
    div [ Attr.class "loading-card" ]
        [ div [ Attr.class "loading-line wide" ] []
        , div [ Attr.class "loading-line" ] []
        , div [ Attr.class "loading-line short" ] []
        ]


viewEmptyState : Model -> Html FrontendMsg
viewEmptyState model =
    let
        filtersActive =
            not (String.isEmpty (String.trim model.search))
                || model.personFilter
                /= AllPeople
                || model.recurrenceFilter
                /= AllRecurrences
    in
    div [ Attr.class "empty-state" ]
        [ div [ Attr.class "empty-symbol" ] [ text "◇" ]
        , h3 []
            [ text
                (if filtersActive then
                    "Keine passenden Termine"

                 else
                    "Noch ist der Zeitplan frei"
                )
            ]
        , p []
            [ text
                (if filtersActive then
                    "Passe Suche oder Filter an, um andere Ereignisse zu sehen."

                 else
                    "Lege ein Zeitfenster an und halte direkt fest, wer was erledigt."
                )
            ]
        , if filtersActive then
            button
                [ Attr.class "button button-secondary"
                , onClick ResetFilters
                ]
                [ text "Alle Filter zurücksetzen" ]

          else
            button [ Attr.class "button button-primary", onClick OpenCreateEditor ]
                [ span [ Attr.class "button-plus" ] [ text "+" ], text "Ersten Termin planen" ]
        ]


viewEventCard : Event -> Html FrontendMsg
viewEventCard event =
    let
        startDate =
            Domain.windowStart event.window |> Domain.momentDate

        ( day, month ) =
            shortDateParts startDate
    in
    div [ Attr.class "event-card" ]
        [ div [ Attr.class "date-block" ]
            [ span [ Attr.class "date-month" ] [ text month ]
            , span [ Attr.class "date-day" ] [ text day ]
            ]
        , div [ Attr.class "event-main" ]
            [ div [ Attr.class "event-head" ]
                [ div []
                    [ div [ Attr.class "event-badges" ]
                        [ recurrenceBadge event.recurrence
                        , personBadge event.assignee
                        ]
                    , h3 [ Attr.class "event-title" ] [ text event.title ]
                    ]
                , div [ Attr.class "card-actions" ]
                    [ button
                        [ Attr.class "icon-button"
                        , Attr.title "Termin bearbeiten"
                        , Attr.attribute "aria-label" "Termin bearbeiten"
                        , onClick (OpenEditEditor event.id)
                        ]
                        [ text "✎" ]
                    , button
                        [ Attr.class "icon-button danger"
                        , Attr.title "Termin löschen"
                        , Attr.attribute "aria-label" "Termin löschen"
                        , onClick (AskDelete event.id)
                        ]
                        [ text "×" ]
                    ]
                ]
            , div [ Attr.class "event-time" ]
                [ span [ Attr.class "time-icon", Attr.attribute "aria-hidden" "true" ] [ text "◷" ]
                , text (Domain.windowToGerman event.window)
                ]
            , viewComment event.comment
            , viewRecurrencePreview event
            ]
        ]


recurrenceBadge : Recurrence -> Html msg
recurrenceBadge recurrence =
    span
        [ Attr.class
            (case recurrence of
                OneTime ->
                    "badge badge-once"

                EverySemester ->
                    "badge badge-semester"

                EveryYear ->
                    "badge badge-year"
            )
        ]
        [ if recurrence == OneTime then
            text "Einmalig"

          else
            span [ Attr.class "badge-repeat" ] [ text "↻" ]
        , if recurrence == OneTime then
            text ""

          else
            text (Domain.recurrenceLabel recurrence)
        ]


personBadge : Person -> Html msg
personBadge person =
    span [ Attr.class "person-badge" ]
        [ personAvatar person
        , text (Domain.personLabel person)
        ]


personAvatar : Person -> Html msg
personAvatar person =
    span
        [ Attr.class
            (case person of
                PersonA ->
                    "avatar avatar-a"

                PersonB ->
                    "avatar avatar-b"
            )
        ]
        [ text
            (case person of
                PersonA ->
                    "A"

                PersonB ->
                    "B"
            )
        ]


viewComment : Comment -> Html msg
viewComment comment =
    case comment of
        NoComment ->
            text ""

        Comment value ->
            div [ Attr.class "comment-box" ]
                [ span [ Attr.class "comment-mark", Attr.attribute "aria-hidden" "true" ] [ text "✓" ]
                , div []
                    [ span [ Attr.class "comment-label" ] [ text "ZU ERLEDIGEN" ]
                    , p [] [ text value ]
                    ]
                ]


viewRecurrencePreview : Event -> Html msg
viewRecurrencePreview event =
    case event.recurrence of
        OneTime ->
            text ""

        _ ->
            div [ Attr.class "recurrence-preview" ]
                [ span [ Attr.class "preview-label" ] [ text "TERMINFOLGE" ]
                , div [ Attr.class "preview-dates" ]
                    (Domain.occurrenceWindows 3 event
                        |> List.map
                            (\window ->
                                span []
                                    [ text
                                        (window
                                            |> Domain.windowStart
                                            |> Domain.momentDate
                                            |> Domain.dateToGerman
                                        )
                                    ]
                            )
                    )
                ]


shortDateParts : Domain.CalendarDate -> ( String, String )
shortDateParts date =
    case String.split "-" (Domain.dateToIso date) of
        [ _, rawMonth, day ] ->
            ( day, monthAbbreviation rawMonth )

        _ ->
            ( "--", "---" )


monthAbbreviation : String -> String
monthAbbreviation month =
    case month of
        "01" ->
            "JAN"

        "02" ->
            "FEB"

        "03" ->
            "MÄR"

        "04" ->
            "APR"

        "05" ->
            "MAI"

        "06" ->
            "JUN"

        "07" ->
            "JUL"

        "08" ->
            "AUG"

        "09" ->
            "SEP"

        "10" ->
            "OKT"

        "11" ->
            "NOV"

        _ ->
            "DEZ"


viewNotice : Maybe String -> Html FrontendMsg
viewNotice maybeNotice =
    case maybeNotice of
        Nothing ->
            text ""

        Just message ->
            div [ Attr.class "toast", Attr.attribute "role" "status" ]
                [ span [ Attr.class "toast-check" ] [ text "✓" ]
                , text message
                , button [ Attr.class "toast-close", onClick DismissNotice, Attr.attribute "aria-label" "Hinweis schließen" ] [ text "×" ]
                ]


viewEditor : Model -> Html FrontendMsg
viewEditor model =
    case model.editor of
        EditorClosed ->
            text ""

        CreatingEvent ->
            editorDialog "Neuen Termin planen" "Zeitfenster anlegen" model

        EditingEvent _ ->
            editorDialog "Termin bearbeiten" "Änderungen speichern" model


editorDialog : String -> String -> Model -> Html FrontendMsg
editorDialog heading submitLabel model =
    div [ Attr.class "modal-backdrop" ]
        [ div [ Attr.class "editor-modal", Attr.attribute "role" "dialog", Attr.attribute "aria-modal" "true" ]
            [ div [ Attr.class "modal-header" ]
                [ div []
                    [ div [ Attr.class "section-kicker" ] [ text "TERMINDETAILS" ]
                    , h2 [] [ text heading ]
                    ]
                , button [ Attr.class "modal-close", onClick CloseEditor, Attr.attribute "aria-label" "Dialog schließen" ] [ text "×" ]
                ]
            , div [ Attr.class "modal-body" ]
                [ field "Titel"
                    True
                    (input
                        [ Attr.type_ "text"
                        , Attr.placeholder "z. B. Zwischenbericht einreichen"
                        , Attr.value model.form.title
                        , Attr.autofocus True
                        , onInput ChangeTitle
                        ]
                        []
                    )
                , div [ Attr.class "form-grid" ]
                    [ dateTimeGroup "Beginn" model.form.startDate model.form.startTime ChangeStartDate ChangeStartTime
                    , dateTimeGroup "Ende" model.form.endDate model.form.endTime ChangeEndDate ChangeEndTime
                    ]
                , div [ Attr.class "field" ]
                    [ label [] [ text "Wiederholung" ]
                    , div [ Attr.class "choice-grid choice-grid-three" ]
                        [ choiceButton (model.form.recurrence == OneTime) (ChangeRecurrence OneTime) "Einmalig" "Nur dieses Zeitfenster"
                        , choiceButton (model.form.recurrence == EverySemester) (ChangeRecurrence EverySemester) "Semester" "Alle sechs Monate"
                        , choiceButton (model.form.recurrence == EveryYear) (ChangeRecurrence EveryYear) "Jährlich" "Alle zwölf Monate"
                        ]
                    ]
                , div [ Attr.class "field" ]
                    [ label [] [ text "Zuständige Person" ]
                    , div [ Attr.class "choice-grid" ]
                        [ personChoice model.form.assignee PersonA
                        , personChoice model.form.assignee PersonB
                        ]
                    ]
                , field "Kommentar / zu erledigen"
                    False
                    (textarea
                        [ Attr.placeholder "Was muss für dieses Ereignis vorbereitet oder erledigt werden?"
                        , Attr.value model.form.comment
                        , Attr.rows 4
                        , onInput ChangeComment
                        ]
                        []
                    )
                , case model.formError of
                    Nothing ->
                        text ""

                    Just problem ->
                        div [ Attr.class "form-error", Attr.attribute "role" "alert" ]
                            [ span [] [ text "!" ], text problem ]
                ]
            , div [ Attr.class "modal-footer" ]
                [ button [ Attr.class "button button-ghost", onClick CloseEditor ] [ text "Abbrechen" ]
                , button
                    [ Attr.class "button button-primary"
                    , Attr.disabled (model.syncState == Saving)
                    , onClick SubmitEvent
                    ]
                    [ text submitLabel, span [ Attr.class "arrow" ] [ text "→" ] ]
                ]
            ]
        ]


field : String -> Bool -> Html FrontendMsg -> Html FrontendMsg
field caption required control =
    div [ Attr.class "field" ]
        [ label []
            [ text caption
            , if required then
                span [ Attr.class "required" ] [ text " *" ]

              else
                span [ Attr.class "optional" ] [ text " · optional" ]
            ]
        , control
        ]


dateTimeGroup : String -> String -> String -> (String -> FrontendMsg) -> (String -> FrontendMsg) -> Html FrontendMsg
dateTimeGroup caption dateValue timeValue dateMessage timeMessage =
    div [ Attr.class "field" ]
        [ label [] [ text caption, span [ Attr.class "required" ] [ text " *" ] ]
        , div [ Attr.class "datetime-inputs" ]
            [ input [ Attr.type_ "date", Attr.value dateValue, onInput dateMessage ] []
            , input [ Attr.type_ "time", Attr.value timeValue, onInput timeMessage ] []
            ]
        ]


choiceButton : Bool -> FrontendMsg -> String -> String -> Html FrontendMsg
choiceButton selected message heading detail =
    button
        [ Attr.class
            (if selected then
                "choice-card is-selected"

             else
                "choice-card"
            )
        , onClick message
        ]
        [ span [ Attr.class "radio-dot" ] []
        , span [ Attr.class "choice-copy" ]
            [ strongText heading
            , smallText detail
            ]
        ]


personChoice : Person -> Person -> Html FrontendMsg
personChoice selected person =
    button
        [ Attr.class
            (if selected == person then
                "choice-card person-choice is-selected"

             else
                "choice-card person-choice"
            )
        , onClick (ChangeAssignee person)
        ]
        [ personAvatar person
        , strongText (Domain.personLabel person)
        , span [ Attr.class "radio-dot" ] []
        ]


strongText : String -> Html msg
strongText value =
    span [ Attr.class "strong-text" ] [ text value ]


viewDeleteDialog : Model -> Html FrontendMsg
viewDeleteDialog model =
    case model.pendingDelete of
        Nothing ->
            text ""

        Just eventId ->
            let
                eventTitle =
                    findEvent eventId model.events
                        |> Maybe.map .title
                        |> Maybe.withDefault "Diesen Termin"
            in
            div [ Attr.class "modal-backdrop delete-backdrop" ]
                [ div [ Attr.class "delete-dialog", Attr.attribute "role" "alertdialog", Attr.attribute "aria-modal" "true" ]
                    [ div [ Attr.class "delete-icon" ] [ text "×" ]
                    , h2 [] [ text "Termin löschen?" ]
                    , p [] [ text ("„" ++ eventTitle ++ "“ wird dauerhaft aus dem Zeitplan entfernt.") ]
                    , div [ Attr.class "delete-actions" ]
                        [ button [ Attr.class "button button-ghost", onClick CancelDelete ] [ text "Abbrechen" ]
                        , button [ Attr.class "button button-danger", onClick (ConfirmDelete eventId) ] [ text "Termin löschen" ]
                        ]
                    ]
                ]


styles : String
styles =
    """
:root {
  --ink: #19231d;
  --muted: #68726c;
  --paper: #f3f3ed;
  --surface: #fffefa;
  --line: #dfe2d9;
  --green: #21543d;
  --green-soft: #e3eee6;
  --lime: #d7e8a7;
  --orange: #d4753d;
  --orange-soft: #f5e6dc;
  --violet: #655483;
  --violet-soft: #e9e4f0;
  --shadow: 0 18px 45px rgba(35, 47, 39, .09);
}

* { box-sizing: border-box; }
body { margin: 0; background: var(--paper); color: var(--ink); font-family: Inter, ui-sans-serif, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
button, input, textarea { font: inherit; }
button { color: inherit; }
.app-shell { min-height: 100vh; background: radial-gradient(circle at 80% 7%, rgba(215,232,167,.22), transparent 30%), var(--paper); }
.topbar { height: 82px; padding: 0 max(28px, calc((100vw - 1180px)/2)); display: flex; align-items: center; justify-content: space-between; background: rgba(255,254,250,.88); border-bottom: 1px solid var(--line); backdrop-filter: blur(16px); position: sticky; top: 0; z-index: 20; }
.brand { display: flex; align-items: center; gap: 12px; }
.brand-mark { width: 42px; height: 42px; display: grid; place-items: center; background: var(--green); border-radius: 50% 50% 50% 12px; color: white; font-family: Georgia, serif; font-size: 23px; font-style: italic; }
.brand-name { font-family: Georgia, serif; font-size: 21px; line-height: 1; letter-spacing: -.4px; }
.brand-subtitle, .section-kicker { margin-top: 5px; color: #89908a; font-size: 9px; font-weight: 800; letter-spacing: 1.8px; }
.topbar-actions { display: flex; align-items: center; gap: 22px; }
.sync-state { display: flex; align-items: center; gap: 8px; color: var(--muted); font-size: 12px; font-weight: 650; }
.sync-dot { width: 7px; height: 7px; background: #66a879; border-radius: 50%; box-shadow: 0 0 0 4px rgba(102,168,121,.12); }
.sync-dot.is-busy { background: #d0a151; animation: pulse 1.2s infinite; }
.sync-error { color: #a9473f; }
.sync-error .sync-dot { background: #c75850; }
@keyframes pulse { 50% { opacity: .4; } }
.button { min-height: 44px; padding: 0 18px; display: inline-flex; align-items: center; justify-content: center; gap: 10px; border: 1px solid transparent; border-radius: 10px; cursor: pointer; font-size: 13px; font-weight: 750; transition: transform .18s, box-shadow .18s, background .18s; }
.button:hover { transform: translateY(-1px); }
.button-primary { background: var(--green); color: white; box-shadow: 0 7px 20px rgba(33,84,61,.18); }
.button-primary:hover { background: #174832; }
.button-plus { font-size: 20px; font-weight: 400; line-height: 0; }
.button-secondary, .button-ghost { background: white; border-color: var(--line); }
.button-danger { background: #a7433d; color: white; }
.arrow { font-size: 17px; }
.page { width: min(1180px, calc(100% - 56px)); margin: 0 auto; padding-bottom: 90px; }
.hero { padding: 82px 0 50px; }
.eyebrow { display: flex; align-items: center; gap: 12px; color: var(--green); font-size: 10px; font-weight: 850; letter-spacing: 2.2px; }
.eyebrow-line { width: 34px; height: 2px; background: var(--orange); }
.hero-row { display: grid; grid-template-columns: 1.5fr .7fr; gap: 80px; align-items: end; margin-top: 22px; }
.hero h1 { margin: 0; font-family: Georgia, "Times New Roman", serif; font-size: clamp(42px, 5vw, 66px); line-height: .99; letter-spacing: -2.6px; font-weight: 500; }
.hero h1 span { color: var(--green); font-style: italic; }
.hero-copy { margin: 0 0 4px; color: var(--muted); line-height: 1.72; font-size: 15px; max-width: 410px; }
.hero-hint { margin-top: 34px; display: inline-flex; align-items: center; gap: 12px; color: var(--muted); font-size: 12px; }
.hint-icon { width: 26px; height: 26px; display: grid; place-items: center; border: 1px solid #bdc5bc; border-radius: 50%; color: var(--green); }
.stats-grid { display: grid; grid-template-columns: 1fr 1fr 1.35fr; gap: 16px; }
.stat-card { min-height: 155px; padding: 23px 25px; background: rgba(255,254,250,.86); border: 1px solid var(--line); border-radius: 15px; box-shadow: 0 3px 14px rgba(36,48,39,.035); }
.stat-top { display: flex; justify-content: space-between; align-items: center; }
.stat-heading { color: var(--muted); font-size: 11px; font-weight: 800; letter-spacing: 1px; text-transform: uppercase; }
.stat-icon { width: 31px; height: 31px; display: grid; place-items: center; border-radius: 8px; background: var(--green-soft); color: var(--green); font-size: 18px; }
.stat-icon.repeat { background: var(--orange-soft); color: var(--orange); }
.stat-number { margin-top: 10px; font-family: Georgia, serif; font-size: 43px; line-height: 1; }
.stat-detail { margin-top: 7px; color: #8a918c; font-size: 11px; }
.people-counts { height: 91px; display: flex; align-items: center; gap: 26px; }
.people-counts > div:not(.people-divider) { display: grid; grid-template-columns: 36px auto; grid-template-rows: 22px 17px; column-gap: 12px; align-items: center; }
.people-counts .avatar { grid-row: 1 / 3; }
.people-counts span:not(.avatar) { font-family: Georgia, serif; font-size: 23px; }
.people-counts .small-text { color: #8a918c; font-family: inherit !important; font-size: 10px !important; }
.people-divider { width: 1px; height: 42px; background: var(--line); }
.avatar { width: 29px; height: 29px; display: inline-grid; place-items: center; border-radius: 50%; font-size: 11px; font-weight: 850; flex: 0 0 auto; }
.avatar-a { background: var(--green); color: white; }
.avatar-b { background: var(--orange-soft); color: #a54f26; }
.people-counts .avatar { width: 36px; height: 36px; }
.events-section { margin-top: 72px; }
.section-title-row { display: flex; align-items: end; justify-content: space-between; margin-bottom: 22px; }
.section-title-row h2, .modal-header h2 { margin: 4px 0 0; font-family: Georgia, serif; font-size: 31px; font-weight: 500; letter-spacing: -.8px; }
.result-count { color: #8b938d; font-size: 11px; }
.filterbar { display: flex; justify-content: space-between; align-items: center; gap: 18px; margin-bottom: 17px; }
.search-wrap { position: relative; flex: 1; max-width: 390px; }
.search-icon { position: absolute; left: 14px; top: 9px; color: #7a837d; font-size: 21px; }
.search-input { width: 100%; height: 42px; padding: 0 14px 0 42px; background: rgba(255,255,255,.7); border: 1px solid var(--line); border-radius: 10px; outline: none; font-size: 12px; }
.search-input:focus, .field input:focus, .field textarea:focus { border-color: #6e8f7a; box-shadow: 0 0 0 3px rgba(33,84,61,.09); }
.filter-groups { display: flex; gap: 9px; }
.filter-pills { display: flex; padding: 3px; background: #e8e9e2; border-radius: 9px; }
.filter-pill { height: 32px; padding: 0 13px; border: 0; background: transparent; border-radius: 7px; color: #747d77; cursor: pointer; font-size: 10px; font-weight: 750; }
.filter-pill.is-active { background: var(--surface); color: var(--ink); box-shadow: 0 2px 8px rgba(32,42,35,.08); }
.event-list { display: grid; gap: 12px; }
.event-card { display: grid; grid-template-columns: 104px 1fr; min-height: 210px; background: var(--surface); border: 1px solid var(--line); border-radius: 15px; overflow: hidden; transition: border-color .18s, box-shadow .18s, transform .18s; }
.event-card:hover { border-color: #cbd2c8; box-shadow: 0 10px 35px rgba(35,47,39,.07); transform: translateY(-1px); }
.date-block { display: flex; flex-direction: column; align-items: center; padding-top: 38px; background: #edf0e7; border-right: 1px solid var(--line); }
.date-month { color: var(--orange); font-size: 10px; font-weight: 900; letter-spacing: 1.6px; }
.date-day { margin-top: 6px; font-family: Georgia, serif; font-size: 40px; line-height: 1; }
.event-main { padding: 25px 29px 22px; min-width: 0; }
.event-head { display: flex; justify-content: space-between; gap: 20px; }
.event-badges { display: flex; align-items: center; gap: 8px; }
.badge { min-height: 23px; padding: 0 9px; display: inline-flex; align-items: center; gap: 5px; border-radius: 20px; font-size: 9px; font-weight: 850; letter-spacing: .45px; text-transform: uppercase; }
.badge-once { background: #ebede8; color: #667169; }
.badge-semester { background: var(--orange-soft); color: #a0522c; }
.badge-year { background: var(--violet-soft); color: var(--violet); }
.badge-repeat { font-size: 13px; }
.person-badge { display: inline-flex; align-items: center; gap: 6px; color: #69726c; font-size: 10px; font-weight: 750; }
.person-badge .avatar { width: 22px; height: 22px; font-size: 9px; }
.event-title { margin: 13px 0 9px; font-family: Georgia, serif; font-size: 24px; font-weight: 500; letter-spacing: -.3px; }
.card-actions { display: flex; gap: 5px; }
.icon-button { width: 34px; height: 34px; border: 1px solid var(--line); border-radius: 8px; background: white; color: #5f6962; cursor: pointer; }
.icon-button:hover { background: #f2f4ef; }
.icon-button.danger:hover { color: #a7433d; background: #faeeee; border-color: #ecd0ce; }
.event-time { display: flex; align-items: center; gap: 7px; color: #667069; font-size: 12px; }
.time-icon { color: var(--green); font-size: 17px; }
.comment-box { margin-top: 18px; padding: 13px 15px; display: flex; gap: 12px; background: #f5f5ef; border-left: 2px solid #aac166; border-radius: 0 8px 8px 0; }
.comment-mark { width: 20px; height: 20px; display: grid; place-items: center; flex: 0 0 auto; border-radius: 50%; background: var(--lime); color: var(--green); font-size: 10px; font-weight: 900; }
.comment-label, .preview-label { display: block; color: #879087; font-size: 8px; font-weight: 900; letter-spacing: 1.2px; }
.comment-box p { margin: 4px 0 0; color: #4f5b53; font-size: 11px; line-height: 1.45; white-space: pre-wrap; }
.recurrence-preview { margin-top: 17px; padding-top: 15px; display: flex; align-items: center; gap: 18px; border-top: 1px solid #eceee8; }
.preview-dates { display: flex; flex-wrap: wrap; gap: 7px; }
.preview-dates span { padding: 5px 9px; background: #f0f2ec; border-radius: 5px; color: #69736c; font-size: 9px; font-weight: 700; }
.empty-state { padding: 58px 20px; text-align: center; background: rgba(255,254,250,.7); border: 1px dashed #cbd0c7; border-radius: 15px; }
.empty-symbol { width: 50px; height: 50px; margin: 0 auto 17px; display: grid; place-items: center; border-radius: 50%; background: var(--green-soft); color: var(--green); font-size: 27px; }
.empty-state h3 { margin: 0; font-family: Georgia, serif; font-size: 24px; font-weight: 500; }
.empty-state p { margin: 9px auto 20px; max-width: 440px; color: var(--muted); font-size: 12px; line-height: 1.6; }
.loading-card { padding: 35px; background: var(--surface); border: 1px solid var(--line); border-radius: 15px; }
.loading-line { width: 42%; height: 11px; margin: 13px 0; background: #e7e9e3; border-radius: 10px; animation: pulse 1.3s infinite; }
.loading-line.wide { width: 70%; height: 18px; }.loading-line.short { width: 25%; }
.toast { position: fixed; right: 25px; bottom: 25px; z-index: 60; min-width: 300px; padding: 14px 16px; display: flex; align-items: center; gap: 11px; background: #183b2c; color: white; border-radius: 11px; box-shadow: 0 16px 40px rgba(20,40,29,.28); font-size: 12px; }
.toast-check { width: 21px; height: 21px; display: grid; place-items: center; background: #d7e8a7; color: #214f39; border-radius: 50%; font-size: 10px; font-weight: 900; }
.toast-close { margin-left: auto; border: 0; background: transparent; color: #cbd8d0; cursor: pointer; font-size: 19px; }
.modal-backdrop { position: fixed; inset: 0; z-index: 50; display: grid; place-items: center; padding: 25px; background: rgba(17,28,22,.53); backdrop-filter: blur(5px); }
.editor-modal { width: min(710px, 100%); max-height: calc(100vh - 50px); display: flex; flex-direction: column; background: var(--surface); border-radius: 18px; box-shadow: 0 30px 90px rgba(15,28,20,.3); overflow: hidden; }
.modal-header { padding: 25px 30px 20px; display: flex; align-items: start; justify-content: space-between; border-bottom: 1px solid var(--line); }
.modal-header h2 { font-size: 29px; }
.modal-close { width: 35px; height: 35px; border: 0; border-radius: 50%; background: #eff0ea; color: #59645d; cursor: pointer; font-size: 21px; }
.modal-body { padding: 24px 30px; overflow-y: auto; }
.field { margin-bottom: 19px; }
.field > label { display: block; margin-bottom: 8px; color: #4d5851; font-size: 10px; font-weight: 850; letter-spacing: .7px; text-transform: uppercase; }
.required { color: var(--orange); }.optional { color: #a2a8a3; font-weight: 550; letter-spacing: 0; text-transform: none; }
.field input, .field textarea { width: 100%; padding: 0 13px; background: white; border: 1px solid #d9ddd5; border-radius: 9px; outline: 0; color: var(--ink); font-size: 12px; }
.field input { height: 43px; }.field textarea { min-height: 92px; padding-top: 12px; resize: vertical; line-height: 1.5; }
.form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }
.datetime-inputs { display: grid; grid-template-columns: 1.35fr .8fr; gap: 7px; }
.choice-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 8px; }
.choice-grid-three { grid-template-columns: repeat(3, 1fr); }
.choice-card { min-height: 58px; padding: 10px 12px; display: flex; align-items: center; gap: 10px; text-align: left; background: white; border: 1px solid #daddd6; border-radius: 9px; cursor: pointer; }
.choice-card:hover { border-color: #9ca99e; }.choice-card.is-selected { background: #f1f6f2; border-color: var(--green); box-shadow: 0 0 0 1px var(--green); }
.radio-dot { width: 14px; height: 14px; flex: 0 0 auto; border: 1px solid #a6aea8; border-radius: 50%; box-shadow: inset 0 0 0 3px white; }
.is-selected .radio-dot { background: var(--green); border-color: var(--green); }
.choice-copy { display: flex; flex-direction: column; gap: 3px; min-width: 0; }
.strong-text { font-size: 11px; font-weight: 800; }.choice-copy .small-text { color: #8b938e; font-size: 8px; white-space: nowrap; }
.person-choice .avatar { width: 27px; height: 27px; }.person-choice .radio-dot { margin-left: auto; }
.form-error { min-height: 39px; padding: 10px 12px; display: flex; align-items: center; gap: 9px; background: #faece9; border-radius: 8px; color: #9d3e37; font-size: 11px; }
.form-error span { width: 18px; height: 18px; display: grid; place-items: center; border: 1px solid #c66d66; border-radius: 50%; font-weight: 900; }
.modal-footer { padding: 17px 30px; display: flex; justify-content: flex-end; gap: 9px; background: #f5f5ef; border-top: 1px solid var(--line); }
.delete-backdrop { z-index: 70; }.delete-dialog { width: min(410px, 100%); padding: 31px; text-align: center; background: var(--surface); border-radius: 17px; box-shadow: var(--shadow); }
.delete-icon { width: 47px; height: 47px; margin: 0 auto 15px; display: grid; place-items: center; border-radius: 50%; background: #f8e6e3; color: #a7433d; font-size: 25px; }
.delete-dialog h2 { margin: 0; font-family: Georgia, serif; font-weight: 500; }.delete-dialog p { margin: 10px 0 24px; color: var(--muted); font-size: 12px; line-height: 1.55; }
.delete-actions { display: flex; justify-content: center; gap: 8px; }

@media (max-width: 860px) {
  .hero-row { grid-template-columns: 1fr; gap: 24px; }.hero-copy { max-width: 600px; }
  .stats-grid { grid-template-columns: 1fr 1fr; }.people-stat { grid-column: 1 / 3; }
  .filterbar { align-items: stretch; flex-direction: column; }.search-wrap { max-width: none; }.filter-groups { justify-content: space-between; }
}

@media (max-width: 620px) {
  .topbar { height: 70px; padding: 0 18px; }.brand-subtitle, .hide-mobile { display: none; }.brand-mark { width: 36px; height: 36px; }.brand-name { font-size: 18px; }
  .topbar .button { min-height: 39px; padding: 0 13px; }.page { width: calc(100% - 28px); }.hero { padding: 50px 0 36px; }.hero h1 { font-size: 41px; letter-spacing: -1.8px; }
  .stats-grid { grid-template-columns: 1fr 1fr; gap: 9px; }.stat-card { min-height: 135px; padding: 18px; }.people-stat { grid-column: 1 / 3; }.stat-number { font-size: 36px; }
  .events-section { margin-top: 52px; }.filter-groups { align-items: flex-start; flex-direction: column; overflow-x: visible; padding-bottom: 3px; }.filter-pills { max-width: 100%; overflow-x: auto; }.recurrence-pills { order: -1; }
  .event-card { grid-template-columns: 69px 1fr; }.date-block { padding-top: 31px; }.date-day { font-size: 31px; }.event-main { padding: 20px 17px; }.event-title { font-size: 21px; }.event-head { gap: 8px; }.person-badge { font-size: 0; }
  .recurrence-preview { align-items: start; flex-direction: column; gap: 8px; }.preview-dates { gap: 4px; }
  .modal-backdrop { padding: 0; place-items: end center; }.editor-modal { max-height: 94vh; border-radius: 18px 18px 0 0; }.modal-header, .modal-body { padding-left: 19px; padding-right: 19px; }.modal-footer { padding: 14px 19px; }
  .form-grid { grid-template-columns: 1fr; gap: 0; }.choice-grid-three { grid-template-columns: 1fr; }.choice-grid-three .choice-card { min-height: 49px; }
  .toast { left: 14px; right: 14px; bottom: 14px; min-width: 0; }.delete-dialog { margin: auto 14px; }
}
"""
