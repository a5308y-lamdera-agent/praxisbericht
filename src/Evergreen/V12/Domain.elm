module Evergreen.V12.Domain exposing (..)


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
    | EveryYear


type Person
    = PersonA
    | PersonB


type Assignment
    = OnlyPerson Person
    | BothPeople


type Tag
    = Tag String


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
    , tags : List Tag
    , comment : Comment
    , completedOccurrences : List OccurrenceIndex
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


type alias EventDraft =
    { title : String
    , window : TimeWindow
    , recurrence : Recurrence
    , assignment : Assignment
    , tags : List Tag
    , comment : Comment
    }
