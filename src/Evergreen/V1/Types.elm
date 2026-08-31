module Evergreen.V1.Types exposing (..)

import Browser
import Browser.Navigation
import Evergreen.V1.Domain
import Url


type alias EventForm =
    { title : String
    , startDate : String
    , startTime : String
    , endDate : String
    , endTime : String
    , recurrence : Evergreen.V1.Domain.Recurrence
    , assignee : Evergreen.V1.Domain.Person
    , comment : String
    }


type EditorState
    = EditorClosed
    | CreatingEvent
    | EditingEvent Evergreen.V1.Domain.EventId


type PersonFilter
    = AllPeople
    | AssignedTo Evergreen.V1.Domain.Person


type RecurrenceFilter
    = AllRecurrences
    | OnlyRecurrence Evergreen.V1.Domain.Recurrence


type SyncState
    = Loading
    | Synced
    | Saving
    | SyncFailed String


type alias FrontendModel =
    { key : Browser.Navigation.Key
    , events : List Evergreen.V1.Domain.Event
    , form : EventForm
    , editor : EditorState
    , personFilter : PersonFilter
    , recurrenceFilter : RecurrenceFilter
    , search : String
    , formError : Maybe String
    , syncState : SyncState
    , notice : Maybe String
    , pendingDelete : Maybe Evergreen.V1.Domain.EventId
    }


type alias BackendModel =
    { events : List Evergreen.V1.Domain.Event
    , nextEventId : Int
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | OpenCreateEditor
    | OpenEditEditor Evergreen.V1.Domain.EventId
    | CloseEditor
    | ChangeTitle String
    | ChangeStartDate String
    | ChangeStartTime String
    | ChangeEndDate String
    | ChangeEndTime String
    | ChangeRecurrence Evergreen.V1.Domain.Recurrence
    | ChangeAssignee Evergreen.V1.Domain.Person
    | ChangeComment String
    | SubmitEvent
    | ChangePersonFilter PersonFilter
    | ChangeRecurrenceFilter RecurrenceFilter
    | ChangeSearch String
    | ResetFilters
    | AskDelete Evergreen.V1.Domain.EventId
    | CancelDelete
    | ConfirmDelete Evergreen.V1.Domain.EventId
    | DismissNotice


type ToBackend
    = RequestEvents
    | CreateEvent Evergreen.V1.Domain.EventDraft
    | UpdateEvent Evergreen.V1.Domain.EventId Evergreen.V1.Domain.EventDraft
    | DeleteEvent Evergreen.V1.Domain.EventId


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = EventsLoaded (List Evergreen.V1.Domain.Event)
    | EventsChanged (List Evergreen.V1.Domain.Event) String
    | ChangeRejected String
