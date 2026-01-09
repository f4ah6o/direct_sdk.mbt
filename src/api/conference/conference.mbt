// Conference/Call API for Direct SDK
// Reference: direct-go-sdk/direct-go/conference.go

// Video/audio conference information

///|
pub struct Conference {
  id : @types.ID
  user_id : @types.ID
  domain_id : @types.ID
  talk_id : @types.ID
  message_id : @types.ID
  created_at : Int64
  expired_at : Int64
  participants : Array[@types.ID]
  skyway_version : Int
}

// Information for joining a conference

///|
pub struct ConferenceJoinInfo {
  conference_id : @types.ID
  room_name : String
  credential : String
  mode : String
  timestamp : Int64
  skyway_version : Int
}

// === Conference Operations ===

// Get all active video/audio conferences the user can see
// cfg(target="native")

///|
pub async fn get_conferences(
  client : @rpc_client.Client,
) -> Result[Array[Conference], @errors.DirectError] {
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_CONFERENCES, []) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let conferences = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_conference(obj) {
              Ok(conf) => conferences.push(conf)
              Err(_) => ()
            }
          _ => ()
        }
      }
      Ok(conferences)
    }
    _ => Err(@errors.invalid_response("Expected array"))
  }
}

// Get the list of users participating in a conference
// cfg(target="native")

///|
pub async fn get_conference_participants(
  client : @rpc_client.Client,
  conference_id : @types.ID,
) -> Result[Array[@types.ID], @errors.DirectError] {
  let params = [@types.id_to_json(conference_id)]
  let result = match
    @rpc_client.call(
      client,
      @constants.METHOD_GET_CONFERENCE_PARTICIPANTS,
      params,
    ) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let participants = []
      for item in arr {
        match @types.json_to_id(item) {
          Some(id) => participants.push(id)
          None => ()
        }
      }
      Ok(participants)
    }
    _ => Err(@errors.invalid_response("Expected array"))
  }
}

// Join an active conference as a participant
// Returns ConferenceJoinInfo with room name, credentials, and connection details
// cfg(target="native")

///|
pub async fn join_conference(
  client : @rpc_client.Client,
  conference_id : @types.ID,
) -> Result[ConferenceJoinInfo, @errors.DirectError] {
  let params = [@types.id_to_json(conference_id)]
  let result = match
    @rpc_client.call(client, @constants.METHOD_JOIN_CONFERENCE, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonObject(obj) => parse_conference_join_info(obj)
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// Disconnect the current user from an active conference
// cfg(target="native")

///|
pub async fn leave_conference(
  client : @rpc_client.Client,
  conference_id : @types.ID,
) -> Result[Unit, @errors.DirectError] {
  let params = [@types.id_to_json(conference_id)]
  match @rpc_client.call(client, @constants.METHOD_LEAVE_CONFERENCE, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// Decline an invitation to join a conference
// cfg(target="native")

///|
pub async fn reject_conference(
  client : @rpc_client.Client,
  conference_id : @types.ID,
) -> Result[Unit, @errors.DirectError] {
  let params = [@types.id_to_json(conference_id)]
  match @rpc_client.call(client, @constants.METHOD_REJECT_CONFERENCE, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// === Helper functions for parsing conference data ===

// Parse Conference from @types.JsonValue

///|
fn parse_conference(
  obj : Map[String, @types.JsonValue],
) -> Result[Conference, @errors.DirectError] {
  let id = match obj.get("id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => @types.IDString("")
      }
    None =>
      match obj.get("conference_id") {
        Some(v) =>
          match @types.json_to_id(v) {
            Some(id) => id
            None => @types.IDString("")
          }
        None => @types.IDString("")
      }
  }
  let user_id = match obj.get("user_id") {
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
  let talk_id = match obj.get("talk_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => @types.IDString("")
      }
    None => @types.IDString("")
  }
  let message_id = match obj.get("message_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => @types.IDString("")
      }
    None => @types.IDString("")
  }
  let created_at = match obj.get("created_at") {
    Some(@types.JsonNumber(n)) => n.to_int().to_int64()
    _ => 0L
  }
  let expired_at = match obj.get("expired_at") {
    Some(@types.JsonNumber(n)) => n.to_int().to_int64()
    _ => 0L
  }
  let participants = match obj.get("participants") {
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
  let skyway_version = match obj.get("skyway_version") {
    Some(@types.JsonNumber(n)) => n.to_int()
    _ => 0
  }
  Ok({
    id,
    user_id,
    domain_id,
    talk_id,
    message_id,
    created_at,
    expired_at,
    participants,
    skyway_version,
  })
}

// Parse ConferenceJoinInfo from @types.JsonValue

///|
fn parse_conference_join_info(
  obj : Map[String, @types.JsonValue],
) -> Result[ConferenceJoinInfo, @errors.DirectError] {
  let conference_id = match obj.get("conference_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => @types.IDString("")
      }
    None => @types.IDString("")
  }
  let room_name = json_get_string(obj, "room_name").unwrap_or("")
  let credential = json_get_string(obj, "credential").unwrap_or("")
  let mode = json_get_string(obj, "mode").unwrap_or("")
  let timestamp = match obj.get("timestamp") {
    Some(@types.JsonNumber(n)) => n.to_int().to_int64()
    _ => 0L
  }
  let skyway_version = match obj.get("skyway_version") {
    Some(@types.JsonNumber(n)) => n.to_int()
    _ => 0
  }
  Ok({ conference_id, room_name, credential, mode, timestamp, skyway_version })
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
