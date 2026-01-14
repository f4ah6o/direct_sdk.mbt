// Action handlers for Select Stamp Bot
// Implements the functionality for each menu option

// Handle the user's menu selection
// cfg(target="native")

///|
pub async fn handle_selection(
  client : @rpc_client.Client,
  room_id : String,
  reply : @action_stamps.SelectStampReply,
) -> Result[Unit, String] {
  // Get the selected option text
  match @menu.option_at(reply.response) {
    Some(option) => {
      println("[ACTION] Selected: " ++ option)

      // Execute the corresponding action
      match option {
        | "uuid 占い" => await handle_uuid_fortune(client, room_id)
        | "ミラサポplus事例表示" => await handle_mirasapo_case(client, room_id)
        | _ => {
          let msg =
            "選択肢 " ++ reply.response.to_string() ++ " を受信しました。"
          await @shared.bot_utils.safe_send_text(client, room_id, msg)
        }
      }

      Ok(())
    }
    None => {
      let msg = "無効な選択です: " ++ reply.response.to_string()
      let _ = await @shared.bot_utils.safe_send_text(client, room_id, msg)
      Err("Invalid selection index")
    }
  }
}

// Handle UUID fortune telling
// cfg(target="native")

///|
pub async fn handle_uuid_fortune(
  client : @rpc_client.Client,
  room_id : String,
) -> Result[Unit, String] {
  // Use uuidm library to generate UUID v4
  let uuid = @uuidm.v4()
  let fortunes = [
    "大吉",
    "中吉",
    "小吉",
    "吉",
    "末吉",
    "凶",
  ]

  // Use first byte of UUID to select fortune
  let hash = uuid_hash(uuid)
  let idx = hash % fortunes.length()
  let fortune = fortunes[idx]

  let lines = [
    "uuid 占いの結果です。",
    "UUID: " ++ uuid.to_string(),
    "運勢: " ++ fortune,
  ]
  let msg = String::join("\n", lines)

  match await @shared.bot_utils.safe_send_text(client, room_id, msg) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// Handle Mirasapo+ case study display
// cfg(target="native")

///|
pub async fn handle_mirasapo_case(
  client : @rpc_client.Client,
  room_id : String,
) -> Result[Unit, String] {
  // For now, return a placeholder since MoonBit doesn't have HTTP client yet
  // In production, this would fetch from https://mirasapo-plus.go.jp/jirei-api
  let msg =
    "ミラサポplus 事例ナビ\n"
    ++ "(HTTP client integration coming soon)\n"
    ++ "API: https://mirasapo-plus.go.jp/jirei-api"

  match await @shared.bot_utils.safe_send_text(client, room_id, msg) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// Calculate a simple hash from UUID for fortune selection

///|
pub fn uuid_hash(uuid : @uuidm.Uuid) -> Int {
  let bytes = uuid.bytes()
  if bytes.length() == 0 {
    return 0
  }
  bytes[0].to_int()
}

// Get fortune text from index

///|
pub fn fortune_text(idx : Int) -> String {
  let fortunes = [
    "大吉",
    "中吉",
    "小吉",
    "吉",
    "末吉",
    "凶",
  ]

  if idx >= 0 && idx < fortunes.length() {
    fortunes[idx]
  } else {
    "未知"
  }
}

// Mirasapo+ API URL (for reference)

///|
pub const MIRASAPO_API_URL : String =
  "https://mirasapo-plus.go.jp/jirei-api"
