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

///|
fn close_code_from_async(code : @async_ws.CloseCode) -> CloseCode {
  match code {
    @async_ws.Normal => Normal
    @async_ws.GoingAway => GoingAway
    @async_ws.ProtocolError => ProtocolError
    @async_ws.UnsupportedData => UnsupportedData
    @async_ws.Abnormal => Abnormal
    @async_ws.InvalidFramePayload => InvalidFramePayload
    @async_ws.PolicyViolation => PolicyViolation
    @async_ws.MessageTooBig => MessageTooBig
    @async_ws.MissingExtension => MissingExtension
    @async_ws.InternalError => InternalError
    @async_ws.Other(code) => Other(code.to_int())
  }
}

///|
fn close_code_to_async(code : CloseCode) -> @async_ws.CloseCode {
  match code {
    Normal => @async_ws.Normal
    GoingAway => @async_ws.GoingAway
    ProtocolError => @async_ws.ProtocolError
    UnsupportedData => @async_ws.UnsupportedData
    Abnormal => @async_ws.Abnormal
    InvalidFramePayload => @async_ws.InvalidFramePayload
    PolicyViolation => @async_ws.PolicyViolation
    MessageTooBig => @async_ws.MessageTooBig
    MissingExtension => @async_ws.MissingExtension
    InternalError => @async_ws.InternalError
    Other(code) => @async_ws.Other(code.to_uint16())
  }
}

///|
fn map_async_error(err : Error) -> WebSocketError {
  match err {
    @async_ws.ConnectionClosed(code, reason) =>
      ConnectionClosed(close_code_from_async(code), reason)
    @async_ws.InvalidHandshake(msg) => InvalidHandshake(msg)
    @async_ws.WebSocketError::ProtocolError(_) => ProtocolError
    _ => ConnectionFailed(err.to_string())
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
// This wraps the underlying @async_ws.Conn from moonbitlang/async

///|
pub struct WebSocketConnection {
  mut conn : InternalConn?
  endpoint : String
  mut connected : Bool
}

// Internal connection type (opaque wrapper around @async_ws.Conn)
// This is defined as opaque to hide the platform-specific details

///|
pub type InternalConn = @async_ws.Conn

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
// Uses @async_ws.connect(url, headers?, proxy?)
// cfg(target="native")

///|
pub async fn connect_native(
  config : WebSocketConfig,
) -> Result[WebSocketConnection, WebSocketError] {
  let headers : Map[String, String] = match config.headers {
    Some(h) => h
    None => {}
  }
  let proxy_client = match config.proxy_url {
    Some(url) => {
      let client = try @http.Client::new(url) catch {
        err => return Err(ConnectionFailed("proxy: " + err.to_string()))
      } noraise {
        c => c
      }
      Some(client)
    }
    None => None
  }
  let result = @async.with_timeout_opt(config.timeout, fn() {
    try {
      let ws = @async_ws.Conn::connect(
        config.endpoint,
        headers~,
        proxy?=proxy_client,
      )
      Ok(ws)
    } catch {
      err => Err(err)
    }
  })
  match result {
    Some(Ok(ws)) =>
      Ok({ conn: Some(ws), endpoint: config.endpoint, connected: true })
    Some(Err(err)) => Err(map_async_error(err))
    None => Err(Timeout("handshake timed out"))
  }
}

// Send binary data (async)
// cfg(target="native")

///|
pub async fn send_binary_native(
  conn : WebSocketConnection,
  data : Bytes,
) -> Result[Unit, WebSocketError] {
  match conn.conn {
    Some(ws) =>
      try ws.send_binary(data[:]) catch {
        err => Err(map_async_error(err))
      } noraise {
        _ => Ok(())
      }
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
    Some(ws) =>
      try ws.send_text(text[:]) catch {
        err => Err(map_async_error(err))
      } noraise {
        _ => Ok(())
      }
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
    Some(ws) =>
      try {
        let msg = ws.recv()
        let content = msg.read_all()
        Ok(content.binary())
      } catch {
        err => Err(map_async_error(err))
      } noraise {
        value => value
      }
    None => Err(ConnectionClosed(Abnormal, Some("Not connected")))
  }
}

// Send ping (async)
// Note: @async_ws.Conn.ping() requires another task to be receiving messages
// cfg(target="native")

///|
pub async fn ping_native(
  conn : WebSocketConnection,
) -> Result[Unit, WebSocketError] {
  match conn.conn {
    Some(ws) =>
      try ws.ping() catch {
        err => Err(map_async_error(err))
      } noraise {
        _ => Ok(())
      }
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
    Some(ws) =>
      try ws.send_close(code=close_code_to_async(Normal)) catch {
        err => Err(map_async_error(err))
      } noraise {
        _ => Ok(())
      }
    None => Err(ConnectionClosed(Abnormal, Some("Not connected")))
  }
}

// Close connection (async)
// cfg(target="native")

///|
pub fn close_native(conn : WebSocketConnection) -> Result[Unit, WebSocketError] {
  match conn.conn {
    Some(ws) => {
      ws.close()
      conn.connected = false
      conn.conn = None
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
  data : Bytes,
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
pub fn close(conn : WebSocketConnection) -> Result[Unit, WebSocketError] {
  close_native(conn)
}

// === JS/WASM platform implementation (placeholder) ===
// For JS/WASM, we would use the native JavaScript WebSocket API
// This would be compiled with cfg(target="wasm") or similar
