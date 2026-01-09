// Event types for Direct SDK
// Reference: direct-go-sdk/direct-go/events.go

// Server-to-client notification events
pub type ServerEvent =
  // Connection events
  | SessionCreated(SessionData)
  | SessionError(String)
  | DataRecovered
  | NotificationError(String)
  | ConnectionError(String)
  | DecodeError(String)
  | AccessTokenChanged(String)

  // Message notifications
  | NotifyCreateMessage(types/ReceivedMessage)
  | NotifyDeleteMessage(MessageDeletedData)

  // Talk/Room notifications
  | NotifyCreateGroupTalk(types/Talk)
  | NotifyCreatePairTalk(types/Talk)
  | NotifyAddTalkers(UsersAddedData)
  | NotifyDeleteTalker(UserRemovedData)
  | NotifyUpdateTalk(types/Talk)

  // User/Friend notifications
  | NotifyAddFriend(types/UserInfo)
  | NotifyDeleteFriend(UserDeletedData)
  | NotifyAddAcquaintance(types/UserInfo)
  | NotifyAddAcquaintances(Array[types/UserInfo])
  | NotifyUpdateUser(types/UserInfo)

  // Domain notifications
  | NotifyJoinDomain(DomainJoinedData)
  | NotifyLeaveDomain(DomainLeftData)
  | NotifyAddDomainInvite(DomainInviteInfo)
  | NotifyDeleteDomainInvite(DomainInviteDeletedData)

  // Attachment notifications
  | NotifyCreateAttachment(AttachmentInfo)
  | NotifyDeleteAttachment(AttachmentDeletedData)

  // Note notifications
  | NotifyCreateNote(NoteInfo)
  | NotifyUpdateNote(NoteInfo)
  | NotifyDeleteNote(NoteDeletedData)

  // Favorite notifications
  | NotifyAddFavoriteTalk(FavoriteTalkData)
  | NotifyDeleteFavoriteTalk(FavoriteTalkData)

  // Announcement notifications
  | NotifyCreateAnnouncement(AnnouncementInfo)
  | NotifyDeleteAnnouncement(AnnouncementDeletedData)

  // Read status notifications
  | NotifyUpdateReadStatus(ReadStatusData)
  | NotifyUpdateTalkStatus(TalkStatusData)

  // Conference notifications
  | NotifyCreateConference(ConferenceInfo)
  | NotifyCloseConference(ConferenceClosedData)
  | NotifyConferenceJoin(ConferenceParticipantData)
  | NotifyConferenceReject(ConferenceParticipantData)

// Session data from session_created event
pub type SessionData = {
  user_id      : types/ID,
  access_token : String,
  endpoint     : String,
}

// Data for notify_delete_message
pub type MessageDeletedData = {
  message_id : types/ID,
  talk_id    : types/ID,
  domain_id  : types/ID,
}

// Data for notify_add_talkers
pub type UsersAddedData = {
  talk_id  : types/ID,
  user_ids : Array[types/ID],
}

// Data for notify_delete_talker
pub type UserRemovedData = {
  talk_id : types/ID,
  user_id : types/ID,
}

// Data for notify_delete_friend
pub type UserDeletedData = {
  user_id : types/ID,
}

// Data for notify_join_domain
pub type DomainJoinedData = {
  domain_id : types/ID,
  name      : String,
}

// Data for notify_leave_domain
pub type DomainLeftData = {
  domain_id : types/ID,
}

// Domain invitation information
pub type DomainInviteInfo = {
  id                        : types/ID,
  name                      : String,
  account_control_request_id : types/ID,
  updated_at                : Int64,
}

// Data for notify_delete_domain_invite
pub type DomainInviteDeletedData = {
  invite_id : types/ID,
}

// Attachment information
pub type AttachmentInfo = {
  id        : types/ID,
  file_id   : types/ID,
  talk_id   : types/ID,
  msg_id    : types/ID,
  domain_id : types/ID,
  name      : String,
  size      : Int64,
  mime_type : String,
}

// Data for notify_delete_attachment
pub type AttachmentDeletedData = {
  attachment_id : types/ID,
  talk_id       : types/ID,
}

// Note information
pub type NoteInfo = {
  id        : types/ID,
  talk_id   : types/ID,
  domain_id : types/ID,
  user_id   : types/ID,
  title     : String,
  content   : String,
  created   : Int64,
  updated   : Int64,
}

// Data for notify_delete_note
pub type NoteDeletedData = {
  note_id  : types/ID,
  talk_id  : types/ID,
}

// Data for favorite talk notifications
pub type FavoriteTalkData = {
  talk_id   : types/ID,
  domain_id : types/ID,
}

// Announcement information
pub type AnnouncementInfo = {
  id        : types/ID,
  domain_id : types/ID,
  talk_id   : types/ID,
  title     : String,
  content   : String,
  created   : Int64,
  updated   : Int64,
}

// Data for notify_delete_announcement
pub type AnnouncementDeletedData = {
  announcement_id : types/ID,
  domain_id       : types/ID,
}

// Data for notify_update_read_status
pub type ReadStatusData = {
  talk_id  : types/ID,
  user_id  : types/ID,
  msg_id   : types/ID,
  read_at  : Int64,
}

// Data for notify_update_talk_status
pub type TalkStatusData = {
  talk_id       : types/ID,
  unread_count  : Int,
  latest_msg_id : types/ID,
}

// Conference information
pub type ConferenceInfo = {
  id        : types/ID,
  talk_id   : types/ID,
  domain_id : types/ID,
  status    : String,
  created   : Int64,
}

// Data for notify_close_conference
pub type ConferenceClosedData = {
  conference_id : types/ID,
  talk_id       : types/ID,
}

// Data for conference participant notifications
pub type ConferenceParticipantData = {
  conference_id : types/ID,
  talk_id       : types/ID,
  user_id       : types/ID,
}

// Generic event handler type (for JSON-based events)
pub type JsonEventHandler = (JsonValue) -> Unit

// Specific event handler types (for parsed events)
pub type MessageEventHandler = (types/ReceivedMessage) -> Unit
pub type TalkEventHandler = (types/Talk) -> Unit
pub type UserEventHandler = (types/UserInfo) -> Unit
