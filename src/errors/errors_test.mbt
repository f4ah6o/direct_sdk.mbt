// Tests for error types and functions
// Reference: direct-go-sdk/direct-go/errors_test.go

///|
test "direct_error_to_string converts errors to strings" {
  let err1 = @errors.not_connected("Not connected")
  inspect(
    @errors.direct_error_to_string(err1),
    content="not connected: Not connected",
  )
  let err2 = @errors.timeout("Request timeout")
  inspect(
    @errors.direct_error_to_string(err2),
    content="timeout: Request timeout",
  )
  let err3 = @errors.invalid_response("Invalid format")
  inspect(
    @errors.direct_error_to_string(err3),
    content="invalid response: Invalid format",
  )
  let err4 = @errors.rpc_error(400, "Bad Request")
  inspect(
    @errors.direct_error_to_string(err4),
    content="RPC error 400: Bad Request",
  )
}

///|
test "error constructor functions create correct error types" {
  let err1 = @errors.not_connected("test")
  match err1 {
    @errors.NotConnected(msg) => inspect(msg, content="test")
    _ => inspect("ERROR", content="wrong type")
  }
  let err2 = @errors.timeout("test")
  match err2 {
    @errors.Timeout(msg) => inspect(msg, content="test")
    _ => inspect("ERROR", content="wrong type")
  }
  let err3 = @errors.rpc_error(500, "server error")
  match err3 {
    @errors.RPCError(code, msg) => {
      inspect(code, content="500")
      inspect(msg, content="server error")
    }
    _ => inspect("ERROR", content="wrong type")
  }
}

///|
test "ws_error_to_direct converts WebSocket errors" {
  let ws_err = @rpc_websocket.ConnectionClosed(
    @rpc_websocket.Normal,
    Some("Normal closure"),
  )
  let err = @rpc_websocket.ws_error_to_direct(ws_err)
  inspect(
    @errors.direct_error_to_string(err),
    content="not connected: Normal closure",
  )
}
