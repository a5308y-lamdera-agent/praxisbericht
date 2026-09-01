module Domain exposing
    ( Assignment(..)
    , CalendarDate(..)
    , ClockTime(..)
    , Comment(..)
    , Event
    , EventDraft
    , EventId(..)
    , Moment(..)
    , Occurrence
    , OccurrenceIndex(..)
    , Person(..)
    , Recurrence(..)
    , TimeWindow(..)
    , assignmentIncludes
    , assignmentLabel
    , calendarDate
    , commentFromString
    , commentToString
    , dateFromIso
    , dateToGerman
    , dateToIso
    , draftIsValid
    , eventFromDraft
    , eventIdToInt
    , eventToDraft
    , momentDate
    , momentTime
    , occurrenceWindows
    , occurrences
    , personLabel
    , recurrenceLabel
    , timeFromIso
    , timeToIso
    , timeWindow
    , toggleOccurrenceCompletion
    , updateEventFromDraft
    , windowEnd
    , windowStart
    , windowToGerman
    )

{-| The domain model deliberately uses small custom types instead of a generic
dictionary-shaped data model. Application code constructs calendar dates, clock
times and time windows through the validating functions below. Their variants
remain exposed because Lamdera's generated Evergreen migrations require them.
-}


type EventId
    = EventId Int


type Person
    = PersonA
    | PersonB


type Assignment
    = OnlyPerson Person
    | BothPeople


type Recurrence
    = OneTime
    | EverySemester
    | EveryYear


type Comment
    = NoComment
    | Comment String


type CalendarDate
    = CalendarDate
        { year : Int
        , month : Int
        , day : Int
        }


type ClockTime
    = ClockTime
        { hour : Int
        , minute : Int
        }


type Moment
    = Moment
        { date : CalendarDate
        , time : ClockTime
        }


type TimeWindow
    = TimeWindow
        { start : Moment
        , end : Moment
        }


type OccurrenceIndex
    = OccurrenceIndex Int


type alias Occurrence =
    { index : OccurrenceIndex
    , window : TimeWindow
    , isCompleted : Bool
    }


type alias EventDraft =
    { title : String
    , window : TimeWindow
    , recurrence : Recurrence
    , assignment : Assignment
    , comment : Comment
    }


type alias Event =
    { id : EventId
    , title : String
    , window : TimeWindow
    , recurrence : Recurrence
    , assignment : Assignment
    , comment : Comment
    , completedOccurrences : List OccurrenceIndex
    }


eventIdToInt : EventId -> Int
eventIdToInt (EventId value) =
    value


personLabel : Person -> String
personLabel person =
    case person of
        PersonA ->
            "Antonia"

        PersonB ->
            "Theresa"


assignmentLabel : Assignment -> String
assignmentLabel assignment =
    case assignment of
        OnlyPerson person ->
            personLabel person

        BothPeople ->
            "Antonia & Theresa"


assignmentIncludes : Person -> Assignment -> Bool
assignmentIncludes person assignment =
    case assignment of
        OnlyPerson assignedPerson ->
            person == assignedPerson

        BothPeople ->
            True


recurrenceLabel : Recurrence -> String
recurrenceLabel recurrence =
    case recurrence of
        OneTime ->
            "Einmalig"

        EverySemester ->
            "Jedes Semester"

        EveryYear ->
            "Jährlich"


commentFromString : String -> Comment
commentFromString rawComment =
    let
        cleaned =
            String.trim rawComment
    in
    if String.isEmpty cleaned then
        NoComment

    else
        Comment cleaned


commentToString : Comment -> String
commentToString comment =
    case comment of
        NoComment ->
            ""

        Comment value ->
            value


calendarDate : Int -> Int -> Int -> Result String CalendarDate
calendarDate year month day =
    if year < 1900 || year > 2200 then
        Err "Das Jahr muss zwischen 1900 und 2200 liegen."

    else if month < 1 || month > 12 then
        Err "Der Monat ist ungültig."

    else if day < 1 || day > daysInMonth year month then
        Err "Der Tag ist für diesen Monat ungültig."

    else
        Ok (CalendarDate { year = year, month = month, day = day })


clockTime : Int -> Int -> Result String ClockTime
clockTime hour minute =
    if hour < 0 || hour > 23 || minute < 0 || minute > 59 then
        Err "Die Uhrzeit ist ungültig."

    else
        Ok (ClockTime { hour = hour, minute = minute })


timeWindow : CalendarDate -> ClockTime -> CalendarDate -> ClockTime -> Result String TimeWindow
timeWindow startDate startTime endDate endTime =
    let
        start =
            Moment { date = startDate, time = startTime }

        end =
            Moment { date = endDate, time = endTime }
    in
    if compareMoment start end == LT then
        Ok (TimeWindow { start = start, end = end })

    else
        Err "Das Ende muss nach dem Beginn liegen."


windowStart : TimeWindow -> Moment
windowStart (TimeWindow window) =
    window.start


windowEnd : TimeWindow -> Moment
windowEnd (TimeWindow window) =
    window.end


momentDate : Moment -> CalendarDate
momentDate (Moment value) =
    value.date


momentTime : Moment -> ClockTime
momentTime (Moment value) =
    value.time


dateFromIso : String -> Result String CalendarDate
dateFromIso value =
    case String.split "-" value of
        [ rawYear, rawMonth, rawDay ] ->
            case ( String.toInt rawYear, String.toInt rawMonth, String.toInt rawDay ) of
                ( Just year, Just month, Just day ) ->
                    calendarDate year month day

                _ ->
                    Err "Bitte ein vollständiges Datum angeben."

        _ ->
            Err "Bitte ein vollständiges Datum angeben."


timeFromIso : String -> Result String ClockTime
timeFromIso value =
    case String.split ":" value of
        [ rawHour, rawMinute ] ->
            case ( String.toInt rawHour, String.toInt rawMinute ) of
                ( Just hour, Just minute ) ->
                    clockTime hour minute

                _ ->
                    Err "Bitte eine vollständige Uhrzeit angeben."

        _ ->
            Err "Bitte eine vollständige Uhrzeit angeben."


dateToIso : CalendarDate -> String
dateToIso (CalendarDate value) =
    String.fromInt value.year
        ++ "-"
        ++ pad2 value.month
        ++ "-"
        ++ pad2 value.day


dateToGerman : CalendarDate -> String
dateToGerman (CalendarDate value) =
    pad2 value.day
        ++ "."
        ++ pad2 value.month
        ++ "."
        ++ String.fromInt value.year


timeToIso : ClockTime -> String
timeToIso (ClockTime value) =
    pad2 value.hour ++ ":" ++ pad2 value.minute


windowToGerman : TimeWindow -> String
windowToGerman window =
    let
        start =
            windowStart window

        end =
            windowEnd window

        startDate =
            momentDate start

        endDate =
            momentDate end
    in
    if dateToIso startDate == dateToIso endDate then
        dateToGerman startDate
            ++ ", "
            ++ timeToIso (momentTime start)
            ++ "–"
            ++ timeToIso (momentTime end)
            ++ " Uhr"

    else
        dateToGerman startDate
            ++ ", "
            ++ timeToIso (momentTime start)
            ++ " – "
            ++ dateToGerman endDate
            ++ ", "
            ++ timeToIso (momentTime end)
            ++ " Uhr"


eventFromDraft : EventId -> EventDraft -> Event
eventFromDraft id draft =
    { id = id
    , title = String.trim draft.title
    , window = draft.window
    , recurrence = draft.recurrence
    , assignment = draft.assignment
    , comment = draft.comment
    , completedOccurrences = []
    }


updateEventFromDraft : EventDraft -> Event -> Event
updateEventFromDraft draft event =
    { event
        | title = String.trim draft.title
        , window = draft.window
        , recurrence = draft.recurrence
        , assignment = draft.assignment
        , comment = draft.comment
    }


eventToDraft : Event -> EventDraft
eventToDraft event =
    { title = event.title
    , window = event.window
    , recurrence = event.recurrence
    , assignment = event.assignment
    , comment = event.comment
    }


draftIsValid : EventDraft -> Bool
draftIsValid draft =
    not (String.isEmpty (String.trim draft.title))


occurrenceWindows : Int -> Event -> List TimeWindow
occurrenceWindows requestedCount event =
    occurrences requestedCount event
        |> List.map .window


occurrences : Int -> Event -> List Occurrence
occurrences requestedCount event =
    let
        count =
            max 1 requestedCount

        monthStep =
            case event.recurrence of
                OneTime ->
                    0

                EverySemester ->
                    6

                EveryYear ->
                    12
    in
    case event.recurrence of
        OneTime ->
            [ occurrenceFor event 0 event.window ]

        _ ->
            List.range 0 (count - 1)
                |> List.map
                    (\index ->
                        occurrenceFor event index (shiftWindow (index * monthStep) event.window)
                    )


occurrenceFor : Event -> Int -> TimeWindow -> Occurrence
occurrenceFor event rawIndex window =
    let
        index =
            OccurrenceIndex rawIndex
    in
    { index = index
    , window = window
    , isCompleted = List.member index event.completedOccurrences
    }


toggleOccurrenceCompletion : OccurrenceIndex -> Event -> Event
toggleOccurrenceCompletion ((OccurrenceIndex rawIndex) as index) event =
    if rawIndex < 0 || (event.recurrence == OneTime && rawIndex /= 0) then
        event

    else if List.member index event.completedOccurrences then
        { event
            | completedOccurrences =
                List.filter ((/=) index) event.completedOccurrences
        }

    else
        { event | completedOccurrences = index :: event.completedOccurrences }


shiftWindow : Int -> TimeWindow -> TimeWindow
shiftWindow monthOffset (TimeWindow window) =
    TimeWindow
        { start = shiftMoment monthOffset window.start
        , end = shiftMoment monthOffset window.end
        }


shiftMoment : Int -> Moment -> Moment
shiftMoment monthOffset (Moment value) =
    Moment
        { date = addMonths monthOffset value.date
        , time = value.time
        }


addMonths : Int -> CalendarDate -> CalendarDate
addMonths amount (CalendarDate value) =
    let
        monthIndex =
            value.year * 12 + (value.month - 1) + amount

        newYear =
            monthIndex // 12

        newMonth =
            modBy 12 monthIndex + 1

        newDay =
            min value.day (daysInMonth newYear newMonth)
    in
    CalendarDate { year = newYear, month = newMonth, day = newDay }


compareMoment : Moment -> Moment -> Order
compareMoment (Moment left) (Moment right) =
    compare (momentSortValue left) (momentSortValue right)


momentSortValue : { date : CalendarDate, time : ClockTime } -> Int
momentSortValue value =
    let
        (CalendarDate date) =
            value.date

        (ClockTime time) =
            value.time
    in
    (((date.year * 13 + date.month) * 32 + date.day) * 24 + time.hour) * 60 + time.minute


daysInMonth : Int -> Int -> Int
daysInMonth year month =
    case month of
        2 ->
            if isLeapYear year then
                29

            else
                28

        4 ->
            30

        6 ->
            30

        9 ->
            30

        11 ->
            30

        _ ->
            31


isLeapYear : Int -> Bool
isLeapYear year =
    (modBy 400 year == 0) || (modBy 4 year == 0 && modBy 100 year /= 0)


pad2 : Int -> String
pad2 value =
    if value < 10 then
        "0" ++ String.fromInt value

    else
        String.fromInt value
