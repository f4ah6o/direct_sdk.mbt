// Select Stamp Bot Example for Direct SDK
// A bot that uses select stamps to create interactive menus
// Reference: direct-go-sdk/daab-go-examples/selectstamp/main.go

// Bot configuration

///|
pub struct BotConfig {
  token      : String
  bot_name   : String
}

// Bot state with menu tracking

///|
pub struct Bot {
  mut client       : @rpc_client.Client
  mut config       : BotConfig
  mut menu_tracker : @menu.MenuTracker
}

// Create a new select stamp bot

///|
pub fn new_bot(config : BotConfig) -> Bot {
  let client = @rpc_client.new_client_with_token(config.token)
  {
    client,
    config,
    menu_tracker: @menu.new_tracker(),
  }
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

  println("Bot is running!")
  println("Send 'menu' or 'メニュー' to see the interactive menu.")
}

// Handle incoming message

///|
fn handle_message(bot : Bot, msg : @types.ReceivedMessage) -> Unit {
  let text = @shared.bot_utils.get_text(msg)

  // Log message with type for debugging
  @shared.bot_utils.log_message_with_type(msg, bot.config.bot_name)

  // Check for menu command
  if @shared.command_parser.match_menu(text) {
    send_menu_to_room(bot, msg)
    return
  }

  // Check for select stamp reply
  match @shared.bot_utils.is_select_reply(msg) {
    true => handle_select_reply(bot, msg)
    false => ()
  }
}

// Send menu to the room

///|
fn send_menu_to_room(bot : Bot, msg : @types.ReceivedMessage) -> Unit {
  let room_id = @shared.bot_utils.get_room_id(msg)

  match await @menu.send_menu(bot.client, room_id, bot.menu_tracker) {
    Ok(msg_id) => {
      println("[MENU] Sent menu with message ID: " ++ msg_id)
    }
    Err(e) => {
      println("[ERROR] Failed to send menu: " ++ e)
      let _ =
        await @shared.bot_utils.safe_send_text(
          bot.client,
          room_id,
          "メニューの送信に失敗しました。",
        )
    }
  }

  ()
}

// Handle select stamp reply

///|
fn handle_select_reply(bot : Bot, msg : @types.ReceivedMessage) -> Unit {
  let room_id = @shared.bot_utils.get_room_id(msg)

  // Parse the select content
  match @action_stamps.parse_select_content(msg) {
    | @action_stamps.SelectParseSuccess(reply) => {
      // Check if this is our menu
      if is_our_menu(bot, reply) {
        match await @actions.handle_selection(bot.client, room_id, reply) {
          Ok(_) => {
            // Resend menu after handling selection
            let _ = await @menu.send_menu(bot.client, room_id, bot.menu_tracker)
          }
          Err(e) => {
            println("[ERROR] Failed to handle selection: " ++ e)
          }
        }
      }
    }
    | @action_stamps.SelectParseNotSelect => ()
    | @action_stamps.SelectParseNoResponse => ()
    | @action_stamps.SelectParseError(e) => {
      println("[ERROR] Parse error: " ++ e)
    }
  }

  ()
}

// Check if the select reply is for our menu

///|
fn is_our_menu(bot : Bot, reply : @action_stamps.SelectStampReply) -> Bool {
  // Check by question text
  if reply.question == @menu.MENU_QUESTION {
    return true
  }

  // Check by tracker (in_reply_to matching)
  @menu.matches_last_question(bot.menu_tracker, reply.in_reply_to)
}

// Main entry point for the bot
// cfg(target="native")

///|
pub async fn main {
  // In production, load token from environment or config file
  let token = "your-access-token-here"

  let config = {
    token: token,
    bot_name: "SelectStampBot",
  }

  let bot = new_bot(config)

  match await start(bot) {
    Ok(_) => {
      println("Bot running. Press Ctrl+C to stop.")
    }
    Err(e) => {
      println("Failed to start bot: " ++ @errors.direct_error_to_string(e))
    }
  }
}
