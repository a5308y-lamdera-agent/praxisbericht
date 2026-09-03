module Domain exposing
    ( Assignment(..)
    , CalendarDate(..)
    , CalendarRange(..)
    , ClockTime(..)
    , Comment(..)
    , Event
    , EventDraft
    , EventId(..)
    , Moment(..)
    , MonthOfYear(..)
    , Occurrence
    , OccurrenceIndex(..)
    , Person(..)
    , Recurrence(..)
    , Tag(..)
    , TimeWindow(..)
    , allMonths
    , assignmentIncludes
    , assignmentLabel
    , calendarDate
    , calendarRange
    , calendarRangeFromIso
    , calendarRangeToGerman
    , commentFromString
    , commentToString
    , dateFromIso
    , dateToGerman
    , dateToIso
    , draftIsValid
    , eventFromDraft
    , eventHasTag
    , eventIdToInt
    , eventOverlapsRange
    , eventToDraft
    , firstOccurrenceOverlapping
    , momentDate
    , momentTime
    , monthOfYearFromString
    , monthOfYearToGerman
    , monthOfYearToString
    , occurrenceWindows
    , occurrences
    , occurrencesFrom
    , personLabel
    , recurrenceLabel
    , tagEquals
    , tagToString
    , tagsFromString
    , tagsToString
    , timeFromIso
    , timeToIso
    , timeWindow
    , toggleOccurrenceCompletion
    , uniqueTags
    , updateEventFromDraft
    , windowEnd
    , windowStart
    , windowToGerman
    , windowTouchesMonth
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
    | EveryYear


type Comment
    = NoComment
    | Comment String


type Tag
    = Tag String


type CalendarDate
    = CalendarDate
        { year : Int
        , month : Int
        , day : Int
        }


type MonthOfYear
    = January
    | February
    | March
    | April
    | May
    | June
    | July
    | August
    | September
    | October
    | November
    | December


type CalendarRange
    = CalendarRange
        { start : CalendarDate
        , end : CalendarDate
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
    , tags : List Tag
    , comment : Comment
    }


type alias Event =
    { id : EventId
    , title : String
    , window : TimeWindow
    , recurrence : Recurrence
    , assignment : Assignment
    , tags : List Tag
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
            personLabel PersonA ++ " & " ++ personLabel PersonB


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

        EveryYear ->
            "Jährlich"


tagToString : Tag -> String
tagToString (Tag value) =
    value


tagEquals : Tag -> Tag -> Bool
tagEquals first second =
    tagKey first == tagKey second


tagsFromString : String -> List Tag
tagsFromString value =
    value
        |> String.split ","
        |> List.filterMap tagFromString
        |> uniqueTags


tagsToString : List Tag -> String
tagsToString tags =
    tags
        |> List.map tagToString
        |> String.join ", "


uniqueTags : List Tag -> List Tag
uniqueTags tags =
    List.foldl
        (\tag unique ->
            if List.any (tagEquals tag) unique then
                unique

            else
                tag :: unique
        )
        []
        tags
        |> List.reverse


eventHasTag : Tag -> Event -> Bool
eventHasTag selectedTag event =
    List.any (tagEquals selectedTag) event.tags


tagFromString : String -> Maybe Tag
tagFromString value =
    let
        cleaned =
            String.trim value
    in
    if String.isEmpty cleaned then
        Nothing

    else
        Just (Tag cleaned)


tagKey : Tag -> String
tagKey (Tag value) =
    value
        |> String.trim
        |> String.toLower


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


calendarRange : CalendarDate -> CalendarDate -> Result String CalendarRange
calendarRange start end =
    if compareDate start end == GT then
        Err "Das Ende des Zeitraums muss am oder nach dem Beginn liegen."

    else
        Ok (CalendarRange { start = start, end = end })


calendarRangeFromIso : String -> String -> Result String CalendarRange
calendarRangeFromIso rawStart rawEnd =
    dateFromIso rawStart
        |> Result.andThen
            (\start ->
                dateFromIso rawEnd
                    |> Result.andThen (calendarRange start)
            )


calendarRangeToGerman : CalendarRange -> String
calendarRangeToGerman (CalendarRange range) =
    dateToGerman range.start ++ " – " ++ dateToGerman range.end


allMonths : List MonthOfYear
allMonths =
    [ January
    , February
    , March
    , April
    , May
    , June
    , July
    , August
    , September
    , October
    , November
    , December
    ]


monthOfYearFromString : String -> Result String MonthOfYear
monthOfYearFromString value =
    value
        |> String.toInt
        |> Maybe.andThen monthOfYearFromNumber
        |> Result.fromMaybe "Bitte einen Monat auswählen."


monthOfYearToString : MonthOfYear -> String
monthOfYearToString month =
    month |> monthOfYearToNumber |> String.fromInt


monthOfYearToGerman : MonthOfYear -> String
monthOfYearToGerman month =
    case month of
        January ->
            "Januar"

        February ->
            "Februar"

        March ->
            "März"

        April ->
            "April"

        May ->
            "Mai"

        June ->
            "Juni"

        July ->
            "Juli"

        August ->
            "August"

        September ->
            "September"

        October ->
            "Oktober"

        November ->
            "November"

        December ->
            "Dezember"


windowTouchesMonth : MonthOfYear -> TimeWindow -> Bool
windowTouchesMonth selectedMonth window =
    let
        (CalendarDate start) =
            window |> windowStart |> momentDate

        (CalendarDate end) =
            window |> windowEnd |> momentDate

        startIndex =
            start.year * 12 + start.month - 1

        endIndex =
            end.year * 12 + end.month - 1
    in
    List.range startIndex endIndex
        |> List.any
            (\monthIndex ->
                modBy 12 monthIndex + 1 == monthOfYearToNumber selectedMonth
            )


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
    , tags = uniqueTags draft.tags
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
        , tags = uniqueTags draft.tags
        , comment = draft.comment
    }


eventToDraft : Event -> EventDraft
eventToDraft event =
    { title = event.title
    , window = event.window
    , recurrence = event.recurrence
    , assignment = event.assignment
    , tags = event.tags
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
    occurrencesFrom (OccurrenceIndex 0) requestedCount event


occurrencesFrom : OccurrenceIndex -> Int -> Event -> List Occurrence
occurrencesFrom (OccurrenceIndex requestedStart) requestedCount event =
    let
        startIndex =
            max 0 requestedStart

        count =
            max 1 requestedCount

        monthStep =
            case event.recurrence of
                OneTime ->
                    0

                EveryYear ->
                    12
    in
    case event.recurrence of
        OneTime ->
            if startIndex == 0 then
                [ occurrenceFor event 0 event.window ]

            else
                []

        _ ->
            List.range startIndex (startIndex + count - 1)
                |> List.map
                    (\index ->
                        occurrenceFor event index (shiftWindow (index * monthStep) event.window)
                    )


eventOverlapsRange : CalendarRange -> Event -> Bool
eventOverlapsRange range event =
    firstOccurrenceOverlapping range event /= Nothing


firstOccurrenceOverlapping : CalendarRange -> Event -> Maybe Occurrence
firstOccurrenceOverlapping range event =
    occurrenceCandidates range event
        |> List.filter (occurrenceOverlaps range)
        |> List.head


occurrenceCandidates : CalendarRange -> Event -> List Occurrence
occurrenceCandidates (CalendarRange range) event =
    let
        baseStart =
            event.window |> windowStart |> momentDate

        monthStep =
            case event.recurrence of
                OneTime ->
                    0

                EveryYear ->
                    12

        countThroughRange =
            if monthStep == 0 then
                1

            else
                max 1 (monthsBetween baseStart range.end // monthStep + 2)
    in
    if compareDate range.end baseStart == LT then
        []

    else
        occurrences countThroughRange event


occurrenceOverlaps : CalendarRange -> Occurrence -> Bool
occurrenceOverlaps (CalendarRange range) occurrence =
    let
        occurrenceStart =
            occurrence.window |> windowStart |> momentDate

        occurrenceEnd =
            occurrence.window |> windowEnd |> momentDate
    in
    compareDate occurrenceStart range.end
        /= GT
        && compareDate occurrenceEnd range.start
        /= LT


monthsBetween : CalendarDate -> CalendarDate -> Int
monthsBetween (CalendarDate start) (CalendarDate end) =
    (end.year * 12 + end.month) - (start.year * 12 + start.month)


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


compareDate : CalendarDate -> CalendarDate -> Order
compareDate (CalendarDate left) (CalendarDate right) =
    compare
        ((left.year * 13 + left.month) * 32 + left.day)
        ((right.year * 13 + right.month) * 32 + right.day)


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


monthOfYearFromNumber : Int -> Maybe MonthOfYear
monthOfYearFromNumber month =
    case month of
        1 ->
            Just January

        2 ->
            Just February

        3 ->
            Just March

        4 ->
            Just April

        5 ->
            Just May

        6 ->
            Just June

        7 ->
            Just July

        8 ->
            Just August

        9 ->
            Just September

        10 ->
            Just October

        11 ->
            Just November

        12 ->
            Just December

        _ ->
            Nothing


monthOfYearToNumber : MonthOfYear -> Int
monthOfYearToNumber month =
    case month of
        January ->
            1

        February ->
            2

        March ->
            3

        April ->
            4

        May ->
            5

        June ->
            6

        July ->
            7

        August ->
            8

        September ->
            9

        October ->
            10

        November ->
            11

        December ->
            12


pad2 : Int -> String
pad2 value =
    if value < 10 then
        "0" ++ String.fromInt value

    else
        String.fromInt value
