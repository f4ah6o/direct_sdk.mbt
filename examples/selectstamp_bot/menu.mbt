// Menu management for Select Stamp Bot
// Handles sending select stamp menus and tracking responses

// Menu configuration constants

///|
pub const MENU_QUESTION : String = "機能メニュー"

///|
pub const MENU_OPTIONS : Array[String] = [
  "uuid 占い",
  "ミラサポplus事例表示",
]

// Menu tracker to correlate responses with sent menus

///|
pub struct MenuTracker {
  mut last_question_id : String
  mut last_question : String
}

// Create a new menu tracker

///|
pub fn new_tracker() -> MenuTracker {
  { last_question_id: "", last_question: "" }
}

// Set the last sent question ID

///|
pub fn set_last_id(tracker : MenuTracker, id : String) -> Unit {
  tracker.last_question_id = id
}

// Set the last sent question text

///|
pub fn set_last_question(tracker : MenuTracker, question : String) -> Unit {
  tracker.last_question = question
}

// Check if the reply matches the last sent question

///|
pub fn matches_last_question(tracker : MenuTracker, in_reply_to : String) -> Bool {
  tracker.last_question_id != "" && tracker.last_question_id == in_reply_to
}

// Send the select menu to a room
// cfg(target="native")

///|
pub async fn send_menu(
  client : @rpc_client.Client,
  room_id : String,
  tracker : MenuTracker,
) -> Result[String, String] {
  let content = @action_stamps.new_select_content(MENU_QUESTION, MENU_OPTIONS)

  match await @action_stamps.send_select(client, room_id, content) {
    Ok(msg_id) => {
      // Update tracker
      set_last_id(tracker, msg_id)
      set_last_question(tracker, MENU_QUESTION)
      Ok(msg_id)
    }
    Err(e) => {
      Err("Failed to send menu: " ++ @errors.direct_error_to_string(e))
    }
  }
}

// Get the option text at the given index

///|
pub fn option_at(index : Int) -> String? {
  if index >= 0 && index < MENU_OPTIONS.length() {
    Some(MENU_OPTIONS[index])
  } else {
    None
  }
}

// Get option index by text

///|
pub fn index_of_option(text : String) -> Int? {
  let mut idx = 0
  for option in MENU_OPTIONS {
    if text == option {
      return Some(idx)
    }
    idx = idx + 1
  }
  None
}

// Get menu display text

///|
pub fn menu_display_text() -> String {
  let mut lines = ["Select Stamp Menu:", "Question: " ++ MENU_QUESTION]
  let mut idx = 0
  for option in MENU_OPTIONS {
    lines.push("  " ++ idx.to_string() ++ ". " ++ option)
    idx = idx + 1
  }
  String::join("\n", lines)
}

// Parse selection result to human-readable text

///|
pub fn format_selection_result(reply : @action_stamps.SelectStampReply) -> String {
  match option_at(reply.response) {
    Some(option) =>
      "選択されたオプション: " ++ option ++ " (インデックス: " ++ reply.response.to_string()
        ++ ")"
    None =>
      "無効な選択 (インデックス: " ++ reply.response.to_string() ++ ")"
  }
}

// Check if a reply is for our menu

///|
pub fn is_menu_reply(reply : @action_stamps.SelectStampReply) -> Bool {
  reply.question == MENU_QUESTION
}
