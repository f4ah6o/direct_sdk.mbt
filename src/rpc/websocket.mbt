// WebSocket connection wrapper for Direct SDK
// Reference: direct-go-sdk/direct-go/client.go, gorilla/websocket

// Note: This module provides an interface for WebSocket connections.
// The actual implementation will vary by platform (JS/WASM vs Native).

// WebSocket connection state
pub type ConnectionState =
  | Disconnected
  | Connecting
  | Connected
  | Closing

// WebSocket message type
pub type MessageType =
  | TextMessage(String)
  | BinaryMessage(Array[Byte])
  | CloseMessage
  | PingMessage(Array[Byte])
  | PongMessage(Array[Byte])

// WebSocket connection interface
// This abstracts the underlying WebSocket implementation
pub type WebSocketConnection = {
  mut state     : ConnectionState,
  endpoint      : String,
  mut last_ping : Int64,  // Unix timestamp of last ping
}

// Create a new WebSocket connection (not connected yet)
pub fn new_connection(endpoint : String) -> WebSocketConnection {
  {
    state:     Disconnected,
    endpoint:  endpoint,
    last_ping: 0L,
  }
}

// Get connection state
pub fn get_state(conn : WebSocketConnection) -> ConnectionState {
  conn.state
}

// Check if connected
pub fn is_connected(conn : WebSocketConnection) -> Bool {
  match conn.state {
    | Connected => true
    | _ => false
  }
}

// Get endpoint
pub fn get_endpoint(conn : WebSocketConnection) -> String {
  conn.endpoint
}

// WebSocket configuration
pub type WebSocketConfig = {
  endpoint        : String,
  proxy_url       : Option[String],
  timeout         : Int,  // Handshake timeout in milliseconds
  ping_interval   : Int,  // Ping interval in milliseconds
  message_size_limit : Option[Int],  // Max message size
}

// Default WebSocket configuration
pub fn default_websocket_config(endpoint : String) -> WebSocketConfig {
  {
    endpoint:          endpoint,
    proxy_url:         None,
    timeout:           DEFAULT_HANDSHAKE_TIMEOUT,
    ping_interval:     DEFAULT_PING_INTERVAL,
    message_size_limit: Some(10_485_760),  // 10MB default
  }
}

// WebSocket errors
pub type WebSocketError =
  | ConnectionFailed(String)
  | HandshakeFailed(String)
  | SendFailed(String)
  | ReceiveFailed(String)
  | InvalidFrame(String)
  | Closed(String)
  | Timeout(String)

// Connect to WebSocket endpoint
// This is a placeholder for the actual async implementation
// The real implementation will use moonbitlang/async/websocket
pub async fn connect(config : WebSocketConfig) -> Result[WebSocketConnection, WebSocketError] {
  // TODO: Implement using moonbitlang/async/websocket
  // For now, return a connection object that represents a pending connection
  let conn = new_connection(config.endpoint)

  // The actual connect implementation would:
  // 1. Parse the endpoint URL
  // 2. Set up proxy if configured
  // 3. Establish WebSocket connection
  // 4. Perform handshake
  // 5. Set up pong handler

  // For JS/WASM backend:
  // - Use JavaScript WebSocket API
  // - Set onopen, onmessage, onerror, onclose handlers

  // For native backend:
  // - Use moonbitlang/async/websocket
  // - Connect with timeout
  // - Handle pong responses

  Err(ConnectionFailed("WebSocket not yet implemented - platform binding required"))
}

// Send binary data
pub async fn send_binary(conn : WebSocketConnection, data : Array[Byte]) -> Result[Unit, WebSocketError] {
  match conn.state {
    | Connected => {
      // TODO: Implement actual send
      Ok(())
    }
    | _ => Err(Closed("Not connected"))
  }
}

// Send text message
pub async fn send_text(conn : WebSocketConnection, text : String) -> Result[Unit, WebSocketError] {
  match conn.state {
    | Connected => {
      // TODO: Implement actual send
      Ok(())
    }
    | _ => Err(Closed("Not connected"))
  }
}

// Send ping
pub async fn send_ping(conn : WebSocketConnection, data : Array[Byte]) -> Result[Unit, WebSocketError] {
  match conn.state {
    | Connected => {
      // TODO: Implement actual ping
      Ok(())
    }
    | _ => Err(Closed("Not connected"))
  }
}

// Receive message
pub async fn receive(conn : WebSocketConnection) -> Result<MessageType, WebSocketError] {
  match conn.state {
    | Connected => {
      // TODO: Implement actual receive
      // Would block until a message is received
      Err(Timeout("Receive not yet implemented"))
    }
    | _ => Err(Closed("Not connected"))
  }
}

// Close connection
pub async fn close(conn : WebSocketConnection, code : Option[Int], reason : Option[String]) -> Result[Unit, WebSocketError] {
  // TODO: Implement actual close
  // Would send close frame and wait for acknowledgment
  Ok(())
}

// Set connection state (for internal use)
pub fn set_state(conn : WebSocketConnection, state : ConnectionState) -> Unit {
  conn.state = state
}

// Update last ping time
pub fn update_last_ping(conn : WebSocketConnection) -> Unit {
  // TODO: Get actual timestamp
  conn.last_ping = 0L
}

// Check if ping timeout occurred
pub fn is_ping_timeout(conn : WebSocketConnection, timeout_ms : Int) -> Bool {
  // TODO: Compare current time with last_ping
  false
}

// Convert WebSocketError to DirectError
pub fn ws_error_to_direct(err : WebSocketError) -> DirectError {
  match err {
    | ConnectionFailed(msg) => connection_error(msg)
    | HandshakeFailed(msg) => connection_error("handshake: " + msg)
    | SendFailed(msg) => internal_error("send: " + msg)
    | ReceiveFailed(msg) => internal_error("receive: " + msg)
    | InvalidFrame(msg) => decode_error("frame: " + msg)
    | Closed(msg) => not_connected(msg)
    | Timeout(msg) => timeout(msg)
  }
}

// Platform-specific implementations

// JS/WASM platform implementation using JavaScript WebSocket API
// This would be compiled with the JS backend

// Native platform implementation using moonbitlang/async/websocket
// This would be compiled with the native backend

// For now, we provide a synchronous interface that can be wrapped
// in async functions as needed

// Connect synchronously (blocks until connected or failed)
pub fn connect_sync(config : WebSocketConfig) -> Result<WebSocketConnection, WebSocketError] {
  // This is a synchronous placeholder
  // The real implementation would block on the connection
  let conn = new_connection(config.endpoint)
  Ok(conn)
}

// Send synchronously
pub fn send_binary_sync(conn : WebSocketConnection, data : Array[Byte]) -> Result[Unit, WebSocketError] {
  match conn.state {
    | Connected => Ok(())
    | _ => Err(Closed("Not connected"))
  }
}

// Receive synchronously (blocks until message or timeout)
pub fn receive_sync_timeout(conn : WebSocketConnection, timeout_ms : Int) -> Result<MessageType, WebSocketError] {
  match conn.state {
    | Connected => Err(Timeout("No message received"))
    | _ => Err(Closed("Not connected"))
  }
}
