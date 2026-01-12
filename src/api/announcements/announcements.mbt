// Announcement API for Direct SDK
// Reference: direct-go-sdk/direct-go/announcements.go

// Announcement message

///|
pub struct Announcement {
  id : @types.ID
  domain_id : @types.ID
  title : String
  text : String
  created_by : @types.ID
  created_at : Int64
  updated_at : Int64
  target_user_ids : Array[@types.ID]
  read_user_ids : Array[@types.ID]
  unread_user_count : Int
}

// Announcement read status for a domain

///|
pub struct AnnouncementStatus {
  domain_id : @types.ID
  unread_count : Int
  max_announcement_id : @types.ID
  max_read_announcement_id : @types.ID
}

// === Announcement Operations ===

// Create a new announcement for specific users in a domain
// target_user_ids specifies which users will receive the announcement
// cfg(target="native")

///|
pub async fn create_announcement(
  client : @rpc_client.Client,
  domain_id : @types.ID,
  title : String,
  text : String,
  target_user_ids : Array[@types.ID],
) -> Result[Announcement, @errors.DirectError] {
  let params = [
    @types.id_to_json(domain_id),
    @types.JsonString(title),
    @types.JsonString(text),
    @types.JsonArray(target_user_ids.map(@types.id_to_json)),
  ]
  let result = match
    @rpc_client.call(client, @constants.METHOD_CREATE_ANNOUNCEMENT, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonObject(obj) => parse_announcement(obj)
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// Get all announcements for a domain
// cfg(target="native")

///|
pub async fn get_announcements(
  client : @rpc_client.Client,
  domain_id : @types.ID,
) -> Result[Array[Announcement], @errors.DirectError] {
  let params = [@types.id_to_json(domain_id)]
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_ANNOUNCEMENTS, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let announcements = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_announcement(obj) {
              Ok(ann) => announcements.push(ann)
              Err(_) => ()
            }
          _ => ()
        }
      }
      Ok(announcements)
    }
    _ => Err(@errors.invalid_response("Expected array"))
  }
}

// Get unread announcement counts for all domains
// cfg(target="native")

///|
pub async fn get_announcement_statuses(
  client : @rpc_client.Client,
) -> Result[Array[AnnouncementStatus], @errors.DirectError] {
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_ANNOUNCEMENT_STATUSES, []) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let statuses = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_announcement_status(obj) {
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

// Get announcement status for a specific domain
// cfg(target="native")

///|
pub async fn get_announcement_status(
  client : @rpc_client.Client,
  domain_id : @types.ID,
) -> Result[AnnouncementStatus, @errors.DirectError] {
  let params = [@types.id_to_json(domain_id)]
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_ANNOUNCEMENT_STATUS, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonObject(obj) => parse_announcement_status(obj)
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// Mark an announcement as read by the current user
// cfg(target="native")

///|
pub async fn update_announcement_status(
  client : @rpc_client.Client,
  domain_id : @types.ID,
  announcement_id : @types.ID,
) -> Result[Unit, @errors.DirectError] {
  let params = [
    @types.id_to_json(domain_id),
    @types.id_to_json(announcement_id),
  ]
  match
    @rpc_client.call(
      client,
      @constants.METHOD_UPDATE_ANNOUNCEMENT_STATUS,
      params,
    ) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// === Helper functions for parsing announcement data ===

// Parse Announcement from @types.JsonValue

///|
fn parse_announcement(
  obj : Map[String, @types.JsonValue],
) -> Result[Announcement, @errors.DirectError] {
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
  let title = json_get_string(obj, "title").unwrap_or("")
  let text = json_get_string(obj, "text").unwrap_or("")
  let created_by = match obj.get("created_by") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => @types.IDString("")
      }
    None => @types.IDString("")
  }
  let created_at = match obj.get("created_at") {
    Some(@types.JsonInt(i)) => i
    Some(@types.JsonNumber(n)) => n.to_int().to_int64()
    _ => 0L
  }
  let updated_at = match obj.get("updated_at") {
    Some(@types.JsonInt(i)) => i
    Some(@types.JsonNumber(n)) => n.to_int().to_int64()
    _ => 0L
  }
  let target_user_ids = match obj.get("target_user_ids") {
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
  let read_user_ids = match obj.get("read_user_ids") {
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
  let unread_user_count = match obj.get("unread_user_count") {
    Some(@types.JsonInt(i)) => i.to_int()
    Some(@types.JsonNumber(n)) => n.to_int()
    _ => 0
  }
  Ok({
    id,
    domain_id,
    title,
    text,
    created_by,
    created_at,
    updated_at,
    target_user_ids,
    read_user_ids,
    unread_user_count,
  })
}

// Parse AnnouncementStatus from @types.JsonValue

///|
fn parse_announcement_status(
  obj : Map[String, @types.JsonValue],
) -> Result[AnnouncementStatus, @errors.DirectError] {
  let domain_id = match obj.get("domain_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => return Err(@errors.invalid_response("Invalid domain_id"))
      }
    None => return Err(@errors.invalid_response("Missing domain_id"))
  }
  let unread_count = match obj.get("unread_count") {
    Some(@types.JsonInt(i)) => i.to_int()
    Some(@types.JsonNumber(n)) => n.to_int()
    _ => 0
  }
  let max_announcement_id = match obj.get("max_announcement_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => @types.IDString("")
      }
    None => @types.IDString("")
  }
  let max_read_announcement_id = match obj.get("max_read_announcement_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => @types.IDString("")
      }
    None => @types.IDString("")
  }
  Ok({ domain_id, unread_count, max_announcement_id, max_read_announcement_id })
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
