module Evergreen.V10.Types exposing (..)

import Browser
import Browser.Navigation
import Evergreen.V10.Domain
import Url


type alias EventForm =
    { title : String
    , startDate : String
    , startTime : String
    , endDate : String
    , endTime : String
    , recurrence : Evergreen.V10.Domain.Recurrence
    , assignment : Evergreen.V10.Domain.Assignment
    , comment : String
    }


type EditorState
    = EditorClosed
    | CreatingEvent
    | DuplicatingEvent
    | EditingEvent Evergreen.V10.Domain.EventId


type PersonFilter
    = AllPeople
    | AssignedTo Evergreen.V10.Domain.Person


type RecurrenceFilter
    = AllRecurrences
    | OnlyRecurrence Evergreen.V10.Domain.Recurrence


type DateFilter
    = AllDates
    | InMonth Evergreen.V10.Domain.MonthOfYear
    | InRange Evergreen.V10.Domain.CalendarRange


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
    , events : List Evergreen.V10.Domain.Event
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
    , pendingDelete : Maybe Evergreen.V10.Domain.EventId
    }


type alias BackendModel =
    { events : List Evergreen.V10.Domain.Event
    , nextEventId : Int
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | OpenCreateEditor
    | OpenDuplicateEditor Evergreen.V10.Domain.EventId
    | OpenEditEditor Evergreen.V10.Domain.EventId
    | CloseEditor
    | ChangeTitle String
    | ChangeStartDate String
    | ChangeStartTime String
    | ChangeEndDate String
    | ChangeEndTime String
    | ChangeRecurrence Evergreen.V10.Domain.Recurrence
    | ChangeAssignment Evergreen.V10.Domain.Assignment
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
    | AskDelete Evergreen.V10.Domain.EventId
    | CancelDelete
    | ConfirmDelete Evergreen.V10.Domain.EventId
    | ToggleOccurrence Evergreen.V10.Domain.EventId Evergreen.V10.Domain.OccurrenceIndex
    | DismissNotice


type ToBackend
    = RequestEvents
    | CreateEvent Evergreen.V10.Domain.EventDraft
    | UpdateEvent Evergreen.V10.Domain.EventId Evergreen.V10.Domain.EventDraft
    | DeleteEvent Evergreen.V10.Domain.EventId
    | ToggleOccurrenceCompletion Evergreen.V10.Domain.EventId Evergreen.V10.Domain.OccurrenceIndex


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = EventsLoaded (List Evergreen.V10.Domain.Event)
    | EventsChanged (List Evergreen.V10.Domain.Event) String
    | ChangeRejected String
