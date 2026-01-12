// Domain API for Direct SDK
// Reference: direct-go-sdk/direct-go/domains.go

// Detailed domain information

///|
pub struct DomainInfo {
  id : @types.ID
  name : String
  updated_at : Int64
  contract : @types.JsonValue
  setting : @types.JsonValue
  role : @types.JsonValue
  closed : Bool
}

// Domain invitation information

///|
pub struct DomainInviteInfo {
  id : @types.ID
  name : String
  account_control_request_id : @types.ID
  updated_at : Int64
}

// === Domain Operations ===

// Get all domains/organizations the user belongs to
// cfg(target="native")

///|
pub async fn get_domains(
  client : @rpc_client.Client,
) -> Result[Array[DomainInfo], @errors.DirectError] {
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_DOMAINS, []) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let domains = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_domain_info(obj) {
              Ok(domain) => domains.push(domain)
              Err(_) => ()
            }
          _ => ()
        }
      }
      Ok(domains)
    }
    _ => Err(@errors.invalid_response("Expected array"))
  }
}

// Get pending domain invitations
// cfg(target="native")

///|
pub async fn get_domain_invites(
  client : @rpc_client.Client,
) -> Result[Array[DomainInviteInfo], @errors.DirectError] {
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_DOMAIN_INVITES, []) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let invites = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_domain_invite_info(obj) {
              Ok(invite) => invites.push(invite)
              Err(_) => ()
            }
          _ => ()
        }
      }
      Ok(invites)
    }
    _ => Err(@errors.invalid_response("Expected array"))
  }
}

// Accept a pending domain invitation and join the domain
// cfg(target="native")

///|
pub async fn accept_domain_invite(
  client : @rpc_client.Client,
  invite_id : @types.ID,
) -> Result[DomainInfo, @errors.DirectError] {
  let params = [@types.id_to_json(invite_id)]
  let result = match
    @rpc_client.call(client, @constants.METHOD_ACCEPT_DOMAIN_INVITE, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonObject(obj) => parse_domain_info(obj)
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// Leave a domain/organization
// cfg(target="native")

///|
pub async fn leave_domain(
  client : @rpc_client.Client,
  domain_id : @types.ID,
) -> Result[Unit, @errors.DirectError] {
  let params = [@types.id_to_json(domain_id)]
  match @rpc_client.call(client, @constants.METHOD_LEAVE_DOMAIN, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// Get all users belonging to a domain
// cfg(target="native")

///|
pub async fn get_domain_users(
  client : @rpc_client.Client,
  domain_id : @types.ID,
) -> Result[Array[@types.UserInfo], @errors.DirectError] {
  let params = [@types.id_to_json(domain_id)]
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_DOMAIN_USERS, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let users = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            // Use parse_user_info from users module
            match parse_user_info_from_json(obj) {
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

// Search for users within a domain
// The query matches against user names, display names, and email addresses
// cfg(target="native")

///|
pub async fn search_domain_users(
  client : @rpc_client.Client,
  domain_id : @types.ID,
  query : String,
) -> Result[Array[@types.UserInfo], @errors.DirectError] {
  let params = [@types.id_to_json(domain_id), @types.JsonString(query)]
  let result = match
    @rpc_client.call(client, @constants.METHOD_SEARCH_DOMAIN_USERS, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let users = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_user_info_from_json(obj) {
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

// Reject and delete a pending domain invitation
// cfg(target="native")

///|
pub async fn delete_domain_invite(
  client : @rpc_client.Client,
  invite_id : @types.ID,
) -> Result[Unit, @errors.DirectError] {
  let params = [@types.id_to_json(invite_id)]
  match
    @rpc_client.call(client, @constants.METHOD_DELETE_DOMAIN_INVITE, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// === Helper functions for parsing domain data ===

// Parse DomainInfo from @types.JsonValue

///|
fn parse_domain_info(
  obj : Map[String, @types.JsonValue],
) -> Result[DomainInfo, @errors.DirectError] {
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
  let name = match json_get_string(obj, "name") {
    Some(s) => s
    None =>
      match json_get_string(obj, "domain_name") {
        Some(s) => s
        None => ""
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

// Parse DomainInviteInfo from @types.JsonValue

///|
fn parse_domain_invite_info(
  obj : Map[String, @types.JsonValue],
) -> Result[DomainInviteInfo, @errors.DirectError] {
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
  let name = match json_get_string(obj, "name") {
    Some(s) => s
    None =>
      match json_get_string(obj, "domain_name") {
        Some(s) => s
        None => ""
      }
  }
  let account_control_request_id = match obj.get("account_control_request_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => @types.IDString("")
      }
    None => @types.IDString("")
  }
  let updated_at = match obj.get("updated_at") {
    Some(@types.JsonInt(i)) => i
    Some(@types.JsonNumber(n)) => n.to_int().to_int64()
    _ => 0L
  }
  Ok({ id, name, account_control_request_id, updated_at })
}

// Parse UserInfo from @types.JsonValue (shared with users module)

///|
fn parse_user_info_from_json(
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
