// Event handler and dispatcher for Direct SDK
// Reference: direct-go-sdk/direct-go/client.go

// Event dispatcher for managing event handlers
pub type EventDispatcher = {
  mut handlers               : Map[String, Array[JsonEventHandler]],
  mut message_handlers       : Array[MessageEventHandler],
  mut talk_handlers          : Array[TalkEventHandler],
  mut user_handlers          : Array[UserEventHandler],
  mut domain_handlers        : Array[DomainEventHandler],
  mut conference_handlers    : Array[ConferenceEventHandler],
}

// Domain event handler
pub type DomainEventHandler = (types/DomainInfo) -> Unit

// Conference event handler
pub type ConferenceEventHandler = (types/ConferenceInfo) -> Unit

// Create a new event dispatcher
pub fn new_dispatcher() -> EventDispatcher {
  {
    handlers:            Map::new(),
    message_handlers:    [],
    talk_handlers:       [],
    user_handlers:       [],
    domain_handlers:     [],
    conference_handlers: [],
  }
}

// Register a handler for a specific event by name
pub fn on(dispatcher : EventDispatcher, event_name : String, handler : JsonEventHandler) -> Unit {
  let handlers = match dispatcher.handlers.get(event_name) {
    | Some(h) => h
    | None => []
  }
  dispatcher.handlers.insert(event_name, handlers.push(handler))
}

// Register a handler for message events
pub fn on_message(dispatcher : EventDispatcher, handler : MessageEventHandler) -> Unit {
  dispatcher.message_handlers = dispatcher.message_handlers.push(handler)
}

// Register a handler for talk events
pub fn on_talk(dispatcher : EventDispatcher, handler : TalkEventHandler) -> Unit {
  dispatcher.talk_handlers = dispatcher.talk_handlers.push(handler)
}

// Register a handler for user events
pub fn on_user(dispatcher : EventDispatcher, handler : UserEventHandler) -> Unit {
  dispatcher.user_handlers = dispatcher.user_handlers.push(handler)
}

// Register a handler for domain events
pub fn on_domain(dispatcher : EventDispatcher, handler : DomainEventHandler) -> Unit {
  dispatcher.domain_handlers = dispatcher.domain_handlers.push(handler)
}

// Register a handler for conference events
pub fn on_conference(dispatcher : EventDispatcher, handler : ConferenceEventHandler) -> Unit {
  dispatcher.conference_handlers = dispatcher.conference_handlers.push(handler)
}

// Emit an event to all registered handlers for that event name
pub fn emit(dispatcher : EventDispatcher, event_name : String, data : JsonValue) -> Unit {
  match dispatcher.handlers.get(event_name) {
    | Some(handlers) => {
      for h in handlers {
        h(data)
      }
    }
    | None => ()
  }

  // Also dispatch to specific typed handlers based on event name
  match event_name {
    | "notify_create_message" => {
      match parse_received_message(data) {
        | Ok(msg) => {
          for h in dispatcher.message_handlers {
            h(msg)
          }
        }
        | Err(_) => ()
      }
    }
    | "notify_create_group_talk" | "notify_create_pair_talk" | "notify_update_talk" => {
      match parse_talk(data) {
        | Ok(talk) => {
          for h in dispatcher.talk_handlers {
            h(talk)
          }
        }
        | Err(_) => ()
      }
    }
    | "notify_add_friend" | "notify_update_user" | "notify_add_acquaintance" => {
      match parse_user_info(data) {
        | Ok(user) => {
          for h in dispatcher.user_handlers {
            h(user)
          }
        }
        | Err(_) => ()
      }
    }
    | "notify_join_domain" => {
      match parse_domain_info(data) {
        | Ok(domain) => {
          for h in dispatcher.domain_handlers {
            h(domain)
          }
        }
        | Err(_) => ()
      }
    }
    | "notify_create_conference" => {
      match parse_conference_info(data) {
        | Ok(conference) => {
          for h in dispatcher.conference_handlers {
            h(conference)
          }
        }
        | Err(_) => ()
      }
    }
    | _ => ()
  }
}

// Emit a message event directly (without JSON parsing)
pub fn emit_message(dispatcher : EventDispatcher, message : types/ReceivedMessage) -> Unit {
  for h in dispatcher.message_handlers {
    h(message)
  }
}

// Emit a talk event directly (without JSON parsing)
pub fn emit_talk(dispatcher : EventDispatcher, talk : types/Talk) -> Unit {
  for h in dispatcher.talk_handlers {
    h(talk)
  }
}

// Emit a user event directly (without JSON parsing)
pub fn emit_user(dispatcher : EventDispatcher, user : types/UserInfo) -> Unit {
  for h in dispatcher.user_handlers {
    h(user)
  }
}

// Remove all handlers for a specific event
pub fn remove_handler(dispatcher : EventDispatcher, event_name : String) -> Unit {
  dispatcher.handlers.remove(event_name)
}

// Remove all message handlers
pub fn remove_message_handlers(dispatcher : EventDispatcher) -> Unit {
  dispatcher.message_handlers = []
}

// Remove all handlers (reset)
pub fn remove_all_handlers(dispatcher : EventDispatcher) -> Unit {
  dispatcher.handlers = Map::new()
  dispatcher.message_handlers = []
  dispatcher.talk_handlers = []
  dispatcher.user_handlers = []
  dispatcher.domain_handlers = []
  dispatcher.conference_handlers = []
}

// Get the count of handlers for a specific event
pub fn handler_count(dispatcher : EventDispatcher, event_name : String) -> Int {
  match dispatcher.handlers.get(event_name) {
    | Some(handlers) => handlers.length
    | None => 0
  }
}

// Get the total count of all handlers
pub fn total_handler_count(dispatcher : EventDispatcher) -> Int {
  let mut total = 0
  for handlers in dispatcher.handlers.to_array() {
    total = total + handlers.1.length
  }
  total + dispatcher.message_handlers.length
    + dispatcher.talk_handlers.length
    + dispatcher.user_handlers.length
    + dispatcher.domain_handlers.length
    + dispatcher.conference_handlers.length
}

// === Helper functions for parsing event data ===

// Parse ReceivedMessage from JsonValue
fn parse_received_message(data : JsonValue) -> Result[types/ReceivedMessage, errors/DirectError] {
  match data {
    | JsonObject(obj) => {
      let id = match obj.get("message_id") {
        | Some(v) => match v {
          | JsonString(s) => s
          | JsonNumber(n) => n.to_string()
          | _ => return Err(errors/invalid_response("Invalid message_id"))
        }
        | None => match obj.get("id") {
          | Some(v) => match v {
            | JsonString(s) => s
            | JsonNumber(n) => n.to_string()
            | _ => return Err(errors/invalid_response("Invalid id"))
          }
          | None => return Err(errors/invalid_response("Missing message_id"))
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

      let room_id = talk_id

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
        | None => types/JsonNull
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
    | _ => Err(errors/invalid_response("Expected object"))
  }
}

// Parse Talk from JsonValue
fn parse_talk(data : JsonValue) -> Result[types/Talk, errors/DirectError] {
  match data {
    | JsonObject(obj) => {
      let id = match obj.get("id") {
        | Some(v) => match types/json_to_id(v) {
          | Some(id) => id
          | None => return Err(errors/invalid_response("Invalid id"))
        }
        | None => return Err(errors/invalid_response("Missing id"))
      }

      let domain_id = match obj.get("domain_id") {
        | Some(v) => match types/json_to_id(v) {
          | Some(id) => id
          | None => types/IDString("")
        }
        | None => types/IDString("")
      }

      let talk_type = match obj.get("type") {
        | Some(JsonNumber(n)) => match n.to_int() {
          | Some(i) => i
          | None => 0
        }
        | _ => 0
      }

      let name = match obj.get("name") {
        | Some(JsonString(s)) => s
        | _ => ""
      }

      let user_ids = match obj.get("user_ids") {
        | Some(JsonArray(arr)) => {
          let mut ids = []
          for item in arr {
            match types/json_to_id(item) {
              | Some(id) => ids = ids.push(id)
              | None => ()
            }
          }
          ids
        }
        | _ => []
      }

      let allow_display_past_messages = match obj.get("allow_display_past_messages") {
        | Some(JsonBool(b)) => b
        | _ => true
      }

      Ok({
        id: id,
        domain_id: domain_id,
        talk_type: talk_type,
        name: name,
        user_ids: user_ids,
        allow_display_past_messages: allow_display_past_messages,
      })
    }
    | _ => Err(errors/invalid_response("Expected object"))
  }
}

// Parse UserInfo from JsonValue
fn parse_user_info(data : JsonValue) -> Result[types/UserInfo, errors/DirectError] {
  match data {
    | JsonObject(obj) => {
      let id = match obj.get("id") {
        | Some(v) => match types/json_to_id(v) {
          | Some(id) => id
          | None => return Err(errors/invalid_response("Invalid id"))
        }
        | None => return Err(errors/invalid_response("Missing id"))
      }

      let name = match obj.get("name") {
        | Some(JsonString(s)) => s
        | _ => ""
      }

      let display_name = match obj.get("display_name") {
        | Some(JsonString(s)) => s
        | _ => ""
      }

      let phonetic_name = match obj.get("phonetic_name") {
        | Some(JsonString(s)) => s
        | _ => ""
      }

      let email = match obj.get("email") {
        | Some(JsonString(s)) => s
        | _ => ""
      }

      let icon_url = match obj.get("icon_url") {
        | Some(JsonString(s)) => s
        | _ => ""
      }

      let domain_id = match obj.get("domain_id") {
        | Some(v) => match types/json_to_id(v) {
          | Some(id) => id
          | None => types/IDString("")
        }
        | None => types/IDString("")
      }

      let departments = match obj.get("departments") {
        | Some(JsonArray(arr)) => {
          let mut deps = []
          for item in arr {
            match types/json_to_id(item) {
              | Some(id) => deps = deps.push(id)
              | None => ()
            }
          }
          deps
        }
        | _ => []
      }

      let profiles = match obj.get("profiles") {
        | Some(JsonObject(p)) => p
        | _ => Map::new()
      }

      let can_talk = match obj.get("can_talk") {
        | Some(JsonBool(b)) => b
        | _ => false
      }

      let allowed_to_create_talk = match obj.get("allowed_to_create_talk") {
        | Some(JsonBool(b)) => b
        | _ => false
      }

      Ok({
        id: id,
        name: name,
        display_name: display_name,
        phonetic_name: phonetic_name,
        email: email,
        icon_url: icon_url,
        domain_id: domain_id,
        departments: departments,
        profiles: profiles,
        can_talk: can_talk,
        allowed_to_create_talk: allowed_to_create_talk,
      })
    }
    | _ => Err(errors/invalid_response("Expected object"))
  }
}

// Parse DomainInfo from JsonValue
fn parse_domain_info(data : JsonValue) -> Result[types/DomainInfo, errors/DirectError] {
  match data {
    | JsonObject(obj) => {
      let id = match obj.get("id") {
        | Some(v) => match types/json_to_id(v) {
          | Some(id) => id
          | None => return Err(errors/invalid_response("Invalid id"))
        }
        | None => match obj.get("domain_id") {
          | Some(v) => match types/json_to_id(v) {
            | Some(id) => id
            | None => return Err(errors/invalid_response("Invalid id"))
          }
          | None => return Err(errors/invalid_response("Missing id"))
        }
      }

      let name = match obj.get("name") {
        | Some(JsonString(s)) => s
        | None => match obj.get("domain_name") {
          | Some(JsonString(s)) => s
          | None => ""
        }
      }

      let updated_at = match obj.get("updated_at") {
        | Some(JsonNumber(n)) => n.to_int64().unwrap_or(0L)
        | _ => 0L
      }

      let contract = match obj.get("contract") {
        | Some(v) => v
        | None => types/JsonNull
      }

      let setting = match obj.get("setting") {
        | Some(v) => v
        | None => types/JsonNull
      }

      let role = match obj.get("role") {
        | Some(v) => v
        | None => types/JsonNull
      }

      let closed = match obj.get("closed") {
        | Some(JsonBool(b)) => b
        | _ => false
      }

      Ok({
        id: id,
        name: name,
        updated_at: updated_at,
        contract: contract,
        setting: setting,
        role: role,
        closed: closed,
      })
    }
    | _ => Err(errors/invalid_response("Expected object"))
  }
}

// Parse ConferenceInfo from JsonValue
fn parse_conference_info(data : JsonValue) -> Result[types/ConferenceInfo, errors/DirectError] {
  match data {
    | JsonObject(obj) => {
      let id = match obj.get("id") {
        | Some(v) => match types/json_to_id(v) {
          | Some(id) => id
          | None => return Err(errors/invalid_response("Invalid id"))
        }
        | None => return Err(errors/invalid_response("Missing id"))
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

      let status = match obj.get("status") {
        | Some(JsonString(s)) => s
        | _ => ""
      }

      let created = match obj.get("created") {
        | Some(JsonNumber(n)) => n.to_int64().unwrap_or(0L)
        | _ => 0L
      }

      Ok({
        id: id,
        talk_id: talk_id,
        domain_id: domain_id,
        status: status,
        created: created,
      })
    }
    | _ => Err(errors/invalid_response("Expected object"))
  }
}
