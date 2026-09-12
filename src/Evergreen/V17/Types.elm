module Evergreen.V17.Types exposing (..)

import Browser
import Browser.Navigation
import Evergreen.V17.Domain
import Url


type alias EventForm =
    { title : String
    , startDate : String
    , startTime : String
    , endDate : String
    , endTime : String
    , recurrence : Evergreen.V17.Domain.Recurrence
    , assignment : Evergreen.V17.Domain.Assignment
    , tags : String
    , todos : String
    , comment : String
    }


type EditorState
    = EditorClosed
    | CreatingEvent
    | DuplicatingEvent
    | EditingEvent Evergreen.V17.Domain.EventId


type PersonFilter
    = AllPeople
    | AssignedTo Evergreen.V17.Domain.Person


type RecurrenceFilter
    = AllRecurrences
    | OnlyRecurrence Evergreen.V17.Domain.Recurrence


type TagFilter
    = AllTags
    | TaggedWith Evergreen.V17.Domain.Tag


type DateFilter
    = AllDates
    | InMonth Evergreen.V17.Domain.MonthOfYear
    | InRange Evergreen.V17.Domain.CalendarRange


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
    , events : List Evergreen.V17.Domain.Event
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
    , pendingDelete : Maybe Evergreen.V17.Domain.EventId
    }


type alias BackendModel =
    { events : List Evergreen.V17.Domain.Event
    , nextEventId : Int
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | OpenCreateEditor
    | OpenDuplicateEditor Evergreen.V17.Domain.EventId
    | OpenEditEditor Evergreen.V17.Domain.EventId
    | CloseEditor
    | ChangeTitle String
    | ChangeStartDate String
    | ChangeStartTime String
    | ChangeEndDate String
    | ChangeEndTime String
    | ChangeRecurrence Evergreen.V17.Domain.Recurrence
    | ChangeAssignment Evergreen.V17.Domain.Assignment
    | ChangeTags String
    | ChangeTodos String
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
    | AskDelete Evergreen.V17.Domain.EventId
    | CancelDelete
    | ConfirmDelete Evergreen.V17.Domain.EventId
    | ToggleOccurrence Evergreen.V17.Domain.EventId Evergreen.V17.Domain.OccurrenceIndex
    | ToggleTodo Evergreen.V17.Domain.EventId Evergreen.V17.Domain.TodoId
    | DismissNotice


type ToBackend
    = RequestEvents
    | CreateEvent Evergreen.V17.Domain.EventDraft
    | UpdateEvent Evergreen.V17.Domain.EventId Evergreen.V17.Domain.EventDraft
    | DeleteEvent Evergreen.V17.Domain.EventId
    | ToggleOccurrenceCompletion Evergreen.V17.Domain.EventId Evergreen.V17.Domain.OccurrenceIndex
    | ToggleTodoCompletion Evergreen.V17.Domain.EventId Evergreen.V17.Domain.TodoId


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = EventsLoaded (List Evergreen.V17.Domain.Event)
    | EventsChanged (List Evergreen.V17.Domain.Event) String
    | ChangeRejected String
