// User API for Direct SDK
// Reference: direct-go-sdk/direct-go/users.go

// Get current user information
// cfg(target="native")
pub async fn get_me(client : rpc/client/Client) -> Result[types/UserInfo, DirectError] {
  let result = await rpc/client/call(client, METHOD_GET_ME, [])?

  match result {
    | JsonObject(obj) => parse_user_info(obj)
    | _ => Err(invalid_response("Expected object"))
  }
}

// Get multiple users by their IDs within a domain
// cfg(target="native")
pub async fn get_users(
  client : rpc/client/Client,
  domain_id : types/ID,
  user_ids : Array[types/ID]
) -> Result[Array[types/UserInfo], DirectError] {
  let params = [
    types/id_to_json(domain_id),
    JsonArray(user_ids.map(types/id_to_json)),
  ]

  let result = await rpc/client/call(client, METHOD_GET_USERS, params)?

  match result {
    | JsonArray(arr) => {
      let mut users = []
      for item in arr {
        match item {
          | JsonObject(obj) => {
            match parse_user_info(obj) {
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

// Get detailed profile for a specific user in a domain
// cfg(target="native")
pub async fn get_profile(
  client : rpc/client/Client,
  domain_id : types/ID,
  user_id : types/ID
) -> Result[types/ProfileInfo, DirectError] {
  let params = [
    types/id_to_json(domain_id),
    types/id_to_json(user_id),
  ]

  let result = await rpc/client/call(client, METHOD_GET_PROFILE, params)?

  match result {
    | JsonObject(obj) => parse_profile_info(obj)
    | _ => Err(invalid_response("Expected object"))
  }
}

// Update current user's profile within a domain
// cfg(target="native")
pub async fn update_profile(
  client : rpc/client/Client,
  domain_id : types/ID,
  updates : Map[String, JsonValue]
) -> Result[Unit, DirectError] {
  let params = [
    types/id_to_json(domain_id),
    JsonObject(updates),
  ]

  match await rpc/client/call(client, METHOD_UPDATE_PROFILE, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// Update user information (requires appropriate permissions)
// cfg(target="native")
pub async fn update_user(
  client : rpc/client/Client,
  user_id : types/ID,
  updates : Map[String, JsonValue]
) -> Result[Unit, DirectError] {
  let params = [
    types/id_to_json(user_id),
    JsonObject(updates),
  ]

  match await rpc/client/call(client, METHOD_UPDATE_USER, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// Get online/offline status for multiple users
// cfg(target="native")
pub async fn get_presences(
  client : rpc/client/Client,
  user_ids : Array[types/ID]
) -> Result[Array[types/PresenceInfo], DirectError] {
  let params = [JsonArray(user_ids.map(types/id_to_json))]

  let result = await rpc/client/call(client, METHOD_GET_PRESENCES, params)?

  match result {
    | JsonArray(arr) => {
      let mut presences = []
      for item in arr {
        match item {
          | JsonObject(obj) => {
            match parse_presence_info(obj) {
              | Ok(pres) => presences = presences.push(pres)
              | Err(_) => ()
            }
          }
          | _ => ()
        }
      }
      Ok(presences)
    }
    | _ => Err(invalid_response("Expected array"))
  }
}

// Get various identifier information for multiple users
// cfg(target="native")
pub async fn get_user_identifiers(
  client : rpc/client/Client,
  user_ids : Array[types/ID]
) -> Result[Array[types/UserIdentifier], DirectError] {
  let params = [JsonArray(user_ids.map(types/id_to_json))]

  let result = await rpc/client/call(client, METHOD_GET_USER_IDENTIFIERS, params)?

  match result {
    | JsonArray(arr) => {
      let mut identifiers = []
      for item in arr {
        match item {
          | JsonObject(obj) => {
            match parse_user_identifier(obj) {
              | Ok(id) => identifiers = identifiers.push(id)
              | Err(_) => ()
            }
          }
          | _ => ()
        }
      }
      Ok(identifiers)
    }
    | _ => Err(invalid_response("Expected array"))
  }
}

// Get current user's friends list
// cfg(target="native")
pub async fn get_friends(client : rpc/client/Client) -> Result[Array[types/UserInfo], DirectError] {
  let result = await rpc/client/call(client, METHOD_GET_FRIENDS, [])?

  match result {
    | JsonArray(arr) => {
      let mut friends = []
      for item in arr {
        match item {
          | JsonObject(obj) => {
            match parse_user_info(obj) {
              | Ok(user) => friends = friends.push(user)
              | Err(_) => ()
            }
          }
          | _ => ()
        }
      }
      Ok(friends)
    }
    | _ => Err(invalid_response("Expected array"))
  }
}

// Add a user to the current user's friends list
// cfg(target="native")
pub async fn add_friend(
  client : rpc/client/Client,
  user_id : types/ID
) -> Result[Unit, DirectError] {
  let params = [types/id_to_json(user_id)]

  match await rpc/client/call(client, METHOD_ADD_FRIEND, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// Remove a user from the current user's friends list
// cfg(target="native")
pub async fn delete_friend(
  client : rpc/client/Client,
  user_id : types/ID
) -> Result[Unit, DirectError] {
  let params = [types/id_to_json(user_id)]

  match await rpc/client/call(client, METHOD_DELETE_FRIEND, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// Get current user's acquaintances list
// Acquaintances are users the current user has interacted with but are not friends
// cfg(target="native")
pub async fn get_acquaintances(client : rpc/client/Client) -> Result[Array[types/UserInfo], DirectError] {
  let result = await rpc/client/call(client, METHOD_GET_ACQUAINTANCES, [])?

  match result {
    | JsonArray(arr) => {
      let mut acquaintances = []
      for item in arr {
        match item {
          | JsonObject(obj) => {
            match parse_user_info(obj) {
              | Ok(user) => acquaintances = acquaintances.push(user)
              | Err(_) => ()
            }
          }
          | _ => ()
        }
      }
      Ok(acquaintances)
    }
    | _ => Err(invalid_response("Expected array"))
  }
}

// === Helper functions for parsing user data ===

// Parse UserInfo from JsonValue
fn parse_user_info(obj : Map[String, JsonValue]) -> Result[types/UserInfo, DirectError] {
  let id = match obj.get("id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => return Err(invalid_response("Invalid id"))
    }
    | None => return Err(invalid_response("Missing id"))
  }

  let name = json_get_string(obj, "name").unwrap_or("")
  let display_name = json_get_string(obj, "display_name").unwrap_or("")
  let phonetic_name = json_get_string(obj, "phonetic_name").unwrap_or("")
  let email = json_get_string(obj, "email").unwrap_or("")
  let icon_url = json_get_string(obj, "icon_url").unwrap_or("")

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

// Parse ProfileInfo from JsonValue
fn parse_profile_info(obj : Map[String, JsonValue]) -> Result[types/ProfileInfo, DirectError] {
  let user_id = match obj.get("user_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => return Err(invalid_response("Invalid user_id"))
    }
    | None => return Err(invalid_response("Missing user_id"))
  }

  let domain_id = match obj.get("domain_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => types/IDString("")
    }
    | None => types/IDString("")
  }

  let display_name = json_get_string(obj, "display_name").unwrap_or("")
  let phonetic_name = json_get_string(obj, "phonetic_name").unwrap_or("")

  let profiles = match obj.get("profiles") {
    | Some(JsonObject(p)) => p
    | _ => Map::new()
  }

  Ok({
    user_id: user_id,
    domain_id: domain_id,
    display_name: display_name,
    phonetic_name: phonetic_name,
    profiles: profiles,
  })
}

// Parse PresenceInfo from JsonValue
fn parse_presence_info(obj : Map[String, JsonValue]) -> Result[types/PresenceInfo, DirectError] {
  let user_id = match obj.get("user_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => return Err(invalid_response("Invalid user_id"))
    }
    | None => return Err(invalid_response("Missing user_id"))
  }

  let status = json_get_string(obj, "status").unwrap_or("offline")

  Ok({
    user_id: user_id,
    status: status,
  })
}

// Parse UserIdentifier from JsonValue
fn parse_user_identifier(obj : Map[String, JsonValue]) -> Result[types/UserIdentifier, DirectError] {
  let user_id = match obj.get("user_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => return Err(invalid_response("Invalid user_id"))
    }
    | None => return Err(invalid_response("Missing user_id"))
  }

  let email = json_get_string(obj, "email").unwrap_or("")
  let sub_email = json_get_string(obj, "sub_email").unwrap_or("")
  let group_alias = json_get_string(obj, "group_alias").unwrap_or("")
  let signin_id = json_get_string(obj, "signin_id").unwrap_or("")

  Ok({
    user_id: user_id,
    email: email,
    sub_email: sub_email,
    group_alias: group_alias,
    signin_id: signin_id,
  })
}

// Helper: Get string value from JsonObject
fn json_get_string(obj : Map[String, JsonValue], key : String) -> Option[String] {
  match obj.get(key) {
    | Some(JsonString(s)) => Some(s)
    | _ => None
  }
}
