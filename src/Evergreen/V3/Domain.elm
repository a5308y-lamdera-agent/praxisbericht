module Evergreen.V3.Domain exposing (..)


type EventId
    = EventId Int


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


type Recurrence
    = OneTime
    | EverySemester
    | EveryYear


type Person
    = PersonA
    | PersonB


type Assignment
    = OnlyPerson Person
    | BothPeople


type Comment
    = NoComment
    | Comment String


type OccurrenceIndex
    = OccurrenceIndex Int


type alias Event =
    { id : EventId
    , title : String
    , window : TimeWindow
    , recurrence : Recurrence
    , assignment : Assignment
    , comment : Comment
    , completedOccurrences : List OccurrenceIndex
    }


type alias EventDraft =
    { title : String
    , window : TimeWindow
    , recurrence : Recurrence
    , assignment : Assignment
    , comment : Comment
    }
