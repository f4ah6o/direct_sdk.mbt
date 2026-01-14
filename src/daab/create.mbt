///|
enum TemplateKind {
  Empty
  PingBot
  SelectStampBot
}

///|
fn normalize_template_name(name : String) -> String {
  name.to_lower().replace_all(old="_", new="-")
}

///|
fn template_from_name(name : String) -> Result[TemplateKind, String] {
  let normalized = normalize_template_name(name)
  if normalized == "" || normalized == "empty" {
    return Ok(TemplateKind::Empty)
  }
  match normalized {
    "ping" | "ping-bot" => Ok(TemplateKind::PingBot)
    "selectstamp" | "selectstamp-bot" => Ok(TemplateKind::SelectStampBot)
    _ =>
      Err(
        "unknown template: " +
        name +
        "\nAvailable templates: empty, ping-bot, selectstamp-bot",
      )
  }
}

///|
fn template_display_name(kind : TemplateKind) -> String {
  match kind {
    TemplateKind::Empty => "empty"
    TemplateKind::PingBot => "ping-bot"
    TemplateKind::SelectStampBot => "selectstamp-bot"
  }
}

///|
fn collect_positionals(args : ArrayView[String]) -> Array[String] {
  let values : Array[String] = []
  for arg in args {
    if !arg.has_prefix("-") {
      values.push(arg)
    }
  }
  values
}

///|
fn ensure_dir(path : String) -> Result[Unit, String] {
  if @fs.path_exists(path) {
    Ok(())
  } else {
    create_dir(path)
  }
}

///|
fn moon_mod_template_with_x(module_name : String) -> String {
  let direct_sdk_version = resolve_direct_sdk_version()
  (
    $|{
    $|  "name": "\{module_name}",
    $|  "version": "0.1.0",
    $|  "deps": {
    $|    "f4ah6o/direct_sdk": "\{direct_sdk_version}",
    $|    "moonbitlang/async": "\{default_async_version}",
    $|    "moonbitlang/x": "\{default_moon_x_version}"
    $|  },
    $|  "readme": "README.md",
    $|  "preferred-target": "native",
    $|  "description": "daab bot project"
    $|}
  )
}

///|
fn shared_pkg_template() -> String {
  (
    #|{
    #|  "import": [
    #|    { "path": "f4ah6o/direct_sdk/rpc/client", "alias": "rpc_client" },
    #|    { "path": "f4ah6o/direct_sdk/types", "alias": "types" },
    #|    { "path": "f4ah6o/direct_sdk/errors", "alias": "errors" }
    #|  ]
    #|}
  )
}

///|
fn shared_bot_utils_template() -> String {
  (
    #|// Bot utilities for Direct SDK examples
    #|// Common helper functions for bot implementations
    #|
    #|// Safe send text with error handling and logging
    #|// cfg(target="native")
    #|
    #|///|
    #|pub async fn safe_send_text(
    #|  client : @rpc_client.Client,
    #|  room_id : String,
    #|  text : String,
    #|) -> Result[Unit, String] {
    #|  match @rpc_client.send_text(client, room_id, text) {
    #|    Ok(_) => Ok(())
    #|    Err(e) => {
    #|      let error_msg = "Failed to send: " + @errors.direct_error_to_string(e)
    #|      println("[ERROR] " + error_msg)
    #|      Err(error_msg)
    #|    }
    #|  }
    #|}
    #|
    #|// Log message with timestamp and metadata
    #|
    #|///|
    #|pub fn log_message(msg : @types.ReceivedMessage, prefix : String) -> Unit {
    #|  let timestamp = msg.created.to_string()
    #|  let message =
    #|    "[\{prefix}] \{timestamp} | Room: \{msg.talk_id} | User: \{msg.user_id} | \{msg.text}"
    #|  println(message)
    #|}
    #|
    #|// Log message with type information
    #|
    #|///|
    #|pub fn log_message_with_type(msg : @types.ReceivedMessage, prefix : String) -> Unit {
    #|  let type_name = msg_type_to_name(msg.msg_type)
    #|  let timestamp = msg.created.to_string()
    #|  let message =
    #|    "[\{prefix}] \{timestamp} | Type: \{type_name} | Room: \{msg.talk_id} | User: \{msg.user_id} | \{msg.text}"
    #|  println(message)
    #|}
    #|
    #|// Convert MessageType to readable name
    #|
    #|///|
    #|pub fn msg_type_to_name(t : @types.MessageType) -> String {
    #|  match t {
    #|    @types.MsgTypeSystem => "System"
    #|    @types.MsgTypeText => "Text"
    #|    @types.MsgTypeStamp => "Stamp"
    #|    @types.MsgTypeLocation => "Location"
    #|    @types.MsgTypeFile => "File"
    #|    @types.MsgTypeTextMultipleFile => "MultiFile"
    #|    @types.MsgTypeDeleted => "Deleted"
    #|    @types.MsgTypeNoteShared => "NoteShared"
    #|    @types.MsgTypeNoteDeleted => "NoteDeleted"
    #|    @types.MsgTypeNoteCreated => "NoteCreated"
    #|    @types.MsgTypeNoteUpdated => "NoteUpdated"
    #|    @types.MsgTypeOriginalStamp => "OriginalStamp"
    #|    @types.MsgTypeYesNo => "YesNo"
    #|    @types.MsgTypeYesNoReply => "YesNoReply"
    #|    @types.MsgTypeSelect => "Select"
    #|    @types.MsgTypeSelectReply => "SelectReply"
    #|    @types.MsgTypeTask => "Task"
    #|    @types.MsgTypeTaskDone => "TaskDone"
    #|    @types.MsgTypeYesNoClosed => "YesNoClosed"
    #|    @types.MsgTypeSelectClosed => "SelectClosed"
    #|    @types.MsgTypeTaskClosed => "TaskClosed"
    #|    _ => "Unknown"
    #|  }
    #|}
    #|
    #|// Extract room_id from ReceivedMessage (handles both talk_id and room_id)
    #|
    #|///|
    #|pub fn get_room_id(msg : @types.ReceivedMessage) -> String {
    #|  if msg.room_id != "" {
    #|    msg.room_id
    #|  } else {
    #|    msg.talk_id
    #|  }
    #|}
    #|
    #|// Extract user_id from ReceivedMessage
    #|
    #|///|
    #|pub fn get_user_id(msg : @types.ReceivedMessage) -> String {
    #|  msg.user_id
    #|}
    #|
    #|// Extract text from ReceivedMessage
    #|
    #|///|
    #|pub fn get_text(msg : @types.ReceivedMessage) -> String {
    #|  msg.text
    #|}
    #|
    #|// Check if message is from a specific user
    #|
    #|///|
    #|pub fn is_from_user(msg : @types.ReceivedMessage, user_id : String) -> Bool {
    #|  msg.user_id == user_id
    #|}
    #|
    #|// Check if message is in a specific room
    #|
    #|///|
    #|pub fn is_in_room(msg : @types.ReceivedMessage, room_id : String) -> Bool {
    #|  get_room_id(msg) == room_id || msg.talk_id == room_id
    #|}
    #|
    #|// Format timestamp to readable string
    #|
    #|///|
    #|pub fn format_timestamp(timestamp : Int64) -> String {
    #|  // Simple timestamp formatting
    #|  timestamp.to_string()
    #|}
    #|
    #|// Combine multiple strings into a message
    #|
    #|///|
    #|pub fn join_lines(lines : Array[String]) -> String {
    #|  lines.join("\n")
    #|}
    #|
    #|// Split text by whitespace
    #|
    #|///|
    #|pub fn split_words(text : String) -> Array[String] {
    #|  text.split(" ").to_array().map((part) => part.to_string())
    #|}
    #|
    #|// Convert ID to String (handles both String and Int64 IDs)
    #|
    #|///|
    #|pub fn id_to_string(id : @types.ID) -> String {
    #|  @types.id_to_string(id)
    #|}
    #|
    #|// Check if message is a select stamp reply
    #|
    #|///|
    #|pub fn is_select_reply(msg : @types.ReceivedMessage) -> Bool {
    #|  match msg.msg_type {
    #|    @types.MsgTypeSelectReply => true
    #|    _ => false
    #|  }
    #|}
    #|
    #|// Check if message is a text message
    #|
    #|///|
    #|pub fn is_text_message(msg : @types.ReceivedMessage) -> Bool {
    #|  match msg.msg_type {
    #|    @types.MsgTypeText => true
    #|    _ => false
    #|  }
    #|}
  )
}

///|
fn shared_command_parser_template() -> String {
  (
    #|// Command parser for Direct SDK bot examples
    #|// Parses text commands and extracts parameters
    #|
    #|// Result of command parsing
    #|
    #|///|
    #|pub enum CommandMatch {
    #|  NoMatch
    #|  ExactMatch                         // Exact match like "ping"
    #|  PrefixMatch(String)                // Prefix with remaining text like "echo hello"
    #|  SuffixMatch(String)                // Suffix with preceding text like "hello!"
    #|}
    #|
    #|// Command pattern definitions
    #|
    #|///|
    #|pub enum CommandPattern {
    #|  ExactPattern(String)  // Exact match: "ping"
    #|  PrefixPattern(String) // Starts with: "echo "
    #|  SuffixPattern(String) // Ends with: "!"
    #|}
    #|
    #|// Parse command and return match result
    #|
    #|///|
    #|pub fn parse_command(text : String, pattern : CommandPattern) -> CommandMatch {
    #|  match pattern {
    #|    ExactPattern(cmd) => {
    #|      let trimmed = trim(text)
    #|      if trimmed == cmd {
    #|        ExactMatch
    #|      } else {
    #|        NoMatch
    #|      }
    #|    }
    #|    PrefixPattern(prefix) => {
    #|      let trimmed = trim(text)
    #|      if starts_with(trimmed, prefix) {
    #|        let remaining =
    #|          trim(
    #|            String::unsafe_substring(
    #|              trimmed,
    #|              start=prefix.length(),
    #|              end=trimmed.length(),
    #|            ),
    #|          )
    #|        PrefixMatch(remaining)
    #|      } else {
    #|        NoMatch
    #|      }
    #|    }
    #|    SuffixPattern(suffix) => {
    #|      let trimmed = trim(text)
    #|      if ends_with(trimmed, suffix) {
    #|        let end_idx = trimmed.length() - suffix.length()
    #|        let preceding =
    #|          trim(String::unsafe_substring(trimmed, start=0, end=end_idx))
    #|        SuffixMatch(preceding)
    #|      } else {
    #|        NoMatch
    #|      }
    #|    }
    #|  }
    #|}
    #|
    #|// Match "ping" command
    #|
    #|///|
    #|pub fn match_ping(text : String) -> Bool {
    #|  let trimmed = trim(text)
    #|  trimmed == "ping"
    #|}
    #|
    #|// Match "time" command
    #|
    #|///|
    #|pub fn match_time(text : String) -> Bool {
    #|  let trimmed = trim(text)
    #|  trimmed == "time"
    #|}
    #|
    #|// Match "echo <text>" command and return the text to echo
    #|
    #|///|
    #|pub fn match_echo(text : String) -> Option[String] {
    #|  let trimmed = trim(text)
    #|  let prefix = "echo "
    #|  if starts_with(trimmed, prefix) {
    #|    let echoed =
    #|      trim(
    #|        String::unsafe_substring(
    #|          trimmed,
    #|          start=prefix.length(),
    #|          end=trimmed.length(),
    #|        ),
    #|      )
    #|    if echoed.length() > 0 {
    #|      Some(echoed)
    #|    } else {
    #|      None
    #|    }
    #|  } else {
    #|    None
    #|  }
    #|}
    #|
    #|// Match "shout <text>" command and return the text to shout
    #|
    #|///|
    #|pub fn match_shout(text : String) -> Option[String] {
    #|  let trimmed = trim(text)
    #|  let prefix = "shout "
    #|  if starts_with(trimmed, prefix) {
    #|    let shouted =
    #|      trim(
    #|        String::unsafe_substring(
    #|          trimmed,
    #|          start=prefix.length(),
    #|          end=trimmed.length(),
    #|        ),
    #|      )
    #|    if shouted.length() > 0 {
    #|      Some(shouted)
    #|    } else {
    #|      None
    #|    }
    #|  } else {
    #|    None
    #|  }
    #|}
    #|
    #|// Match "menu" or "メニュー" command
    #|
    #|///|
    #|pub fn match_menu(text : String) -> Bool {
    #|  let trimmed = trim(text)
    #|  trimmed == "menu" || trimmed == "メニュー"
    #|}
    #|
    #|// Split command and arguments
    #|
    #|///|
    #|pub fn split_command(text : String) -> (String, String) {
    #|  let trimmed = trim(text)
    #|  if trimmed == "" {
    #|    ("", "")
    #|  } else {
    #|    let parts =
    #|      trimmed.split(" ").to_array().map((part) => part.to_string())
    #|        .filter((part) => part != "")
    #|    if parts.length() == 0 {
    #|      ("", "")
    #|    } else if parts.length() == 1 {
    #|      (parts[0], "")
    #|    } else {
    #|      let args = parts[1:parts.length()].to_array().join(" ")
    #|      (parts[0], trim(args))
    #|    }
    #|  }
    #|}
    #|
    #|// Get first word from text
    #|
    #|///|
    #|pub fn first_word(text : String) -> String {
    #|  let trimmed = trim(text)
    #|  match trimmed.find(" ") {
    #|    Some(idx) => String::unsafe_substring(trimmed, start=0, end=idx)
    #|    None => trimmed
    #|  }
    #|}
    #|
    #|// Get remaining text after first word
    #|
    #|///|
    #|pub fn remaining_text(text : String) -> String {
    #|  let trimmed = trim(text)
    #|  match trimmed.find(" ") {
    #|    Some(idx) =>
    #|      trim(
    #|        String::unsafe_substring(
    #|          trimmed,
    #|          start=idx + 1,
    #|          end=trimmed.length(),
    #|        ),
    #|      )
    #|    None => ""
    #|  }
    #|}
    #|
    #|// Check if text matches any of the given patterns
    #|
    #|///|
    #|pub fn matches_any(text : String, patterns : Array[String]) -> Bool {
    #|  for pattern in patterns {
    #|    if trim(text) == trim(pattern) {
    #|      return true
    #|    }
    #|  }
    #|  false
    #|}
    #|
    #|// Trim whitespace from text
    #|
    #|///|
    #|pub fn trim(text : String) -> String {
    #|  text.trim().to_string()
    #|}
    #|
    #|// Check if text starts with prefix
    #|
    #|///|
    #|pub fn starts_with(text : String, prefix : String) -> Bool {
    #|  match text.find(prefix) {
    #|    Some(0) => true
    #|    _ => false
    #|  }
    #|}
    #|
    #|// Check if text ends with suffix
    #|
    #|///|
    #|pub fn ends_with(text : String, suffix : String) -> Bool {
    #|  let text_len = text.length()
    #|  let suffix_len = suffix.length()
    #|  if suffix_len == 0 {
    #|    true
    #|  } else if text_len < suffix_len {
    #|    false
    #|  } else {
    #|    match text.rev_find(suffix) {
    #|      Some(idx) => idx + suffix_len == text_len
    #|      None => false
    #|    }
    #|  }
    #|}
    #|
    #|// Tokenize text by spaces
    #|
    #|///|
    #|pub fn tokenize(text : String) -> Array[String] {
    #|  let trimmed = trim(text)
    #|  if trimmed == "" {
    #|    return []
    #|  }
    #|  trimmed.split(" ").to_array().map((part) => part.to_string())
    #|    .filter((part) => part != "")
    #|}
    #|
    #|// Find command by prefix in text
    #|
    #|///|
    #|pub fn find_command(text : String, commands : Array[String]) -> Option[String] {
    #|  let trimmed = trim(text)
    #|  for cmd in commands {
    #|    if starts_with(trimmed, cmd + " ") {
    #|      return Some(cmd)
    #|    }
    #|  }
    #|  None
    #|}
  )
}

///|
fn ping_cmd_pkg_template(module_name : String) -> String {
  (
    $|{
    $|  "is-main": true,
    $|  "import": [
    $|    { "path": "moonbitlang/async", "alias": "async" },
    $|    { "path": "f4ah6o/direct_sdk/rpc/client", "alias": "rpc_client" },
    $|    { "path": "f4ah6o/direct_sdk/types", "alias": "types" },
    $|    { "path": "f4ah6o/direct_sdk/errors", "alias": "errors" },
    $|    { "path": "\{module_name}/shared", "alias": "shared" },
    $|    { "path": "moonbitlang/x/sys", "alias": "sys" }
    $|  ]
    $|}
  )
}

///|
fn ping_main_template() -> String {
  (
    #|// Ping Bot Example for Direct SDK
    #|// A simple bot that responds to commands with various messages
    #|// Reference: direct-go-sdk/daab-go-examples/ping/main.go
    #|
    #|// Bot configuration
    #|
    #|///|
    #|pub struct BotConfig {
    #|  token      : String
    #|  bot_name   : String
    #|  log_all    : Bool
    #|}
    #|
    #|// Bot state
    #|
    #|///|
    #|pub struct Bot {
    #|  client : @rpc_client.Client
    #|  config : BotConfig
    #|  tasks  : @async.TaskGroup[Unit]
    #|}
    #|
    #|// Create a new bot with configuration
    #|
    #|///|
    #|pub fn new_bot(config : BotConfig, tasks : @async.TaskGroup[Unit]) -> Bot {
    #|  let client = @rpc_client.new_client_with_token(config.token)
    #|  { client, config, tasks }
    #|}
    #|
    #|// Start the bot and connect to Direct API
    #|// cfg(target="native")
    #|
    #|///|
    #|pub async fn start(bot : Bot) -> Result[Unit, @errors.DirectError] {
    #|  println("Starting " + bot.config.bot_name + "...")
    #|
    #|  match @rpc_client.connect(bot.client, bot.tasks) {
    #|    Ok(_) => {
    #|      println("Connected to Direct API")
    #|      setup_handlers(bot)
    #|      Ok(())
    #|    }
    #|    Err(e) => {
    #|      println("Connection failed: " + @errors.direct_error_to_string(e))
    #|      Err(e)
    #|    }
    #|  }
    #|}
    #|
    #|// Setup message handlers for the bot
    #|
    #|///|
    #|fn setup_handlers(bot : Bot) -> Unit {
    #|  @rpc_client.on_message(bot.client, fn(msg) {
    #|    bot.tasks.spawn_bg(fn() {
    #|      handle_message(bot, msg)
    #|    })
    #|  })
    #|
    #|  println("Bot is running. Send commands to interact!")
    #|  println("Commands: ping, echo <text>, time, shout <text>")
    #|}
    #|
    #|// Handle incoming message
    #|
    #|///|
    #|async fn handle_message(bot : Bot, msg : @types.ReceivedMessage) -> Unit {
    #|  let text = @shared.get_text(msg)
    #|
    #|  // Log all messages if enabled
    #|  if bot.config.log_all {
    #|    @shared.log_message(msg, bot.config.bot_name)
    #|  }
    #|
    #|  // Parse and handle commands
    #|  match text {
    #|    "ping" => {
    #|      send_pong(bot, msg)
    #|      ()
    #|    }
    #|    "time" => {
    #|      send_time(bot, msg)
    #|      ()
    #|    }
    #|    _ => {
    #|      // Try echo command
    #|      match @shared.match_echo(text) {
    #|        Some(echoed) => {
    #|          send_echo(bot, msg, echoed)
    #|          ()
    #|        }
    #|        None => ()
    #|      }
    #|
    #|      // Try shout command
    #|      match @shared.match_shout(text) {
    #|        Some(shouted) => {
    #|          send_shout(bot, msg, shouted)
    #|          ()
    #|        }
    #|        None => ()
    #|      }
    #|    }
    #|  }
    #|}
    #|
    #|// Send PONG response
    #|
    #|///|
    #|async fn send_pong(bot : Bot, msg : @types.ReceivedMessage) -> Unit {
    #|  let room_id = @shared.get_room_id(msg)
    #|  match @shared.safe_send_text(bot.client, room_id, "PONG") {
    #|    Ok(_) => ()
    #|    Err(e) => println("[ERROR] Failed to send PONG: " + e)
    #|  }
    #|}
    #|
    #|// Send echo response
    #|
    #|///|
    #|async fn send_echo(
    #|  bot : Bot,
    #|  msg : @types.ReceivedMessage,
    #|  text : String,
    #|) -> Unit {
    #|  let room_id = @shared.get_room_id(msg)
    #|  match @shared.safe_send_text(bot.client, room_id, text) {
    #|    Ok(_) => ()
    #|    Err(e) => println("[ERROR] Failed to send echo: " + e)
    #|  }
    #|}
    #|
    #|// Send current server time
    #|
    #|///|
    #|async fn send_time(bot : Bot, msg : @types.ReceivedMessage) -> Unit {
    #|  let room_id = @shared.get_room_id(msg)
    #|  // For now, use a placeholder. In production, you'd get actual time
    #|  let time_msg = "Server time: " + get_current_time()
    #|  match @shared.safe_send_text(bot.client, room_id, time_msg) {
    #|    Ok(_) => ()
    #|    Err(e) => println("[ERROR] Failed to send time: " + e)
    #|  }
    #|}
    #|
    #|// Send shout message (same as echo but with intent)
    #|
    #|///|
    #|async fn send_shout(
    #|  bot : Bot,
    #|  msg : @types.ReceivedMessage,
    #|  text : String,
    #|) -> Unit {
    #|  let room_id = @shared.get_room_id(msg)
    #|  match @shared.safe_send_text(bot.client, room_id, text) {
    #|    Ok(_) => ()
    #|    Err(e) => println("[ERROR] Failed to shout: " + e)
    #|  }
    #|}
    #|
    #|// Get current time (simplified - returns timestamp)
    #|
    #|///|
    #|fn get_current_time() -> String {
    #|  // MoonBit doesn't have built-in time yet
    #|  // This would need platform-specific implementation
    #|  "<current_time>"
    #|}
    #|
    #|// Main entry point for the bot
    #|// cfg(target="native")
    #|
    #|///|
    #|async fn main {
    #|  let token = match @sys.get_env_var("HUBOT_DIRECT_TOKEN") {
    #|    Some(value) => value
    #|    None => {
    #|      println("HUBOT_DIRECT_TOKEN is not set. Run 'daab login' first.")
    #|      return
    #|    }
    #|  }
    #|  if token == "" {
    #|    println("HUBOT_DIRECT_TOKEN is not set. Run 'daab login' first.")
    #|    return
    #|  }
    #|
    #|  let config = {
    #|    token: token,
    #|    bot_name: "PingBot",
    #|    log_all: true,
    #|  }
    #|
    #|  @async.with_task_group(fn(tasks) {
    #|    let bot = new_bot(config, tasks)
    #|    match start(bot) {
    #|      Ok(_) => ()
    #|      Err(e) => {
    #|        println("Failed to start bot: " + @errors.direct_error_to_string(e))
    #|        return
    #|      }
    #|    }
    #|    println("Bot running. Press Ctrl+C to stop.")
    #|    while true {
    #|      @async.sleep(60_000)
    #|    }
    #|  })
    #|}
  )
}

///|
fn ping_readme_template(project_name : String) -> String {
  (
    $|# \{project_name}
    $|
    $|A simple bot for the Direct SDK that responds to various commands.
    $|
    $|## Features
    $|
    $|- **ping** - Responds with "PONG"
    $|- **echo <text>** - Echoes back the given text
    $|- **time** - Shows the current server time
    $|- **shout <text>** - Sends text to the room
    $|
    $|## Getting Started
    $|
    $|1. Save your access token in `.env`:
    $|   - Run `daab login` or `daab login --token <token>`
    $|2. Run the bot:
    $|   - `daab run`
    $|
    $|## Environment
    $|
    $|- `HUBOT_DIRECT_TOKEN`: Access token for the Direct API.
  )
}

///|
fn select_cmd_pkg_template(module_name : String) -> String {
  (
    $|{
    $|  "is-main": true,
    $|  "import": [
    $|    { "path": "moonbitlang/async", "alias": "async" },
    $|    { "path": "f4ah6o/direct_sdk/rpc/client", "alias": "rpc_client" },
    $|    { "path": "f4ah6o/direct_sdk/types", "alias": "types" },
    $|    { "path": "f4ah6o/direct_sdk/errors", "alias": "errors" },
    $|    { "path": "f4ah6o/direct_sdk/api/action_stamps", "alias": "action_stamps" },
    $|    { "path": "\{module_name}/shared", "alias": "shared" },
    $|    { "path": "moonbitlang/x/sys", "alias": "sys" }
    $|  ]
    $|}
  )
}

///|
fn select_main_template() -> String {
  (
    #|// Select Stamp Bot Example for Direct SDK
    #|// A bot that uses select stamps to create interactive menus
    #|// Reference: direct-go-sdk/daab-go-examples/selectstamp/main.go
    #|
    #|// Bot configuration
    #|
    #|///|
    #|pub struct BotConfig {
    #|  token      : String
    #|  bot_name   : String
    #|}
    #|
    #|// Bot state with menu tracking
    #|
    #|///|
    #|pub struct Bot {
    #|  client       : @rpc_client.Client
    #|  config       : BotConfig
    #|  menu_tracker : MenuTracker
    #|  tasks        : @async.TaskGroup[Unit]
    #|}
    #|
    #|// Create a new select stamp bot
    #|
    #|///|
    #|pub fn new_bot(config : BotConfig, tasks : @async.TaskGroup[Unit]) -> Bot {
    #|  let client = @rpc_client.new_client_with_token(config.token)
    #|  {
    #|    client,
    #|    config,
    #|    menu_tracker: new_tracker(),
    #|    tasks,
    #|  }
    #|}
    #|
    #|// Start the bot and connect to Direct API
    #|// cfg(target="native")
    #|
    #|///|
    #|pub async fn start(bot : Bot) -> Result[Unit, @errors.DirectError] {
    #|  println("Starting " + bot.config.bot_name + "...")
    #|
    #|  match @rpc_client.connect(bot.client, bot.tasks) {
    #|    Ok(_) => {
    #|      println("Connected to Direct API")
    #|      setup_handlers(bot)
    #|      Ok(())
    #|    }
    #|    Err(e) => {
    #|      println("Connection failed: " + @errors.direct_error_to_string(e))
    #|      Err(e)
    #|    }
    #|  }
    #|}
    #|
    #|// Setup message handlers for the bot
    #|
    #|///|
    #|fn setup_handlers(bot : Bot) -> Unit {
    #|  @rpc_client.on_message(bot.client, fn(msg) {
    #|    bot.tasks.spawn_bg(fn() {
    #|      handle_message(bot, msg)
    #|    })
    #|  })
    #|
    #|  println("Bot is running!")
    #|  println("Send 'menu' or 'メニュー' to see the interactive menu.")
    #|}
    #|
    #|// Handle incoming message
    #|
    #|///|
    #|async fn handle_message(bot : Bot, msg : @types.ReceivedMessage) -> Unit {
    #|  let text = @shared.get_text(msg)
    #|
    #|  // Log message with type for debugging
    #|  @shared.log_message_with_type(msg, bot.config.bot_name)
    #|
    #|  // Check for menu command
    #|  if @shared.match_menu(text) {
    #|    send_menu_to_room(bot, msg)
    #|    return
    #|  }
    #|
    #|  // Check for select stamp reply
    #|  match @shared.is_select_reply(msg) {
    #|    true => handle_select_reply(bot, msg)
    #|    false => ()
    #|  }
    #|}
    #|
    #|// Send menu to the room
    #|
    #|///|
    #|async fn send_menu_to_room(bot : Bot, msg : @types.ReceivedMessage) -> Unit {
    #|  let room_id = @shared.get_room_id(msg)
    #|
    #|  match send_menu(bot.client, room_id, bot.menu_tracker) {
    #|    Ok(msg_id) => {
    #|      println("[MENU] Sent menu with message ID: " + msg_id)
    #|    }
    #|    Err(e) => {
    #|      println("[ERROR] Failed to send menu: " + e)
    #|      let _ =
    #|        @shared.safe_send_text(
    #|          bot.client,
    #|          room_id,
    #|          "メニューの送信に失敗しました。",
    #|        )
    #|    }
    #|  }
    #|
    #|  ()
    #|}
    #|
    #|// Handle select stamp reply
    #|
    #|///|
    #|async fn handle_select_reply(bot : Bot, msg : @types.ReceivedMessage) -> Unit {
    #|  let room_id = @shared.get_room_id(msg)
    #|
    #|  // Parse the select content
    #|  match @action_stamps.parse_select_content(msg) {
    #|    @action_stamps.SelectParseSuccess(reply) => {
    #|      // Check if this is our menu
    #|      if is_our_menu(bot, reply) {
    #|        match handle_selection(bot.client, room_id, reply) {
    #|          Ok(_) => {
    #|            // Resend menu after handling selection
    #|            let _ = send_menu(bot.client, room_id, bot.menu_tracker)
    #|          }
    #|          Err(e) => {
    #|            println("[ERROR] Failed to handle selection: " + e)
    #|          }
    #|        }
    #|      }
    #|    }
    #|    @action_stamps.SelectParseNotSelect => ()
    #|    @action_stamps.SelectParseNoResponse => ()
    #|    @action_stamps.SelectParseError(e) => {
    #|      println("[ERROR] Parse error: " + e)
    #|    }
    #|  }
    #|
    #|  ()
    #|}
    #|
    #|// Check if the select reply is for our menu
    #|
    #|///|
    #|fn is_our_menu(bot : Bot, reply : @action_stamps.SelectStampReply) -> Bool {
    #|  // Check by question text
    #|  if reply.question == MENU_QUESTION {
    #|    return true
    #|  }
    #|
    #|  // Check by tracker (in_reply_to matching)
    #|  matches_last_question(bot.menu_tracker, reply.in_reply_to)
    #|}
    #|
    #|// Main entry point for the bot
    #|// cfg(target="native")
    #|
    #|///|
    #|async fn main {
    #|  let token = match @sys.get_env_var("HUBOT_DIRECT_TOKEN") {
    #|    Some(value) => value
    #|    None => {
    #|      println("HUBOT_DIRECT_TOKEN is not set. Run 'daab login' first.")
    #|      return
    #|    }
    #|  }
    #|  if token == "" {
    #|    println("HUBOT_DIRECT_TOKEN is not set. Run 'daab login' first.")
    #|    return
    #|  }
    #|
    #|  let config = {
    #|    token: token,
    #|    bot_name: "SelectStampBot",
    #|  }
    #|
    #|  @async.with_task_group(fn(tasks) {
    #|    let bot = new_bot(config, tasks)
    #|    match start(bot) {
    #|      Ok(_) => ()
    #|      Err(e) => {
    #|        println("Failed to start bot: " + @errors.direct_error_to_string(e))
    #|        return
    #|      }
    #|    }
    #|    println("Bot running. Press Ctrl+C to stop.")
    #|    while true {
    #|      @async.sleep(60_000)
    #|    }
    #|  })
    #|}
  )
}

///|
fn select_menu_template() -> String {
  (
    #|// Menu management for Select Stamp Bot
    #|// Handles sending select stamp menus and tracking responses
    #|
    #|// Menu configuration constants
    #|
    #|///|
    #|pub const MENU_QUESTION : String = "機能メニュー"
    #|
    #|///|
    #|pub let menu_options : Array[String] = [
    #|  "uuid 占い",
    #|  "ミラサポplus事例表示",
    #|]
    #|
    #|// Menu tracker to correlate responses with sent menus
    #|
    #|///|
    #|pub struct MenuTracker {
    #|  mut last_question_id : String
    #|  mut last_question : String
    #|}
    #|
    #|// Create a new menu tracker
    #|
    #|///|
    #|pub fn new_tracker() -> MenuTracker {
    #|  { last_question_id: "", last_question: "" }
    #|}
    #|
    #|// Set the last sent question ID
    #|
    #|///|
    #|pub fn set_last_id(tracker : MenuTracker, id : String) -> Unit {
    #|  tracker.last_question_id = id
    #|}
    #|
    #|// Set the last sent question text
    #|
    #|///|
    #|pub fn set_last_question(tracker : MenuTracker, question : String) -> Unit {
    #|  tracker.last_question = question
    #|}
    #|
    #|// Check if the reply matches the last sent question
    #|
    #|///|
    #|pub fn matches_last_question(tracker : MenuTracker, in_reply_to : String) -> Bool {
    #|  tracker.last_question_id != "" && tracker.last_question_id == in_reply_to
    #|}
    #|
    #|// Send the select menu to a room
    #|// cfg(target="native")
    #|
    #|///|
    #|pub async fn send_menu(
    #|  client : @rpc_client.Client,
    #|  room_id : String,
    #|  tracker : MenuTracker,
    #|) -> Result[String, String] {
    #|  let content = @action_stamps.new_select_content(MENU_QUESTION, menu_options)
    #|
    #|  match @action_stamps.send_select(client, room_id, content) {
    #|    Ok(msg_id) => {
    #|      // Update tracker
    #|      set_last_id(tracker, msg_id)
    #|      set_last_question(tracker, MENU_QUESTION)
    #|      Ok(msg_id)
    #|    }
    #|    Err(e) => {
    #|      Err("Failed to send menu: " + @errors.direct_error_to_string(e))
    #|    }
    #|  }
    #|}
    #|
    #|// Get the option text at the given index
    #|
    #|///|
    #|pub fn option_at(index : Int) -> String? {
    #|  if index >= 0 && index < menu_options.length() {
    #|    Some(menu_options[index])
    #|  } else {
    #|    None
    #|  }
    #|}
    #|
    #|// Get option index by text
    #|
    #|///|
    #|pub fn index_of_option(text : String) -> Int? {
    #|  let mut idx = 0
    #|  for option in menu_options {
    #|    if text == option {
    #|      return Some(idx)
    #|    }
    #|    idx = idx + 1
    #|  }
    #|  None
    #|}
    #|
    #|// Get menu display text
    #|
    #|///|
    #|pub fn menu_display_text() -> String {
    #|  let lines = ["Select Stamp Menu:", "Question: " + MENU_QUESTION]
    #|  let mut idx = 0
    #|  for option in menu_options {
    #|    lines.push("  " + idx.to_string() + ". " + option)
    #|    idx = idx + 1
    #|  }
    #|  lines.join("\n")
    #|}
    #|
    #|// Parse selection result to human-readable text
    #|
    #|///|
    #|pub fn format_selection_result(reply : @action_stamps.SelectStampReply) -> String {
    #|  match option_at(reply.response) {
    #|    Some(option) =>
    #|      "選択されたオプション: \{option} (インデックス: \{reply.response.to_string()})"
    #|    None =>
    #|      "無効な選択 (インデックス: \{reply.response.to_string()})"
    #|  }
    #|}
    #|
    #|// Check if a reply is for our menu
    #|
    #|///|
    #|pub fn is_menu_reply(reply : @action_stamps.SelectStampReply) -> Bool {
    #|  reply.question == MENU_QUESTION
    #|}
  )
}

///|
fn select_actions_template() -> String {
  (
    #|// Action handlers for Select Stamp Bot
    #|// Implements the functionality for each menu option
    #|
    #|// Handle the user's menu selection
    #|// cfg(target="native")
    #|
    #|///|
    #|pub async fn handle_selection(
    #|  client : @rpc_client.Client,
    #|  room_id : String,
    #|  reply : @action_stamps.SelectStampReply,
    #|) -> Result[Unit, String] {
    #|  // Get the selected option text
    #|  match option_at(reply.response) {
    #|    Some(option) => {
    #|      println("[ACTION] Selected: " + option)
    #|
    #|      // Execute the corresponding action
    #|      match option {
    #|        "uuid 占い" => handle_uuid_fortune(client, room_id)
    #|        "ミラサポplus事例表示" => handle_mirasapo_case(client, room_id)
    #|        _ => {
    #|          let msg =
    #|            "選択肢 " + reply.response.to_string() + " を受信しました。"
    #|          @shared.safe_send_text(client, room_id, msg)
    #|        }
    #|      }
    #|    }
    #|    None => {
    #|      let msg = "無効な選択です: " + reply.response.to_string()
    #|      let _ = @shared.safe_send_text(client, room_id, msg)
    #|      Err("Invalid selection index")
    #|    }
    #|  }
    #|}
    #|
    #|// Handle UUID fortune telling
    #|// cfg(target="native")
    #|
    #|///|
    #|pub async fn handle_uuid_fortune(
    #|  client : @rpc_client.Client,
    #|  room_id : String,
    #|) -> Result[Unit, String] {
    #|  let uuid = generate_uuid_v4()
    #|  let fortunes = [
    #|    "大吉",
    #|    "中吉",
    #|    "小吉",
    #|    "吉",
    #|    "末吉",
    #|    "凶",
    #|  ]
    #|
    #|  // Use first byte of UUID to select fortune
    #|  let hash = uuid_hash(uuid)
    #|  let idx = hash % fortunes.length()
    #|  let fortune = fortunes[idx]
    #|
    #|  let lines = [
    #|    "uuid 占いの結果です。",
    #|    "UUID: " + format_uuid(uuid),
    #|    "運勢: " + fortune,
    #|  ]
    #|  let msg = lines.join("\n")
    #|
    #|  match @shared.safe_send_text(client, room_id, msg) {
    #|    Ok(_) => Ok(())
    #|    Err(e) => Err(e)
    #|  }
    #|}
    #|
    #|// Handle Mirasapo+ case study display
    #|// cfg(target="native")
    #|
    #|///|
    #|pub async fn handle_mirasapo_case(
    #|  client : @rpc_client.Client,
    #|  room_id : String,
    #|) -> Result[Unit, String] {
    #|  // For now, return a placeholder since MoonBit doesn't have HTTP client yet
    #|  // In production, this would fetch from https://mirasapo-plus.go.jp/jirei-api
    #|  let msg =
    #|    "ミラサポplus 事例ナビ\n(HTTP client integration coming soon)\nAPI: https://mirasapo-plus.go.jp/jirei-api"
    #|
    #|  match @shared.safe_send_text(client, room_id, msg) {
    #|    Ok(_) => Ok(())
    #|    Err(e) => Err(e)
    #|  }
    #|}
    #|
    #|// Generate a UUID v4 (simplified implementation)
    #|// Returns 16 bytes representing a UUID
    #|// cfg(target="native")
    #|
    #|///|
    #|pub fn generate_uuid_v4() -> Array[Byte] {
    #|  // Use current time as seed for randomness
    #|  let seed = @env.now().reinterpret_as_int64()
    #|  let bytes = Array::makei(16, (i) => pseudo_random_byte(seed + i.to_int64()))
    #|
    #|  // Set version bits (0100xxxx for v4)
    #|  bytes[6] = bytes[6].land(b'\x0f').lor(b'\x40')
    #|
    #|  // Set variant bits (10xxxxxx for standard variant)
    #|  bytes[8] = bytes[8].land(b'\x3f').lor(b'\x80')
    #|
    #|  bytes
    #|}
    #|
    #|// Simple pseudo-random byte generator
    #|// This is a placeholder - NOT cryptographically secure!
    #|
    #|///|
    #|fn pseudo_random_byte(seed : Int64) -> Byte {
    #|  // Linear congruential generator
    #|  let a = 1103515245L
    #|  let c = 12345L
    #|  let m = 256L
    #|  ((seed * a + c) % m).to_int().to_byte()
    #|}
    #|
    #|// Calculate a simple hash from UUID bytes for fortune selection
    #|
    #|///|
    #|pub fn uuid_hash(uuid : Array[Byte]) -> Int {
    #|  if uuid.length() == 0 {
    #|    return 0
    #|  }
    #|  uuid[0].to_int()
    #|}
    #|
    #|// Format UUID as standard string (e.g., "123e4567-e89b-12d3-a456-426614174000")
    #|
    #|///|
    #|pub fn format_uuid(uuid : Array[Byte]) -> String {
    #|  if uuid.length() != 16 {
    #|    return "<invalid-uuid>"
    #|  }
    #|
    #|  // Format: 8-4-4-4-12
    #|  let hex = bytes_to_hex(uuid)
    #|  let part1 = String::unsafe_substring(hex, start=0, end=8)
    #|  let part2 = String::unsafe_substring(hex, start=8, end=12)
    #|  let part3 = String::unsafe_substring(hex, start=12, end=16)
    #|  let part4 = String::unsafe_substring(hex, start=16, end=20)
    #|  let part5 = String::unsafe_substring(hex, start=20, end=32)
    #|  part1 + "-" + part2 + "-" + part3 + "-" + part4 + "-" + part5
    #|}
    #|
    #|// Convert bytes to hex string
    #|
    #|///|
    #|fn bytes_to_hex(bytes : Array[Byte]) -> String {
    #|  let mut result = ""
    #|  for b in bytes {
    #|    result = result + b.to_hex()
    #|  }
    #|  result
    #|}
    #|
    #|// Get fortune text from index
    #|
    #|///|
    #|pub fn fortune_text(idx : Int) -> String {
    #|  let fortunes = [
    #|    "大吉",
    #|    "中吉",
    #|    "小吉",
    #|    "吉",
    #|    "末吉",
    #|    "凶",
    #|  ]
    #|
    #|  if idx >= 0 && idx < fortunes.length() {
    #|    fortunes[idx]
    #|  } else {
    #|    "未知"
    #|  }
    #|}
  )
}

///|
fn select_readme_template(project_name : String) -> String {
  (
    $|# \{project_name}
    $|
    $|A bot for the Direct SDK that demonstrates interactive menus using select stamps.
    $|
    $|## Features
    $|
    $|- **Interactive Menu** - Sends a select stamp with two options:
    $|  1. uuid 占い - Fortune telling based on UUID
    $|  2. ミラサポplus事例表示 - Display a case study from Mirasapo+ API
    $|
    $|- **Automatic Resend** - After handling a selection, the menu is resent for continuous operation
    $|
    $|## Getting Started
    $|
    $|1. Save your access token in `.env`:
    $|   - Run `daab login` or `daab login --token <token>`
    $|2. Run the bot:
    $|   - `daab run`
    $|
    $|## Environment
    $|
    $|- `HUBOT_DIRECT_TOKEN`: Access token for the Direct API.
  )
}

///|
fn apply_shared_template(project_name : String) -> Result[Unit, String] {
  let shared_dir = join_path(project_name, "shared")
  match ensure_dir(shared_dir) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match
    write_file(join_path(shared_dir, "moon.pkg.json"), shared_pkg_template()) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match
    write_file(
      join_path(shared_dir, "bot_utils.mbt"),
      shared_bot_utils_template(),
    ) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match
    write_file(
      join_path(shared_dir, "command_parser.mbt"),
      shared_command_parser_template(),
    ) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  Ok(())
}

///|
fn apply_ping_template(project_name : String) -> Result[Unit, String] {
  let module_name = module_name_for(project_name)
  let cmd_dir = join_path(project_name, "cmd")
  let cmd_main_dir = join_path(cmd_dir, "main")
  match apply_shared_template(project_name) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match
    write_file(
      join_path(project_name, "moon.mod.json"),
      moon_mod_template_with_x(module_name),
    ) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match
    write_file(
      join_path(cmd_main_dir, "moon.pkg.json"),
      ping_cmd_pkg_template(module_name),
    ) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match write_file(join_path(cmd_main_dir, "main.mbt"), ping_main_template()) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match
    write_file(
      join_path(project_name, "README.md"),
      ping_readme_template(project_name),
    ) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  Ok(())
}

///|
fn apply_select_template(project_name : String) -> Result[Unit, String] {
  let module_name = module_name_for(project_name)
  let cmd_dir = join_path(project_name, "cmd")
  let cmd_main_dir = join_path(cmd_dir, "main")
  match apply_shared_template(project_name) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match
    write_file(
      join_path(project_name, "moon.mod.json"),
      moon_mod_template_with_x(module_name),
    ) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match
    write_file(
      join_path(cmd_main_dir, "moon.pkg.json"),
      select_cmd_pkg_template(module_name),
    ) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match
    write_file(join_path(cmd_main_dir, "main.mbt"), select_main_template()) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match
    write_file(join_path(cmd_main_dir, "menu.mbt"), select_menu_template()) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match
    write_file(
      join_path(cmd_main_dir, "actions.mbt"),
      select_actions_template(),
    ) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match
    write_file(
      join_path(project_name, "README.md"),
      select_readme_template(project_name),
    ) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  Ok(())
}

///|
fn apply_template(
  project_name : String,
  template : TemplateKind,
) -> Result[Unit, String] {
  match template {
    TemplateKind::Empty => Ok(())
    TemplateKind::PingBot => apply_ping_template(project_name)
    TemplateKind::SelectStampBot => apply_select_template(project_name)
  }
}

///|
pub fn run_create(args : ArrayView[String]) -> Result[Unit, String] {
  if has_flag(args, "--help") || has_flag(args, "-h") {
    print_create_help()
    return Ok(())
  }
  let template_flag = flag_value(args, "--template")
  if has_flag(args, "--template") && template_flag is None {
    return Err("template name is required")
  }
  let positionals = collect_positionals(args)
  let project_name = match positionals.get(0) {
    Some(name) => name
    None => return Err("project name is required")
  }
  let template_arg = match positionals.get(1) {
    Some(name) => name
    None => ""
  }
  let template_name = match template_flag {
    Some(value) => {
      if template_arg != "" && template_arg != value {
        return Err(
          "template specified twice: " + value + " and " + template_arg,
        )
      }
      value
    }
    None => template_arg
  }
  let template = match template_from_name(template_name) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  match scaffold_project(project_name) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match apply_template(project_name, template) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match template {
    TemplateKind::Empty =>
      println("Initialized daab bot project in " + project_name)
    _ => {
      println("Created daab bot project in " + project_name)
      println("Applied template: " + template_display_name(template))
    }
  }
  println("Next steps:")
  println("  1. cd " + project_name)
  println("  2. daab login --token <token>")
  println("  3. daab run")
  Ok(())
}
