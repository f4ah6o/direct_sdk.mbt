///|
test "MessagePack request wire fixture" {
  let request = @msgpack.create_request(42L, "test", [@types.JsonNull])
  let encoded = match @msgpack.encode_request(request) {
    Ok(bytes) => bytes
    Err(err) => fail(@errors.direct_error_to_string(err))
  }
  let fixture = Bytes::from_array([
    b'\x94', b'\x00', b'\x2a', b'\xa4', b't', b'e', b's', b't', b'\x91', b'\xc0',
  ])
  assert_true(encoded == fixture)
  match @msgpack.decode_message(fixture) {
    Ok(@msgpack.Request(decoded)) => {
      inspect(decoded.msg_type, content="0")
      inspect(decoded.msg_id, content="42")
      inspect(decoded.rpc_method, content="test")
      inspect(decoded.params.length(), content="1")
      debug_inspect(decoded.params[0], content="JsonNull")
    }
    _ => fail("wire fixture did not decode as a request")
  }
}
