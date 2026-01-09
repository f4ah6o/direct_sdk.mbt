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
  let uuid = generate_uuid_v4()
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
    "UUID: " ++ format_uuid(uuid),
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

// Generate a UUID v4 (simplified implementation)
// Returns 16 bytes representing a UUID

///|
pub fn generate_uuid_v4() -> Array[UByte] {
  // Simple UUID v4 generation
  // In production, use a proper crypto library
  let mut bytes = []
  for i in range(0, 16) {
    // Use a simple pseudo-random value
    // This is NOT cryptographically secure!
    bytes.push(pseudo_random_byte(i))
  }

  // Set version bits (0100xxxx for v4)
  bytes[6] = (bytes[6] & 0x0F) | 0x40

  // Set variant bits (10xxxxxx for standard variant)
  bytes[8] = (bytes[8] & 0x3F) | 0x80

  bytes
}

// Simple pseudo-random byte generator
// This is a placeholder - NOT cryptographically secure!

///|
fn pseudo_random_byte(seed : Int) -> UByte {
  // Linear congruential generator
  let a = 1103515245
  let c = 12345
  let m = 256
  ((seed * a + c) % m).to_ubyte()
}

// Calculate a simple hash from UUID bytes for fortune selection

///|
pub fn uuid_hash(uuid : Array[UByte]) -> Int {
  if uuid.length() == 0 {
    return 0
  }
  uuid[0].to_int()
}

// Format UUID as standard string (e.g., "123e4567-e89b-12d3-a456-426614174000")

///|
pub fn format_uuid(uuid : Array[UByte]) -> String {
  if uuid.length() != 16 {
    return "<invalid-uuid>"
  }

  // Format: 8-4-4-4-12
  let hex = bytes_to_hex(uuid)
  hex.substring(0, 8)
    ++ "-"
    ++ hex.substring(8, 12)
    ++ "-"
    ++ hex.substring(12, 16)
    ++ "-"
    ++ hex.substring(16, 20)
    ++ "-"
    ++ hex.substring(20, 32)
}

// Convert bytes to hex string

///|
fn bytes_to_hex(bytes : Array[UByte]) -> String {
  let hex_chars = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e',
    'f',
  ]

  let mut result = ""
  for b in bytes {
    let hi = (b >> 4).to_int()
    let lo = (b & 0x0F).to_int()
    result = result
      ++ hex_chars[hi].to_string()
      ++ hex_chars[lo].to_string()
  }
  result
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
