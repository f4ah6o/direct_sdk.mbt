// Domain API for Direct SDK
// Reference: direct-go-sdk/direct-go/domains.go

// Detailed domain information
pub type DomainInfo = {
  id         : types/ID,
  name       : String,
  updated_at : Int64,
  contract   : JsonValue,
  setting    : JsonValue,
  role       : JsonValue,
  closed     : Bool,
}

// Domain invitation information
pub type DomainInviteInfo = {
  id                        : types/ID,
  name                      : String,
  account_control_request_id : types/ID,
  updated_at                : Int64,
}

// === Domain Operations ===

// Get all domains/organizations the user belongs to
// cfg(target="native")
pub async fn get_domains(client : rpc/client/Client) -> Result[Array[DomainInfo], DirectError] {
  let result = await rpc/client/call(client, METHOD_GET_DOMAINS, [])?

  match result {
    | JsonArray(arr) => {
      let mut domains = []
      for item in arr {
        match item {
          | JsonObject(obj) => {
            match parse_domain_info(obj) {
              | Ok(domain) => domains = domains.push(domain)
              | Err(_) => ()
            }
          }
          | _ => ()
        }
      }
      Ok(domains)
    }
    | _ => Err(invalid_response("Expected array"))
  }
}

// Get pending domain invitations
// cfg(target="native")
pub async fn get_domain_invites(client : rpc/client/Client) -> Result[Array[DomainInviteInfo], DirectError] {
  let result = await rpc/client/call(client, METHOD_GET_DOMAIN_INVITES, [])?

  match result {
    | JsonArray(arr) => {
      let mut invites = []
      for item in arr {
        match item {
          | JsonObject(obj) => {
            match parse_domain_invite_info(obj) {
              | Ok(invite) => invites = invites.push(invite)
              | Err(_) => ()
            }
          }
          | _ => ()
        }
      }
      Ok(invites)
    }
    | _ => Err(invalid_response("Expected array"))
  }
}

// Accept a pending domain invitation and join the domain
// cfg(target="native")
pub async fn accept_domain_invite(client : rpc/client/Client, invite_id : types/ID) -> Result[DomainInfo, DirectError] {
  let params = [types/id_to_json(invite_id)]

  let result = await rpc/client/call(client, METHOD_ACCEPT_DOMAIN_INVITE, params)?

  match result {
    | JsonObject(obj) => parse_domain_info(obj)
    | _ => Err(invalid_response("Expected object"))
  }
}

// Leave a domain/organization
// cfg(target="native")
pub async fn leave_domain(client : rpc/client/Client, domain_id : types/ID) -> Result[Unit, DirectError] {
  let params = [types/id_to_json(domain_id)]

  match await rpc/client/call(client, METHOD_LEAVE_DOMAIN, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// Get all users belonging to a domain
// cfg(target="native")
pub async fn get_domain_users(client : rpc/client/Client, domain_id : types/ID) -> Result[Array[types/UserInfo], DirectError] {
  let params = [types/id_to_json(domain_id)]

  let result = await rpc/client/call(client, METHOD_GET_DOMAIN_USERS, params)?

  match result {
    | JsonArray(arr) => {
      let mut users = []
      for item in arr {
        match item {
          | JsonObject(obj) => {
            // Use parse_user_info from users module
            match parse_user_info_from_json(obj) {
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

// Search for users within a domain
// The query matches against user names, display names, and email addresses
// cfg(target="native")
pub async fn search_domain_users(
  client : rpc/client/Client,
  domain_id : types/ID,
  query : String
) -> Result[Array[types/UserInfo], DirectError] {
  let params = [
    types/id_to_json(domain_id),
    JsonString(query),
  ]

  let result = await rpc/client/call(client, METHOD_SEARCH_DOMAIN_USERS, params)?

  match result {
    | JsonArray(arr) => {
      let mut users = []
      for item in arr {
        match item {
          | JsonObject(obj) => {
            match parse_user_info_from_json(obj) {
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

// Reject and delete a pending domain invitation
// cfg(target="native")
pub async fn delete_domain_invite(client : rpc/client/Client, invite_id : types/ID) -> Result[Unit, DirectError] {
  let params = [types/id_to_json(invite_id)]

  match await rpc/client/call(client, METHOD_DELETE_DOMAIN_INVITE, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// === Helper functions for parsing domain data ===

// Parse DomainInfo from JsonValue
fn parse_domain_info(obj : Map[String, JsonValue]) -> Result[DomainInfo, DirectError] {
  let id = match obj.get("id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => return Err(invalid_response("Invalid id"))
    }
    | None => match obj.get("domain_id") {
      | Some(v) => match types/json_to_id(v) {
        | Some(id) => id
        | None => return Err(invalid_response("Invalid id"))
      }
      | None => return Err(invalid_response("Missing id"))
    }
  }

  let name = match json_get_string(obj, "name") {
    | Some(s) => s
    | None => match json_get_string(obj, "domain_name") {
      | Some(s) => s
      | None => ""
    }
  }

  let updated_at = match obj.get("updated_at") {
    | Some(JsonNumber(n)) => n.to_int64().unwrap_or(0L)
    | _ => 0L
  }

  let contract = match obj.get("contract") {
    | Some(v) => v
    | None => JsonNull
  }

  let setting = match obj.get("setting") {
    | Some(v) => v
    | None => JsonNull
  }

  let role = match obj.get("role") {
    | Some(v) => v
    | None => JsonNull
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

// Parse DomainInviteInfo from JsonValue
fn parse_domain_invite_info(obj : Map[String, JsonValue]) -> Result[DomainInviteInfo, DirectError] {
  let id = match obj.get("id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => return Err(invalid_response("Invalid id"))
    }
    | None => match obj.get("domain_id") {
      | Some(v) => match types/json_to_id(v) {
        | Some(id) => id
        | None => return Err(invalid_response("Invalid id"))
      }
      | None => return Err(invalid_response("Missing id"))
    }
  }

  let name = match json_get_string(obj, "name") {
    | Some(s) => s
    | None => match json_get_string(obj, "domain_name") {
      | Some(s) => s
      | None => ""
    }
  }

  let account_control_request_id = match obj.get("account_control_request_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => types/IDString("")
    }
    | None => types/IDString("")
  }

  let updated_at = match obj.get("updated_at") {
    | Some(JsonNumber(n)) => n.to_int64().unwrap_or(0L)
    | _ => 0L
  }

  Ok({
    id: id,
    name: name,
    account_control_request_id: account_control_request_id,
    updated_at: updated_at,
  })
}

// Parse UserInfo from JsonValue (shared with users module)
fn parse_user_info_from_json(obj : Map[String, JsonValue]) -> Result[types/UserInfo, DirectError] {
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

// Helper: Get string value from JsonObject
fn json_get_string(obj : Map[String, JsonValue], key : String) -> Option[String] {
  match obj.get(key) {
    | Some(JsonString(s)) => Some(s)
    | _ => None
  }
}
