// Message API for Direct SDK
// Reference: direct-go-sdk/direct-go/message_operations.go

// Message order for retrieving messages
///|
pub enum MessageOrder {
  Asc // Ascending order (oldest first)
  Desc // Descending order (newest first)
}

///|
pub fn message_order_to_int(order : MessageOrder) -> Int {
  match order {
    Asc => 1
    Desc => 2
  }
}

///|
pub fn int_to_message_order(i : Int) -> MessageOrder {
  match i {
    1 => Asc
    2 => Desc
    _ => Desc // default
  }
}

// Options for retrieving messages

///|
pub struct GetMessagesOptions {
  since_id : @types.ID?
  max_id : @types.ID?
  order : MessageOrder
}

// Default options for getting messages

///|
pub fn default_get_messages_options() -> GetMessagesOptions {
  { since_id: None, max_id: None, order: Desc }
}

// Result from SearchMessages

///|
pub struct SearchMessagesResult {
  total : Int
  marker : @types.ID?
  next_marker : @types.ID?
  contents : Array[MessageSearchContent]
}

// Content from message search

///|
pub struct MessageSearchContent {
  message : @types.ReceivedMessage
  talk_id : @types.ID
  domain_id : @types.ID
  match_score : Float
}

// Scheduled message

///|
pub struct ScheduledMessage {
  id : @types.ID
  talk_id : @types.ID
  domain_id : @types.ID
  msg_type : @types.MessageType
  content : @types.JsonValue
  scheduled_at : Int64 // Unix timestamp
  created_at : Int64 // Unix timestamp
}

// Message reaction

///|
pub struct MessageReaction {
  id : @types.ID
  name : String
  image_url : String
}

// User who reacted to a message

///|
pub struct MessageReactionUser {
  user_id : @types.ID
  reaction_id : @types.ID
  created_at : Int64
}

// === Message Operations ===

// Get messages from a talk room
// cfg(target="native")

///|
pub async fn get_messages(
  client : @rpc_client.Client,
  domain_id : @types.ID,
  talk_id : @types.ID,
  opts : GetMessagesOptions?,
) -> Result[Array[@types.ReceivedMessage], @errors.DirectError] {
  let options = match opts {
    Some(o) => o
    None => default_get_messages_options()
  }
  let params = [
    @types.id_to_json(domain_id),
    @types.id_to_json(talk_id),
    match options.since_id {
      Some(id) => @types.id_to_json(id)
      None => @types.JsonNull
    },
    match options.max_id {
      Some(id) => @types.id_to_json(id)
      None => @types.JsonNull
    },
    @types.JsonNumber(Float::from_int(message_order_to_int(options.order))),
  ]
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_MESSAGES, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let messages = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_message(obj) {
              Ok(msg) => messages.push(msg)
              Err(_) => ()
            }
          _ => ()
        }
      }
      Ok(messages)
    }
    _ => Err(@errors.invalid_response("Expected array"))
  }
}

// Delete a message
// cfg(target="native")

///|
pub async fn delete_message(
  client : @rpc_client.Client,
  domain_id : @types.ID,
  message_id : @types.ID,
) -> Result[Unit, @errors.DirectError] {
  let params = [@types.id_to_json(domain_id), @types.id_to_json(message_id)]
  match @rpc_client.call(client, @constants.METHOD_DELETE_MESSAGE, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// Search for messages in a talk room
// cfg(target="native")

///|
pub async fn search_messages(
  client : @rpc_client.Client,
  domain_id : @types.ID,
  talk_id : @types.ID?,
  keyword : String,
  marker : @types.ID?,
  limit : Int,
) -> Result[SearchMessagesResult, @errors.DirectError] {
  let params = [
    @types.id_to_json(domain_id),
    match talk_id {
      Some(id) => @types.id_to_json(id)
      None => @types.JsonNull
    },
    @types.JsonString(keyword),
    match marker {
      Some(id) => @types.id_to_json(id)
      None => @types.JsonNull
    },
    @types.JsonNumber(Float::from_int(limit)),
  ]
  let result = match
    @rpc_client.call(client, @constants.METHOD_SEARCH_MESSAGES, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonObject(obj) => parse_search_result(obj)
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// Get favorite messages
// cfg(target="native")

///|
pub async fn get_favorite_messages(
  client : @rpc_client.Client,
) -> Result[Array[@types.ReceivedMessage], @errors.DirectError] {
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_FAVORITE_MESSAGES, []) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let messages = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_message(obj) {
              Ok(msg) => messages.push(msg)
              Err(_) => ()
            }
          _ => ()
        }
      }
      Ok(messages)
    }
    _ => Err(@errors.invalid_response("Expected array"))
  }
}

// Add a message to favorites
// cfg(target="native")

///|
pub async fn add_favorite_message(
  client : @rpc_client.Client,
  message_id : @types.ID,
) -> Result[Unit, @errors.DirectError] {
  let params = [@types.id_to_json(message_id)]
  match
    @rpc_client.call(client, @constants.METHOD_ADD_FAVORITE_MESSAGE, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// Remove a message from favorites
// cfg(target="native")

///|
pub async fn delete_favorite_message(
  client : @rpc_client.Client,
  message_id : @types.ID,
) -> Result[Unit, @errors.DirectError] {
  let params = [@types.id_to_json(message_id)]
  match
    @rpc_client.call(client, @constants.METHOD_DELETE_FAVORITE_MESSAGE, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// === Scheduled Messages ===

// Get all scheduled messages
// cfg(target="native")

///|
pub async fn get_scheduled_messages(
  client : @rpc_client.Client,
) -> Result[Array[ScheduledMessage], @errors.DirectError] {
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_SCHEDULED_MESSAGES, []) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let messages = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_scheduled_message(obj) {
              Ok(msg) => messages.push(msg)
              Err(_) => ()
            }
          _ => ()
        }
      }
      Ok(messages)
    }
    _ => Err(@errors.invalid_response("Expected array"))
  }
}

// Schedule a message to be sent at a specific time
// cfg(target="native")

///|
pub async fn schedule_message(
  client : @rpc_client.Client,
  talk_id : @types.ID,
  msg_type : @types.MessageType,
  content : @types.JsonValue,
  scheduled_at : Int64, // Unix timestamp
) -> Result[ScheduledMessage, @errors.DirectError] {
  let params = [
    @types.id_to_json(talk_id),
    @types.JsonNumber(Float::from_int(@types.msg_type_to_wire(msg_type))),
    content,
    @types.JsonNumber(Float::from_int64(scheduled_at)),
  ]
  let result = match
    @rpc_client.call(client, @constants.METHOD_SCHEDULE_MESSAGE, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonObject(obj) => parse_scheduled_message(obj)
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// Delete a scheduled message
// cfg(target="native")

///|
pub async fn delete_scheduled_message(
  client : @rpc_client.Client,
  message_id : @types.ID,
) -> Result[Unit, @errors.DirectError] {
  let params = [@types.id_to_json(message_id)]
  match
    @rpc_client.call(client, @constants.METHOD_DELETE_SCHEDULED_MESSAGE, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// Reschedule a message to a new time
// cfg(target="native")

///|
pub async fn reschedule_message(
  client : @rpc_client.Client,
  message_id : @types.ID,
  new_scheduled_at : Int64,
) -> Result[Unit, @errors.DirectError] {
  let params = [
    @types.id_to_json(message_id),
    @types.JsonNumber(Float::from_int64(new_scheduled_at)),
  ]
  match @rpc_client.call(client, @constants.METHOD_RESCHEDULE_MESSAGE, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// === Message Reactions ===

// Get all available message reactions
// cfg(target="native")

///|
pub async fn get_available_message_reactions(
  client : @rpc_client.Client,
) -> Result[Array[MessageReaction], @errors.DirectError] {
  let result = match
    @rpc_client.call(
      client,
      @constants.METHOD_GET_AVAILABLE_MESSAGE_REACTIONS,
      [],
    ) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let reactions = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_message_reaction(obj) {
              Ok(reaction) => reactions.push(reaction)
              Err(_) => ()
            }
          _ => ()
        }
      }
      Ok(reactions)
    }
    _ => Err(@errors.invalid_response("Expected array"))
  }
}

// Set a reaction on a message
// cfg(target="native")

///|
pub async fn set_message_reaction(
  client : @rpc_client.Client,
  message_id : @types.ID,
  reaction_id : @types.ID,
) -> Result[Unit, @errors.DirectError] {
  let params = [@types.id_to_json(message_id), @types.id_to_json(reaction_id)]
  match
    @rpc_client.call(client, @constants.METHOD_SET_MESSAGE_REACTION, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// Remove a reaction from a message
// cfg(target="native")

///|
pub async fn reset_message_reaction(
  client : @rpc_client.Client,
  message_id : @types.ID,
  reaction_id : @types.ID,
) -> Result[Unit, @errors.DirectError] {
  let params = [@types.id_to_json(message_id), @types.id_to_json(reaction_id)]
  match
    @rpc_client.call(client, @constants.METHOD_RESET_MESSAGE_REACTION, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// Get users who reacted to a message
// cfg(target="native")

///|
pub async fn get_message_reaction_users(
  client : @rpc_client.Client,
  message_id : @types.ID,
) -> Result[Array[MessageReactionUser], @errors.DirectError] {
  let params = [@types.id_to_json(message_id)]
  let result = match
    @rpc_client.call(
      client,
      @constants.METHOD_GET_MESSAGE_REACTION_USERS,
      params,
    ) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let users = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_reaction_user(obj) {
              Ok(user) => users.push(user)
              Err(_) => ()
            }
          _ => ()
        }
      }
      Ok(users)
    }
    _ => Err(@errors.invalid_response("Expected array"))
  }
}

// === Helper functions for parsing message data ===

// Parse ReceivedMessage from @types.JsonValue

///|
fn parse_message(
  obj : Map[String, @types.JsonValue],
) -> Result[@types.ReceivedMessage, @errors.DirectError] {
  let id = match obj.get("message_id") {
    Some(v) =>
      match v {
        @types.JsonString(s) => s
        @types.JsonNumber(n) => n.to_string()
        _ => return Err(@errors.invalid_response("Invalid message_id"))
      }
    None =>
      match obj.get("id") {
        Some(v) =>
          match v {
            @types.JsonString(s) => s
            @types.JsonNumber(n) => n.to_string()
            _ => return Err(@errors.invalid_response("Invalid id"))
          }
        None => return Err(@errors.invalid_response("Missing message_id"))
      }
  }
  let talk_id = match obj.get("talk_id") {
    Some(v) =>
      match v {
        @types.JsonString(s) => s
        @types.JsonNumber(n) => n.to_string()
        _ => ""
      }
    None => ""
  }
  let room_id = talk_id // Alias for talk_id
  let user_id = match obj.get("user_id") {
    Some(@types.JsonString(s)) => s
    _ => ""
  }
  let domain_id = match obj.get("domain_id") {
    Some(@types.JsonString(s)) => s
    _ => ""
  }
  let text = match obj.get("content") {
    Some(@types.JsonString(s)) => s
    Some(@types.JsonObject(content)) =>
      match content.get("text") {
        Some(@types.JsonString(s)) => s
        _ => ""
      }
    _ => ""
  }
  let msg_type = match obj.get("type") {
    Some(@types.JsonNumber(n)) =>
      match @types.wire_to_msg_type(n.to_int()) {
        Some(t) => t
        None => @types.MsgTypeText
      }
    _ => @types.MsgTypeText
  }
  let content = match obj.get("content") {
    Some(v) => v
    None => @types.JsonNull
  }
  let created = match obj.get("created") {
    Some(@types.JsonNumber(n)) => n.to_int().to_int64()
    _ => 0L
  }
  Ok({
    id,
    talk_id,
    room_id,
    user_id,
    domain_id,
    text,
    msg_type,
    content,
    created,
    raw: None,
  })
}

// Parse SearchMessagesResult

///|
fn parse_search_result(
  obj : Map[String, @types.JsonValue],
) -> Result[SearchMessagesResult, @errors.DirectError] {
  let total = match obj.get("total") {
    Some(@types.JsonNumber(n)) => n.to_int()
    _ => 0
  }
  let marker = match obj.get("marker") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => Some(id)
        None => None
      }
    None => None
  }
  let next_marker = match obj.get("next_marker") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => Some(id)
        None => None
      }
    None => None
  }
  let contents = match obj.get("contents") {
    Some(@types.JsonArray(arr)) => {
      let result = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_message_search_content(obj) {
              Ok(content) => result.push(content)
              Err(_) => ()
            }
          _ => ()
        }
      }
      result
    }
    _ => []
  }
  Ok({ total, marker, next_marker, contents })
}

// Parse MessageSearchContent

///|
fn parse_message_search_content(
  obj : Map[String, @types.JsonValue],
) -> Result[MessageSearchContent, @errors.DirectError] {
  let message = match obj.get("message") {
    Some(@types.JsonObject(msg_obj)) =>
      match parse_message(msg_obj) {
        Ok(msg) => msg
        Err(_) =>
          // Create minimal message
          {
            id: "",
            talk_id: "",
            room_id: "",
            user_id: "",
            domain_id: "",
            text: "",
            msg_type: @types.MsgTypeText,
            content: @types.JsonNull,
            created: 0L,
            raw: None,
          }
      }
    _ => return Err(@errors.invalid_response("Missing message"))
  }
  let talk_id = match obj.get("talk_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => @types.IDString("")
      }
    None => @types.IDString("")
  }
  let domain_id = match obj.get("domain_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => @types.IDString("")
      }
    None => @types.IDString("")
  }
  let match_score = match obj.get("match_score") {
    Some(@types.JsonNumber(n)) => n
    _ => 0.0
  }
  Ok({ message, talk_id, domain_id, match_score })
}

// Parse ScheduledMessage

///|
fn parse_scheduled_message(
  obj : Map[String, @types.JsonValue],
) -> Result[ScheduledMessage, @errors.DirectError] {
  let id = match obj.get("id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => return Err(@errors.invalid_response("Invalid id"))
      }
    None => return Err(@errors.invalid_response("Missing id"))
  }
  let talk_id = match obj.get("talk_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => @types.IDString("")
      }
    None => @types.IDString("")
  }
  let domain_id = match obj.get("domain_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => @types.IDString("")
      }
    None => @types.IDString("")
  }
  let msg_type = match obj.get("type") {
    Some(@types.JsonNumber(n)) =>
      match @types.wire_to_msg_type(n.to_int()) {
        Some(t) => t
        None => @types.MsgTypeText
      }
    _ => @types.MsgTypeText
  }
  let content = match obj.get("content") {
    Some(v) => v
    None => @types.JsonNull
  }
  let scheduled_at = match obj.get("scheduled_at") {
    Some(@types.JsonNumber(n)) => n.to_int().to_int64()
    _ => 0L
  }
  let created_at = match obj.get("created_at") {
    Some(@types.JsonNumber(n)) => n.to_int().to_int64()
    _ => 0L
  }
  Ok({ id, talk_id, domain_id, msg_type, content, scheduled_at, created_at })
}

// Parse MessageReaction

///|
fn parse_message_reaction(
  obj : Map[String, @types.JsonValue],
) -> Result[MessageReaction, @errors.DirectError] {
  let id = match obj.get("id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => return Err(@errors.invalid_response("Invalid id"))
      }
    None => return Err(@errors.invalid_response("Missing id"))
  }
  let name = json_get_string(obj, "name").unwrap_or("")
  let image_url = json_get_string(obj, "image_url").unwrap_or("")
  Ok({ id, name, image_url })
}

// Parse MessageReactionUser

///|
fn parse_reaction_user(
  obj : Map[String, @types.JsonValue],
) -> Result[MessageReactionUser, @errors.DirectError] {
  let user_id = match obj.get("user_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => return Err(@errors.invalid_response("Invalid user_id"))
      }
    None => return Err(@errors.invalid_response("Missing user_id"))
  }
  let reaction_id = match obj.get("reaction_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => @types.IDString("")
      }
    None => @types.IDString("")
  }
  let created_at = match obj.get("created_at") {
    Some(@types.JsonNumber(n)) => n.to_int().to_int64()
    _ => 0L
  }
  Ok({ user_id, reaction_id, created_at })
}

// Helper: Get string value from @types.JsonObject

///|
fn json_get_string(
  obj : Map[String, @types.JsonValue],
  key : String,
) -> String? {
  match obj.get(key) {
    Some(@types.JsonString(s)) => Some(s)
    _ => None
  }
}
