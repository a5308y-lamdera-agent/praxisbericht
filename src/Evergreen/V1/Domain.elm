module Evergreen.V1.Domain exposing (..)


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


type Comment
    = NoComment
    | Comment String


type alias Event =
    { id : EventId
    , title : String
    , window : TimeWindow
    , recurrence : Recurrence
    , assignee : Person
    , comment : Comment
    }


type alias EventDraft =
    { title : String
    , window : TimeWindow
    , recurrence : Recurrence
    , assignee : Person
    , comment : Comment
    }
