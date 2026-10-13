///|
/// MessagePack integer formats, independent of the SDK encoder/decoder.
/// https://github.com/msgpack/msgpack/blob/master/spec.md#int-format-family
/// A table chooses the narrowest legal format; division extracts big-endian
/// octets without the encoder's bit reinterpretation/write helpers.
fn integer_wire(value : Int64) -> Array[Byte] {
  if value >= -32L && value <= 127L {
    return [(if value < 0L { value + 256L } else { value }).to_byte()]
  }
  let formats = if value >= 0L {
    [(255L, 0xcc, 1), (65535L, 0xcd, 2), (4294967295L, 0xce, 4)]
  } else {
    [(-128L, 0xd0, 1), (-32768L, 0xd1, 2), (-2147483648L, 0xd2, 4)]
  }
  let mut tag = if value >= 0L { 0xcf } else { 0xd3 }
  let mut width = 8
  for (limit, prefix, size) in formats {
    if (value >= 0L && value <= limit) || (value < 0L && value >= limit) {
      tag = prefix
      width = size
      break
    }
  }
  let bytes = Array::make(width + 1, b'\x00')
  bytes[0] = tag.to_byte()
  let mut remaining = value
  for i = width; i > 0; i = i - 1 {
    // Euclidean remainder also works for Int64::MIN without negation.
    let digit = (remaining % 256L + 256L) % 256L
    bytes[i] = digit.to_byte()
    remaining = remaining / 256L -
      (if remaining < 0L && digit != 0L { 1L } else { 0L })
  }
  bytes
}

///|
fn request_matches_integer_wire(value : Int64) -> Bool {
  let expected = Bytes::from_array(
    [b'\x94', b'\x00'] + integer_wire(value) + [b'\xa0', b'\x90'],
  )
  match @msgpack.encode_request(@msgpack.create_request(value, "", [])) {
    Ok(actual) => actual == expected
    Err(_) => false
  }
}

///|
fn response_matches_wire(value : Int64, has_error : Bool) -> Bool {
  let error_byte = if has_error { b'\xc2' } else { b'\xc0' }
  let fixture = Bytes::from_array(
    [b'\x94', b'\x01'] + integer_wire(value) + [error_byte, b'\xc3'],
  )
  match @msgpack.decode_response(fixture) {
    Ok(response) =>
      response.msg_type == 1 &&
      response.msg_id == value &&
      (match response.error {
        None => !has_error
        Some(@types.JsonBool(false)) => has_error
        _ => false
      }) &&
      response.result is @types.JsonBool(true)
    Err(_) => false
  }
}

///|
test "core quickcheck integer request bytes match MessagePack specification" {
  @gen.check(
    request_matches_integer_wire,
    count=2000,
    max_size=100,
    max_shrinks=1000,
    seed=20261012,
  )
}

///|
test "core quickcheck response distinguishes nil and false errors" {
  @gen.check(
    fn(input : (Int64, Bool)) { response_matches_wire(input.0, input.1) },
    count=2000,
    max_size=100,
    max_shrinks=1000,
    seed=20261013,
  )
}

///|
test "MessagePack integer format transition and signed extremes" {
  for
    value in [
      -9223372036854775808L, -2147483649L, -2147483648L, -32769L, -32768L, -129L,
      -128L, -33L, -32L, -1L, 0L, 1L, 127L, 128L, 255L, 256L, 65535L, 65536L, 4294967295L,
      4294967296L, 9223372036854775807L,
    ] {
    assert_true(request_matches_integer_wire(value))
    assert_true(response_matches_wire(value, false))
    assert_true(response_matches_wire(value, true))
  }
  assert_eq(integer_wire(-129L), [b'\xd1', b'\xff', b'\x7f'])
  assert_eq(integer_wire(65536L), [b'\xce', b'\x00', b'\x01', b'\x00', b'\x00'])
  assert_eq(integer_wire(-9223372036854775808L), [
    b'\xd3', b'\x80', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00',
  ])
}
