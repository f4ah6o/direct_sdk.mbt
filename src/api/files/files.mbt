// File and Attachment API for Direct SDK
// Reference: direct-go-sdk/direct-go/files.go

// Upload authentication credentials for file upload

///|
pub struct UploadAuth {
  file_id : @types.ID
  post_url : String
  post_form : Map[String, String]
  put_url : String
}

// Download authentication credentials for file download

///|
pub struct DownloadAuth {
  file_id : @types.ID
  url : String
  headers : Map[String, String]
}

// File attachment information

///|
pub struct Attachment {
  id : @types.ID
  message_id : @types.ID
  talk_id : @types.ID
  file_id : @types.ID
  name : String
  content_type : String
  content_size : Int64
  url : String
  created_at : Int64
}

// File preview information

///|
pub struct FilePreview {
  file_id : @types.ID
  status : String
  file_preview_file_id : @types.ID
  url : String
  key : String
}

// === File Upload Operations ===

// Create authentication credentials for uploading a file
// The use_type parameter specifies how the file will be used (e.g., "message", "profile")
// cfg(target="native")

///|
pub async fn create_upload_auth(
  client : @rpc_client.Client,
  filename : String,
  content_type : String,
  size : Int64,
  use_type : String,
) -> Result[UploadAuth, @errors.DirectError] {
  let params = [
    @types.JsonString(filename),
    @types.JsonString(content_type),
    @types.JsonInt(size),
    @types.JsonNumber(0.0), // thumbnail flag (0 = no thumbnail)
    @types.JsonString(use_type),
  ]
  let result = match
    @rpc_client.call(client, @constants.METHOD_CREATE_UPLOAD_AUTH, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonObject(obj) => parse_upload_auth(obj)
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// Create authentication credentials for downloading a file.
// Parameters are: talk_id, message_id, file_id.
// cfg(target="native")

///|
pub async fn create_download_auth(
  client : @rpc_client.Client,
  talk_id : @types.ID,
  message_id : @types.ID,
  file_id : @types.ID,
) -> Result[DownloadAuth, @errors.DirectError] {
  let params = create_download_auth_params(talk_id, message_id, file_id)
  let result = match
    @rpc_client.call(client, @constants.METHOD_CREATE_DOWNLOAD_AUTH, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonObject(obj) => parse_download_auth(obj)
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// === Attachment Operations ===

// Get file attachments from a talk/conversation
// The limit parameter controls how many attachments to return (most recent first)
// cfg(target="native")

///|
pub async fn get_attachments(
  client : @rpc_client.Client,
  talk_id : @types.ID,
  limit : Int,
) -> Result[Array[Attachment], @errors.DirectError] {
  let params = [
    id_to_rpc_json(talk_id),
    @types.JsonInt(limit.to_int64()),
    @types.JsonNull,
    @types.JsonNull,
  ]
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_ATTACHMENTS, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let attachments = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_attachment(obj) {
              Ok(att) => attachments.push(att)
              Err(_) => ()
            }
          _ => ()
        }
      }
      Ok(attachments)
    }
    _ => Err(@errors.invalid_response("Expected array"))
  }
}

// Delete a file attachment from the system
// cfg(target="native")

///|
pub async fn delete_attachment(
  client : @rpc_client.Client,
  attachment_id : @types.ID,
) -> Result[Unit, @errors.DirectError] {
  let params = [@types.id_to_json(attachment_id)]
  match @rpc_client.call(client, @constants.METHOD_DELETE_ATTACHMENT, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// Search for file attachments within a talk by filename or content
// cfg(target="native")

///|
pub async fn search_attachments(
  client : @rpc_client.Client,
  query : String,
  talk_id : @types.ID,
) -> Result[Array[Attachment], @errors.DirectError] {
  let params = [@types.JsonString(query), @types.id_to_json(talk_id)]
  let result = match
    @rpc_client.call(client, @constants.METHOD_SEARCH_ATTACHMENTS, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonArray(arr) => {
      let attachments = []
      for item in arr {
        match item {
          @types.JsonObject(obj) =>
            match parse_attachment(obj) {
              Ok(att) => attachments.push(att)
              Err(_) => ()
            }
          _ => ()
        }
      }
      Ok(attachments)
    }
    _ => Err(@errors.invalid_response("Expected array"))
  }
}

// === File Preview Operations ===

// Generate a preview (thumbnail/image) for a file
// This is useful for displaying image or document previews in the UI
// cfg(target="native")

///|
pub async fn create_file_preview(
  client : @rpc_client.Client,
  file_id : @types.ID,
) -> Result[FilePreview, @errors.DirectError] {
  let params = [@types.id_to_json(file_id)]
  let result = match
    @rpc_client.call(client, @constants.METHOD_CREATE_FILE_PREVIEW, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonObject(obj) => parse_file_preview(obj)
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// Retrieve an existing file preview if one has been generated
// cfg(target="native")

///|
pub async fn get_file_preview(
  client : @rpc_client.Client,
  file_id : @types.ID,
) -> Result[FilePreview, @errors.DirectError] {
  let params = [@types.id_to_json(file_id)]
  let result = match
    @rpc_client.call(client, @constants.METHOD_GET_FILE_PREVIEW, params) {
    Ok(value) => value
    Err(e) => return Err(e)
  }
  match result {
    @types.JsonObject(obj) => parse_file_preview(obj)
    _ => Err(@errors.invalid_response("Expected object"))
  }
}

// === Helper functions for parsing file data ===

// Parse DownloadAuth from @types.JsonValue

///|
fn parse_download_auth(
  obj : Map[String, @types.JsonValue],
) -> Result[DownloadAuth, @errors.DirectError] {
  let file_id = match obj.get("file_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => @types.IDString("")
      }
    None => @types.IDString("")
  }
  let url = match obj.get("get_url") {
    Some(@types.JsonString(s)) => s
    _ => ""
  }
  let headers = match obj.get("get_headers") {
    Some(@types.JsonObject(raw)) => {
      let result = Map::new()
      for kv in raw.to_array() {
        match kv.1 {
          @types.JsonString(s) => result[kv.0] = s
          _ => ()
        }
      }
      result
    }
    _ => Map::new()
  }
  Ok({ file_id, url, headers })
}

///|
fn id_to_rpc_json(id : @types.ID) -> @types.JsonValue {
  match id {
    @types.IDInt(i) => @types.JsonInt(i)
    @types.IDString(s) =>
      match @types.string_to_id(s) {
        @types.IDInt(i) => @types.JsonInt(i)
        @types.IDString(_) => @types.JsonString(s)
      }
  }
}

///|
fn create_download_auth_params(
  talk_id : @types.ID,
  message_id : @types.ID,
  file_id : @types.ID,
) -> Array[@types.JsonValue] {
  [id_to_rpc_json(talk_id), id_to_rpc_json(message_id), id_to_rpc_json(file_id)]
}

// Parse UploadAuth from @types.JsonValue

///|
fn parse_upload_auth(
  obj : Map[String, @types.JsonValue],
) -> Result[UploadAuth, @errors.DirectError] {
  let file_id = match obj.get("file_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => @types.IDString("")
      }
    None => @types.IDString("")
  }
  let post_url = match obj.get("post_url") {
    Some(@types.JsonString(s)) => s
    _ => ""
  }
  let put_url = match obj.get("put_url") {
    Some(@types.JsonString(s)) => s
    _ => ""
  }
  let post_form = match obj.get("post_form") {
    Some(@types.JsonObject(form)) => {
      let result = Map::new()
      for kv in form.to_array() {
        match kv.1 {
          @types.JsonString(s) => result[kv.0] = s
          _ => ()
        }
      }
      result
    }
    _ => Map::new()
  }
  Ok({ file_id, post_url, post_form, put_url })
}

// Parse Attachment from @types.JsonValue

///|
fn parse_attachment(
  obj : Map[String, @types.JsonValue],
) -> Result[Attachment, @errors.DirectError] {
  let id = match obj.get("id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => return Err(@errors.invalid_response("Invalid id"))
      }
    None =>
      match obj.get("attachment_id") {
        Some(v) =>
          match @types.json_to_id(v) {
            Some(id) => id
            None =>
              return Err(@errors.invalid_response("Invalid attachment_id"))
          }
        None => return Err(@errors.invalid_response("Missing id"))
      }
  }
  let message_id = match obj.get("message_id") {
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
  let file_id = match obj.get("file_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => @types.IDString("")
      }
    None => @types.IDString("")
  }
  let name = json_get_string(obj, "name").unwrap_or("")
  let content_type = json_get_string(obj, "content_type").unwrap_or("")
  let url = json_get_string(obj, "url").unwrap_or("")
  let content_size = match obj.get("content_size") {
    Some(@types.JsonInt(i)) => i
    Some(@types.JsonNumber(n)) => n.to_int().to_int64()
    _ => 0L
  }
  let created_at = match obj.get("created_at") {
    Some(@types.JsonInt(i)) => i
    Some(@types.JsonNumber(n)) => n.to_int().to_int64()
    _ => 0L
  }
  Ok({
    id,
    message_id,
    talk_id,
    file_id,
    name,
    content_type,
    content_size,
    url,
    created_at,
  })
}

// Parse FilePreview from @types.JsonValue

///|
fn parse_file_preview(
  obj : Map[String, @types.JsonValue],
) -> Result[FilePreview, @errors.DirectError] {
  let file_id = match obj.get("file_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => @types.IDString("")
      }
    None => @types.IDString("")
  }
  let file_preview_file_id = match obj.get("file_preview_file_id") {
    Some(v) =>
      match @types.json_to_id(v) {
        Some(id) => id
        None => @types.IDString("")
      }
    None => @types.IDString("")
  }
  let status = json_get_string(obj, "status").unwrap_or("")
  let url = json_get_string(obj, "url").unwrap_or("")
  let key = json_get_string(obj, "key").unwrap_or("")
  Ok({ file_id, status, file_preview_file_id, url, key })
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
