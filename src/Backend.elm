module Backend exposing (app, init, update, updateFromFrontend)

import Domain exposing (EventId(..), draftIsValid, eventFromDraft, toggleOccurrenceCompletion, updateEventFromDraft)
import Lamdera exposing (ClientId, SessionId)
import Types exposing (BackendModel, BackendMsg(..), ToBackend(..), ToFrontend(..))


type alias Model =
    BackendModel


app =
    Lamdera.backend
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = \_ -> Sub.none
        }


init : ( Model, Cmd BackendMsg )
init =
    ( { events = []
      , nextEventId = 1
      }
    , Cmd.none
    )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        NoOpBackendMsg ->
            ( model, Cmd.none )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend _ clientId msg model =
    case msg of
        RequestEvents ->
            ( model, Lamdera.sendToFrontend clientId (EventsLoaded model.events) )

        CreateEvent draft ->
            if draftIsValid draft then
                let
                    event =
                        eventFromDraft (EventId model.nextEventId) draft

                    nextModel =
                        { model
                            | events = event :: model.events
                            , nextEventId = model.nextEventId + 1
                        }
                in
                ( nextModel
                , Lamdera.broadcast (EventsChanged nextModel.events "Termin wurde angelegt.")
                )

            else
                ( model, Lamdera.sendToFrontend clientId (ChangeRejected "Der Titel darf nicht leer sein.") )

        UpdateEvent eventId draft ->
            if not (draftIsValid draft) then
                ( model, Lamdera.sendToFrontend clientId (ChangeRejected "Der Titel darf nicht leer sein.") )

            else if List.any (\event -> event.id == eventId) model.events then
                let
                    nextEvents =
                        List.map
                            (\event ->
                                if event.id == eventId then
                                    updateEventFromDraft draft event

                                else
                                    event
                            )
                            model.events

                    nextModel =
                        { model | events = nextEvents }
                in
                ( nextModel
                , Lamdera.broadcast (EventsChanged nextEvents "Änderungen wurden gespeichert.")
                )

            else
                ( model, Lamdera.sendToFrontend clientId (ChangeRejected "Der Termin existiert nicht mehr.") )

        DeleteEvent eventId ->
            let
                nextEvents =
                    List.filter (\event -> event.id /= eventId) model.events

                nextModel =
                    { model | events = nextEvents }
            in
            ( nextModel
            , Lamdera.broadcast (EventsChanged nextEvents "Termin wurde gelöscht.")
            )

        ToggleOccurrenceCompletion eventId occurrenceIndex ->
            if List.any (\event -> event.id == eventId) model.events then
                let
                    nextEvents =
                        List.map
                            (\event ->
                                if event.id == eventId then
                                    toggleOccurrenceCompletion occurrenceIndex event

                                else
                                    event
                            )
                            model.events

                    nextModel =
                        { model | events = nextEvents }
                in
                ( nextModel
                , Lamdera.broadcast (EventsChanged nextEvents "Erledigt-Status wurde aktualisiert.")
                )

            else
                ( model, Lamdera.sendToFrontend clientId (ChangeRejected "Der Termin existiert nicht mehr.") )
