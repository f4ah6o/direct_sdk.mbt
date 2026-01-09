// Command implementations for Ping Bot
// Individual command handlers that can be tested independently

// Send PONG response to a room
// cfg(target="native")

///|
pub async fn send_pong(
  client : @rpc_client.Client,
  room_id : String,
) -> Result[Unit, String] {
  await @shared.bot_utils.safe_send_text(client, room_id, "PONG")
}

// Send echo response
// cfg(target="native")

///|
pub async fn send_echo(
  client : @rpc_client.Client,
  room_id : String,
  text : String,
) -> Result[Unit, String] {
  await @shared.bot_utils.safe_send_text(client, room_id, text)
}

// Send current server time
// cfg(target="native")

///|
pub async fn send_time(
  client : @rpc_client.Client,
  room_id : String,
) -> Result[Unit, String] {
  let time_msg = "Server time: " ++ get_current_time()
  await @shared.bot_utils.safe_send_text(client, room_id, time_msg)
}

// Send shout message
// cfg(target="native")

///|
pub async fn send_shout(
  client : @rpc_client.Client,
  room_id : String,
  text : String,
) -> Result[Unit, String] {
  await @shared.bot_utils.safe_send_text(client, room_id, text)
}

// Get current time string

///|
pub fn get_current_time() -> String {
  // MoonBit doesn't have built-in time functions yet
  // This would need platform-specific code via FFI
  // For now, return a placeholder
  let timestamp = get_timestamp()
  timestamp.to_string()
}

// Get Unix timestamp (placeholder)
// In production, this would call platform-specific time functions

///|
pub fn get_timestamp() -> Int64 {
  // Placeholder - would need FFI for actual time
  0L
}

// Format timestamp as readable string

///|
pub fn format_time(timestamp : Int64) -> String {
  // Simple formatting - would use proper time library in production
  "T" ++ timestamp.to_string()
}

// Parse command from text and return command type

///|
pub enum PingCommand {
  Ping
  Echo(String)
  Time
  Shout(String)
  Unknown
}

// Parse text into a PingCommand

///|
pub fn parse_command(text : String) -> PingCommand {
  let trimmed = @shared.command_parser.trim(text)

  match trimmed {
    | "ping" => Ping
    | "time" => Time
    | _ => {
      match @shared.command_parser.match_echo(trimmed) {
        Some(echoed) => Echo(echoed)
        None => {
          match @shared.command_parser.match_shout(trimmed) {
            Some(shouted) => Shout(shouted)
            None => Unknown
          }
        }
      }
    }
  }
}

// Execute a PingCommand
// cfg(target="native")

///|
pub async fn execute_command(
  client : @rpc_client.Client,
  room_id : String,
  cmd : PingCommand,
) -> Result[Unit, String] {
  match cmd {
    | Ping => await send_pong(client, room_id)
    | Echo(text) => await send_echo(client, room_id, text)
    | Time => await send_time(client, room_id)
    | Shout(text) => await send_shout(client, room_id, text)
    | Unknown => Ok(())
  }
}

// Get help text for available commands

///|
pub fn help_text() -> String {
  "Available commands:\n"
    ++ "  ping - Respond with PONG\n"
    ++ "  echo <text> - Echo back the given text\n"
    ++ "  time - Show current server time\n"
    ++ "  shout <text> - Send text to the room"
}
