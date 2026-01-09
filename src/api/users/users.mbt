// User API for Direct SDK
// Reference: direct-go-sdk/direct-go/users.go

// Get current user information
// cfg(target="native")

///|
pub async fn get_me(
  client : @rpc_client.Client,
) -> Result[@types.UserInfo, @errors.DirectError] {
  let result = match @rpc_client.call(client, @constants.METHOD_GET_ME, []) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonObject(obj) => parse_user_info(obj)
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// Get multiple users by their IDs within a domain
// cfg(target="native")

///|
pub async fn get_users(
  client : @rpc_client.Client,
  domain_id : @types.ID,
  user_ids : Array[@types.ID],
) -> Result[Array[@types.UserInfo], @errors.DirectError] {
  let params = [
    @types.id_to_json(domain_id),
    @types.JsonArray(user_ids.map(@types.id_to_json)),
  ]
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_USERS, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let users = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_user_info(obj) {
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

// Get detailed profile for a specific user in a domain
// cfg(target="native")

///|
pub async fn get_profile(
  client : @rpc_client.Client,
  domain_id : @types.ID,
  user_id : @types.ID,
) -> Result[@types.ProfileInfo, @errors.DirectError] {
  let params = [@types.id_to_json(domain_id), @types.id_to_json(user_id)]
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_PROFILE, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonObject(obj) => parse_profile_info(obj)
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// Update current user's profile within a domain
// cfg(target="native")

///|
pub async fn update_profile(
  client : @rpc_client.Client,
  domain_id : @types.ID,
  updates : Map[String, @types.JsonValue],
) -> Result[Unit, @errors.DirectError] {
  let params = [@types.id_to_json(domain_id), @types.JsonObject(updates)]
  match @rpc_client.call(client, @constants.METHOD_UPDATE_PROFILE, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// Update user information (requires appropriate permissions)
// cfg(target="native")

///|
pub async fn update_user(
  client : @rpc_client.Client,
  user_id : @types.ID,
  updates : Map[String, @types.JsonValue],
) -> Result[Unit, @errors.DirectError] {
  let params = [@types.id_to_json(user_id), @types.JsonObject(updates)]
  match @rpc_client.call(client, @constants.METHOD_UPDATE_USER, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// Get online/offline status for multiple users
// cfg(target="native")

///|
pub async fn get_presences(
  client : @rpc_client.Client,
  user_ids : Array[@types.ID],
) -> Result[Array[@types.PresenceInfo], @errors.DirectError] {
  let params = [@types.JsonArray(user_ids.map(@types.id_to_json))]
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_PRESENCES, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let presences = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_presence_info(obj) {
              Ok(pres) => presences.push(pres)
              Err(_) => ()
            }
          _ => ()
        }
      }
      Ok(presences)
    }
    _ => Err(@errors.invalid_response("Expected array"))
  }
}

// Get various identifier information for multiple users
// cfg(target="native")

///|
pub async fn get_user_identifiers(
  client : @rpc_client.Client,
  user_ids : Array[@types.ID],
) -> Result[Array[@types.UserIdentifier], @errors.DirectError] {
  let params = [@types.JsonArray(user_ids.map(@types.id_to_json))]
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_USER_IDENTIFIERS, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let identifiers = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_user_identifier(obj) {
              Ok(id) => identifiers.push(id)
              Err(_) => ()
            }
          _ => ()
        }
      }
      Ok(identifiers)
    }
    _ => Err(@errors.invalid_response("Expected array"))
  }
}

// Get current user's friends list
// cfg(target="native")

///|
pub async fn get_friends(
  client : @rpc_client.Client,
) -> Result[Array[@types.UserInfo], @errors.DirectError] {
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_FRIENDS, []) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let friends = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_user_info(obj) {
              Ok(user) => friends.push(user)
              Err(_) => ()
            }
          _ => ()
        }
      }
      Ok(friends)
    }
    _ => Err(@errors.invalid_response("Expected array"))
  }
}

// Add a user to the current user's friends list
// cfg(target="native")

///|
pub async fn add_friend(
  client : @rpc_client.Client,
  user_id : @types.ID,
) -> Result[Unit, @errors.DirectError] {
  let params = [@types.id_to_json(user_id)]
  match @rpc_client.call(client, @constants.METHOD_ADD_FRIEND, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// Remove a user from the current user's friends list
// cfg(target="native")

///|
pub async fn delete_friend(
  client : @rpc_client.Client,
  user_id : @types.ID,
) -> Result[Unit, @errors.DirectError] {
  let params = [@types.id_to_json(user_id)]
  match @rpc_client.call(client, @constants.METHOD_DELETE_FRIEND, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// Get current user's acquaintances list
// Acquaintances are users the current user has interacted with but are not friends
// cfg(target="native")

///|
pub async fn get_acquaintances(
  client : @rpc_client.Client,
) -> Result[Array[@types.UserInfo], @errors.DirectError] {
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_ACQUAINTANCES, []) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let acquaintances = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_user_info(obj) {
              Ok(user) => acquaintances.push(user)
              Err(_) => ()
            }
          _ => ()
        }
      }
      Ok(acquaintances)
    }
    _ => Err(@errors.invalid_response("Expected array"))
  }
}

// === Helper functions for parsing user data ===

// Parse UserInfo from @types.JsonValue

///|
fn parse_user_info(
  obj : Map[String, @types.JsonValue],
) -> Result[@types.UserInfo, @errors.DirectError] {
  let id = match obj.get("id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => return Err(@errors.invalid_response("Invalid id"))
      }
    None => return Err(@errors.invalid_response("Missing id"))
  }
  let name = json_get_string(obj, "name").unwrap_or("")
  let display_name = json_get_string(obj, "display_name").unwrap_or("")
  let phonetic_name = json_get_string(obj, "phonetic_name").unwrap_or("")
  let email = json_get_string(obj, "email").unwrap_or("")
  let icon_url = json_get_string(obj, "icon_url").unwrap_or("")
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

// Parse ProfileInfo from @types.JsonValue

///|
fn parse_profile_info(
  obj : Map[String, @types.JsonValue],
) -> Result[@types.ProfileInfo, @errors.DirectError] {
  let user_id = match obj.get("user_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => return Err(@errors.invalid_response("Invalid user_id"))
      }
    None => return Err(@errors.invalid_response("Missing user_id"))
  }
  let domain_id = match obj.get("domain_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => @types.IDString("")
      }
    None => @types.IDString("")
  }
  let display_name = json_get_string(obj, "display_name").unwrap_or("")
  let phonetic_name = json_get_string(obj, "phonetic_name").unwrap_or("")
  let profiles = match obj.get("profiles") {
    Some(@types.JsonObject(p)) => p
    _ => Map::new()
  }
  Ok({ user_id, domain_id, display_name, phonetic_name, profiles })
}

// Parse PresenceInfo from @types.JsonValue

///|
fn parse_presence_info(
  obj : Map[String, @types.JsonValue],
) -> Result[@types.PresenceInfo, @errors.DirectError] {
  let user_id = match obj.get("user_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => return Err(@errors.invalid_response("Invalid user_id"))
      }
    None => return Err(@errors.invalid_response("Missing user_id"))
  }
  let status = json_get_string(obj, "status").unwrap_or("offline")
  Ok({ user_id, status })
}

// Parse UserIdentifier from @types.JsonValue

///|
fn parse_user_identifier(
  obj : Map[String, @types.JsonValue],
) -> Result[@types.UserIdentifier, @errors.DirectError] {
  let user_id = match obj.get("user_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => return Err(@errors.invalid_response("Invalid user_id"))
      }
    None => return Err(@errors.invalid_response("Missing user_id"))
  }
  let email = json_get_string(obj, "email").unwrap_or("")
  let sub_email = json_get_string(obj, "sub_email").unwrap_or("")
  let group_alias = json_get_string(obj, "group_alias").unwrap_or("")
  let signin_id = json_get_string(obj, "signin_id").unwrap_or("")
  Ok({ user_id, email, sub_email, group_alias, signin_id })
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
