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

///|
pub enum RpcMessage {
  Request(RpcRequest)
  Response(RpcResponse)
}

// Encode RPC request to MessagePack format
// Returns Result with bytes on success, @errors.DirectError on failure

///|
pub fn encode_request(req : RpcRequest) -> Result[Bytes, @errors.DirectError] {
  // Build array: [type, msgId, method, params]
  let arr = [
    @types.JsonInt(Int64::from_int(req.msg_type)),
    @types.JsonInt(req.msg_id),
    @types.JsonString(req.method),
    @types.JsonArray(req.params),
  ]
  match encode_json_value(@types.JsonArray(arr)) {
    Ok(bytes) => Ok(bytes)
    Err(e) => Err(@errors.decode_error("encode_request: " + e))
  }
}

// Decode MessagePack data to RPC message

///|
pub fn decode_message(data : Bytes) -> Result[RpcMessage, @errors.DirectError] {
  match decode_json_value(data) {
    Ok(@types.JsonArray(arr)) => {
      if arr.length() < 4 {
        return Err(@errors.invalid_response("Response too short"))
      }
      let msg_type = match json_number_to_int(arr[0]) {
        Ok(value) => value
        Err(msg) => return Err(@errors.invalid_response(msg))
      }
      let msg_id = match json_number_to_int64(arr[1]) {
        Ok(value) => value
        Err(msg) => return Err(@errors.invalid_response(msg))
      }
      if msg_type == @constants.RPC_REQUEST {
        let method = match arr[2] {
          @types.JsonString(value) => value
          _ =>
            return Err(
              @errors.invalid_response("Request method must be string"),
            )
        }
        let params = match arr[3] {
          @types.JsonArray(values) => values
          _ =>
            return Err(@errors.invalid_response("Request params must be array"))
        }
        Ok(Request({ msg_type, msg_id, method, params }))
      } else if msg_type == @constants.RPC_RESPONSE {
        let error = if is_null_or_nil(arr[2]) { None } else { Some(arr[2]) }
        let result = arr[3]
        Ok(Response({ msg_type, msg_id, error, result }))
      } else {
        Err(@errors.invalid_response("Unknown message type"))
      }
    }
    Ok(_) => Err(@errors.invalid_response("Expected array"))
    Err(e) => Err(@errors.decode_error("decode_message: " + e))
  }
}

// Decode MessagePack data to RPC response

///|
pub fn decode_response(
  data : Bytes,
) -> Result[RpcResponse, @errors.DirectError] {
  match decode_message(data) {
    Ok(Response(resp)) => Ok(resp)
    Ok(Request(_)) => Err(@errors.invalid_response("Expected response message"))
    Err(e) => Err(e)
  }
}

// Encode notification from server (same format as request but different handling)

///|
pub fn encode_notification(
  method : String,
  params : Array[@types.JsonValue],
) -> Result[Bytes, @errors.DirectError] {
  let arr = [
    @types.JsonInt(Int64::from_int(@constants.RPC_REQUEST)),
    @types.JsonInt(0L), // msgId is 0 for notifications
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

///|
fn json_number_to_int(value : @types.JsonValue) -> Result[Int, String] {
  match value {
    @types.JsonInt(i) => {
      let int_val = i.to_int()
      if Int64::from_int(int_val) == i {
        Ok(int_val)
      } else {
        Err("Expected integer number")
      }
    }
    @types.JsonNumber(n) => {
      let int_val = n.to_int()
      if Float::from_int(int_val) == n {
        Ok(int_val)
      } else {
        Err("Expected integer number")
      }
    }
    _ => Err("Expected numeric value")
  }
}

///|
fn json_number_to_int64(value : @types.JsonValue) -> Result[Int64, String] {
  match value {
    @types.JsonInt(i) => Ok(i)
    _ =>
      match json_number_to_int(value) {
        Ok(int_val) => Ok(Int64::from_int(int_val))
        Err(msg) => Err(msg)
      }
  }
}

// === MessagePack Encoder ===

///|
priv struct Encoder {
  buf : Array[Byte]
}

///|
fn Encoder::new() -> Encoder {
  { buf: [] }
}

///|
fn Encoder::push_byte(self : Encoder, value : Byte) -> Unit {
  self.buf.push(value)
}

///|
fn Encoder::push_bytes(self : Encoder, bytes : Bytes) -> Unit {
  for b in bytes {
    self.buf.push(b)
  }
}

///|
fn Encoder::push_u16(self : Encoder, value : Int) -> Unit {
  let tmp = FixedArray::make(2, b'\x00')
  tmp.unsafe_write_uint16_be(0, value.to_uint16())
  for b in tmp {
    self.buf.push(b)
  }
}

///|
fn Encoder::push_u32(self : Encoder, value : Int) -> Unit {
  let tmp = FixedArray::make(4, b'\x00')
  let u = UInt::trunc_double(value.to_double())
  tmp.unsafe_write_uint32_be(0, u)
  for b in tmp {
    self.buf.push(b)
  }
}

///|
fn Encoder::push_u32_from_uint64(self : Encoder, value : UInt64) -> Unit {
  let bytes = value.to_be_bytes()
  for i = 4; i < 8; i = i + 1 {
    self.buf.push(bytes[i])
  }
}

///|
fn Encoder::push_u64(self : Encoder, value : UInt64) -> Unit {
  let bytes = value.to_be_bytes()
  for b in bytes {
    self.buf.push(b)
  }
}

///|
fn Encoder::to_bytes(self : Encoder) -> Bytes {
  Bytes::from_array(self.buf)
}

///|
fn encode_json_value(v : @types.JsonValue) -> Result[Bytes, String] {
  let enc = Encoder::new()
  match encode_value(enc, v) {
    Ok(_) => Ok(enc.to_bytes())
    Err(msg) => Err(msg)
  }
}

///|
fn encode_value(enc : Encoder, v : @types.JsonValue) -> Result[Unit, String] {
  match v {
    @types.JsonNull => {
      enc.push_byte(0xc0)
      Ok(())
    }
    @types.JsonBool(value) => {
      enc.push_byte(if value { 0xc3 } else { 0xc2 })
      Ok(())
    }
    @types.JsonNumber(value) => encode_number(enc, value)
    @types.JsonInt(value) => {
      encode_int64(enc, value)
      Ok(())
    }
    @types.JsonString(value) => encode_string(enc, value)
    @types.JsonArray(values) => encode_array(enc, values)
    @types.JsonObject(values) => encode_map(enc, values)
  }
}

///|
fn encode_number(enc : Encoder, value : Float) -> Result[Unit, String] {
  let int_val = value.to_int()
  if Float::from_int(int_val) == value {
    encode_int(enc, int_val)
    Ok(())
  } else {
    encode_float(enc, value)
    Ok(())
  }
}

///|
fn encode_int(enc : Encoder, value : Int) -> Unit {
  if value >= 0 {
    if value <= 0x7f {
      enc.push_byte(value.to_byte())
    } else if value <= 0xff {
      enc.push_byte(0xcc)
      enc.push_byte(value.to_byte())
    } else if value <= 0xffff {
      enc.push_byte(0xcd)
      enc.push_u16(value)
    } else if value <= 0xffff_ffff {
      enc.push_byte(0xce)
      enc.push_u32(value)
    } else {
      enc.push_byte(0xcf)
      enc.push_u64(UInt64::trunc_double(value.to_double()))
    }
  } else if value >= -32 {
    enc.push_byte((value + 256).to_byte())
  } else if value >= -128 {
    enc.push_byte(0xd0)
    enc.push_byte((value + 256).to_byte())
  } else if value >= -32_768 {
    enc.push_byte(0xd1)
    enc.push_u16(value + 65_536)
  } else if value >= -2_147_483_648 {
    enc.push_byte(0xd2)
    let u = Int64::from_int(value).reinterpret_as_uint64()
    enc.push_u32_from_uint64(u)
  } else {
    enc.push_byte(0xd3)
    let i64 = Int64::from_int(value)
    enc.push_u64(i64.reinterpret_as_uint64())
  }
}

///|
fn encode_int64(enc : Encoder, value : Int64) -> Unit {
  if value >= 0L {
    let u = value.reinterpret_as_uint64()
    if value <= 0x7fL {
      enc.push_byte(value.to_byte())
    } else if value <= 0xffL {
      enc.push_byte(0xcc)
      enc.push_byte(value.to_byte())
    } else if value <= 0xffffL {
      enc.push_byte(0xcd)
      enc.push_u16(value.to_int())
    } else if value <= 4_294_967_295L {
      enc.push_byte(0xce)
      enc.push_u32_from_uint64(u)
    } else {
      enc.push_byte(0xcf)
      enc.push_u64(u)
    }
  } else if value >= -32L {
    enc.push_byte((value.to_int() + 256).to_byte())
  } else if value >= -128L {
    enc.push_byte(0xd0)
    enc.push_byte((value.to_int() + 256).to_byte())
  } else if value >= -32_768L {
    enc.push_byte(0xd1)
    enc.push_u16(value.to_int() + 65_536)
  } else if value >= -2_147_483_648L {
    enc.push_byte(0xd2)
    enc.push_u32_from_uint64(value.reinterpret_as_uint64())
  } else {
    enc.push_byte(0xd3)
    enc.push_u64(value.reinterpret_as_uint64())
  }
}

///|
fn encode_float(enc : Encoder, value : Float) -> Unit {
  enc.push_byte(0xcb)
  enc.push_bytes(value.to_be_bytes())
}

///|
fn encode_string(enc : Encoder, value : String) -> Result[Unit, String] {
  let bytes = @encoding/utf8.encode(value)
  let len = bytes.length()
  if len <= 31 {
    enc.push_byte((0xa0 + len).to_byte())
  } else if len <= 0xff {
    enc.push_byte(0xd9)
    enc.push_byte(len.to_byte())
  } else if len <= 0xffff {
    enc.push_byte(0xda)
    enc.push_u16(len)
  } else {
    enc.push_byte(0xdb)
    enc.push_u32(len)
  }
  enc.push_bytes(bytes)
  Ok(())
}

///|
fn encode_array(
  enc : Encoder,
  values : Array[@types.JsonValue],
) -> Result[Unit, String] {
  let len = values.length()
  if len < 16 {
    enc.push_byte((0x90 + len).to_byte())
  } else if len <= 0xffff {
    enc.push_byte(0xdc)
    enc.push_u16(len)
  } else {
    enc.push_byte(0xdd)
    enc.push_u32(len)
  }
  for value in values {
    match encode_value(enc, value) {
      Ok(_) => ()
      Err(msg) => return Err(msg)
    }
  }
  Ok(())
}

///|
fn encode_map(
  enc : Encoder,
  values : Map[String, @types.JsonValue],
) -> Result[Unit, String] {
  let len = values.length()
  if len < 16 {
    enc.push_byte((0x80 + len).to_byte())
  } else if len <= 0xffff {
    enc.push_byte(0xde)
    enc.push_u16(len)
  } else {
    enc.push_byte(0xdf)
    enc.push_u32(len)
  }
  for key, value in values {
    match encode_string(enc, key) {
      Ok(_) => ()
      Err(msg) => return Err(msg)
    }
    match encode_value(enc, value) {
      Ok(_) => ()
      Err(msg) => return Err(msg)
    }
  }
  Ok(())
}

// === MessagePack Decoder ===

///|
priv struct Decoder {
  data : Bytes
  mut pos : Int
}

///|
fn Decoder::new(data : Bytes) -> Decoder {
  { data, pos: 0 }
}

///|
fn Decoder::read_byte(self : Decoder) -> Result[Byte, String] {
  if self.pos >= self.data.length() {
    return Err("Unexpected end of input")
  }
  let value = self.data[self.pos]
  self.pos += 1
  Ok(value)
}

///|
fn Decoder::read_bytes(self : Decoder, len : Int) -> Result[Bytes, String] {
  let end_pos = self.pos + len
  if end_pos > self.data.length() {
    return Err("Unexpected end of input")
  }
  let view = self.data[self.pos:end_pos]
  self.pos = end_pos
  Ok(view.to_bytes())
}

///|
fn Decoder::read_uint(self : Decoder, len : Int) -> Result[UInt64, String] {
  let mut acc : UInt64 = 0
  for _ in 0..<len {
    match self.read_byte() {
      Ok(b) => acc = (acc << 8) | b.to_uint64()
      Err(msg) => return Err(msg)
    }
  }
  Ok(acc)
}

///|
fn Decoder::read_int(self : Decoder, bits : Int) -> Result[Int64, String] {
  let value = self.read_uint(bits / 8)
  match value {
    Ok(raw) =>
      if bits == 64 {
        Ok(raw.reinterpret_as_int64())
      } else {
        let sign_bit : UInt64 = 1
        let sign_bit = sign_bit << (bits - 1)
        if (raw & sign_bit) != 0 {
          let max : UInt64 = 1
          let max = max << bits
          Ok(raw.sub(max).reinterpret_as_int64())
        } else {
          Ok(raw.reinterpret_as_int64())
        }
      }
    Err(msg) => Err(msg)
  }
}

///|
fn decode_json_value(data : Bytes) -> Result[@types.JsonValue, String] {
  let dec = Decoder::new(data)
  let value = match decode_value(dec) {
    Ok(v) => v
    Err(msg) => return Err(msg)
  }
  if dec.pos != data.length() {
    return Err("Trailing data")
  }
  Ok(value)
}

///|
fn decode_value(dec : Decoder) -> Result[@types.JsonValue, String] {
  let prefix = match dec.read_byte() {
    Ok(value) => value.to_int()
    Err(msg) => return Err(msg)
  }
  if prefix <= 0x7f {
    return Ok(@types.JsonInt(Int64::from_int(prefix)))
  }
  if prefix >= 0xe0 {
    return Ok(@types.JsonInt(Int64::from_int(prefix - 256)))
  }
  if prefix >= 0x80 && prefix <= 0x8f {
    let len = prefix - 0x80
    return decode_map(dec, len)
  }
  if prefix >= 0x90 && prefix <= 0x9f {
    let len = prefix - 0x90
    return decode_array(dec, len)
  }
  if prefix >= 0xa0 && prefix <= 0xbf {
    let len = prefix - 0xa0
    return decode_string(dec, len)
  }
  match prefix {
    0xc0 => Ok(@types.JsonNull)
    0xc2 => Ok(@types.JsonBool(false))
    0xc3 => Ok(@types.JsonBool(true))
    0xcc =>
      match dec.read_byte() {
        Ok(value) => Ok(@types.JsonInt(Int64::from_int(value.to_int())))
        Err(msg) => Err(msg)
      }
    0xcd =>
      match dec.read_uint(2) {
        Ok(value) => Ok(@types.JsonInt(value.reinterpret_as_int64()))
        Err(msg) => Err(msg)
      }
    0xce =>
      match dec.read_uint(4) {
        Ok(value) => Ok(@types.JsonInt(value.reinterpret_as_int64()))
        Err(msg) => Err(msg)
      }
    0xcf =>
      match dec.read_uint(8) {
        Ok(value) => {
          let max_i64 = 9_223_372_036_854_775_807L
          let max_u64 = max_i64.reinterpret_as_uint64()
          if value <= max_u64 {
            Ok(@types.JsonInt(value.reinterpret_as_int64()))
          } else {
            Ok(@types.JsonNumber(Float::from_uint64(value)))
          }
        }
        Err(msg) => Err(msg)
      }
    0xd0 =>
      match dec.read_int(8) {
        Ok(value) => Ok(@types.JsonInt(value))
        Err(msg) => Err(msg)
      }
    0xd1 =>
      match dec.read_int(16) {
        Ok(value) => Ok(@types.JsonInt(value))
        Err(msg) => Err(msg)
      }
    0xd2 =>
      match dec.read_int(32) {
        Ok(value) => Ok(@types.JsonInt(value))
        Err(msg) => Err(msg)
      }
    0xd3 =>
      match dec.read_int(64) {
        Ok(value) => Ok(@types.JsonInt(value))
        Err(msg) => Err(msg)
      }
    0xca =>
      match dec.read_uint(4) {
        Ok(value) => Ok(@types.JsonNumber(decode_float32(value)))
        Err(msg) => Err(msg)
      }
    0xcb =>
      match dec.read_uint(8) {
        Ok(value) =>
          Ok(@types.JsonNumber(Float::reinterpret_from_uint(value.to_uint())))
        Err(msg) => Err(msg)
      }
    0xd9 =>
      match dec.read_byte() {
        Ok(len) => decode_string(dec, len.to_int())
        Err(msg) => Err(msg)
      }
    0xda =>
      match dec.read_uint(2) {
        Ok(len) => decode_string(dec, len.to_int())
        Err(msg) => Err(msg)
      }
    0xdb =>
      match dec.read_uint(4) {
        Ok(len) => decode_string(dec, len.to_int())
        Err(msg) => Err(msg)
      }
    0xdc =>
      match dec.read_uint(2) {
        Ok(len) => decode_array(dec, len.to_int())
        Err(msg) => Err(msg)
      }
    0xdd =>
      match dec.read_uint(4) {
        Ok(len) => decode_array(dec, len.to_int())
        Err(msg) => Err(msg)
      }
    0xde =>
      match dec.read_uint(2) {
        Ok(len) => decode_map(dec, len.to_int())
        Err(msg) => Err(msg)
      }
    0xdf =>
      match dec.read_uint(4) {
        Ok(len) => decode_map(dec, len.to_int())
        Err(msg) => Err(msg)
      }
    _ => Err("Unsupported MessagePack prefix")
  }
}

///|
fn decode_string(dec : Decoder, len : Int) -> Result[@types.JsonValue, String] {
  match dec.read_bytes(len) {
    Ok(bytes) =>
      try @encoding/utf8.decode(bytes) catch {
        _ => Err("Invalid UTF-8 string")
      } noraise {
        value => Ok(@types.JsonString(value))
      }
    Err(msg) => Err(msg)
  }
}

///|
fn decode_array(dec : Decoder, len : Int) -> Result[@types.JsonValue, String] {
  let values : Array[@types.JsonValue] = []
  for _ in 0..<len {
    match decode_value(dec) {
      Ok(value) => values.push(value)
      Err(msg) => return Err(msg)
    }
  }
  Ok(@types.JsonArray(values))
}

///|
fn decode_map(dec : Decoder, len : Int) -> Result[@types.JsonValue, String] {
  let values : Map[String, @types.JsonValue] = Map::new()
  for _ in 0..<len {
    let key = match decode_value(dec) {
      Ok(@types.JsonString(value)) => value
      Ok(_) => return Err("Map keys must be strings")
      Err(msg) => return Err(msg)
    }
    let value = match decode_value(dec) {
      Ok(val) => val
      Err(msg) => return Err(msg)
    }
    values[key] = value
  }
  Ok(@types.JsonObject(values))
}

///|
fn decode_float32(bits : UInt64) -> Float {
  let sign : Float = if (bits & 0x8000_0000) != 0 {
    Float::from_int(-1)
  } else {
    Float::from_int(1)
  }
  let exp = (bits >> 23).land(0xff).to_int()
  let frac_bits = bits & 0x7fffff
  if exp == 255 {
    return Float::default()
  }
  let fraction = Float::from_uint64(frac_bits) / Float::from_int(8_388_608)
  if exp == 0 {
    if frac_bits == 0 {
      return Float::default()
    }
    let base = Float::from_int(2)
    let exponent = Float::from_int(-126)
    return sign * Float::pow(base, exponent) * fraction
  }
  let exp_value = exp - 127
  let base = Float::from_int(2)
  let exponent = Float::from_int(exp_value)
  sign * Float::pow(base, exponent) * (Float::from_int(1) + fraction)
}
