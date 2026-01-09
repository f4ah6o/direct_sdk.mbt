// Bot example for Direct SDK
// This example demonstrates how to create a simple bot that:
// 1. Responds to messages
// 2. Handles user join events
// 3. Manages domain operations

// Bot configuration
pub type BotConfig = {
  token      : String,
  bot_name   : String,
  log_events : Bool,
}

// Bot state
pub type Bot = {
  mut client       : @rpc_client.Client,
  mut config       : BotConfig,
  mut start_time   : Int64,
}

// Create a new bot
pub fn new_bot(config : BotConfig) -> Bot {
  let client = @rpc_client.new_client_with_token(config.token)
  {
    client: client,
    config: config,
    start_time: 0L,
  }
}

// Start the bot
// cfg(target="native")
pub async fn start(bot : Bot) -> Result[Unit, @errors.DirectError] {
  println("Starting bot: \${bot.config.bot_name}")

  // Connect to API
  match await @rpc_client.connect(bot.client) {
    | Ok(_) => println("Bot connected")
    | Err(e) => {
      println("Connection failed: \${@errors.direct_error_to_string(e)}")
      return Err(e)
    }
  }

  bot.start_time = 0L  // Use actual time in production

  // Setup event handlers
  setup_handlers(bot)

  println("Bot is running...")
  Ok(())
}

// Stop the bot
// cfg(target="native")
pub async fn stop(bot : Bot) -> Result[Unit, @errors.DirectError] {
  println("Stopping bot: \${bot.config.bot_name}")
  match await @rpc_client.close(bot.client) {
    | Ok(_) => println("Bot stopped")
    | Err(e) => return Err(e)
  }
  Ok(())
}

// Setup event handlers for the bot
fn setup_handlers(bot : Bot) -> Unit {
  // Handle incoming messages
  @rpc_client.on_message(bot.client, fn(msg) {
    if bot.config.log_events {
      println("[MESSAGE] From: \${msg.user_id}, Text: \${msg.text}")
    }
    handle_message(bot, msg)
  })

  // Handle talk creation
  @rpc_client.on_talk(bot.client, fn(talk) {
    if bot.config.log_events {
      println("[TALK] Created: \${talk.name}")
    }
  })

  // Handle user updates
  @rpc_client.on_user(bot.client, fn(user) {
    if bot.config.log_events {
      println("[USER] Updated: \${user.display_name}")
    }
  })

  // Handle domain events
  @rpc_client.on_domain(bot.client, fn(domain) {
    if bot.config.log_events {
      println("[DOMAIN] Joined: \${domain.name}")
    }
  })

  // Handle session events
  @rpc_client.on(bot.client, @constants.EVENT_SESSION_CREATED, fn(data) {
    println("[SESSION] Created: \${data}")
  })

  @rpc_client.on(bot.client, @constants.EVENT_SESSION_ERROR, fn(data) {
    println("[SESSION] Error: \${data}")
  })

  ()
}

// Handle incoming message
fn handle_message(bot : Bot, msg : @types.ReceivedMessage) -> Unit {
  // Example: Respond to specific commands
  match msg.text {
    | "!ping" => {
      // Send pong response
      // TODO: Implement send_message helper
      println("Responding with pong to: \${msg.user_id}")
    }
    | "!help" => {
      println("Sending help to: \${msg.user_id}")
    }
    | "!info" => {
      println("Bot info: \${bot.config.bot_name}")
    }
    | _ => ()
  }
  ()
}

// Get bot statistics
pub fn get_stats(bot : Bot) -> Map[String, String] {
  Map::from_array([
    ("name", bot.config.bot_name),
    ("connected", if bot.client.connected { "true" } else { "false" }),
    ("authenticated", if bot.client.authenticated { "true" } else { "false" }),
  ])
}

// === Usage Example ===

// cfg(target="native")
pub async fn main_bot_example() -> Result[Unit, @errors.DirectError] {
  let config = {
    token: "your-bot-token-here",
    bot_name: "MoonBit Bot",
    log_events: true,
  }

  let bot = new_bot(config)

  match await start(bot) {
    | Ok(_) => {
      // Bot is running, handle events...
      // In production, you would keep the bot running here

      // Get stats
      let stats = get_stats(bot)
      println("Bot stats: \${stats}")

      // Stop when done
      await stop(bot)
    }
    | Err(e) => {
      println("Bot failed to start: \${@errors.direct_error_to_string(e)}")
      return Err(e)
    }
  }

  Ok(())
}

// === Event-driven bot pattern ===

// Create a bot that responds to specific patterns
pub type MessageHandler = (@types.ReceivedMessage) -> Unit

pub type PatternBot = {
  mut client        : @rpc_client.Client,
  mut handlers      : Map[String, MessageHandler],
  mut default_handler : Option[MessageHandler],
}

pub fn new_pattern_bot(token : String) -> PatternBot {
  let client = @rpc_client.new_client_with_token(token)
  {
    client: client,
    handlers: Map::new(),
    default_handler: None,
  }
}

// Register a handler for a specific command
pub fn on_command(bot : PatternBot, command : String, handler : MessageHandler) -> Unit {
  bot.handlers.insert(command, handler)
}

// Register a default handler for unmatched messages
pub fn on_default(bot : PatternBot, handler : MessageHandler) -> Unit {
  bot.default_handler = Some(handler)
}

// Start the pattern bot
// cfg(target="native")
pub async fn start_pattern_bot(bot : PatternBot) -> Result[Unit, @errors.DirectError] {
  // Connect
  match await @rpc_client.connect(bot.client) {
    | Ok(_) => ()
    | Err(e) => return Err(e)
  }

  // Setup message handler that routes to pattern handlers
  @rpc_client.on_message(bot.client, fn(msg) {
    let text = msg.text

    match bot.handlers.get(text) {
      | Some(handler) => handler(msg)
      | None => {
        match bot.default_handler {
          | Some(default) => default(msg)
          | None => ()
        }
      }
    }
  })

  Ok(())
}
