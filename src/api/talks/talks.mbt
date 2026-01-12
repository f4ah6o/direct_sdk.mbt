// Talk/Room API for Direct SDK
// Reference: direct-go-sdk/direct-go/talks.go

// Get all talks (conversations/rooms)
// cfg(target="native")

///|
pub async fn get_talks(
  client : @rpc_client.Client,
) -> Result[Array[@types.Talk], @errors.DirectError] {
  let result = match @rpc_client.call(client, @constants.METHOD_GET_TALKS, []) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let talks = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_talk(obj) {
              Ok(talk) => talks.push(talk)
              Err(_) => ()
            }
          _ => ()
        }
      }
      Ok(talks)
    }
    _ => Err(@errors.invalid_response("Expected array"))
  }
}

// Get talk statuses (unread counts, etc.)
// cfg(target="native")

///|
pub async fn get_talk_statuses(
  client : @rpc_client.Client,
) -> Result[Array[@types.TalkStatus], @errors.DirectError] {
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_TALK_STATUSES, []) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let statuses = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_talk_status(obj) {
              Ok(status) => statuses.push(status)
              Err(_) => ()
            }
          _ => ()
        }
      }
      Ok(statuses)
    }
    _ => Err(@errors.invalid_response("Expected array"))
  }
}

// Create a new group conversation with multiple participants
// cfg(target="native")

///|
pub async fn create_group_talk(
  client : @rpc_client.Client,
  domain_id : @types.ID,
  name : String,
  user_ids : Array[@types.ID],
  settings : @types.GroupTalkSettings?,
) -> Result[@types.Talk, @errors.DirectError] {
  let params = match settings {
    Some(s) =>
      [
        @types.id_to_json(domain_id),
        @types.JsonString(s.name),
        @types.JsonArray(user_ids.map(@types.id_to_json)),
        @types.JsonBool(s.allow_display_past_messages),
        match s.icon_url {
          Some(url) => @types.JsonString(url)
          None => @types.JsonNull
        },
        match s.description {
          Some(desc) => @types.JsonString(desc)
          None => @types.JsonNull
        },
      ]
    None =>
      [
        @types.id_to_json(domain_id),
        @types.JsonString(name),
        @types.JsonArray(user_ids.map(@types.id_to_json)),
        @types.JsonBool(true), // default: allow display past messages
        @types.JsonNull, // no icon
        @types.JsonNull,
      ]
  } // no description
  let result = match
    @rpc_client.call(client, @constants.METHOD_CREATE_GROUP_TALK, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonObject(obj) => parse_talk(obj)
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// Create a 1-on-1 conversation with another user
// cfg(target="native")

///|
pub async fn create_pair_talk(
  client : @rpc_client.Client,
  domain_id : @types.ID,
  user_id : @types.ID,
) -> Result[@types.Talk, @errors.DirectError] {
  let params = [@types.id_to_json(domain_id), @types.id_to_json(user_id)]
  let result = match
    @rpc_client.call(client, @constants.METHOD_CREATE_PAIR_TALK, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonObject(obj) => parse_talk(obj)
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// Update a group talk's settings (name, icon, description, etc.)
// cfg(target="native")

///|
pub async fn update_group_talk(
  client : @rpc_client.Client,
  talk_id : @types.ID,
  updates : Map[String, @types.JsonValue],
) -> Result[@types.Talk, @errors.DirectError] {
  let params = [@types.id_to_json(talk_id), @types.JsonObject(updates)]
  let result = match
    @rpc_client.call(client, @constants.METHOD_UPDATE_GROUP_TALK, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonObject(obj) => parse_talk(obj)
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// Add multiple users as participants to an existing talk
// cfg(target="native")

///|
pub async fn add_talkers(
  client : @rpc_client.Client,
  talk_id : @types.ID,
  user_ids : Array[@types.ID],
) -> Result[Unit, @errors.DirectError] {
  let params = [
    @types.id_to_json(talk_id),
    @types.JsonArray(user_ids.map(@types.id_to_json)),
  ]
  match @rpc_client.call(client, @constants.METHOD_ADD_TALKERS, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// Remove a user from a talk
// cfg(target="native")

///|
pub async fn delete_talker(
  client : @rpc_client.Client,
  talk_id : @types.ID,
  user_id : @types.ID,
) -> Result[Unit, @errors.DirectError] {
  let params = [@types.id_to_json(talk_id), @types.id_to_json(user_id)]
  match @rpc_client.call(client, @constants.METHOD_DELETE_TALKER, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// Add a talk to the current user's favorites list
// cfg(target="native")

///|
pub async fn add_favorite_talk(
  client : @rpc_client.Client,
  talk_id : @types.ID,
) -> Result[Unit, @errors.DirectError] {
  let params = [@types.id_to_json(talk_id)]
  match @rpc_client.call(client, @constants.METHOD_ADD_FAVORITE_TALK, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// Remove a talk from the current user's favorites list
// cfg(target="native")

///|
pub async fn delete_favorite_talk(
  client : @rpc_client.Client,
  talk_id : @types.ID,
) -> Result[Unit, @errors.DirectError] {
  let params = [@types.id_to_json(talk_id)]
  match
    @rpc_client.call(client, @constants.METHOD_DELETE_FAVORITE_TALK, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// === Helper functions for parsing talk data ===

// Parse Talk from @types.JsonValue

///|
fn parse_talk(
  obj : Map[String, @types.JsonValue],
) -> Result[@types.Talk, @errors.DirectError] {
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
  let name = json_get_string(obj, "name").unwrap_or("")
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
  Ok({ id, domain_id, talk_type, name, user_ids, allow_display_past_messages })
}

// Parse TalkStatus from @types.JsonValue

///|
fn parse_talk_status(
  obj : Map[String, @types.JsonValue],
) -> Result[@types.TalkStatus, @errors.DirectError] {
  let talk_id = match obj.get("talk_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => return Err(@errors.invalid_response("Invalid talk_id"))
      }
    None => return Err(@errors.invalid_response("Missing talk_id"))
  }
  let unread_count = match obj.get("unread_count") {
    Some(@types.JsonInt(i)) => i.to_int()
    Some(@types.JsonNumber(n)) => n.to_int()
    _ => 0
  }
  let latest_msg_id = match obj.get("latest_msg_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => Some(id)
        None => None
      }
    None => None
  }
  Ok({ talk_id, unread_count, latest_msg_id })
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
