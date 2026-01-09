// Core type definitions for Direct SDK
// Reference: direct-go-sdk/direct-go/messages.go

// Message types (internal enum values 0-21, wire values 500-508 for action stamps)
pub type MessageType =
  | MsgTypeSystem           // 0
  | MsgTypeText             // 1
  | MsgTypeStamp            // 2
  | MsgTypeLocation         // 3
  | MsgTypeFile             // 4
  | MsgTypeTextMultipleFile // 5
  | MsgTypeUnused           // 6 - Reserved
  | MsgTypeDeleted          // 7
  | MsgTypeNoteShared       // 8
  | MsgTypeNoteDeleted      // 9
  | MsgTypeNoteCreated      // 10
  | MsgTypeNoteUpdated      // 11
  | MsgTypeOriginalStamp    // 12
  | MsgTypeYesNo            // 13 - internal (wire: 500)
  | MsgTypeYesNoReply       // 14 - internal (wire: 501)
  | MsgTypeSelect           // 15 - internal (wire: 502)
  | MsgTypeSelectReply      // 16 - internal (wire: 503)
  | MsgTypeTask             // 17 - internal (wire: 504)
  | MsgTypeTaskDone         // 18 - internal (wire: 505)
  | MsgTypeYesNoClosed      // 19 - internal (wire: 506)
  | MsgTypeSelectClosed     // 20 - internal (wire: 507)
  | MsgTypeTaskClosed       // 21 - internal (wire: 508)

// Convert internal MessageType to wire format value
// For action stamps (types 13-21), use: wireType = 500 + internalType - 13
pub fn msg_type_to_wire(t : MessageType) -> Int {
  match t {
    | MsgTypeYesNo            => 500
    | MsgTypeYesNoReply       => 501
    | MsgTypeSelect           => 502
    | MsgTypeSelectReply      => 503
    | MsgTypeTask             => 504
    | MsgTypeTaskDone         => 505
    | MsgTypeYesNoClosed      => 506
    | MsgTypeSelectClosed     => 507
    | MsgTypeTaskClosed       => 508
    | MsgTypeSystem           => 0
    | MsgTypeText             => 1
    | MsgTypeStamp            => 2
    | MsgTypeLocation         => 3
    | MsgTypeFile             => 4
    | MsgTypeTextMultipleFile => 5
    | MsgTypeUnused           => 6
    | MsgTypeDeleted          => 7
    | MsgTypeNoteShared       => 8
    | MsgTypeNoteDeleted      => 9
    | MsgTypeNoteCreated      => 10
    | MsgTypeNoteUpdated      => 11
    | MsgTypeOriginalStamp    => 12
  }
}

// Convert wire format value to MessageType
pub fn wire_to_msg_type(wire : Int) -> Option[MessageType] {
  match wire {
    | 0  => Some(MsgTypeSystem)
    | 1  => Some(MsgTypeText)
    | 2  => Some(MsgTypeStamp)
    | 3  => Some(MsgTypeLocation)
    | 4  => Some(MsgTypeFile)
    | 5  => Some(MsgTypeTextMultipleFile)
    | 6  => Some(MsgTypeUnused)
    | 7  => Some(MsgTypeDeleted)
    | 8  => Some(MsgTypeNoteShared)
    | 9  => Some(MsgTypeNoteDeleted)
    | 10 => Some(MsgTypeNoteCreated)
    | 11 => Some(MsgTypeNoteUpdated)
    | 12 => Some(MsgTypeOriginalStamp)
    | 500 => Some(MsgTypeYesNo)
    | 501 => Some(MsgTypeYesNoReply)
    | 502 => Some(MsgTypeSelect)
    | 503 => Some(MsgTypeSelectReply)
    | 504 => Some(MsgTypeTask)
    | 505 => Some(MsgTypeTaskDone)
    | 506 => Some(MsgTypeYesNoClosed)
    | 507 => Some(MsgTypeSelectClosed)
    | 508 => Some(MsgTypeTaskClosed)
    | _   => None
  }
}

// Room/Talk type
pub type RoomType =
  | RoomTypePair   // 1 - 1:1 chat
  | RoomTypeGroup  // 2 - Group chat

pub fn room_type_to_int(t : RoomType) -> Int {
  match t {
    | RoomTypePair  => 1
    | RoomTypeGroup => 2
  }
}

pub fn int_to_room_type(i : Int) -> Option[RoomType] {
  match i {
    | 1 => Some(RoomTypePair)
    | 2 => Some(RoomTypeGroup)
    | _ => None
  }
}

// Generic ID type (can be String or Int64)
// The Direct API uses both string and numeric IDs
pub type ID =
  | IDString(String)
  | IDInt(Int64)

pub fn id_to_string(id : ID) -> String {
  match id {
    | IDString(s) => s
    | IDInt(i)    => i.to_string()
  }
}

pub fn string_to_id(s : String) -> ID {
  // Try to parse as Int64 first, fallback to String
  match s.to_int64() {
    | Some(i) => IDInt(i)
    | None    => IDString(s)
  }
}

// User information
pub type UserInfo = {
  id                  : ID,
  name                : String,
  display_name        : String,
  phonetic_name       : String,
  email               : String,
  icon_url            : String,
  domain_id           : ID,
  departments         : Array[ID],
  profiles            : Map[String, JsonValue],
  can_talk            : Bool,
  allowed_to_create_talk : Bool,
}

// Profile information
pub type ProfileInfo = {
  user_id       : ID,
  domain_id     : ID,
  display_name  : String,
  phonetic_name : String,
  profiles      : Map[String, JsonValue],
}

// Presence information
pub type PresenceInfo = {
  user_id : ID,
  status  : String,  // "online", "offline", "away", etc.
}

// Received message from server
pub type ReceivedMessage = {
  id        : String,
  talk_id   : String,
  room_id   : String,  // Alias for talk_id
  user_id   : String,
  domain_id : String,
  text      : String,
  msg_type  : MessageType,
  content   : JsonValue,
  created   : Int64,
  raw       : Option[JsonValue],  // Raw data for custom parsing
}

// Talk/Room information
pub type Talk = {
  id                       : ID,
  domain_id                : ID,
  talk_type                : Int,
  name                     : String,
  user_ids                 : Array[ID],
  allow_display_past_messages : Bool,
}

// Talk status (unread count, etc.)
pub type TalkStatus = {
  talk_id      : ID,
  unread_count : Int,
  latest_msg_id : Option[ID],
}

// Domain/Organization
pub type Domain = {
  id   : ID,
  name : String,
}

// Domain invitation
pub type DomainInvite = {
  id                       : ID,
  name                     : String,
  account_control_request_id : Option[ID],
}

// Room (simpler version of Talk)
pub type Room = {
  id        : ID,
  name      : String,
  room_type : RoomType,
  user_ids  : Array[ID],
  domain_id : Option[ID],
}

// Session response from create_session
pub type SessionResponse = {
  user_id             : ID,
  device_id           : ID,
  password_expiration : Option[ID],
}

// Health status
pub type HealthStatus = {
  connected     : Bool,
  authenticated : Bool,
  endpoint      : String,
  error         : Option[String],
}

// Message content types

// Text message content
pub type TextMessage = {
  text : String,
}

// Stamp message content
pub type StampMessage = {
  stamp_set   : String,
  stamp_index : String,
  text        : Option[String],
}

// Yes/No action stamp
pub type YesNoMessage = {
  question  : String,
  listing   : Bool,     // Show who responded
  close_yes : Bool,     // Close after yes
  close_no  : Bool,     // Close after no
}

// Select action stamp
pub type SelectMessage = {
  question     : String,
  options      : Array[String],
  listing      : Bool,
  closing_type : Int,
}

// Task action stamp
pub type TaskMessage = {
  title          : String,
  closing_type   : Int,
  closing_users  : Int,
  target_user_ids : Array[ID],
}

// File attachment
pub type FileMessage = {
  file_id   : ID,
  name      : String,
  mime_type : String,
  text      : Option[String],
}

// Note message
pub type NoteMessage = {
  title   : String,
  content : String,
}

// Location message
pub type LocationMessage = {
  address   : String,
  latitude  : Float,
  longitude : Float,
}

// User identifier
pub type UserIdentifier = {
  user_id     : ID,
  email       : String,
  sub_email   : String,
  group_alias : String,
  signin_id   : String,
}

// Group talk settings
pub type GroupTalkSettings = {
  name                     : String,
  icon_url                 : Option[String],
  allow_display_past_messages : Bool,
  description              : Option[String],
}

// Generic JSON value type for dynamic API responses
pub type JsonValue =
  | JsonNull
  | JsonBool(Bool)
  | JsonNumber(Float)
  | JsonString(String)
  | JsonArray(Array[JsonValue])
  | JsonObject(Map[String, JsonValue])

// Convert ID to JsonValue
pub fn id_to_json(id : ID) -> JsonValue {
  match id {
    | IDString(s) => JsonString(s)
    | IDInt(i)    => JsonNumber(i.to_float())
  }
}

// Parse JsonValue as ID
pub fn json_to_id(v : JsonValue) -> Option[ID] {
  match v {
    | JsonString(s) => Some(string_to_id(s))
    | JsonNumber(n) =>
      match n.to_int64() {
        | Some(i) => Some(IDInt(i))
        | None    => None
      }
    | _ => None
  }
}
