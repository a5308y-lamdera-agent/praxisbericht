module Evergreen.V12.Types exposing (..)

import Browser
import Browser.Navigation
import Evergreen.V12.Domain
import Url


type alias EventForm =
    { title : String
    , startDate : String
    , startTime : String
    , endDate : String
    , endTime : String
    , recurrence : Evergreen.V12.Domain.Recurrence
    , assignment : Evergreen.V12.Domain.Assignment
    , tags : String
    , comment : String
    }


type EditorState
    = EditorClosed
    | CreatingEvent
    | DuplicatingEvent
    | EditingEvent Evergreen.V12.Domain.EventId


type PersonFilter
    = AllPeople
    | AssignedTo Evergreen.V12.Domain.Person


type RecurrenceFilter
    = AllRecurrences
    | OnlyRecurrence Evergreen.V12.Domain.Recurrence


type TagFilter
    = AllTags
    | TaggedWith Evergreen.V12.Domain.Tag


type DateFilter
    = AllDates
    | InMonth Evergreen.V12.Domain.MonthOfYear
    | InRange Evergreen.V12.Domain.CalendarRange


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
    , events : List Evergreen.V12.Domain.Event
    , form : EventForm
    , editor : EditorState
    , personFilter : PersonFilter
    , recurrenceFilter : RecurrenceFilter
    , tagFilter : TagFilter
    , dateFilter : DateFilter
    , dateFilterForm : DateFilterForm
    , search : String
    , formError : Maybe String
    , syncState : SyncState
    , notice : Maybe String
    , pendingDelete : Maybe Evergreen.V12.Domain.EventId
    }


type alias BackendModel =
    { events : List Evergreen.V12.Domain.Event
    , nextEventId : Int
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | OpenCreateEditor
    | OpenDuplicateEditor Evergreen.V12.Domain.EventId
    | OpenEditEditor Evergreen.V12.Domain.EventId
    | CloseEditor
    | ChangeTitle String
    | ChangeStartDate String
    | ChangeStartTime String
    | ChangeEndDate String
    | ChangeEndTime String
    | ChangeRecurrence Evergreen.V12.Domain.Recurrence
    | ChangeAssignment Evergreen.V12.Domain.Assignment
    | ChangeTags String
    | ChangeComment String
    | SubmitEvent
    | ChangePersonFilter PersonFilter
    | ChangeRecurrenceFilter RecurrenceFilter
    | ChangeTagFilter TagFilter
    | ChangeMonthFilter String
    | ChangeRangeStart String
    | ChangeRangeEnd String
    | ApplyDateRange
    | ClearDateFilter
    | ChangeSearch String
    | ResetFilters
    | AskDelete Evergreen.V12.Domain.EventId
    | CancelDelete
    | ConfirmDelete Evergreen.V12.Domain.EventId
    | ToggleOccurrence Evergreen.V12.Domain.EventId Evergreen.V12.Domain.OccurrenceIndex
    | DismissNotice


type ToBackend
    = RequestEvents
    | CreateEvent Evergreen.V12.Domain.EventDraft
    | UpdateEvent Evergreen.V12.Domain.EventId Evergreen.V12.Domain.EventDraft
    | DeleteEvent Evergreen.V12.Domain.EventId
    | ToggleOccurrenceCompletion Evergreen.V12.Domain.EventId Evergreen.V12.Domain.OccurrenceIndex


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = EventsLoaded (List Evergreen.V12.Domain.Event)
    | EventsChanged (List Evergreen.V12.Domain.Event) String
    | ChangeRejected String
