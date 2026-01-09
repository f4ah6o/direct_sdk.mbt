// Action Stamps API for Direct SDK
// Reference: direct-go-sdk/daab-go-examples/selectstamp/main.go

// Select stamp content for sending action stamps

///|
pub struct SelectStampContent {
  question : String
  options : Array[String]
  listing : Bool
  closing_type : Int
}

// Select stamp reply content (received from user)

///|
pub struct SelectStampReply {
  question : String
  options : Array[String]
  response : Int // Selected index (0-based)
  in_reply_to : String // Original message ID
}

// Result type for parsing select stamp content

///|
pub enum SelectParseResult {
  SelectParseSuccess(SelectStampReply)
  SelectParseNotSelect // Not a select message
  SelectParseNoResponse // Select sent, not a reply
  SelectParseError(String) // Parse error
}

// Create a new select stamp content with default values

///|
pub fn new_select_content(
  question : String,
  options : Array[String],
) -> SelectStampContent {
  { question, options, listing: true, closing_type: 1 }
}

// Create select stamp content with custom listing

///|
pub fn select_content_with_listing(
  question : String,
  options : Array[String],
  listing : Bool,
) -> SelectStampContent {
  { question, options, listing, closing_type: 1 }
}

// Send a select action stamp to a room
// Returns the message ID on success
// cfg(target="native")

///|
pub async fn send_select(
  client : @rpc_client.Client,
  room_id : String,
  content : SelectStampContent,
) -> Result[String, @errors.DirectError] {
  // Build content object
  let content_map = Map::new()
  content_map["question"] = @types.JsonString(content.question)
  content_map["options"] = @types.JsonArray(
    content.options.map(fn(o) { @types.JsonString(o) }),
  )
  content_map["listing"] = @types.JsonBool(content.listing)
  content_map["closing_type"] = @types.JsonNumber(Float::from_int(content.closing_type))

  let content_json = @types.JsonObject(content_map)

  // Build params for create_message RPC call
  let params = [
    @types.JsonString(room_id),
    @types.JsonNumber(Float::from_int(@types.msg_type_to_wire(@types.MsgTypeSelect))),
    content_json,
  ]

  match @rpc_client.call(client, @constants.METHOD_CREATE_MESSAGE, params) {
    Ok(result) =>
      // Extract message ID from result
      match result {
        @types.JsonObject(obj) =>
          match obj.get("id") {
            Some(@types.JsonString(id)) => Ok(id)
            Some(@types.JsonNumber(n)) => Ok(n.to_string())
            _ => Ok("unknown")
          }
        @types.JsonString(id) => Ok(id)
        _ => Ok("unknown")
      }
    Err(e) => Err(e)
  }
}

// Parse select stamp content from a received message
// Returns SelectParseResult indicating the parse status

///|
pub fn parse_select_content(msg : @types.ReceivedMessage) -> SelectParseResult {
  // Check if this is a select stamp message (502 or 503)
  match msg.msg_type {
    @types.MsgTypeSelect => SelectParseNotSelect
    @types.MsgTypeSelectReply => parse_select_reply_content(msg)
    _ => SelectParseNotSelect
  }
}

// Parse select reply content from a MsgTypeSelectReply message

///|
fn parse_select_reply_content(
  msg : @types.ReceivedMessage,
) -> SelectParseResult {
  let content_map = match msg.content {
    @types.JsonObject(obj) => extract_content_from_raw(msg, obj)
    _ => return SelectParseError("Invalid content type")
  }
  match content_map {
    Ok(obj) => {
      let question = match obj.get("question") {
        Some(@types.JsonString(s)) => s
        _ => ""
      }
      let options = match obj.get("options") {
        Some(@types.JsonArray(arr)) => parse_string_array(arr)
        _ => []
      }
      match obj.get("response") {
        Some(@types.JsonNumber(n)) => {
          let response_idx = n.to_int()
          let in_reply_to = match obj.get("in_reply_to") {
            Some(@types.JsonString(s)) => s
            Some(@types.JsonNumber(num)) => num.to_string()
            _ => ""
          }
          SelectParseSuccess({
            question,
            options,
            response: response_idx,
            in_reply_to,
          })
        }
        _ => SelectParseNoResponse
      }
    }
    Err(e) => SelectParseError(e)
  }
}

// Extract content from message, falling back to raw data if needed

///|
fn extract_content_from_raw(
  msg : @types.ReceivedMessage,
  current_obj : Map[String, @types.JsonValue],
) -> Result[Map[String, @types.JsonValue], String] {
  // Check if we have the required fields in current object
  if current_obj.contains("question") && current_obj.contains("options") {
    return Ok(current_obj)
  }

  // Try to extract from raw data
  match msg.raw {
    Some(@types.JsonObject(raw_obj)) =>
      match raw_obj.get("content") {
        Some(@types.JsonObject(content_obj)) =>
          if content_obj.contains("question") &&
            content_obj.contains("options") {
            Ok(content_obj)
          } else {
            Err("Content not found in raw data")
          }
        _ => Err("Invalid raw content structure")
      }
    _ => Err("No raw data available")
  }
}

// Parse JSON array to string array

///|
fn parse_string_array(arr : Array[@types.JsonValue]) -> Array[String] {
  let result = []
  for item in arr {
    match item {
      @types.JsonString(s) => result.push(s)
      @types.JsonNumber(n) => result.push(n.to_string())
      _ => ()
    }
  }
  result
}

// Send a select stamp with simple question and options
// Convenience function for common use case
// cfg(target="native")

///|
pub async fn send_select_simple(
  client : @rpc_client.Client,
  room_id : String,
  question : String,
  options : Array[String],
) -> Result[String, @errors.DirectError] {
  let content = new_select_content(question, options)
  send_select(client, room_id, content)
}

// Get the selected option text from a SelectStampReply

///|
pub fn get_selected_option(reply : SelectStampReply) -> String? {
  if reply.response >= 0 && reply.response < reply.options.length() {
    Some(reply.options[reply.response])
  } else {
    None
  }
}

// Format SelectStampReply for display

///|
pub fn format_select_reply(reply : SelectStampReply) -> String {
  match get_selected_option(reply) {
    Some(option) =>
      "選択されたオプション: " + option + " (インデックス: " + reply.response.to_string() + ")"
    None =>
      "無効な選択 (インデックス: " + reply.response.to_string() + ")"
  }
}
