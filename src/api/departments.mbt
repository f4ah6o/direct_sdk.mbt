// Department/Organization API for Direct SDK
// Reference: direct-go-sdk/direct-go/departments.go

// Department tree structure for a domain
pub type DepartmentTree = {
  domain_id   : types/ID,
  departments : Array[Department],
}

// Department/organizational unit
pub type Department = {
  id          : types/ID,
  name        : String,
  parent_id   : types/ID,
  children_ids : Array[types/ID],
  user_count  : Int,
}

// User count statistics for a department
pub type DepartmentUserCount = {
  department_id : types/ID,
  all           : Int,
  partial       : Int,
}

// All user counts for departments in a domain
pub type DepartmentUserCounts = {
  domain_id   : types/ID,
  departments : Array[DepartmentUserCount],
}

// === Department Operations ===

// Get the organizational department hierarchy for a domain
// cfg(target="native")
pub async fn get_department_tree(
  client : rpc/client/Client,
  domain_id : types/ID
) -> Result[DepartmentTree, DirectError] {
  let params = [types/id_to_json(domain_id)]

  let result = await rpc/client/call(client, METHOD_GET_DEPARTMENT_TREE, params)?

  match result {
    | JsonObject(obj) => parse_department_tree(obj)
    | _ => Err(invalid_response("Expected object"))
  }
}

// Get all users belonging to a specific department
// cfg(target="native")
pub async fn get_department_users(
  client : rpc/client/Client,
  domain_id     : types/ID,
  department_id : types/ID
) -> Result[Array[types/UserInfo], DirectError] {
  let params = [
    types/id_to_json(domain_id),
    types/id_to_json(department_id),
  ]

  let result = await rpc/client/call(client, METHOD_GET_DEPARTMENT_USERS, params)?

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

// Get user count statistics for all departments in a domain
// cfg(target="native")
pub async fn get_department_user_count(
  client : rpc/client/Client,
  domain_id : types/ID
) -> Result[DepartmentUserCounts, DirectError] {
  let params = [types/id_to_json(domain_id)]

  let result = await rpc/client/call(client, METHOD_GET_DEPARTMENT_USER_COUNT, params)?

  match result {
    | JsonObject(obj) => parse_department_user_counts(obj)
    | _ => Err(invalid_response("Expected object"))
  }
}

// === Helper functions for parsing department data ===

// Parse DepartmentTree from JsonValue
fn parse_department_tree(obj : Map[String, JsonValue]) -> Result[DepartmentTree, DirectError] {
  let domain_id = match obj.get("domain_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => return Err(invalid_response("Invalid domain_id"))
    }
    | None => return Err(invalid_response("Missing domain_id"))
  }

  let departments = match obj.get("departments") {
    | Some(JsonArray(arr)) => {
      let mut deps = []
      for item in arr {
        match item {
          | JsonObject(dept_obj) => {
            match parse_department(dept_obj) {
              | Ok(dept) => deps = deps.push(dept)
              | Err(_) => ()
            }
          }
          | _ => ()
        }
      }
      deps
    }
    | _ => []
  }

  Ok({
    domain_id: domain_id,
    departments: departments,
  })
}

// Parse Department from JsonValue
fn parse_department(obj : Map[String, JsonValue]) -> Result[Department, DirectError] {
  let id = match obj.get("id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => return Err(invalid_response("Invalid id"))
    }
    | None => return Err(invalid_response("Missing id"))
  }

  let name = json_get_string(obj, "name").unwrap_or("")

  let parent_id = match obj.get("parent_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => types/IDString("")
    }
    | None => types/IDString("")
  }

  let children_ids = match obj.get("children_ids") {
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

  let user_count = match obj.get("user_count") {
    | Some(JsonNumber(n)) => match n.to_int() {
      | Some(i) => i
      | None => 0
    }
    | _ => 0
  }

  Ok({
    id: id,
    name: name,
    parent_id: parent_id,
    children_ids: children_ids,
    user_count: user_count,
  })
}

// Parse DepartmentUserCounts from JsonValue
fn parse_department_user_counts(obj : Map[String, JsonValue]) -> Result[DepartmentUserCounts, DirectError] {
  let domain_id = match obj.get("domain_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => types/IDString("")
    }
    | None => types/IDString("")
  }

  let departments = match obj.get("departments") {
    | Some(JsonArray(arr)) => {
      let mut counts = []
      for item in arr {
        match item {
          | JsonObject(count_obj) => {
            match parse_department_user_count(count_obj) {
              | Ok(count) => counts = counts.push(count)
              | Err(_) => ()
            }
          }
          | _ => ()
        }
      }
      counts
    }
    | _ => []
  }

  Ok({
    domain_id: domain_id,
    departments: departments,
  })
}

// Parse DepartmentUserCount from JsonValue
fn parse_department_user_count(obj : Map[String, JsonValue]) -> Result[DepartmentUserCount, DirectError] {
  let department_id = match obj.get("department_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => return Err(invalid_response("Invalid department_id"))
    }
    | None => return Err(invalid_response("Missing department_id"))
  }

  let all = match obj.get("all") {
    | Some(JsonNumber(n)) => match n.to_int() {
      | Some(i) => i
      | None => 0
    }
    | _ => 0
  }

  let partial = match obj.get("partial") {
    | Some(JsonNumber(n)) => match n.to_int() {
      | Some(i) => i
      | None => 0
    }
    | _ => 0
  }

  Ok({
    department_id: department_id,
    all: all,
    partial: partial,
  })
}

// Parse UserInfo from JsonValue (shared with users module)
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

// Helper: Get string value from JsonObject
fn json_get_string(obj : Map[String, JsonValue], key : String) -> Option[String] {
  match obj.get(key) {
    | Some(JsonString(s)) => Some(s)
    | _ => None
  }
}
