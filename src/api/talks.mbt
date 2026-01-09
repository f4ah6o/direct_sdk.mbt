// Talk/Room API for Direct SDK
// Reference: direct-go-sdk/direct-go/talks.go

// Get all talks (conversations/rooms)
// cfg(target="native")
pub async fn get_talks(client : rpc/client/Client) -> Result[Array[types/Talk], DirectError] {
  let result = await rpc/client/call(client, METHOD_GET_TALKS, [])?

  match result {
    | JsonArray(arr) => {
      let mut talks = []
      for item in arr {
        match item {
          | JsonObject(obj) => {
            match parse_talk(obj) {
              | Ok(talk) => talks = talks.push(talk)
              | Err(_) => ()
            }
          }
          | _ => ()
        }
      }
      Ok(talks)
    }
    | _ => Err(invalid_response("Expected array"))
  }
}

// Get talk statuses (unread counts, etc.)
// cfg(target="native")
pub async fn get_talk_statuses(client : rpc/client/Client) -> Result[Array[types/TalkStatus], DirectError] {
  let result = await rpc/client/call(client, METHOD_GET_TALK_STATUSES, [])?

  match result {
    | JsonArray(arr) => {
      let mut statuses = []
      for item in arr {
        match item {
          | JsonObject(obj) => {
            match parse_talk_status(obj) {
              | Ok(status) => statuses = statuses.push(status)
              | Err(_) => ()
            }
          }
          | _ => ()
        }
      }
      Ok(statuses)
    }
    | _ => Err(invalid_response("Expected array"))
  }
}

// Create a new group conversation with multiple participants
// cfg(target="native")
pub async fn create_group_talk(
  client : rpc/client/Client,
  domain_id : types/ID,
  name : String,
  user_ids : Array[types/ID],
  settings : Option[types/GroupTalkSettings]
) -> Result[types/Talk, DirectError] {
  let params = match settings {
    | Some(s) => [
      types/id_to_json(domain_id),
      JsonString(s.name),
      JsonArray(user_ids.map(types/id_to_json)),
      JsonBool(s.allow_display_past_messages),
      match s.icon_url {
        | Some(url) => JsonString(url)
        | None => JsonNull
      },
      match s.description {
        | Some(desc) => JsonString(desc)
        | None => JsonNull
      },
    ]
    | None => [
      types/id_to_json(domain_id),
      JsonString(name),
      JsonArray(user_ids.map(types/id_to_json)),
      JsonBool(true),  // default: allow display past messages
      JsonNull,        // no icon
      JsonNull,        // no description
    ]
  }

  let result = await rpc/client/call(client, METHOD_CREATE_GROUP_TALK, params)?

  match result {
    | JsonObject(obj) => parse_talk(obj)
    | _ => Err(invalid_response("Expected object"))
  }
}

// Create a 1-on-1 conversation with another user
// cfg(target="native")
pub async fn create_pair_talk(
  client : rpc/client/Client,
  domain_id : types/ID,
  user_id : types/ID
) -> Result[types/Talk, DirectError] {
  let params = [
    types/id_to_json(domain_id),
    types/id_to_json(user_id),
  ]

  let result = await rpc/client/call(client, METHOD_CREATE_PAIR_TALK, params)?

  match result {
    | JsonObject(obj) => parse_talk(obj)
    | _ => Err(invalid_response("Expected object"))
  }
}

// Update a group talk's settings (name, icon, description, etc.)
// cfg(target="native")
pub async fn update_group_talk(
  client : rpc/client/Client,
  talk_id : types/ID,
  updates : Map[String, JsonValue]
) -> Result[types/Talk, DirectError] {
  let params = [
    types/id_to_json(talk_id),
    JsonObject(updates),
  ]

  let result = await rpc/client/call(client, METHOD_UPDATE_GROUP_TALK, params)?

  match result {
    | JsonObject(obj) => parse_talk(obj)
    | _ => Err(invalid_response("Expected object"))
  }
}

// Add multiple users as participants to an existing talk
// cfg(target="native")
pub async fn add_talkers(
  client : rpc/client/Client,
  talk_id : types/ID,
  user_ids : Array[types/ID]
) -> Result[Unit, DirectError] {
  let params = [
    types/id_to_json(talk_id),
    JsonArray(user_ids.map(types/id_to_json)),
  ]

  match await rpc/client/call(client, METHOD_ADD_TALKERS, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// Remove a user from a talk
// cfg(target="native")
pub async fn delete_talker(
  client : rpc/client/Client,
  talk_id : types/ID,
  user_id : types/ID
) -> Result[Unit, DirectError] {
  let params = [
    types/id_to_json(talk_id),
    types/id_to_json(user_id),
  ]

  match await rpc/client/call(client, METHOD_DELETE_TALKER, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// Add a talk to the current user's favorites list
// cfg(target="native")
pub async fn add_favorite_talk(
  client : rpc/client/Client,
  talk_id : types/ID
) -> Result[Unit, DirectError] {
  let params = [types/id_to_json(talk_id)]

  match await rpc/client/call(client, METHOD_ADD_FAVORITE_TALK, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// Remove a talk from the current user's favorites list
// cfg(target="native")
pub async fn delete_favorite_talk(
  client : rpc/client/Client,
  talk_id : types/ID
) -> Result[Unit, DirectError] {
  let params = [types/id_to_json(talk_id)]

  match await rpc/client/call(client, METHOD_DELETE_FAVORITE_TALK, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// === Helper functions for parsing talk data ===

// Parse Talk from JsonValue
fn parse_talk(obj : Map[String, JsonValue]) -> Result[types/Talk, DirectError] {
  let id = match obj.get("id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => return Err(invalid_response("Invalid id"))
    }
    | None => return Err(invalid_response("Missing id"))
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

  let name = json_get_string(obj, "name").unwrap_or("")

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

// Parse TalkStatus from JsonValue
fn parse_talk_status(obj : Map[String, JsonValue]) -> Result[types/TalkStatus, DirectError] {
  let talk_id = match obj.get("talk_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => return Err(invalid_response("Invalid talk_id"))
    }
    | None => return Err(invalid_response("Missing talk_id"))
  }

  let unread_count = match obj.get("unread_count") {
    | Some(JsonNumber(n)) => match n.to_int() {
      | Some(i) => i
      | None => 0
    }
    | _ => 0
  }

  let latest_msg_id = match obj.get("latest_msg_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => Some(id)
      | None => None
    }
    | None => None
  }

  Ok({
    talk_id: talk_id,
    unread_count: unread_count,
    latest_msg_id: latest_msg_id,
  })
}

// Helper: Get string value from JsonObject
fn json_get_string(obj : Map[String, JsonValue], key : String) -> Option[String] {
  match obj.get(key) {
    | Some(JsonString(s)) => Some(s)
    | _ => None
  }
}
