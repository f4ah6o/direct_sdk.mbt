// Ping Bot Example for Direct SDK
// A simple bot that responds to commands with various messages
// Reference: direct-go-sdk/daab-go-examples/ping/main.go

// Bot configuration

///|
pub struct BotConfig {
  token      : String
  bot_name   : String
  log_all    : Bool
}

// Bot state

///|
pub struct Bot {
  mut client : @rpc_client.Client
  mut config : BotConfig
}

// Create a new bot with configuration

///|
pub fn new_bot(config : BotConfig) -> Bot {
  let client = @rpc_client.new_client_with_token(config.token)
  { client, config }
}

// Start the bot and connect to Direct API
// cfg(target="native")

///|
pub async fn start(bot : Bot) -> Result[Unit, @errors.DirectError] {
  println("Starting " ++ bot.config.bot_name ++ "...")

  match await @rpc_client.connect(bot.client) {
    Ok(_) => {
      println("Connected to Direct API")
      setup_handlers(bot)
      Ok(())
    }
    Err(e) => {
      println("Connection failed: " ++ @errors.direct_error_to_string(e))
      Err(e)
    }
  }
}

// Setup message handlers for the bot

///|
fn setup_handlers(bot : Bot) -> Unit {
  @rpc_client.on_message(bot.client, fn(msg) {
    handle_message(bot, msg)
  })

  println("Bot is running. Send commands to interact!")
  println("Commands: ping, echo <text>, time, shout <text>")
}

// Handle incoming message

///|
fn handle_message(bot : Bot, msg : @types.ReceivedMessage) -> Unit {
  let text = @shared.bot_utils.get_text(msg)

  // Log all messages if enabled
  if bot.config.log_all {
    @shared.bot_utils.log_message(msg, bot.config.bot_name)
  }

  // Parse and handle commands
  match text {
    | "ping" => {
      send_pong(bot, msg)
      ()
    }
    | "time" => {
      send_time(bot, msg)
      ()
    }
    | _ => {
      // Try echo command
      match @shared.command_parser.match_echo(text) {
        Some(echoed) => {
          send_echo(bot, msg, echoed)
          ()
        }
        None => ()
      }

      // Try shout command
      match @shared.command_parser.match_shout(text) {
        Some(shouted) => {
          send_shout(bot, msg, shouted)
          ()
        }
        None => ()
      }
    }
  }
}

// Send PONG response

///|
fn send_pong(bot : Bot, msg : @types.ReceivedMessage) -> Unit {
  let room_id = @shared.bot_utils.get_room_id(msg)
  match await @shared.bot_utils.safe_send_text(bot.client, room_id, "PONG") {
    Ok(_) => ()
    Err(e) => println("[ERROR] Failed to send PONG: " ++ e)
  }
}

// Send echo response

///|
fn send_echo(bot : Bot, msg : @types.ReceivedMessage, text : String) -> Unit {
  let room_id = @shared.bot_utils.get_room_id(msg)
  match await @shared.bot_utils.safe_send_text(bot.client, room_id, text) {
    Ok(_) => ()
    Err(e) => println("[ERROR] Failed to send echo: " ++ e)
  }
}

// Send current server time

///|
fn send_time(bot : Bot, msg : @types.ReceivedMessage) -> Unit {
  let room_id = @shared.bot_utils.get_room_id(msg)
  // For now, use a placeholder. In production, you'd get actual time
  let time_msg = "Server time: " ++ get_current_time()
  match await @shared.bot_utils.safe_send_text(bot.client, room_id, time_msg) {
    Ok(_) => ()
    Err(e) => println("[ERROR] Failed to send time: " ++ e)
  }
}

// Send shout message (same as echo but with intent)

///|
fn send_shout(bot : Bot, msg : @types.ReceivedMessage, text : String) -> Unit {
  let room_id = @shared.bot_utils.get_room_id(msg)
  match await @shared.bot_utils.safe_send_text(bot.client, room_id, text) {
    Ok(_) => ()
    Err(e) => println("[ERROR] Failed to shout: " ++ e)
  }
}

// Get current time (simplified - returns timestamp)

///|
fn get_current_time() -> String {
  // MoonBit doesn't have built-in time yet
  // This would need platform-specific implementation
  "<current_time>"
}

// Main entry point for the bot
// cfg(target="native")

///|
pub async fn main {
  // In production, load token from environment or config file
  let token = "your-access-token-here"

  let config = {
    token: token,
    bot_name: "PingBot",
    log_all: true,
  }

  let bot = new_bot(config)

  match await start(bot) {
    Ok(_) => {
      // Keep the bot running
      // In production, you'd have a keep-alive loop here
      println("Bot running. Press Ctrl+C to stop.")
    }
    Err(e) => {
      println("Failed to start bot: " ++ @errors.direct_error_to_string(e))
    }
  }
}
