module Evergreen.V17.Domain exposing (..)


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


type TodoId
    = TodoId Int


type TodoText
    = TodoText String


type TodoStatus
    = TodoOpen
    | TodoCompleted


type alias TodoItem =
    { id : TodoId
    , text : TodoText
    , status : TodoStatus
    }


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
    , todos : List TodoItem
    , nextTodoId : Int
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
    , todos : List TodoText
    , comment : Comment
    }
