// Department/Organization API for Direct SDK
// Reference: direct-go-sdk/direct-go/departments.go

// Department tree structure for a domain

///|
pub struct DepartmentTree {
  domain_id : @types.ID
  departments : Array[Department]
}

// Department/organizational unit

///|
pub struct Department {
  id : @types.ID
  name : String
  parent_id : @types.ID
  children_ids : Array[@types.ID]
  user_count : Int
}

// User count statistics for a department

///|
pub struct DepartmentUserCount {
  department_id : @types.ID
  all : Int
  partial : Int
}

// All user counts for departments in a domain

///|
pub struct DepartmentUserCounts {
  domain_id : @types.ID
  departments : Array[DepartmentUserCount]
}

// === Department Operations ===

// Get the organizational department hierarchy for a domain
// cfg(target="native")

///|
pub async fn get_department_tree(
  client : @rpc_client.Client,
  domain_id : @types.ID,
) -> Result[DepartmentTree, @errors.DirectError] {
  let params = [@types.id_to_json(domain_id)]
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_DEPARTMENT_TREE, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonObject(obj) => parse_department_tree(obj)
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// Get all users belonging to a specific department
// cfg(target="native")

///|
pub async fn get_department_users(
  client : @rpc_client.Client,
  domain_id : @types.ID,
  department_id : @types.ID,
) -> Result[Array[@types.UserInfo], @errors.DirectError] {
  let params = [@types.id_to_json(domain_id), @types.id_to_json(department_id)]
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_DEPARTMENT_USERS, params) {
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

// Get user count statistics for all departments in a domain
// cfg(target="native")

///|
pub async fn get_department_user_count(
  client : @rpc_client.Client,
  domain_id : @types.ID,
) -> Result[DepartmentUserCounts, @errors.DirectError] {
  let params = [@types.id_to_json(domain_id)]
  let result = match
    @rpc_client.call(
      client,
      @constants.METHOD_GET_DEPARTMENT_USER_COUNT,
      params,
    ) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonObject(obj) => parse_department_user_counts(obj)
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// === Helper functions for parsing department data ===

// Parse DepartmentTree from @types.JsonValue

///|
fn parse_department_tree(
  obj : Map[String, @types.JsonValue],
) -> Result[DepartmentTree, @errors.DirectError] {
  let domain_id = match obj.get("domain_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => return Err(@errors.invalid_response("Invalid domain_id"))
      }
    None => return Err(@errors.invalid_response("Missing domain_id"))
  }
  let departments = match obj.get("departments") {
    Some(@types.JsonArray(arr)) => {
      let deps = []
      for item in arr {
        match item {
          @types.JsonObject(dept_obj) =>
            match parse_department(dept_obj) {
              Ok(dept) => deps.push(dept)
              Err(_) => ()
            }
          _ => ()
        }
      }
      deps
    }
    _ => []
  }
  Ok({ domain_id, departments })
}

// Parse Department from @types.JsonValue

///|
fn parse_department(
  obj : Map[String, @types.JsonValue],
) -> Result[Department, @errors.DirectError] {
  let id = match obj.get("id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => return Err(@errors.invalid_response("Invalid id"))
      }
    None => return Err(@errors.invalid_response("Missing id"))
  }
  let name = json_get_string(obj, "name").unwrap_or("")
  let parent_id = match obj.get("parent_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => @types.IDString("")
      }
    None => @types.IDString("")
  }
  let children_ids = match obj.get("children_ids") {
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
  let user_count = match obj.get("user_count") {
    Some(@types.JsonNumber(n)) => n.to_int()
    _ => 0
  }
  Ok({ id, name, parent_id, children_ids, user_count })
}

// Parse DepartmentUserCounts from @types.JsonValue

///|
fn parse_department_user_counts(
  obj : Map[String, @types.JsonValue],
) -> Result[DepartmentUserCounts, @errors.DirectError] {
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
      let counts = []
      for item in arr {
        match item {
          @types.JsonObject(count_obj) =>
            match parse_department_user_count(count_obj) {
              Ok(count) => counts.push(count)
              Err(_) => ()
            }
          _ => ()
        }
      }
      counts
    }
    _ => []
  }
  Ok({ domain_id, departments })
}

// Parse DepartmentUserCount from @types.JsonValue

///|
fn parse_department_user_count(
  obj : Map[String, @types.JsonValue],
) -> Result[DepartmentUserCount, @errors.DirectError] {
  let department_id = match obj.get("department_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => return Err(@errors.invalid_response("Invalid department_id"))
      }
    None => return Err(@errors.invalid_response("Missing department_id"))
  }
  let all = match obj.get("all") {
    Some(@types.JsonNumber(n)) => n.to_int()
    _ => 0
  }
  let partial = match obj.get("partial") {
    Some(@types.JsonNumber(n)) => n.to_int()
    _ => 0
  }
  Ok({ department_id, all, partial })
}

// Parse UserInfo from @types.JsonValue (shared with users module)

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
