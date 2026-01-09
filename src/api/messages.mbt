// Message API for Direct SDK
// Reference: direct-go-sdk/direct-go/message_operations.go

// Message order for retrieving messages
pub type MessageOrder =
  | Asc   // Ascending order (oldest first)
  | Desc  // Descending order (newest first)

pub fn message_order_to_int(order : MessageOrder) -> Int {
  match order {
    | Asc => 1
    | Desc => 2
  }
}

pub fn int_to_message_order(i : Int) -> MessageOrder {
  match i {
    | 1 => Asc
    | 2 => Desc
    | _ => Desc  // default
  }
}

// Options for retrieving messages
pub type GetMessagesOptions = {
  since_id : Option[types/ID],
  max_id   : Option[types/ID],
  order    : MessageOrder,
}

// Default options for getting messages
pub fn default_get_messages_options() -> GetMessagesOptions {
  {
    since_id: None,
    max_id: None,
    order: Desc,
  }
}

// Result from SearchMessages
pub type SearchMessagesResult = {
  total      : Int,
  marker     : Option[types/ID],
  next_marker : Option[types/ID],
  contents   : Array[MessageSearchContent],
}

// Content from message search
pub type MessageSearchContent = {
  message     : types/ReceivedMessage,
  talk_id     : types/ID,
  domain_id   : types/ID,
  match_score : Float,
}

// Scheduled message
pub type ScheduledMessage = {
  id           : types/ID,
  talk_id      : types/ID,
  domain_id    : types/ID,
  msg_type     : types/MessageType,
  content      : JsonValue,
  scheduled_at : Int64,  // Unix timestamp
  created_at   : Int64,  // Unix timestamp
}

// Message reaction
pub type MessageReaction = {
  id       : types/ID,
  name     : String,
  image_url : String,
}

// User who reacted to a message
pub type MessageReactionUser = {
  user_id     : types/ID,
  reaction_id : types/ID,
  created_at  : Int64,
}

// === Message Operations ===

// Get messages from a talk room
// cfg(target="native")
pub async fn get_messages(
  client : rpc/client/Client,
  domain_id : types/ID,
  talk_id : types/ID,
  opts : Option[GetMessagesOptions]
) -> Result[Array[types/ReceivedMessage], DirectError] {
  let options = match opts {
    | Some(o) => o
    | None => default_get_messages_options()
  }

  let params = [
    types/id_to_json(domain_id),
    types/id_to_json(talk_id),
    match options.since_id {
      | Some(id) => types/id_to_json(id)
      | None => JsonNull
    },
    match options.max_id {
      | Some(id) => types/id_to_json(id)
      | None => JsonNull
    },
    JsonNumber(message_order_to_int(options.order).to_float()),
  ]

  let result = await rpc/client/call(client, METHOD_GET_MESSAGES, params)?

  match result {
    | JsonArray(arr) => {
      let mut messages = []
      for item in arr {
        match item {
          | JsonObject(obj) => {
            match parse_message(obj) {
              | Ok(msg) => messages = messages.push(msg)
              | Err(_) => ()
            }
          }
          | _ => ()
        }
      }
      Ok(messages)
    }
    | _ => Err(invalid_response("Expected array"))
  }
}

// Delete a message
// cfg(target="native")
pub async fn delete_message(
  client : rpc/client/Client,
  domain_id : types/ID,
  message_id : types/ID
) -> Result[Unit, DirectError] {
  let params = [
    types/id_to_json(domain_id),
    types/id_to_json(message_id),
  ]

  match await rpc/client/call(client, METHOD_DELETE_MESSAGE, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// Search for messages in a talk room
// cfg(target="native")
pub async fn search_messages(
  client : rpc/client/Client,
  domain_id : types/ID,
  talk_id : Option[types/ID],
  keyword : String,
  marker : Option[types/ID],
  limit : Int
) -> Result[SearchMessagesResult, DirectError] {
  let params = [
    types/id_to_json(domain_id),
    match talk_id {
      | Some(id) => types/id_to_json(id)
      | None => JsonNull
    },
    JsonString(keyword),
    match marker {
      | Some(id) => types/id_to_json(id)
      | None => JsonNull
    },
    JsonNumber(limit.to_float()),
  ]

  let result = await rpc/client/call(client, METHOD_SEARCH_MESSAGES, params)?

  match result {
    | JsonObject(obj) => parse_search_result(obj)
    | _ => Err(invalid_response("Expected object"))
  }
}

// Get favorite messages
// cfg(target="native")
pub async fn get_favorite_messages(client : rpc/client/Client) -> Result[Array[types/ReceivedMessage], DirectError] {
  let result = await rpc/client/call(client, METHOD_GET_FAVORITE_MESSAGES, [])?

  match result {
    | JsonArray(arr) => {
      let mut messages = []
      for item in arr {
        match item {
          | JsonObject(obj) => {
            match parse_message(obj) {
              | Ok(msg) => messages = messages.push(msg)
              | Err(_) => ()
            }
          }
          | _ => ()
        }
      }
      Ok(messages)
    }
    | _ => Err(invalid_response("Expected array"))
  }
}

// Add a message to favorites
// cfg(target="native")
pub async fn add_favorite_message(
  client : rpc/client/Client,
  message_id : types/ID
) -> Result[Unit, DirectError] {
  let params = [types/id_to_json(message_id)]

  match await rpc/client/call(client, METHOD_ADD_FAVORITE_MESSAGE, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// Remove a message from favorites
// cfg(target="native")
pub async fn delete_favorite_message(
  client : rpc/client/Client,
  message_id : types/ID
) -> Result[Unit, DirectError] {
  let params = [types/id_to_json(message_id)]

  match await rpc/client/call(client, METHOD_DELETE_FAVORITE_MESSAGE, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// === Scheduled Messages ===

// Get all scheduled messages
// cfg(target="native")
pub async fn get_scheduled_messages(client : rpc/client/Client) -> Result[Array[ScheduledMessage], DirectError] {
  let result = await rpc/client/call(client, METHOD_GET_SCHEDULED_MESSAGES, [])?

  match result {
    | JsonArray(arr) => {
      let mut messages = []
      for item in arr {
        match item {
          | JsonObject(obj) => {
            match parse_scheduled_message(obj) {
              | Ok(msg) => messages = messages.push(msg)
              | Err(_) => ()
            }
          }
          | _ => ()
        }
      }
      Ok(messages)
    }
    | _ => Err(invalid_response("Expected array"))
  }
}

// Schedule a message to be sent at a specific time
// cfg(target="native")
pub async fn schedule_message(
  client : rpc/client/Client,
  talk_id : types/ID,
  msg_type : types/MessageType,
  content : JsonValue,
  scheduled_at : Int64  // Unix timestamp
) -> Result[ScheduledMessage, DirectError] {
  let params = [
    types/id_to_json(talk_id),
    JsonNumber(types/msg_type_to_wire(msg_type).to_float()),
    content,
    JsonNumber(scheduled_at.to_float()),
  ]

  let result = await rpc/client/call(client, METHOD_SCHEDULE_MESSAGE, params)?

  match result {
    | JsonObject(obj) => parse_scheduled_message(obj)
    | _ => Err(invalid_response("Expected object"))
  }
}

// Delete a scheduled message
// cfg(target="native")
pub async fn delete_scheduled_message(
  client : rpc/client/Client,
  message_id : types/ID
) -> Result[Unit, DirectError] {
  let params = [types/id_to_json(message_id)]

  match await rpc/client/call(client, METHOD_DELETE_SCHEDULED_MESSAGE, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// Reschedule a message to a new time
// cfg(target="native")
pub async fn reschedule_message(
  client : rpc/client/Client,
  message_id : types/ID,
  new_scheduled_at : Int64
) -> Result[Unit, DirectError] {
  let params = [
    types/id_to_json(message_id),
    JsonNumber(new_scheduled_at.to_float()),
  ]

  match await rpc/client/call(client, METHOD_RESCHEDULE_MESSAGE, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// === Message Reactions ===

// Get all available message reactions
// cfg(target="native")
pub async fn get_available_message_reactions(client : rpc/client/Client) -> Result[Array[MessageReaction], DirectError] {
  let result = await rpc/client/call(client, METHOD_GET_AVAILABLE_MESSAGE_REACTIONS, [])?

  match result {
    | JsonArray(arr) => {
      let mut reactions = []
      for item in arr {
        match item {
          | JsonObject(obj) => {
            match parse_message_reaction(obj) {
              | Ok(reaction) => reactions = reactions.push(reaction)
              | Err(_) => ()
            }
          }
          | _ => ()
        }
      }
      Ok(reactions)
    }
    | _ => Err(invalid_response("Expected array"))
  }
}

// Set a reaction on a message
// cfg(target="native")
pub async fn set_message_reaction(
  client : rpc/client/Client,
  message_id : types/ID,
  reaction_id : types/ID
) -> Result[Unit, DirectError] {
  let params = [
    types/id_to_json(message_id),
    types/id_to_json(reaction_id),
  ]

  match await rpc/client/call(client, METHOD_SET_MESSAGE_REACTION, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// Remove a reaction from a message
// cfg(target="native")
pub async fn reset_message_reaction(
  client : rpc/client/Client,
  message_id : types/ID,
  reaction_id : types/ID
) -> Result[Unit, DirectError] {
  let params = [
    types/id_to_json(message_id),
    types/id_to_json(reaction_id),
  ]

  match await rpc/client/call(client, METHOD_RESET_MESSAGE_REACTION, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// Get users who reacted to a message
// cfg(target="native")
pub async fn get_message_reaction_users(client : rpc/client/Client, message_id : types/ID) -> Result[Array[MessageReactionUser], DirectError] {
  let params = [types/id_to_json(message_id)]

  let result = await rpc/client/call(client, METHOD_GET_MESSAGE_REACTION_USERS, params)?

  match result {
    | JsonArray(arr) => {
      let mut users = []
      for item in arr {
        match item {
          | JsonObject(obj) => {
            match parse_reaction_user(obj) {
              | Ok(user) => users = users.push(user)
              | Err(_) => ()
            }
          }
          | _ => ()
        }
      }
      Ok(users)
    }
    | _ => Err(invalid_response("Expected array"))
  }
}

// === Helper functions for parsing message data ===

// Parse ReceivedMessage from JsonValue
fn parse_message(obj : Map[String, JsonValue]) -> Result[types/ReceivedMessage, DirectError] {
  let id = match obj.get("message_id") {
    | Some(v) => match v {
      | JsonString(s) => s
      | JsonNumber(n) => n.to_string()
      | _ => return Err(invalid_response("Invalid message_id"))
    }
    | None => match obj.get("id") {
      | Some(v) => match v {
        | JsonString(s) => s
        | JsonNumber(n) => n.to_string()
        | _ => return Err(invalid_response("Invalid id"))
      }
      | None => return Err(invalid_response("Missing message_id"))
    }
  }

  let talk_id = match obj.get("talk_id") {
    | Some(v) => match v {
      | JsonString(s) => s
      | JsonNumber(n) => n.to_string()
      | _ => ""
    }
    | None => ""
  }

  let room_id = talk_id  // Alias for talk_id

  let user_id = match obj.get("user_id") {
    | Some(JsonString(s)) => s
    | _ => ""
  }

  let domain_id = match obj.get("domain_id") {
    | Some(JsonString(s)) => s
    | _ => ""
  }

  let text = match obj.get("content") {
    | Some(JsonString(s)) => s
    | Some(JsonObject(content)) => {
      match content.get("text") {
        | Some(JsonString(s)) => s
        | _ => ""
      }
    }
    | _ => ""
  }

  let msg_type = match obj.get("type") {
    | Some(JsonNumber(n)) => match types/wire_to_msg_type(n.to_int().unwrap_or(0)) {
      | Some(t) => t
      | None => types/MsgTypeText
    }
    | _ => types/MsgTypeText
  }

  let content = match obj.get("content") {
    | Some(v) => v
    | None => JsonNull
  }

  let created = match obj.get("created") {
    | Some(JsonNumber(n)) => n.to_int64().unwrap_or(0L)
    | _ => 0L
  }

  Ok({
    id: id,
    talk_id: talk_id,
    room_id: room_id,
    user_id: user_id,
    domain_id: domain_id,
    text: text,
    msg_type: msg_type,
    content: content,
    created: created,
    raw: None,
  })
}

// Parse SearchMessagesResult
fn parse_search_result(obj : Map[String, JsonValue]) -> Result[SearchMessagesResult, DirectError] {
  let total = match obj.get("total") {
    | Some(JsonNumber(n)) => n.to_int().unwrap_or(0)
    | _ => 0
  }

  let marker = match obj.get("marker") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => Some(id)
      | None => None
    }
    | None => None
  }

  let next_marker = match obj.get("next_marker") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => Some(id)
      | None => None
    }
    | None => None
  }

  let contents = match obj.get("contents") {
    | Some(JsonArray(arr)) => {
      let mut result = []
      for item in arr {
        match item {
          | JsonObject(obj) => {
            match parse_message_search_content(obj) {
              | Ok(content) => result = result.push(content)
              | Err(_) => ()
            }
          }
          | _ => ()
        }
      }
      result
    }
    | _ => []
  }

  Ok({
    total: total,
    marker: marker,
    next_marker: next_marker,
    contents: contents,
  })
}

// Parse MessageSearchContent
fn parse_message_search_content(obj : Map[String, JsonValue]) -> Result[MessageSearchContent, DirectError] {
  let message = match obj.get("message") {
    | Some(JsonObject(msg_obj)) => {
      match parse_message(msg_obj) {
        | Ok(msg) => msg
        | Err(_) => {
          // Create minimal message
          {
            id: "",
            talk_id: "",
            room_id: "",
            user_id: "",
            domain_id: "",
            text: "",
            msg_type: types/MsgTypeText,
            content: JsonNull,
            created: 0L,
            raw: None,
          }
        }
      }
    }
    | _ => return Err(invalid_response("Missing message"))
  }

  let talk_id = match obj.get("talk_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => types/IDString("")
    }
    | None => types/IDString("")
  }

  let domain_id = match obj.get("domain_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => types/IDString("")
    }
    | None => types/IDString("")
  }

  let match_score = match obj.get("match_score") {
    | Some(JsonNumber(n)) => n
    | _ => 0.0
  }

  Ok({
    message: message,
    talk_id: talk_id,
    domain_id: domain_id,
    match_score: match_score,
  })
}

// Parse ScheduledMessage
fn parse_scheduled_message(obj : Map[String, JsonValue]) -> Result[ScheduledMessage, DirectError] {
  let id = match obj.get("id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => return Err(invalid_response("Invalid id"))
    }
    | None => return Err(invalid_response("Missing id"))
  }

  let talk_id = match obj.get("talk_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => types/IDString("")
    }
    | None => types/IDString("")
  }

  let domain_id = match obj.get("domain_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => types/IDString("")
    }
    | None => types/IDString("")
  }

  let msg_type = match obj.get("type") {
    | Some(JsonNumber(n)) => match types/wire_to_msg_type(n.to_int().unwrap_or(0)) {
      | Some(t) => t
      | None => types/MsgTypeText
    }
    | _ => types/MsgTypeText
  }

  let content = match obj.get("content") {
    | Some(v) => v
    | None => JsonNull
  }

  let scheduled_at = match obj.get("scheduled_at") {
    | Some(JsonNumber(n)) => n.to_int64().unwrap_or(0L)
    | _ => 0L
  }

  let created_at = match obj.get("created_at") {
    | Some(JsonNumber(n)) => n.to_int64().unwrap_or(0L)
    | _ => 0L
  }

  Ok({
    id: id,
    talk_id: talk_id,
    domain_id: domain_id,
    msg_type: msg_type,
    content: content,
    scheduled_at: scheduled_at,
    created_at: created_at,
  })
}

// Parse MessageReaction
fn parse_message_reaction(obj : Map[String, JsonValue]) -> Result[MessageReaction, DirectError] {
  let id = match obj.get("id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => return Err(invalid_response("Invalid id"))
    }
    | None => return Err(invalid_response("Missing id"))
  }

  let name = json_get_string(obj, "name").unwrap_or("")
  let image_url = json_get_string(obj, "image_url").unwrap_or("")

  Ok({
    id: id,
    name: name,
    image_url: image_url,
  })
}

// Parse MessageReactionUser
fn parse_reaction_user(obj : Map[String, JsonValue]) -> Result[MessageReactionUser, DirectError] {
  let user_id = match obj.get("user_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => return Err(invalid_response("Invalid user_id"))
    }
    | None => return Err(invalid_response("Missing user_id"))
  }

  let reaction_id = match obj.get("reaction_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => types/IDString("")
    }
    | None => types/IDString("")
  }

  let created_at = match obj.get("created_at") {
    | Some(JsonNumber(n)) => n.to_int64().unwrap_or(0L)
    | _ => 0L
  }

  Ok({
    user_id: user_id,
    reaction_id: reaction_id,
    created_at: created_at,
  })
}

// Helper: Get string value from JsonObject
fn json_get_string(obj : Map[String, JsonValue], key : String) -> Option[String] {
  match obj.get(key) {
    | Some(JsonString(s)) => Some(s)
    | _ => None
  }
}
