module Evergreen.V9.Types exposing (..)

import Browser
import Browser.Navigation
import Evergreen.V9.Domain
import Url


type alias EventForm =
    { title : String
    , startDate : String
    , startTime : String
    , endDate : String
    , endTime : String
    , recurrence : Evergreen.V9.Domain.Recurrence
    , assignment : Evergreen.V9.Domain.Assignment
    , comment : String
    }


type EditorState
    = EditorClosed
    | CreatingEvent
    | EditingEvent Evergreen.V9.Domain.EventId


type PersonFilter
    = AllPeople
    | AssignedTo Evergreen.V9.Domain.Person


type RecurrenceFilter
    = AllRecurrences
    | OnlyRecurrence Evergreen.V9.Domain.Recurrence


type DateFilter
    = AllDates
    | InMonth Evergreen.V9.Domain.MonthOfYear
    | InRange Evergreen.V9.Domain.CalendarRange


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


type alias FrontendModel =
    { key : Browser.Navigation.Key
    , events : List Evergreen.V9.Domain.Event
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
    , pendingDelete : Maybe Evergreen.V9.Domain.EventId
    }


type alias BackendModel =
    { events : List Evergreen.V9.Domain.Event
    , nextEventId : Int
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | OpenCreateEditor
    | OpenEditEditor Evergreen.V9.Domain.EventId
    | CloseEditor
    | ChangeTitle String
    | ChangeStartDate String
    | ChangeStartTime String
    | ChangeEndDate String
    | ChangeEndTime String
    | ChangeRecurrence Evergreen.V9.Domain.Recurrence
    | ChangeAssignment Evergreen.V9.Domain.Assignment
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
    | AskDelete Evergreen.V9.Domain.EventId
    | CancelDelete
    | ConfirmDelete Evergreen.V9.Domain.EventId
    | ToggleOccurrence Evergreen.V9.Domain.EventId Evergreen.V9.Domain.OccurrenceIndex
    | DismissNotice


type ToBackend
    = RequestEvents
    | CreateEvent Evergreen.V9.Domain.EventDraft
    | UpdateEvent Evergreen.V9.Domain.EventId Evergreen.V9.Domain.EventDraft
    | DeleteEvent Evergreen.V9.Domain.EventId
    | ToggleOccurrenceCompletion Evergreen.V9.Domain.EventId Evergreen.V9.Domain.OccurrenceIndex


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = EventsLoaded (List Evergreen.V9.Domain.Event)
    | EventsChanged (List Evergreen.V9.Domain.Event) String
    | ChangeRejected String
