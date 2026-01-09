// Core type definitions for Direct SDK
// Reference: direct-go-sdk/direct-go/messages.go

// Message types (internal enum values 0-21, wire values 500-508 for action stamps)

///|
pub(all) enum MessageType {
  MsgTypeSystem // 0
  MsgTypeText // 1
  MsgTypeStamp // 2
  MsgTypeLocation // 3
  MsgTypeFile // 4
  MsgTypeTextMultipleFile // 5
  MsgTypeUnused // 6 - Reserved
  MsgTypeDeleted // 7
  MsgTypeNoteShared // 8
  MsgTypeNoteDeleted // 9
  MsgTypeNoteCreated // 10
  MsgTypeNoteUpdated // 11
  MsgTypeOriginalStamp // 12
  MsgTypeYesNo // 13 - internal (wire: 500)
  MsgTypeYesNoReply // 14 - internal (wire: 501)
  MsgTypeSelect // 15 - internal (wire: 502)
  MsgTypeSelectReply // 16 - internal (wire: 503)
  MsgTypeTask // 17 - internal (wire: 504)
  MsgTypeTaskDone // 18 - internal (wire: 505)
  MsgTypeYesNoClosed // 19 - internal (wire: 506)
  MsgTypeSelectClosed // 20 - internal (wire: 507)
  MsgTypeTaskClosed // 21 - internal (wire: 508)
} derive(Show, Eq)

// Convert internal MessageType to wire format value
// For action stamps (types 13-21), use: wireType = 500 + internalType - 13

///|
pub fn msg_type_to_wire(t : MessageType) -> Int {
  match t {
    MsgTypeYesNo => 500
    MsgTypeYesNoReply => 501
    MsgTypeSelect => 502
    MsgTypeSelectReply => 503
    MsgTypeTask => 504
    MsgTypeTaskDone => 505
    MsgTypeYesNoClosed => 506
    MsgTypeSelectClosed => 507
    MsgTypeTaskClosed => 508
    MsgTypeSystem => 0
    MsgTypeText => 1
    MsgTypeStamp => 2
    MsgTypeLocation => 3
    MsgTypeFile => 4
    MsgTypeTextMultipleFile => 5
    MsgTypeUnused => 6
    MsgTypeDeleted => 7
    MsgTypeNoteShared => 8
    MsgTypeNoteDeleted => 9
    MsgTypeNoteCreated => 10
    MsgTypeNoteUpdated => 11
    MsgTypeOriginalStamp => 12
  }
}

// Convert wire format value to MessageType

///|
pub fn wire_to_msg_type(wire : Int) -> MessageType? {
  match wire {
    0 => Some(MsgTypeSystem)
    1 => Some(MsgTypeText)
    2 => Some(MsgTypeStamp)
    3 => Some(MsgTypeLocation)
    4 => Some(MsgTypeFile)
    5 => Some(MsgTypeTextMultipleFile)
    6 => Some(MsgTypeUnused)
    7 => Some(MsgTypeDeleted)
    8 => Some(MsgTypeNoteShared)
    9 => Some(MsgTypeNoteDeleted)
    10 => Some(MsgTypeNoteCreated)
    11 => Some(MsgTypeNoteUpdated)
    12 => Some(MsgTypeOriginalStamp)
    500 => Some(MsgTypeYesNo)
    501 => Some(MsgTypeYesNoReply)
    502 => Some(MsgTypeSelect)
    503 => Some(MsgTypeSelectReply)
    504 => Some(MsgTypeTask)
    505 => Some(MsgTypeTaskDone)
    506 => Some(MsgTypeYesNoClosed)
    507 => Some(MsgTypeSelectClosed)
    508 => Some(MsgTypeTaskClosed)
    _ => None
  }
}

// Room/Talk type

///|
pub(all) enum RoomType {
  RoomTypePair // 1 - 1:1 chat
  RoomTypeGroup // 2 - Group chat
} derive(Show, Eq)

///|
pub fn room_type_to_int(t : RoomType) -> Int {
  match t {
    RoomTypePair => 1
    RoomTypeGroup => 2
  }
}

///|
pub fn int_to_room_type(i : Int) -> RoomType? {
  match i {
    1 => Some(RoomTypePair)
    2 => Some(RoomTypeGroup)
    _ => None
  }
}

// Generic ID type (can be String or Int64)
// The Direct API uses both string and numeric IDs

///|
pub(all) enum ID {
  IDString(String)
  IDInt(Int64)
} derive(Show, Eq)

///|
pub fn id_to_string(id : ID) -> String {
  match id {
    IDString(s) => s
    IDInt(i) => i.to_string()
  }
}

///|
pub fn string_to_id(s : String) -> ID {
  // Try to parse as Int64 first, fallback to String
  try @strconv.parse_int64(s) catch {
    _ => IDString(s)
  } noraise {
    i => IDInt(i)
  }
}

// User information

///|
pub(all) struct UserInfo {
  id : ID
  name : String
  display_name : String
  phonetic_name : String
  email : String
  icon_url : String
  domain_id : ID
  departments : Array[ID]
  profiles : Map[String, JsonValue]
  can_talk : Bool
  allowed_to_create_talk : Bool
}

// Profile information

///|
pub(all) struct ProfileInfo {
  user_id : ID
  domain_id : ID
  display_name : String
  phonetic_name : String
  profiles : Map[String, JsonValue]
}

// Presence information

///|
pub(all) struct PresenceInfo {
  user_id : ID
  status : String // "online", "offline", "away", etc.
}

// Received message from server

///|
pub(all) struct ReceivedMessage {
  id : String
  talk_id : String
  room_id : String // Alias for talk_id
  user_id : String
  domain_id : String
  text : String
  msg_type : MessageType
  content : JsonValue
  created : Int64
  raw : JsonValue? // Raw data for custom parsing
}

// Talk/Room information

///|
pub(all) struct Talk {
  id : ID
  domain_id : ID
  talk_type : Int
  name : String
  user_ids : Array[ID]
  allow_display_past_messages : Bool
}

// Talk status (unread count, etc.)

///|
pub(all) struct TalkStatus {
  talk_id : ID
  unread_count : Int
  latest_msg_id : ID?
}

// Domain/Organization (simplified)

///|
pub(all) struct Domain {
  id : ID
  name : String
}

// Domain invitation (simplified)

///|
pub(all) struct DomainInvite {
  id : ID
  name : String
  account_control_request_id : ID?
}

// Detailed domain information

///|
pub(all) struct DomainInfo {
  id : ID
  name : String
  updated_at : Int64
  contract : JsonValue
  setting : JsonValue
  role : JsonValue
  closed : Bool
}

// Conference information

///|
pub(all) struct ConferenceInfo {
  id : ID
  talk_id : ID
  domain_id : ID
  status : String
  created : Int64
}

// Room (simpler version of Talk)

///|
pub(all) struct Room {
  id : ID
  name : String
  room_type : RoomType
  user_ids : Array[ID]
  domain_id : ID?
}

// Session response from create_session

///|
pub(all) struct SessionResponse {
  user_id : ID
  device_id : ID
  password_expiration : ID?
}

// Health status

///|
pub(all) struct HealthStatus {
  connected : Bool
  authenticated : Bool
  endpoint : String
  error : String?
}

// Message content types

// Text message content

///|
pub(all) struct TextMessage {
  text : String
}

// Stamp message content

///|
pub(all) struct StampMessage {
  stamp_set : String
  stamp_index : String
  text : String?
}

// Yes/No action stamp

///|
pub(all) struct YesNoMessage {
  question : String
  listing : Bool // Show who responded
  close_yes : Bool // Close after yes
  close_no : Bool // Close after no
}

// Select action stamp

///|
pub(all) struct SelectMessage {
  question : String
  options : Array[String]
  listing : Bool
  closing_type : Int
}

// Task action stamp

///|
pub(all) struct TaskMessage {
  title : String
  closing_type : Int
  closing_users : Int
  target_user_ids : Array[ID]
}

// File attachment

///|
pub(all) struct FileMessage {
  file_id : ID
  name : String
  mime_type : String
  text : String?
}

// Note message

///|
pub(all) struct NoteMessage {
  title : String
  content : String
}

// Location message

///|
pub(all) struct LocationMessage {
  address : String
  latitude : Float
  longitude : Float
}

// User identifier

///|
pub(all) struct UserIdentifier {
  user_id : ID
  email : String
  sub_email : String
  group_alias : String
  signin_id : String
}

// Group talk settings

///|
pub(all) struct GroupTalkSettings {
  name : String
  icon_url : String?
  allow_display_past_messages : Bool
  description : String?
}

// Generic JSON value type for dynamic API responses

///|
pub(all) enum JsonValue {
  JsonNull
  JsonBool(Bool)
  JsonNumber(Float)
  JsonString(String)
  JsonArray(Array[JsonValue])
  JsonObject(Map[String, JsonValue])
} derive(Show)

// Convert ID to JsonValue

///|
pub fn id_to_json(id : ID) -> JsonValue {
  match id {
    IDString(s) => JsonString(s)
    IDInt(i) => JsonNumber(Float::from_int64(i))
  }
}

// Parse JsonValue as ID

///|
pub fn json_to_id(v : JsonValue) -> ID? {
  match v {
    JsonString(s) => Some(string_to_id(s))
    JsonNumber(n) => {
      let int_val = n.to_int()
      if Float::from_int(int_val) == n {
        Some(IDInt(int_val.to_int64()))
      } else {
        None
      }
    }
    _ => None
  }
}
