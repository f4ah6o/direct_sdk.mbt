// MessagePack RPC protocol implementation
// Reference: direct-go-sdk/direct-go/client.go

// RPC protocol format:
// - Request:  [type, msgId, method, params]  where type = 0
// - Response: [type, msgId, error, result] where type = 1

// RPC Request type
///|
pub struct RpcRequest {
  msg_type : Int // Always @constants.RPC_REQUEST (0)
  msg_id : Int64
  method : String
  params : Array[@types.JsonValue]
}

// RPC Response type

///|
pub struct RpcResponse {
  msg_type : Int // Always @constants.RPC_RESPONSE (1)
  msg_id : Int64
  error : @types.JsonValue?
  result : @types.JsonValue
}

// Encode RPC request to MessagePack format
// Returns Result with byte array on success, @errors.DirectError on failure

///|
pub fn encode_request(
  req : RpcRequest,
) -> Result[Array[Byte], @errors.DirectError] {
  // Build array: [type, msgId, method, params]
  let arr = [
    @types.JsonNumber(Float::from_int(req.msg_type)),
    @types.JsonNumber(Float::from_int64(req.msg_id)),
    @types.JsonString(req.method),
    @types.JsonArray(req.params),
  ]
  match encode_json_value(@types.JsonArray(arr)) {
    Ok(bytes) => Ok(bytes)
    Err(e) => Err(@errors.decode_error("encode_request: " + e))
  }
}

// Decode MessagePack data to RPC response

///|
pub fn decode_response(
  data : Array[Byte],
) -> Result[RpcResponse, @errors.DirectError] {
  match decode_json_value(data) {
    Ok(@types.JsonArray(arr)) => {
      if arr.length() < 4 {
        return Err(@errors.invalid_response("Response too short"))
      }

      // Parse: [type, msgId, error, result]
      let msg_type = match arr[0] {
        @types.JsonNumber(n) => n.to_int()
        _ => 0
      }
      let msg_id = match arr[1] {
        @types.JsonNumber(n) => n.to_int().to_int64()
        _ => 0L
      }
      let error = if is_null_or_nil(arr[2]) { None } else { Some(arr[2]) }
      let result = arr[3]
      Ok({ msg_type, msg_id, error, result })
    }
    Ok(_) => Err(@errors.invalid_response("Expected array"))
    Err(e) => Err(@errors.decode_error("decode_response: " + e))
  }
}

// Encode notification from server (same format as request but different handling)

///|
pub fn encode_notification(
  method : String,
  params : Array[@types.JsonValue],
) -> Result[Array[Byte], @errors.DirectError] {
  let arr = [
    @types.JsonNumber(Float::from_int(@constants.RPC_REQUEST)),
    @types.JsonNumber(0.0), // msgId is 0 for notifications
    @types.JsonString(method),
    @types.JsonArray(params),
  ]
  match encode_json_value(@types.JsonArray(arr)) {
    Ok(bytes) => Ok(bytes)
    Err(e) => Err(@errors.decode_error("encode_notification: " + e))
  }
}

// Create RPC request

///|
pub fn create_request(
  msg_id : Int64,
  method : String,
  params : Array[@types.JsonValue],
) -> RpcRequest {
  { msg_type: @constants.RPC_REQUEST, msg_id, method, params }
}

// Helper: Check if @types.JsonValue is null or nil

///|
fn is_null_or_nil(v : @types.JsonValue) -> Bool {
  match v {
    @types.JsonNull => true
    _ => false
  }
}

// === Simple MessagePack-like Encoder ===
// This is a simplified encoder that creates a basic binary format.
// For production use, integrate with moonbit-community/msgpack.

// Encode @types.JsonValue to byte array (simplified MessagePack-like format)

///|
fn encode_json_value(_v : @types.JsonValue) -> Result[Array[Byte], String] {
  Err("MessagePack encoding not implemented")
}

// Decode byte array to @types.JsonValue (simplified MessagePack-like format)

///|
fn decode_json_value(_data : Array[Byte]) -> Result[@types.JsonValue, String] {
  Err("MessagePack decoding not implemented")
}

// === Byte conversion helpers (placeholders) ===

///|
fn float_to_bytes(_f : Float) -> Array[Byte] {
  []
}

///|
fn bytes_to_float(_bytes : Array[Byte]) -> Float {
  0.0
}

///|
fn int_to_bytes(_i : Int) -> Array[Byte] {
  []
}

///|
fn bytes_to_int(_bytes : Array[Byte]) -> Int {
  0
}

///|
fn string_to_bytes(_s : String) -> Array[Byte] {
  []
}

///|
fn bytes_to_string(_bytes : Array[Byte]) -> String {
  ""
}
