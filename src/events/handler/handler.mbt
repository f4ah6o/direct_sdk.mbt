// Event handler and dispatcher for Direct SDK
// Reference: direct-go-sdk/direct-go/client.go

// Event dispatcher for managing event handlers

///|
pub struct EventDispatcher {
  mut handlers : Map[String, Array[@events_types.JsonEventHandler]]
  mut message_handlers : Array[@events_types.MessageEventHandler]
  mut talk_handlers : Array[@events_types.TalkEventHandler]
  mut user_handlers : Array[@events_types.UserEventHandler]
  mut domain_handlers : Array[DomainEventHandler]
  mut conference_handlers : Array[ConferenceEventHandler]
}

// Domain event handler

///|
pub type DomainEventHandler = (@types.DomainInfo) -> Unit

// Conference event handler

///|
pub type ConferenceEventHandler = (@types.ConferenceInfo) -> Unit

// Create a new event dispatcher

///|
pub fn new_dispatcher() -> EventDispatcher {
  {
    handlers: Map::new(),
    message_handlers: [],
    talk_handlers: [],
    user_handlers: [],
    domain_handlers: [],
    conference_handlers: [],
  }
}

///|
pub fn EventDispatcher::on(
  self : EventDispatcher,
  event_name : String,
  handler : @events_types.JsonEventHandler,
) -> Unit {
  let handlers = match self.handlers.get(event_name) {
    Some(h) => h
    None => []
  }
  handlers.push(handler)
  self.handlers[event_name] = handlers
}

///|
pub fn EventDispatcher::on_message(
  self : EventDispatcher,
  handler : @events_types.MessageEventHandler,
) -> Unit {
  self.message_handlers.push(handler)
}

///|
pub fn EventDispatcher::on_talk(
  self : EventDispatcher,
  handler : @events_types.TalkEventHandler,
) -> Unit {
  self.talk_handlers.push(handler)
}

///|
pub fn EventDispatcher::on_user(
  self : EventDispatcher,
  handler : @events_types.UserEventHandler,
) -> Unit {
  self.user_handlers.push(handler)
}

///|
pub fn EventDispatcher::on_domain(
  self : EventDispatcher,
  handler : DomainEventHandler,
) -> Unit {
  self.domain_handlers.push(handler)
}

///|
pub fn EventDispatcher::on_conference(
  self : EventDispatcher,
  handler : ConferenceEventHandler,
) -> Unit {
  self.conference_handlers.push(handler)
}

///|
pub fn EventDispatcher::emit(
  self : EventDispatcher,
  event_name : String,
  data : @types.JsonValue,
) -> Unit {
  match self.handlers.get(event_name) {
    Some(handlers) =>
      for h in handlers {
        h(data)
      }
    None => ()
  }
  match event_name {
    "notify_create_message" =>
      match parse_received_message(data) {
        Ok(msg) =>
          for h in self.message_handlers {
            h(msg)
          }
        Err(_) => ()
      }
    "notify_create_group_talk"
    | "notify_create_pair_talk"
    | "notify_update_talk" =>
      match parse_talk(data) {
        Ok(talk) =>
          for h in self.talk_handlers {
            h(talk)
          }
        Err(_) => ()
      }
    "notify_add_friend" | "notify_update_user" | "notify_add_acquaintance" =>
      match parse_user_info(data) {
        Ok(user) =>
          for h in self.user_handlers {
            h(user)
          }
        Err(_) => ()
      }
    "notify_join_domain" =>
      match parse_domain_info(data) {
        Ok(domain) =>
          for h in self.domain_handlers {
            h(domain)
          }
        Err(_) => ()
      }
    "notify_create_conference" =>
      match parse_conference_info(data) {
        Ok(conference) =>
          for h in self.conference_handlers {
            h(conference)
          }
        Err(_) => ()
      }
    _ => ()
  }
}

///|
pub fn EventDispatcher::emit_message(
  self : EventDispatcher,
  message : @types.ReceivedMessage,
) -> Unit {
  for h in self.message_handlers {
    h(message)
  }
}

///|
pub fn EventDispatcher::emit_talk(
  self : EventDispatcher,
  talk : @types.Talk,
) -> Unit {
  for h in self.talk_handlers {
    h(talk)
  }
}

///|
pub fn EventDispatcher::emit_user(
  self : EventDispatcher,
  user : @types.UserInfo,
) -> Unit {
  for h in self.user_handlers {
    h(user)
  }
}

///|
pub fn EventDispatcher::remove_handler(
  self : EventDispatcher,
  event_name : String,
) -> Unit {
  self.handlers.remove(event_name)
}

///|
pub fn EventDispatcher::remove_message_handlers(self : EventDispatcher) -> Unit {
  self.message_handlers = []
}

///|
pub fn EventDispatcher::remove_all_handlers(self : EventDispatcher) -> Unit {
  self.handlers = Map::new()
  self.message_handlers = []
  self.talk_handlers = []
  self.user_handlers = []
  self.domain_handlers = []
  self.conference_handlers = []
}

///|
pub fn EventDispatcher::handler_count(
  self : EventDispatcher,
  event_name : String,
) -> Int {
  match self.handlers.get(event_name) {
    Some(handlers) => handlers.length()
    None => 0
  }
}

///|
pub fn EventDispatcher::total_handler_count(self : EventDispatcher) -> Int {
  let mut total = 0
  for handlers in self.handlers.to_array() {
    total = total + handlers.1.length()
  }
  total = total + self.message_handlers.length()
  total = total + self.talk_handlers.length()
  total = total + self.user_handlers.length()
  total = total + self.domain_handlers.length()
  total = total + self.conference_handlers.length()
  total
}

// Register a handler for a specific event by name

///|
pub fn on(
  dispatcher : EventDispatcher,
  event_name : String,
  handler : @events_types.JsonEventHandler,
) -> Unit {
  dispatcher.on(event_name, handler)
}

// Register a handler for message events

///|
pub fn on_message(
  dispatcher : EventDispatcher,
  handler : @events_types.MessageEventHandler,
) -> Unit {
  dispatcher.on_message(handler)
}

// Register a handler for talk events

///|
pub fn on_talk(
  dispatcher : EventDispatcher,
  handler : @events_types.TalkEventHandler,
) -> Unit {
  dispatcher.on_talk(handler)
}

// Register a handler for user events

///|
pub fn on_user(
  dispatcher : EventDispatcher,
  handler : @events_types.UserEventHandler,
) -> Unit {
  dispatcher.on_user(handler)
}

// Register a handler for domain events

///|
pub fn on_domain(
  dispatcher : EventDispatcher,
  handler : DomainEventHandler,
) -> Unit {
  dispatcher.on_domain(handler)
}

// Register a handler for conference events

///|
pub fn on_conference(
  dispatcher : EventDispatcher,
  handler : ConferenceEventHandler,
) -> Unit {
  dispatcher.on_conference(handler)
}

// Emit an event to all registered handlers for that event name

///|
pub fn emit(
  dispatcher : EventDispatcher,
  event_name : String,
  data : @types.JsonValue,
) -> Unit {
  dispatcher.emit(event_name, data)
}

// Emit a message event directly (without JSON parsing)

///|
pub fn emit_message(
  dispatcher : EventDispatcher,
  message : @types.ReceivedMessage,
) -> Unit {
  dispatcher.emit_message(message)
}

// Emit a talk event directly (without JSON parsing)

///|
pub fn emit_talk(dispatcher : EventDispatcher, talk : @types.Talk) -> Unit {
  dispatcher.emit_talk(talk)
}

// Emit a user event directly (without JSON parsing)

///|
pub fn emit_user(dispatcher : EventDispatcher, user : @types.UserInfo) -> Unit {
  dispatcher.emit_user(user)
}

// Remove all handlers for a specific event

///|
pub fn remove_handler(
  dispatcher : EventDispatcher,
  event_name : String,
) -> Unit {
  dispatcher.remove_handler(event_name)
}

// Remove all message handlers

///|
pub fn remove_message_handlers(dispatcher : EventDispatcher) -> Unit {
  dispatcher.remove_message_handlers()
}

// Remove all handlers (reset)

///|
pub fn remove_all_handlers(dispatcher : EventDispatcher) -> Unit {
  dispatcher.remove_all_handlers()
}

// Get the count of handlers for a specific event

///|
pub fn handler_count(dispatcher : EventDispatcher, event_name : String) -> Int {
  dispatcher.handler_count(event_name)
}

// Get the total count of all handlers

///|
pub fn total_handler_count(dispatcher : EventDispatcher) -> Int {
  dispatcher.total_handler_count()
}

// === Helper functions for parsing event data ===

// Parse ReceivedMessage from @types.JsonValue

///|
fn parse_received_message(
  data : @types.JsonValue,
) -> Result[@types.ReceivedMessage, @errors.DirectError] {
  match data {
    @types.JsonObject(obj) => {
      let id = match obj.get("message_id") {
        Some(v) =>
          match v {
            @types.JsonString(s) => s
            @types.JsonInt(i) => i.to_string()
            @types.JsonNumber(n) => n.to_string()
            _ => return Err(@errors.invalid_response("Invalid message_id"))
          }
        None =>
          match obj.get("id") {
            Some(v) =>
              match v {
                @types.JsonString(s) => s
                @types.JsonInt(i) => i.to_string()
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
            @types.JsonInt(i) => i.to_string()
            @types.JsonNumber(n) => n.to_string()
            _ => ""
          }
        None => ""
      }
      let room_id = talk_id
      let user_id = match obj.get("user_id") {
        Some(@types.JsonString(s)) => s
        Some(@types.JsonInt(i)) => i.to_string()
        Some(@types.JsonNumber(n)) => n.to_string()
        _ => ""
      }
      let domain_id = match obj.get("domain_id") {
        Some(@types.JsonString(s)) => s
        Some(@types.JsonInt(i)) => i.to_string()
        Some(@types.JsonNumber(n)) => n.to_string()
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
        Some(@types.JsonInt(i)) =>
          match @types.wire_to_msg_type(i.to_int()) {
            Some(t) => t
            None => @types.MsgTypeText
          }
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
        Some(@types.JsonInt(i)) => i
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
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// Parse Talk from @types.JsonValue

///|
fn parse_talk(
  data : @types.JsonValue,
) -> Result[@types.Talk, @errors.DirectError] {
  match data {
    @types.JsonObject(obj) => {
      let id = match obj.get("id") {
        Some(v) =>
          match @types.json_to_id(v) {
            Some(id) => id
            None => return Err(@errors.invalid_response("Invalid id"))
          }
        None => return Err(@errors.invalid_response("Missing id"))
      }
      let domain_id = match obj.get("domain_id") {
        Some(v) =>
          match @types.json_to_id(v) {
            Some(id) => id
            None => @types.IDString("")
          }
        None => @types.IDString("")
      }
      let talk_type = match obj.get("type") {
        Some(@types.JsonInt(i)) => i.to_int()
        Some(@types.JsonNumber(n)) => n.to_int()
        _ => 0
      }
      let name = match obj.get("name") {
        Some(@types.JsonString(s)) => s
        _ => ""
      }
      let user_ids = match obj.get("user_ids") {
        Some(@types.JsonArray(arr)) => {
          let ids = []
          for item in arr {
            match @types.json_to_id(item) {
              Some(id) => ids.push(id)
              None => ()
            }
          }
          ids
        }
        _ => []
      }
      let allow_display_past_messages = match
        obj.get("allow_display_past_messages") {
        Some(@types.JsonBool(b)) => b
        _ => true
      }
      Ok({
        id,
        domain_id,
        talk_type,
        name,
        user_ids,
        allow_display_past_messages,
      })
    }
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// Parse UserInfo from @types.JsonValue

///|
fn parse_user_info(
  data : @types.JsonValue,
) -> Result[@types.UserInfo, @errors.DirectError] {
  match data {
    @types.JsonObject(obj) => {
      let id = match obj.get("id") {
        Some(v) =>
          match @types.json_to_id(v) {
            Some(id) => id
            None => return Err(@errors.invalid_response("Invalid id"))
          }
        None => return Err(@errors.invalid_response("Missing id"))
      }
      let name = match obj.get("name") {
        Some(@types.JsonString(s)) => s
        _ => ""
      }
      let display_name = match obj.get("display_name") {
        Some(@types.JsonString(s)) => s
        _ => ""
      }
      let phonetic_name = match obj.get("phonetic_name") {
        Some(@types.JsonString(s)) => s
        _ => ""
      }
      let email = match obj.get("email") {
        Some(@types.JsonString(s)) => s
        _ => ""
      }
      let icon_url = match obj.get("icon_url") {
        Some(@types.JsonString(s)) => s
        _ => ""
      }
      let domain_id = match obj.get("domain_id") {
        Some(v) =>
          match @types.json_to_id(v) {
            Some(id) => id
            None => @types.IDString("")
          }
        None => @types.IDString("")
      }
      let departments = match obj.get("departments") {
        Some(@types.JsonArray(arr)) => {
          let deps = []
          for item in arr {
            match @types.json_to_id(item) {
              Some(id) => deps.push(id)
              None => ()
            }
          }
          deps
        }
        _ => []
      }
      let profiles = match obj.get("profiles") {
        Some(@types.JsonObject(p)) => p
        _ => Map::new()
      }
      let can_talk = match obj.get("can_talk") {
        Some(@types.JsonBool(b)) => b
        _ => false
      }
      let allowed_to_create_talk = match obj.get("allowed_to_create_talk") {
        Some(@types.JsonBool(b)) => b
        _ => false
      }
      Ok({
        id,
        name,
        display_name,
        phonetic_name,
        email,
        icon_url,
        domain_id,
        departments,
        profiles,
        can_talk,
        allowed_to_create_talk,
      })
    }
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// Parse DomainInfo from @types.JsonValue

///|
fn parse_domain_info(
  data : @types.JsonValue,
) -> Result[@types.DomainInfo, @errors.DirectError] {
  match data {
    @types.JsonObject(obj) => {
      let id = match obj.get("id") {
        Some(v) =>
          match @types.json_to_id(v) {
            Some(id) => id
            None => return Err(@errors.invalid_response("Invalid id"))
          }
        None =>
          match obj.get("domain_id") {
            Some(v) =>
              match @types.json_to_id(v) {
                Some(id) => id
                None => return Err(@errors.invalid_response("Invalid id"))
              }
            None => return Err(@errors.invalid_response("Missing id"))
          }
      }
      let name = match obj.get("name") {
        Some(@types.JsonString(s)) => s
        _ =>
          match obj.get("domain_name") {
            Some(@types.JsonString(s)) => s
            _ => ""
          }
      }
      let updated_at = match obj.get("updated_at") {
        Some(@types.JsonInt(i)) => i
        Some(@types.JsonNumber(n)) => n.to_int().to_int64()
        _ => 0L
      }
      let contract = match obj.get("contract") {
        Some(v) => v
        None => @types.JsonNull
      }
      let setting = match obj.get("setting") {
        Some(v) => v
        None => @types.JsonNull
      }
      let role = match obj.get("role") {
        Some(v) => v
        None => @types.JsonNull
      }
      let closed = match obj.get("closed") {
        Some(@types.JsonBool(b)) => b
        _ => false
      }
      Ok({ id, name, updated_at, contract, setting, role, closed })
    }
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// Parse ConferenceInfo from @types.JsonValue

///|
fn parse_conference_info(
  data : @types.JsonValue,
) -> Result[@types.ConferenceInfo, @errors.DirectError] {
  match data {
    @types.JsonObject(obj) => {
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
      let status = match obj.get("status") {
        Some(@types.JsonString(s)) => s
        _ => ""
      }
      let created = match obj.get("created") {
        Some(@types.JsonInt(i)) => i
        Some(@types.JsonNumber(n)) => n.to_int().to_int64()
        _ => 0L
      }
      Ok({ id, talk_id, domain_id, status, created })
    }
    _ => Err(@errors.invalid_response("Expected object"))
  }
}
