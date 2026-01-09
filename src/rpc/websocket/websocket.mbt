// WebSocket connection wrapper for Direct SDK
// Reference: direct-go-sdk/direct-go/client.go, gorilla/websocket
// Moonbit async WebSocket: https://github.com/moonbitlang/async

// Import moonbitlang/async/websocket (platform-specific)
// Note: This module is only available for native target currently
// cfg(target="native") will be used for native-specific code

// WebSocket close codes (RFC 6455)
///|
pub(all) enum CloseCode {
  Normal // 1000
  GoingAway // 1001
  ProtocolError // 1002
  UnsupportedData // 1003
  Abnormal // 1006
  InvalidFramePayload // 1007
  PolicyViolation // 1008
  MessageTooBig // 1009
  MissingExtension // 1010
  InternalError // 1011
  Other(Int) // Other codes
}

///|
pub fn close_code_to_int(code : CloseCode) -> Int {
  match code {
    Normal => 1000
    GoingAway => 1001
    ProtocolError => 1002
    UnsupportedData => 1003
    Abnormal => 1006
    InvalidFramePayload => 1007
    PolicyViolation => 1008
    MessageTooBig => 1009
    MissingExtension => 1010
    InternalError => 1011
    Other(n) => n
  }
}

// WebSocket errors (matching moonbitlang/async/websocket)

///|
pub(all) enum WebSocketError {
  ConnectionClosed(CloseCode, String?)
  InvalidHandshake(String)
  ProtocolError
  ConnectionFailed(String)
  Timeout(String)
}

// Convert WebSocketError to String

///|
pub fn ws_error_to_string(err : WebSocketError) -> String {
  match err {
    ConnectionClosed(code, reason) => {
      let reason_text = match reason {
        Some(r) => " (" + r + ")"
        None => ""
      }
      "Connection closed: " + close_code_to_int(code).to_string() + reason_text
    }
    InvalidHandshake(msg) => "Invalid handshake: " + msg
    ProtocolError => "Protocol error: malformed frame"
    ConnectionFailed(msg) => "Connection failed: " + msg
    Timeout(msg) => "Timeout: " + msg
  }
}

// Convert WebSocketError to @errors.DirectError

///|
pub fn ws_error_to_direct(err : WebSocketError) -> @errors.DirectError {
  match err {
    ConnectionClosed(_, reason) => {
      let message = match reason {
        Some(r) => r
        None => "Connection closed"
      }
      @errors.not_connected(message)
    }
    InvalidHandshake(msg) => @errors.connection_error("handshake: " + msg)
    ProtocolError => @errors.decode_error("Malformed WebSocket frame")
    ConnectionFailed(msg) => @errors.connection_error(msg)
    Timeout(msg) => @errors.timeout(msg)
  }
}

// WebSocket configuration

///|
pub struct WebSocketConfig {
  endpoint : String
  mut proxy_url : String?
  mut headers : Map[String, String]?
  mut timeout : Int // Handshake timeout in milliseconds
}

// Default WebSocket configuration

///|
pub fn default_websocket_config(endpoint : String) -> WebSocketConfig {
  {
    endpoint,
    proxy_url: None,
    headers: None,
    timeout: @constants.DEFAULT_HANDSHAKE_TIMEOUT,
  }
}

// Builder pattern for WebSocketConfig

///|
pub fn with_proxy(cfg : WebSocketConfig, proxy_url : String) -> WebSocketConfig {
  cfg.proxy_url = Some(proxy_url)
  cfg
}

///|
pub fn with_headers(
  cfg : WebSocketConfig,
  headers : Map[String, String],
) -> WebSocketConfig {
  cfg.headers = Some(headers)
  cfg
}

///|
pub fn with_timeout(cfg : WebSocketConfig, timeout_ms : Int) -> WebSocketConfig {
  cfg.timeout = timeout_ms
  cfg
}

// WebSocket connection wrapper
// This wraps the underlying @websocket.Conn from moonbitlang/async

///|
pub struct WebSocketConnection {
  conn : InternalConn?
  endpoint : String
  mut connected : Bool
}

// Internal connection type (opaque wrapper around @websocket.Conn)
// This is defined as opaque to hide the platform-specific details

///|
pub type InternalConn = Unit

// Create a new WebSocket connection wrapper (not connected)

///|
pub fn new_connection(endpoint : String) -> WebSocketConnection {
  { conn: None, endpoint, connected: false }
}

// Check if connected

///|
pub fn is_connected(conn : WebSocketConnection) -> Bool {
  conn.connected
}

// Get endpoint

///|
pub fn get_endpoint(conn : WebSocketConnection) -> String {
  conn.endpoint
}

// === Native platform implementation ===
// These functions use moonbitlang/async/websocket

// Connect to WebSocket endpoint (async)
// Uses @websocket.connect(url, headers?, proxy?)
// cfg(target="native")

///|
pub async fn connect_native(
  config : WebSocketConfig,
) -> Result[WebSocketConnection, WebSocketError] {
  // TODO: Implement using moonbitlang/async/websocket
  // The implementation would be:
  //
  // let ws = match config.headers {
  //   | Some(h) => match config.proxy_url {
  //     | Some(p) => @websocket.connect(config.endpoint, h, p)
  //     | None => @websocket.connect(config.endpoint, h)
  //   }
  //   | None => match config.proxy_url {
  //     | Some(p) => @websocket.connect(config.endpoint, proxy=p)
  //     | None => @websocket.connect(config.endpoint)
  //   }
  // }
  //
  // return Ok({
  //   conn: Some(ws),
  //   endpoint: config.endpoint,
  //   connected: true,
  // })

  // For now, return an error as a placeholder
  Err(
    ConnectionFailed(
      "Native WebSocket implementation pending - requires cfg(target=\"native\") build",
    ),
  )
}

// Send binary data (async)
// cfg(target="native")

///|
pub async fn send_binary_native(
  conn : WebSocketConnection,
  data : Array[Byte],
) -> Result[Unit, WebSocketError] {
  match conn.conn {
    Some(_) =>
      // TODO: Implement using @websocket.Conn.send_binary(data)
      Ok(())
    None => Err(ConnectionClosed(Abnormal, Some("Not connected")))
  }
}

// Send text message (async)
// cfg(target="native")

///|
pub async fn send_text_native(
  conn : WebSocketConnection,
  text : String,
) -> Result[Unit, WebSocketError] {
  match conn.conn {
    Some(_) =>
      // TODO: Implement using @websocket.Conn.send_text(text)
      Ok(())
    None => Err(ConnectionClosed(Abnormal, Some("Not connected")))
  }
}

// Receive message (async)
// Returns the raw message content as bytes
// cfg(target="native")

///|
pub async fn receive_native(
  conn : WebSocketConnection,
) -> Result[Bytes, WebSocketError] {
  match conn.conn {
    Some(_) =>
      // TODO: Implement using @websocket.Conn.recv()
      // let msg = ws.recv()
      // let content = msg.read_all()
      // Ok(content.to_bytes())
      Err(Timeout("Receive not yet implemented"))
    None => Err(ConnectionClosed(Abnormal, Some("Not connected")))
  }
}

// Send ping (async)
// Note: @websocket.Conn.ping() requires another task to be receiving messages
// cfg(target="native")

///|
pub async fn ping_native(
  conn : WebSocketConnection,
) -> Result[Unit, WebSocketError] {
  match conn.conn {
    Some(_) =>
      // TODO: Implement using @websocket.Conn.ping()
      Ok(())
    None => Err(ConnectionClosed(Abnormal, Some("Not connected")))
  }
}

// Send close frame (async)
// cfg(target="native")

///|
pub async fn send_close_native(
  conn : WebSocketConnection,
) -> Result[Unit, WebSocketError] {
  match conn.conn {
    Some(_) =>
      // TODO: Implement using @websocket.Conn.send_close()
      Ok(())
    None => Err(ConnectionClosed(Abnormal, Some("Not connected")))
  }
}

// Close connection (async)
// cfg(target="native")

///|
pub async fn close_native(
  conn : WebSocketConnection,
) -> Result[Unit, WebSocketError] {
  match conn.conn {
    Some(_) => {
      // TODO: Implement using @websocket.Conn.close()
      conn.connected = false
      Ok(())
    }
    None => Ok(())
  }
}

// === Platform-agnostic interface ===
// These functions dispatch to the appropriate platform implementation

// Connect to WebSocket endpoint

///|
pub async fn connect(
  config : WebSocketConfig,
) -> Result[WebSocketConnection, WebSocketError] {
  // TODO: Dispatch based on target platform
  connect_native(config)
}

// Send binary data

///|
pub async fn send_binary(
  conn : WebSocketConnection,
  data : Array[Byte],
) -> Result[Unit, WebSocketError] {
  send_binary_native(conn, data)
}

// Send text message

///|
pub async fn send_text(
  conn : WebSocketConnection,
  text : String,
) -> Result[Unit, WebSocketError] {
  send_text_native(conn, text)
}

// Receive message

///|
pub async fn receive(
  conn : WebSocketConnection,
) -> Result[Bytes, WebSocketError] {
  receive_native(conn)
}

// Send ping

///|
pub async fn ping(conn : WebSocketConnection) -> Result[Unit, WebSocketError] {
  ping_native(conn)
}

// Send close frame

///|
pub async fn send_close(
  conn : WebSocketConnection,
) -> Result[Unit, WebSocketError] {
  send_close_native(conn)
}

// Close connection

///|
pub async fn close(conn : WebSocketConnection) -> Result[Unit, WebSocketError] {
  close_native(conn)
}

// === JS/WASM platform implementation (placeholder) ===
// For JS/WASM, we would use the native JavaScript WebSocket API
// This would be compiled with cfg(target="wasm") or similar
