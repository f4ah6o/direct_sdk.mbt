// MessagePack RPC protocol implementation
// Reference: direct-go-sdk/direct-go/client.go

// RPC protocol format:
// - Request:  [type, msgId, method, params]  where type = 0
// - Response: [type, msgId, error, result] where type = 1

use moonbit.stdout/println

// RPC Request type
pub type RpcRequest = {
  msg_type : Int,  // Always RPC_REQUEST (0)
  msg_id   : Int64,
  method   : String,
  params   : Array[JsonValue],
}

// RPC Response type
pub type RpcResponse = {
  msg_type : Int,  // Always RPC_RESPONSE (1)
  msg_id   : Int64,
  error    : Option[JsonValue],
  result   : JsonValue,
}

// Encode RPC request to MessagePack format
// Returns Result with byte array on success, DirectError on failure
pub fn encode_request(req : RpcRequest) -> Result[Array[Byte], DirectError] {
  // Build array: [type, msgId, method, params]
  let arr = [
    JsonNumber(req.msg_type.to_float()),
    JsonNumber(req.msg_id.to_float()),
    JsonString(req.method),
    JsonArray(req.params),
  ]

  match encode_json_value(arr) {
    Ok(bytes) => Ok(bytes)
    Err(e) => Err(decode_error("encode_request: " + e))
  }
}

// Decode MessagePack data to RPC response
pub fn decode_response(data : Array[Byte]) -> Result[RpcResponse, DirectError] {
  match decode_json_value(data) {
    Ok(JsonArray(arr)) => {
      if arr.length() < 4 {
        return Err(invalid_response("Response too short"))
      }

      // Parse: [type, msgId, error, result]
      let msg_type = match arr[0] {
        | JsonNumber(n) => match n.to_int() { Some(i) => i | None => 0 }
        | _ => 0
      }

      let msg_id = match arr[1] {
        | JsonNumber(n) => n.to_int64().unwrap_or(0L)
        | _ => 0L
      }

      let error = if is_null_or_nil(arr[2]) { None } else { Some(arr[2]) }
      let result = arr[3]

      Ok({
        msg_type: msg_type,
        msg_id: msg_id,
        error: error,
        result: result,
      })
    }
    Ok(_) => Err(invalid_response("Expected array"))
    Err(e) => Err(decode_error("decode_response: " + e))
  }
}

// Encode notification from server (same format as request but different handling)
pub fn encode_notification(method : String, params : Array[JsonValue]) -> Result[Array[Byte], DirectError] {
  let arr = [
    JsonNumber(RPC_REQUEST.to_float()),
    JsonNumber(0.0),  // msgId is 0 for notifications
    JsonString(method),
    JsonArray(params),
  ]

  match encode_json_value(arr) {
    Ok(bytes) => Ok(bytes)
    Err(e) => Err(decode_error("encode_notification: " + e))
  }
}

// Create RPC request
pub fn create_request(msg_id : Int64, method : String, params : Array[JsonValue]) -> RpcRequest {
  {
    msg_type: RPC_REQUEST,
    msg_id: msg_id,
    method: method,
    params: params,
  }
}

// Helper: Check if JsonValue is null or nil
fn is_null_or_nil(v : JsonValue) -> Bool {
  match v {
    | JsonNull => true
    | _ => false
  }
}

// === Simple MessagePack-like Encoder ===
// This is a simplified encoder that creates a basic binary format.
// For production use, integrate with moonbit-community/msgpack.

// Encode JsonValue to byte array (simplified MessagePack-like format)
fn encode_json_value(v : JsonValue) -> Result[Array[Byte], String] {
  match v {
    | JsonNull => Ok([0xC0])  // MessagePack nil
    | JsonBool(b) => Ok(if b { [0xC3] } else { [0xC2] })  // MessagePack true/false
    | JsonNumber(n) => {
      // Encode as float64 (0xCB prefix + 8 bytes)
      let bytes = float_to_bytes(n);
      let mut result = [0xCB];
      result.extend(bytes);
      Ok(result)
    }
    | JsonString(s) => {
      // Encode as str32 (0xDB prefix + 4 bytes length + string bytes)
      let len = s.length();
      let len_bytes = int_to_bytes(len);
      let mut result = [0xDB];
      result.extend(len_bytes);
      result.extend(string_to_bytes(s));
      Ok(result)
    }
    | JsonArray(arr) => {
      // Encode as array32 (0xDD prefix + 4 bytes length + elements)
      let len = arr.length();
      let len_bytes = int_to_bytes(len);
      let mut result = [0xDD];
      result.extend(len_bytes);
      for elem in arr {
        match encode_json_value(elem) {
          Ok(bytes) => result.extend(bytes)
          Err(e) => return Err(e)
        }
      }
      Ok(result)
    }
    | JsonObject(obj) => {
      // Encode as map32 (0xDF prefix + 4 bytes length + key-value pairs)
      let len = obj.length();
      let len_bytes = int_to_bytes(len);
      let mut result = [0xDF];
      result.extend(len_bytes);
      for (key, val) in obj {
        match encode_json_value(JsonString(key)) {
          Ok(bytes) => result.extend(bytes)
          Err(e) => return Err(e)
        }
        match encode_json_value(val) {
          Ok(bytes) => result.extend(bytes)
          Err(e) => return Err(e)
        }
      }
      Ok(result)
    }
  }
}

// Decode byte array to JsonValue (simplified MessagePack-like format)
fn decode_json_value(data : Array[Byte]) -> Result[JsonValue, String] {
  if data.is_empty() {
    return Err("Empty data")
  }

  let format_byte = data[0];

  match format_byte {
    // nil
    | 0xC0 => Ok(JsonNull)

    // false
    | 0xC2 => Ok(JsonBool(false))

    // true
    | 0xC3 => Ok(JsonBool(true))

    // float64
    | 0xCB => {
      if data.length() < 9 {
        return Err("Invalid float64 data")
      }
      let bytes = data.slice(1, 9);
      let n = bytes_to_float(bytes);
      Ok(JsonNumber(n))
    }

    // str32
    | 0xDB => {
      if data.length() < 5 {
        return Err("Invalid str32 data")
      }
      let len_bytes = data.slice(1, 5);
      let len = bytes_to_int(len_bytes);
      if data.length() < 5 + len {
        return Err("Invalid str32 length")
      }
      let str_bytes = data.slice(5, 5 + len);
      Ok(JsonString(bytes_to_string(str_bytes)))
    }

    // array32
    | 0xDD => {
      if data.length() < 5 {
        return Err("Invalid array32 data")
      }
      let len_bytes = data.slice(1, 5);
      let len = bytes_to_int(len_bytes);
      let mut arr = [];
      let mut pos = 5;
      for _ = 0; len < pos; pos = pos + 1 {
        let remaining = data.slice(from = pos);
        // For simplicity, we'll need the full data to parse nested structures
        // This is a simplified implementation
        arr.push(JsonNull);
      }
      Ok(JsonArray(arr))
    }

    // map32
    | 0xDF => {
      if data.length() < 5 {
        return Err("Invalid map32 data")
      }
      let len_bytes = data.slice(1, 5);
      let len = bytes_to_int(len_bytes);
      let mut obj = Map::new();
      let mut pos = 5;
      for _ = 0; len < pos; pos = pos + 1 {
        // Simplified - just return empty map for now
        obj.insert("key", JsonNull);
      }
      Ok(JsonObject(obj))
    }

    | _ => Err("Unknown format byte: " + format_byte.to_string())
  }
}

// === Byte conversion helpers ===

// Convert float to 8 bytes (little-endian)
fn float_to_bytes(f : Float) -> Array[Byte] {
  // This is a simplified version
  // In production, use proper float-to-bytes conversion
  [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
}

// Convert 8 bytes to float (little-endian)
fn bytes_to_float(bytes : Array[Byte]) -> Float {
  // Simplified version
  0.0
}

// Convert int to 4 bytes (little-endian)
fn int_to_bytes(i : Int) -> Array[Byte] {
  [
    (i & 0xFF) as Byte,
    ((i >> 8) & 0xFF) as Byte,
    ((i >> 16) & 0xFF) as Byte,
    ((i >> 24) & 0xFF) as Byte,
  ]
}

// Convert 4 bytes to int (little-endian)
fn bytes_to_int(bytes : Array[Byte]) -> Int {
  let b0 = bytes[0].to_int()
  let b1 = bytes[1].to_int()
  let b2 = bytes[2].to_int()
  let b3 = bytes[3].to_int()
  b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
}

// Convert string to byte array
fn string_to_bytes(s : String) -> Array[Byte] {
  let mut bytes = [];
  let chars = s.to_char_array();
  for c in chars {
    bytes.push(c.to_int() as Byte);
  }
  bytes
}

// Convert byte array to string
fn bytes_to_string(bytes : Array[Byte]) -> String {
  let mut chars = [];
  for b in bytes {
    chars.push(b.to_char());
  }
  String::from_char_array(chars)
}
