module Evergreen.V3.Types exposing (..)

import Browser
import Browser.Navigation
import Evergreen.V3.Domain
import Url


type alias EventForm =
    { title : String
    , startDate : String
    , startTime : String
    , endDate : String
    , endTime : String
    , recurrence : Evergreen.V3.Domain.Recurrence
    , assignment : Evergreen.V3.Domain.Assignment
    , comment : String
    }


type EditorState
    = EditorClosed
    | CreatingEvent
    | EditingEvent Evergreen.V3.Domain.EventId


type PersonFilter
    = AllPeople
    | AssignedTo Evergreen.V3.Domain.Person


type RecurrenceFilter
    = AllRecurrences
    | OnlyRecurrence Evergreen.V3.Domain.Recurrence


type SyncState
    = Loading
    | Synced
    | Saving
    | SyncFailed String


type alias FrontendModel =
    { key : Browser.Navigation.Key
    , events : List Evergreen.V3.Domain.Event
    , form : EventForm
    , editor : EditorState
    , personFilter : PersonFilter
    , recurrenceFilter : RecurrenceFilter
    , search : String
    , formError : Maybe String
    , syncState : SyncState
    , notice : Maybe String
    , pendingDelete : Maybe Evergreen.V3.Domain.EventId
    }


type alias BackendModel =
    { events : List Evergreen.V3.Domain.Event
    , nextEventId : Int
    }


type FrontendMsg
    = UrlClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | OpenCreateEditor
    | OpenEditEditor Evergreen.V3.Domain.EventId
    | CloseEditor
    | ChangeTitle String
    | ChangeStartDate String
    | ChangeStartTime String
    | ChangeEndDate String
    | ChangeEndTime String
    | ChangeRecurrence Evergreen.V3.Domain.Recurrence
    | ChangeAssignment Evergreen.V3.Domain.Assignment
    | ChangeComment String
    | SubmitEvent
    | ChangePersonFilter PersonFilter
    | ChangeRecurrenceFilter RecurrenceFilter
    | ChangeSearch String
    | ResetFilters
    | AskDelete Evergreen.V3.Domain.EventId
    | CancelDelete
    | ConfirmDelete Evergreen.V3.Domain.EventId
    | ToggleOccurrence Evergreen.V3.Domain.EventId Evergreen.V3.Domain.OccurrenceIndex
    | DismissNotice


type ToBackend
    = RequestEvents
    | CreateEvent Evergreen.V3.Domain.EventDraft
    | UpdateEvent Evergreen.V3.Domain.EventId Evergreen.V3.Domain.EventDraft
    | DeleteEvent Evergreen.V3.Domain.EventId
    | ToggleOccurrenceCompletion Evergreen.V3.Domain.EventId Evergreen.V3.Domain.OccurrenceIndex


type BackendMsg
    = NoOpBackendMsg


type ToFrontend
    = EventsLoaded (List Evergreen.V3.Domain.Event)
    | EventsChanged (List Evergreen.V3.Domain.Event) String
    | ChangeRejected String
