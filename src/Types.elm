module Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Domain exposing (Assignment, CalendarRange, Event, EventDraft, EventId, OccurrenceIndex, Person, Recurrence, YearMonth)
import Url exposing (Url)


type alias FrontendModel =
    { key : Key
    , events : List Event
    , form : EventForm
    , editor : EditorState
    , personFilter : PersonFilter
    , recurrenceFilter : RecurrenceFilter
    , dateFilter : DateFilter
    , dateFilterForm : DateFilterForm
    , search : String
    , formError : Maybe String
    , syncState : SyncState
    , notice : Maybe String
    , pendingDelete : Maybe EventId
    }


type alias EventForm =
    { title : String
    , startDate : String
    , startTime : String
    , endDate : String
    , endTime : String
    , recurrence : Recurrence
    , assignment : Assignment
    , comment : String
    }


type EditorState
    = EditorClosed
    | CreatingEvent
    | EditingEvent EventId


type PersonFilter
    = AllPeople
    | AssignedTo Person


type RecurrenceFilter
    = AllRecurrences
    | OnlyRecurrence Recurrence


type DateFilter
    = AllDates
    | InMonth YearMonth
    | InRange CalendarRange


type alias DateFilterForm =
    { month : String
    , rangeStart : String
    , rangeEnd : String
    , error : Maybe String
    }


type SyncState
    = Loading
    | Synced
    | Saving
    | SyncFailed String


type alias BackendModel =
    { events : List Event
    , nextEventId : Int
    }


type FrontendMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | OpenCreateEditor
    | OpenEditEditor EventId
    | CloseEditor
    | ChangeTitle String
    | ChangeStartDate String
    | ChangeStartTime String
    | ChangeEndDate String
    | ChangeEndTime String
    | ChangeRecurrence Recurrence
    | ChangeAssignment Assignment
    | ChangeComment String
    | SubmitEvent
    | ChangePersonFilter PersonFilter
    | ChangeRecurrenceFilter RecurrenceFilter
    | ChangeMonthFilter String
    | ChangeRangeStart String
    | ChangeRangeEnd String
    | ApplyDateRange
    | ClearDateFilter
    | ChangeSearch String
    | ResetFilters
    | AskDelete EventId
    | CancelDelete
    | ConfirmDelete EventId
    | ToggleOccurrence EventId OccurrenceIndex
    | DismissNotice


type ToBackend
    = RequestEvents
    | CreateEvent EventDraft
    | UpdateEvent EventId EventDraft
    | DeleteEvent EventId
    | ToggleOccurrenceCompletion EventId OccurrenceIndex


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = EventsLoaded (List Event)
    | EventsChanged (List Event) String
    | ChangeRejected String
