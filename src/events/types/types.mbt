// Event types for Direct SDK
// Reference: direct-go-sdk/direct-go/events.go

///|
#warnings("-unused_constructor")
// Server-to-client notification events

pub enum ServerEvent {
  // Connection events
  SessionCreated(SessionData)
  SessionError(String)
  DataRecovered
  NotificationError(String)
  ConnectionError(String)
  DecodeError(String)
  AccessTokenChanged(String)

  // Message notifications
  NotifyCreateMessage(@sdk_types.ReceivedMessage)
  NotifyDeleteMessage(MessageDeletedData)

  // Talk/Room notifications
  NotifyCreateGroupTalk(@sdk_types.Talk)
  NotifyCreatePairTalk(@sdk_types.Talk)
  NotifyAddTalkers(UsersAddedData)
  NotifyDeleteTalker(UserRemovedData)
  NotifyUpdateTalk(@sdk_types.Talk)

  // User/Friend notifications
  NotifyAddFriend(@sdk_types.UserInfo)
  NotifyDeleteFriend(UserDeletedData)
  NotifyAddAcquaintance(@sdk_types.UserInfo)
  NotifyAddAcquaintances(Array[@sdk_types.UserInfo])
  NotifyUpdateUser(@sdk_types.UserInfo)

  // Domain notifications
  NotifyJoinDomain(DomainJoinedData)
  NotifyLeaveDomain(DomainLeftData)
  NotifyAddDomainInvite(DomainInviteInfo)
  NotifyDeleteDomainInvite(DomainInviteDeletedData)

  // Attachment notifications
  NotifyCreateAttachment(AttachmentInfo)
  NotifyDeleteAttachment(AttachmentDeletedData)

  // Note notifications
  NotifyCreateNote(NoteInfo)
  NotifyUpdateNote(NoteInfo)
  NotifyDeleteNote(NoteDeletedData)

  // Favorite notifications
  NotifyAddFavoriteTalk(FavoriteTalkData)
  NotifyDeleteFavoriteTalk(FavoriteTalkData)

  // Announcement notifications
  NotifyCreateAnnouncement(AnnouncementInfo)
  NotifyDeleteAnnouncement(AnnouncementDeletedData)

  // Read status notifications
  NotifyUpdateReadStatus(ReadStatusData)
  NotifyUpdateTalkStatus(TalkStatusData)

  // Conference notifications
  NotifyCreateConference(ConferenceInfo)
  NotifyCloseConference(ConferenceClosedData)
  NotifyConferenceJoin(ConferenceParticipantData)
  NotifyConferenceReject(ConferenceParticipantData)
}

// Session data from session_created event

///|
#warnings("-struct_never_constructed")
pub struct SessionData {
  user_id : @sdk_types.ID
  access_token : String
  endpoint : String
}

// Data for notify_delete_message

///|
#warnings("-struct_never_constructed")
pub struct MessageDeletedData {
  message_id : @sdk_types.ID
  talk_id : @sdk_types.ID
  domain_id : @sdk_types.ID
}

// Data for notify_add_talkers

///|
#warnings("-struct_never_constructed")
pub struct UsersAddedData {
  talk_id : @sdk_types.ID
  user_ids : Array[@sdk_types.ID]
}

// Data for notify_delete_talker

///|
#warnings("-struct_never_constructed")
pub struct UserRemovedData {
  talk_id : @sdk_types.ID
  user_id : @sdk_types.ID
}

// Data for notify_delete_friend

///|
#warnings("-struct_never_constructed")
pub struct UserDeletedData {
  user_id : @sdk_types.ID
}

// Data for notify_join_domain

///|
#warnings("-struct_never_constructed")
pub struct DomainJoinedData {
  domain_id : @sdk_types.ID
  name : String
}

// Data for notify_leave_domain

///|
#warnings("-struct_never_constructed")
pub struct DomainLeftData {
  domain_id : @sdk_types.ID
}

// Domain invitation information

///|
#warnings("-struct_never_constructed")
pub struct DomainInviteInfo {
  id : @sdk_types.ID
  name : String
  account_control_request_id : @sdk_types.ID
  updated_at : Int64
}

// Data for notify_delete_domain_invite

///|
#warnings("-struct_never_constructed")
pub struct DomainInviteDeletedData {
  invite_id : @sdk_types.ID
}

// Attachment information

///|
#warnings("-struct_never_constructed")
pub struct AttachmentInfo {
  id : @sdk_types.ID
  file_id : @sdk_types.ID
  talk_id : @sdk_types.ID
  msg_id : @sdk_types.ID
  domain_id : @sdk_types.ID
  name : String
  size : Int64
  mime_type : String
}

// Data for notify_delete_attachment

///|
#warnings("-struct_never_constructed")
pub struct AttachmentDeletedData {
  attachment_id : @sdk_types.ID
  talk_id : @sdk_types.ID
}

// Note information

///|
#warnings("-struct_never_constructed")
pub struct NoteInfo {
  id : @sdk_types.ID
  talk_id : @sdk_types.ID
  domain_id : @sdk_types.ID
  user_id : @sdk_types.ID
  title : String
  content : String
  created : Int64
  updated : Int64
}

// Data for notify_delete_note

///|
#warnings("-struct_never_constructed")
pub struct NoteDeletedData {
  note_id : @sdk_types.ID
  talk_id : @sdk_types.ID
}

// Data for favorite talk notifications

///|
#warnings("-struct_never_constructed")
pub struct FavoriteTalkData {
  talk_id : @sdk_types.ID
  domain_id : @sdk_types.ID
}

// Announcement information

///|
#warnings("-struct_never_constructed")
pub struct AnnouncementInfo {
  id : @sdk_types.ID
  domain_id : @sdk_types.ID
  talk_id : @sdk_types.ID
  title : String
  content : String
  created : Int64
  updated : Int64
}

// Data for notify_delete_announcement

///|
#warnings("-struct_never_constructed")
pub struct AnnouncementDeletedData {
  announcement_id : @sdk_types.ID
  domain_id : @sdk_types.ID
}

// Data for notify_update_read_status

///|
#warnings("-struct_never_constructed")
pub struct ReadStatusData {
  talk_id : @sdk_types.ID
  user_id : @sdk_types.ID
  msg_id : @sdk_types.ID
  read_at : Int64
}

// Data for notify_update_talk_status

///|
#warnings("-struct_never_constructed")
pub struct TalkStatusData {
  talk_id : @sdk_types.ID
  unread_count : Int
  latest_msg_id : @sdk_types.ID
}

// Conference information

///|
#warnings("-struct_never_constructed")
pub struct ConferenceInfo {
  id : @sdk_types.ID
  talk_id : @sdk_types.ID
  domain_id : @sdk_types.ID
  status : String
  created : Int64
}

// Data for notify_close_conference

///|
#warnings("-struct_never_constructed")
pub struct ConferenceClosedData {
  conference_id : @sdk_types.ID
  talk_id : @sdk_types.ID
}

// Data for conference participant notifications

///|
#warnings("-struct_never_constructed")
pub struct ConferenceParticipantData {
  conference_id : @sdk_types.ID
  talk_id : @sdk_types.ID
  user_id : @sdk_types.ID
}

// Generic event handler type (for JSON-based events)

///|
pub type JsonEventHandler = (@sdk_types.JsonValue) -> Unit

// Specific event handler types (for parsed events)

///|
pub type MessageEventHandler = (@sdk_types.ReceivedMessage) -> Unit

///|
pub type TalkEventHandler = (@sdk_types.Talk) -> Unit

///|
pub type UserEventHandler = (@sdk_types.UserInfo) -> Unit
