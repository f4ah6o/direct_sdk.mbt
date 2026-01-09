// Conference/Call API for Direct SDK
// Reference: direct-go-sdk/direct-go/conference.go

// Video/audio conference information
pub type Conference = {
  id            : types/ID,
  user_id       : types/ID,
  domain_id     : types/ID,
  talk_id       : types/ID,
  message_id    : types/ID,
  created_at    : Int64,
  expired_at    : Int64,
  participants  : Array[types/ID],
  skyway_version : Int,
}

// Information for joining a conference
pub type ConferenceJoinInfo = {
  conference_id  : types/ID,
  room_name      : String,
  credential     : String,
  mode           : String,
  timestamp      : Int64,
  skyway_version : Int,
}

// === Conference Operations ===

// Get all active video/audio conferences the user can see
// cfg(target="native")
pub async fn get_conferences(client : rpc/client/Client) -> Result[Array[Conference], DirectError] {
  let result = await rpc/client/call(client, METHOD_GET_CONFERENCES, [])?

  match result {
    | JsonArray(arr) => {
      let mut conferences = []
      for item in arr {
        match item {
          | JsonObject(obj) => {
            match parse_conference(obj) {
              | Ok(conf) => conferences = conferences.push(conf)
              | Err(_) => ()
            }
          }
          | _ => ()
        }
      }
      Ok(conferences)
    }
    | _ => Err(invalid_response("Expected array"))
  }
}

// Get the list of users participating in a conference
// cfg(target="native")
pub async fn get_conference_participants(
  client : rpc/client/Client,
  conference_id : types/ID
) -> Result[Array[types/ID], DirectError] {
  let params = [types/id_to_json(conference_id)]

  let result = await rpc/client/call(client, METHOD_GET_CONFERENCE_PARTICIPANTS, params)?

  match result {
    | JsonArray(arr) => {
      let mut participants = []
      for item in arr {
        match types/json_to_id(item) {
          | Some(id) => participants = participants.push(id)
          | None => ()
        }
      }
      Ok(participants)
    }
    | _ => Err(invalid_response("Expected array"))
  }
}

// Join an active conference as a participant
// Returns ConferenceJoinInfo with room name, credentials, and connection details
// cfg(target="native")
pub async fn join_conference(
  client : rpc/client/Client,
  conference_id : types/ID
) -> Result[ConferenceJoinInfo, DirectError] {
  let params = [types/id_to_json(conference_id)]

  let result = await rpc/client/call(client, METHOD_JOIN_CONFERENCE, params)?

  match result {
    | JsonObject(obj) => parse_conference_join_info(obj)
    | _ => Err(invalid_response("Expected object"))
  }
}

// Disconnect the current user from an active conference
// cfg(target="native")
pub async fn leave_conference(
  client : rpc/client/Client,
  conference_id : types/ID
) -> Result[Unit, DirectError] {
  let params = [types/id_to_json(conference_id)]

  match await rpc/client/call(client, METHOD_LEAVE_CONFERENCE, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// Decline an invitation to join a conference
// cfg(target="native")
pub async fn reject_conference(
  client : rpc/client/Client,
  conference_id : types/ID
) -> Result[Unit, DirectError] {
  let params = [types/id_to_json(conference_id)]

  match await rpc/client/call(client, METHOD_REJECT_CONFERENCE, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// === Helper functions for parsing conference data ===

// Parse Conference from JsonValue
fn parse_conference(obj : Map[String, JsonValue]) -> Result[Conference, DirectError] {
  let id = match obj.get("id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => types/IDString("")
    }
    | None => match obj.get("conference_id") {
      | Some(v) => match types/json_to_id(v) {
        | Some(id) => id
        | None => types/IDString("")
      }
      | None => types/IDString("")
    }
  }

  let user_id = match obj.get("user_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => types/IDString("")
    }
    | None => types/IDString("")
  }

  let domain_id = match obj.get("domain_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => types/IDString("")
    }
    | None => types/IDString("")
  }

  let talk_id = match obj.get("talk_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => types/IDString("")
    }
    | None => types/IDString("")
  }

  let message_id = match obj.get("message_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => types/IDString("")
    }
    | None => types/IDString("")
  }

  let created_at = match obj.get("created_at") {
    | Some(JsonNumber(n)) => n.to_int64().unwrap_or(0L)
    | _ => 0L
  }

  let expired_at = match obj.get("expired_at") {
    | Some(JsonNumber(n)) => n.to_int64().unwrap_or(0L)
    | _ => 0L
  }

  let participants = match obj.get("participants") {
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

  let skyway_version = match obj.get("skyway_version") {
    | Some(JsonNumber(n)) => match n.to_int() {
      | Some(i) => i
      | None => 0
    }
    | _ => 0
  }

  Ok({
    id: id,
    user_id: user_id,
    domain_id: domain_id,
    talk_id: talk_id,
    message_id: message_id,
    created_at: created_at,
    expired_at: expired_at,
    participants: participants,
    skyway_version: skyway_version,
  })
}

// Parse ConferenceJoinInfo from JsonValue
fn parse_conference_join_info(obj : Map[String, JsonValue]) -> Result[ConferenceJoinInfo, DirectError] {
  let conference_id = match obj.get("conference_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => types/IDString("")
    }
    | None => types/IDString("")
  }

  let room_name = json_get_string(obj, "room_name").unwrap_or("")
  let credential = json_get_string(obj, "credential").unwrap_or("")
  let mode = json_get_string(obj, "mode").unwrap_or("")

  let timestamp = match obj.get("timestamp") {
    | Some(JsonNumber(n)) => n.to_int64().unwrap_or(0L)
    | _ => 0L
  }

  let skyway_version = match obj.get("skyway_version") {
    | Some(JsonNumber(n)) => match n.to_int() {
      | Some(i) => i
      | None => 0
    }
    | _ => 0
  }

  Ok({
    conference_id: conference_id,
    room_name: room_name,
    credential: credential,
    mode: mode,
    timestamp: timestamp,
    skyway_version: skyway_version,
  })
}

// Helper: Get string value from JsonObject
fn json_get_string(obj : Map[String, JsonValue], key : String) -> Option[String] {
  match obj.get(key) {
    | Some(JsonString(s)) => Some(s)
    | _ => None
  }
}
