module Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Domain exposing (Event, EventDraft, EventId, Person, Recurrence)
import Url exposing (Url)


type alias FrontendModel =
    { key : Key
    , events : List Event
    , form : EventForm
    , editor : EditorState
    , personFilter : PersonFilter
    , recurrenceFilter : RecurrenceFilter
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
    , assignee : Person
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
    | ChangeAssignee Person
    | ChangeComment String
    | SubmitEvent
    | ChangePersonFilter PersonFilter
    | ChangeRecurrenceFilter RecurrenceFilter
    | ChangeSearch String
    | ResetFilters
    | AskDelete EventId
    | CancelDelete
    | ConfirmDelete EventId
    | DismissNotice


type ToBackend
    = RequestEvents
    | CreateEvent EventDraft
    | UpdateEvent EventId EventDraft
    | DeleteEvent EventId


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = EventsLoaded (List Event)
    | EventsChanged (List Event) String
    | ChangeRejected String
