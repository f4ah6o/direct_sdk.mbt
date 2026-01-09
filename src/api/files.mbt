// File and Attachment API for Direct SDK
// Reference: direct-go-sdk/direct-go/files.go

// Upload authentication credentials for file upload
pub type UploadAuth = {
  file_id   : types/ID,
  post_url  : String,
  post_form : Map[String, String],
  put_url   : String,
}

// File attachment information
pub type Attachment = {
  id          : types/ID,
  message_id  : types/ID,
  talk_id     : types/ID,
  file_id     : types/ID,
  name        : String,
  content_type : String,
  content_size : Int64,
  url         : String,
  created_at  : Int64,
}

// File preview information
pub type FilePreview = {
  file_id             : types/ID,
  status              : String,
  file_preview_file_id : types/ID,
  url                 : String,
  key                 : String,
}

// === File Upload Operations ===

// Create authentication credentials for uploading a file
// The use_type parameter specifies how the file will be used (e.g., "message", "profile")
// cfg(target="native")
pub async fn create_upload_auth(
  client : rpc/client/Client,
  filename     : String,
  content_type : String,
  size         : Int64,
  use_type     : String
) -> Result[UploadAuth, DirectError] {
  let params = [
    JsonString(filename),
    JsonString(content_type),
    JsonNumber(size.to_float()),
    JsonNumber(0.0),  // thumbnail flag (0 = no thumbnail)
    JsonString(use_type),
  ]

  let result = await rpc/client/call(client, METHOD_CREATE_UPLOAD_AUTH, params)?

  match result {
    | JsonObject(obj) => parse_upload_auth(obj)
    | _ => Err(invalid_response("Expected object"))
  }
}

// === Attachment Operations ===

// Get file attachments from a talk/conversation
// The limit parameter controls how many attachments to return (most recent first)
// cfg(target="native")
pub async fn get_attachments(
  client : rpc/client/Client,
  talk_id : types/ID,
  limit : Int
) -> Result[Array[Attachment], DirectError] {
  let params = [
    types/id_to_json(talk_id),
    JsonNumber(limit.to_float()),
  ]

  let result = await rpc/client/call(client, METHOD_GET_ATTACHMENTS, params)?

  match result {
    | JsonArray(arr) => {
      let mut attachments = []
      for item in arr {
        match item {
          | JsonObject(obj) => {
            match parse_attachment(obj) {
              | Ok(att) => attachments = attachments.push(att)
              | Err(_) => ()
            }
          }
          | _ => ()
        }
      }
      Ok(attachments)
    }
    | _ => Err(invalid_response("Expected array"))
  }
}

// Delete a file attachment from the system
// cfg(target="native")
pub async fn delete_attachment(
  client : rpc/client/Client,
  attachment_id : types/ID
) -> Result[Unit, DirectError] {
  let params = [types/id_to_json(attachment_id)]

  match await rpc/client/call(client, METHOD_DELETE_ATTACHMENT, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// Search for file attachments within a talk by filename or content
// cfg(target="native")
pub async fn search_attachments(
  client : rpc/client/Client,
  query : String,
  talk_id : types/ID
) -> Result[Array[Attachment], DirectError] {
  let params = [
    JsonString(query),
    types/id_to_json(talk_id),
  ]

  let result = await rpc/client/call(client, METHOD_SEARCH_ATTACHMENTS, params)?

  match result {
    | JsonArray(arr) => {
      let mut attachments = []
      for item in arr {
        match item {
          | JsonObject(obj) => {
            match parse_attachment(obj) {
              | Ok(att) => attachments = attachments.push(att)
              | Err(_) => ()
            }
          }
          | _ => ()
        }
      }
      Ok(attachments)
    }
    | _ => Err(invalid_response("Expected array"))
  }
}

// === File Preview Operations ===

// Generate a preview (thumbnail/image) for a file
// This is useful for displaying image or document previews in the UI
// cfg(target="native")
pub async fn create_file_preview(
  client : rpc/client/Client,
  file_id : types/ID
) -> Result[FilePreview, DirectError] {
  let params = [types/id_to_json(file_id)]

  let result = await rpc/client/call(client, METHOD_CREATE_FILE_PREVIEW, params)?

  match result {
    | JsonObject(obj) => parse_file_preview(obj)
    | _ => Err(invalid_response("Expected object"))
  }
}

// Retrieve an existing file preview if one has been generated
// cfg(target="native")
pub async fn get_file_preview(
  client : rpc/client/Client,
  file_id : types/ID
) -> Result[FilePreview, DirectError] {
  let params = [types/id_to_json(file_id)]

  let result = await rpc/client/call(client, METHOD_GET_FILE_PREVIEW, params)?

  match result {
    | JsonObject(obj) => parse_file_preview(obj)
    | _ => Err(invalid_response("Expected object"))
  }
}

// === Helper functions for parsing file data ===

// Parse UploadAuth from JsonValue
fn parse_upload_auth(obj : Map[String, JsonValue]) -> Result[UploadAuth, DirectError] {
  let file_id = match obj.get("file_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => types/IDString("")
    }
    | None => types/IDString("")
  }

  let post_url = match obj.get("post_url") {
    | Some(JsonString(s)) => s
    | _ => ""
  }

  let put_url = match obj.get("put_url") {
    | Some(JsonString(s)) => s
    | _ => ""
  }

  let post_form = match obj.get("post_form") {
    | Some(JsonObject(form)) => {
      let mut result = Map::new()
      for kv in form.to_array() {
        match kv.1 {
          | JsonString(s) => result.insert(kv.0, s)
          | _ => ()
        }
      }
      result
    }
    | _ => Map::new()
  }

  Ok({
    file_id: file_id,
    post_url: post_url,
    post_form: post_form,
    put_url: put_url,
  })
}

// Parse Attachment from JsonValue
fn parse_attachment(obj : Map[String, JsonValue]) -> Result[Attachment, DirectError] {
  let id = match obj.get("id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => return Err(invalid_response("Invalid id"))
    }
    | None => return Err(invalid_response("Missing id"))
  }

  let message_id = match obj.get("message_id") {
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

  let file_id = match obj.get("file_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => types/IDString("")
    }
    | None => types/IDString("")
  }

  let name = json_get_string(obj, "name").unwrap_or("")
  let content_type = json_get_string(obj, "content_type").unwrap_or("")
  let url = json_get_string(obj, "url").unwrap_or("")

  let content_size = match obj.get("content_size") {
    | Some(JsonNumber(n)) => n.to_int64().unwrap_or(0L)
    | _ => 0L
  }

  let created_at = match obj.get("created_at") {
    | Some(JsonNumber(n)) => n.to_int64().unwrap_or(0L)
    | _ => 0L
  }

  Ok({
    id: id,
    message_id: message_id,
    talk_id: talk_id,
    file_id: file_id,
    name: name,
    content_type: content_type,
    content_size: content_size,
    url: url,
    created_at: created_at,
  })
}

// Parse FilePreview from JsonValue
fn parse_file_preview(obj : Map[String, JsonValue]) -> Result[FilePreview, DirectError] {
  let file_id = match obj.get("file_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => types/IDString("")
    }
    | None => types/IDString("")
  }

  let file_preview_file_id = match obj.get("file_preview_file_id") {
    | Some(v) => match types/json_to_id(v) {
      | Some(id) => id
      | None => types/IDString("")
    }
    | None => types/IDString("")
  }

  let status = json_get_string(obj, "status").unwrap_or("")
  let url = json_get_string(obj, "url").unwrap_or("")
  let key = json_get_string(obj, "key").unwrap_or("")

  Ok({
    file_id: file_id,
    status: status,
    file_preview_file_id: file_preview_file_id,
    url: url,
    key: key,
  })
}

// Helper: Get string value from JsonObject
fn json_get_string(obj : Map[String, JsonValue], key : String) -> Option[String] {
  match obj.get(key) {
    | Some(JsonString(s)) => Some(s)
    | _ => None
  }
}
