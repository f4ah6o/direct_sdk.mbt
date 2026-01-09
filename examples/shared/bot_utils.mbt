// Bot utilities for Direct SDK examples
// Common helper functions for bot implementations

// Safe send text with error handling and logging
// cfg(target="native")

///|
pub async fn safe_send_text(
  client : @rpc_client.Client,
  room_id : String,
  text : String,
) -> Result[Unit, String] {
  match await @rpc_client.send_text(client, room_id, text) {
    Ok(_) => Ok(())
    Err(e) => {
      let error_msg = "Failed to send: " ++ @errors.direct_error_to_string(e)
      println("[ERROR] " ++ error_msg)
      Err(error_msg)
    }
  }
}

// Log message with timestamp and metadata

///|
pub fn log_message(msg : @types.ReceivedMessage, prefix : String) -> Unit {
  let timestamp = msg.created.to_string()
  println(
    "[" ++ prefix ++ "] " ++ timestamp ++ " | Room: " ++ msg.talk_id
      ++ " | User: " ++ msg.user_id ++ " | " ++ msg.text,
  )
}

// Log message with type information

///|
pub fn log_message_with_type(msg : @types.ReceivedMessage, prefix : String) -> Unit {
  let type_name = msg_type_to_name(msg.msg_type)
  let timestamp = msg.created.to_string()
  println(
    "[" ++ prefix ++ "] " ++ timestamp ++ " | Type: " ++ type_name
      ++ " | Room: " ++ msg.talk_id ++ " | User: " ++ msg.user_id ++ " | "
      ++ msg.text,
  )
}

// Convert MessageType to readable name

///|
pub fn msg_type_to_name(t : @types.MessageType) -> String {
  match t {
    | @types.MsgTypeSystem => "System"
    | @types.MsgTypeText => "Text"
    | @types.MsgTypeStamp => "Stamp"
    | @types.MsgTypeLocation => "Location"
    | @types.MsgTypeFile => "File"
    | @types.MsgTypeTextMultipleFile => "MultiFile"
    | @types.MsgTypeDeleted => "Deleted"
    | @types.MsgTypeNoteShared => "NoteShared"
    | @types.MsgTypeNoteDeleted => "NoteDeleted"
    | @types.MsgTypeNoteCreated => "NoteCreated"
    | @types.MsgTypeNoteUpdated => "NoteUpdated"
    | @types.MsgTypeOriginalStamp => "OriginalStamp"
    | @types.MsgTypeYesNo => "YesNo"
    | @types.MsgTypeYesNoReply => "YesNoReply"
    | @types.MsgTypeSelect => "Select"
    | @types.MsgTypeSelectReply => "SelectReply"
    | @types.MsgTypeTask => "Task"
    | @types.MsgTypeTaskDone => "TaskDone"
    | @types.MsgTypeYesNoClosed => "YesNoClosed"
    | @types.MsgTypeSelectClosed => "SelectClosed"
    | @types.MsgTypeTaskClosed => "TaskClosed"
    | _ => "Unknown"
  }
}

// Extract room_id from ReceivedMessage (handles both talk_id and room_id)

///|
pub fn get_room_id(msg : @types.ReceivedMessage) -> String {
  if msg.room_id != "" {
    msg.room_id
  } else {
    msg.talk_id
  }
}

// Extract user_id from ReceivedMessage

///|
pub fn get_user_id(msg : @types.ReceivedMessage) -> String {
  msg.user_id
}

// Extract text from ReceivedMessage

///|
pub fn get_text(msg : @types.ReceivedMessage) -> String {
  msg.text
}

// Check if message is from a specific user

///|
pub fn is_from_user(msg : @types.ReceivedMessage, user_id : String) -> Bool {
  msg.user_id == user_id
}

// Check if message is in a specific room

///|
pub fn is_in_room(msg : @types.ReceivedMessage, room_id : String) -> Bool {
  get_room_id(msg) == room_id || msg.talk_id == room_id
}

// Format timestamp to readable string

///|
pub fn format_timestamp(timestamp : Int64) -> String {
  // Simple timestamp formatting
  timestamp.to_string()
}

// Load environment variable with default value

///|
pub fn env_or_default(key : String, default : String) -> String {
  // Note: MoonBit doesn't have built-in env access
  // This would need to be implemented via FFI or platform-specific code
  // For now, return default
  default
}

// Combine multiple strings into a message

///|
pub fn join_lines(lines : Array[String]) -> String {
  String::join("\n", lines)
}

// Split text by whitespace

///|
pub fn split_words(text : String) -> Array[String] {
  text.split(" ")
}

// Check if text starts with prefix

///|
pub fn starts_with(text : String, prefix : String) -> Bool {
  text.length() >= prefix.length()
    && text.substring(0, prefix.length()) == prefix
}

// Check if text ends with suffix

///|
pub fn ends_with(text : String, suffix : String) -> Bool {
  let text_len = text.length()
  let suffix_len = suffix.length()
  text_len >= suffix_len
    && text.substring(text_len - suffix_len, text_len) == suffix
}

// Trim whitespace from text

///|
pub fn trim(text : String) -> String {
  // Simple trim implementation
  let mut start = 0
  let mut end = text.length()

  while start < end && text.char_at(start) == ' ' {
    start = start + 1
  }

  while end > start && text.char_at(end - 1) == ' ' {
    end = end - 1
  }

  if start == 0 && end == text.length() {
    text
  } else {
    text.substring(start, end)
  }
}

// Convert ID to String (handles both String and Int64 IDs)

///|
pub fn id_to_string(id : @types.ID) -> String {
  @types.id_to_string(id)
}

// Check if message is a select stamp reply

///|
pub fn is_select_reply(msg : @types.ReceivedMessage) -> Bool {
  match msg.msg_type {
    | @types.MsgTypeSelectReply => true
    | _ => false
  }
}

// Check if message is a text message

///|
pub fn is_text_message(msg : @types.ReceivedMessage) -> Bool {
  match msg.msg_type {
    | @types.MsgTypeText => true
    | _ => false
  }
}
