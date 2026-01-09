// RPC Client for Direct SDK
// Reference: direct-go-sdk/direct-go/client.go

// Main client type with WebSocket and MessagePack RPC protocol
pub type Client = {
  mut config            : Config,
  mut ws                : Option[rpc/websocket/WebSocketConnection],
  mut msg_id            : Int64,
  mut connected         : Bool,
  mut authenticated     : Bool,
  mut pending_requests  : Map[Int64, RequestPromise],
  mut event_handlers    : Map[String, Array[EventHandler]],
  mut message_channel   : Option[MessageChannel],
  mut done_channel      : Option[DoneChannel],
  mut talk_domains      : Map[String, String],  // talk_id -> domain_id
  mut metrics           : config/Metrics,
}

// Request promise for async RPC calls
pub type RequestPromise = {
  result_ch : ResultChannel,
  error_ch  : ErrorChannel,
}

// Channel types (will use moonbitlang/async channels when available)
pub type ResultChannel = Unit  // Placeholder
pub type ErrorChannel = Unit    // Placeholder
pub type MessageChannel = Unit  // Placeholder
pub type DoneChannel = Unit     // Placeholder

// Event handler type
pub type EventHandler = (JsonValue) -> Unit

// Response handler for RPC calls (for callback-style API)
pub type ResponseHandler = {
  method    : String,
  on_success : (JsonValue) -> Unit,
  on_error   : (JsonValue) -> Unit,
}

// Create a new client with the given configuration
pub fn new_client(config : Config) -> Client {
  {
    config:            config,
    ws:                None,
    msg_id:            0L,
    connected:         false,
    authenticated:     false,
    pending_requests:  Map::new(),
    event_handlers:    Map::new(),
    message_channel:   None,
    done_channel:      None,
    talk_domains:      Map::new(),
    metrics:           config/noop_metrics(),
  }
}

// Create a new client with default configuration
pub fn new_client_with_token(token : String) -> Client {
  let cfg = config/new_config(token)
  new_client(cfg)
}

// Connect to the WebSocket server and start background tasks
// cfg(target="native")
pub async fn connect(client : Client) -> Result[Unit, DirectError] {
  // Check if already connected
  match client.ws {
    | Some(_) => return Err(already_connected("Already connected"))
    | None => ()
  }

  // Create WebSocket configuration
  let ws_config = rpc/websocket/default_websocket_config(client.config.endpoint)

  // Connect to WebSocket
  let ws = match await rpc/websocket/connect(ws_config) {
    | Ok(conn) => conn
    | Err(e) => return Err(ws_error_to_direct(e))
  }

  client.ws = Some(ws)
  client.connected = true

  // Record connection state
  client.metrics.record_connection_state("connected")

  // Start background tasks
  // TODO: Spawn read_loop and ping_loop using TaskGroup
  // await spawn_bg(true, () => read_loop(client))
  // await spawn_bg(true, () => ping_loop(client))

  // Create session if token is provided
  if client.config.token != "" {
    // TODO: await spawn_bg(true, () => create_session(client))
  }

  Ok(())
}

// Close the WebSocket connection and cleanup
// cfg(target="native")
pub async fn close(client : Client) -> Result[Unit, DirectError] {
  match client.ws {
    | Some(ws) => {
      match await rpc/websocket/close(ws) {
        | Ok(_) => ()
        | Err(e) => return Err(ws_error_to_direct(e))
      }
    }
    | None => ()
  }

  // Clear pending requests
  client.pending_requests = Map::new()

  // Clear talk domains cache
  client.talk_domains = Map::new()

  client.connected = false
  client.authenticated = false
  client.ws = None

  // Record disconnection
  client.metrics.record_connection_state("disconnected")

  Ok(())
}

// Get health status
pub fn health(client : Client) -> config/HealthStatus {
  let connected = match client.ws {
    | Some(ws) => rpc/websocket/is_connected(ws)
    | None => false
  }

  if connected {
    config/healthy_health_status(client.config.endpoint)
  } else {
    config/unhealthy_health_status(client.config.endpoint, "not connected")
  }
}

// === RPC Calls ===

// Generic RPC call (async, with timeout)
// cfg(target="native")
pub async fn call(
  client : Client,
  method : String,
  params : Array[JsonValue]
) -> Result[JsonValue, DirectError] {
  if !client.connected {
    return Err(not_connected("Not connected"))
  }

  // Generate message ID
  client.msg_id = client.msg_id + 1L
  let msg_id = client.msg_id

  // Create RPC request
  let req = rpc/msgpack/create_request(msg_id, method, params)

  // Encode request
  let data = match rpc/msgpack/encode_request(req) {
    | Ok(bytes) => bytes
    Err(e) => return Err(e)
  }

  // Send request
  match client.ws {
    | Some(ws) => {
      match await rpc/websocket/send_binary(ws, data) {
        | Ok(_) => ()
        | Err(e) => return Err(ws_error_to_direct(e))
      }
    }
    | None => return Err(not_connected("WebSocket not connected"))
  }

  // Wait for response with timeout
  // TODO: Implement async wait with timeout using TaskGroup
  // For now, return an error
  Err(timeout("Response timeout not yet implemented"))
}

// Synchronous-style RPC call with timeout
pub fn call_sync(
  client : Client,
  method : String,
  params : Array[JsonValue],
  timeout_ms : Int
) -> Result[JsonValue, DirectError] {
  if !client.connected {
    return Err(not_connected("Not connected"))
  }

  // TODO: Implement blocking wait with timeout
  Err(timeout("Sync call not yet implemented"))
}

// Send a text message (convenience method)
pub async fn send_text(
  client : Client,
  room_id : String,
  text : String
) -> Result[Unit, DirectError] {
  let params = [
    JsonString(room_id),
    JsonNumber(msg_type_to_wire(MsgTypeText).to_float()),
    JsonString(text),
  ]

  match await call(client, METHOD_CREATE_MESSAGE, params) {
    | Ok(_) => Ok(())
    | Err(e) => Err(e)
  }
}

// === Authentication ===

// Create a session with the server
async fn create_session(client : Client) -> Result[Unit, DirectError] {
  let params = [
    JsonString(client.config.token),
    JsonString(API_VERSION),
    JsonString("MoonBit"),
  ]

  match await call(client, METHOD_CREATE_SESSION, params) {
    | Ok(result) => {
      client.authenticated = true

      // Emit session_created event
      emit(client, EVENT_SESSION_CREATED, result)

      // Start notification
      // TODO: await start_notification(client)

      Ok(())
    }
    | Err(e) => {
      emit(client, EVENT_SESSION_ERROR, JsonString(e |> direct_error_to_string))
      Err(e)
    }
  }
}

// === Event Handling ===

// Register an event handler
pub fn on(client : Client, event : String, handler : EventHandler) -> Unit {
  let handlers = match client.event_handlers.get(event) {
    | Some(h) => h
    | None => []
  }
  client.event_handlers.insert(event, handlers.push(handler))
}

// Register a message handler
pub fn on_message(client : Client, handler : (types/ReceivedMessage) -> Unit) -> Unit {
  // TODO: Add to message handlers list
  ()
}

// Emit an event to all registered handlers
pub fn emit(client : Client, event : String, data : JsonValue) -> Unit {
  match client.event_handlers.get(event) {
    | Some(handlers) => {
      for h in handlers {
        h(data)
      }
    }
    | None => ()
  }
}

// === Background Loops ===

// Read loop for incoming WebSocket messages
async fn read_loop(client : Client) -> Unit {
  // TODO: Implement using TaskGroup
  // loop {
  //   match client.ws {
  //     | Some(ws) => {
  //       match await rpc/websocket.receive(ws) {
  //         | Ok(data) => handle_message(client, data)
  //         | Err(e) => {
  //           emit(client, EVENT_ERROR, JsonString(e |> ws_error_to_string))
  //           await close(client)
  //           break
  //         }
  //       }
  //     }
  //     | None => break
  //   }
  // }
  ()
}

// Ping loop for keepalive
async fn ping_loop(client : Client) -> Unit {
  // TODO: Implement using TaskGroup and interval
  // let ticker = async/interval(client.config.timeout / 2)
  // loop {
  //   select {
  //     _ = await ticker.tick() => {
  //       match client.ws {
  //         | Some(ws) => {
  //           match await rpc/websocket/ping(ws) {
  //             | Ok(_) => ()
  //             | Err(e) => {
  //               await close(client)
  //               break
  //             }
  //           }
  //         }
  //         | None => break
  //       }
  //     }
  //     _ = await client.done_channel.receive() => break
  //   }
  // }
  ()
}

// Handle incoming message
fn handle_message(client : Client, data : Array[Byte]) -> Unit {
  match rpc/msgpack/decode_response(data) {
    | Ok(resp) => {
      if resp.msg_type == RPC_RESPONSE {
        handle_response(client, resp)
      } else if resp.msg_type == RPC_REQUEST {
        handle_notification(client, resp)
      }
    }
    Err(e) => emit(client, EVENT_DECODE_ERROR, JsonString(e |> direct_error_to_string))
  }
}

// Handle RPC response
fn handle_response(client : Client, resp : rpc/msgpack/RpcResponse) -> Unit {
  match client.pending_requests.get(resp.msg_id) {
    | Some(promise) => {
      client.pending_requests.remove(resp.msg_id)
      match resp.error {
        | Some(err) => {
          // TODO: Send to error channel
          ()
        }
        | None => {
          // TODO: Send result to result channel
          ()
        }
      }
    }
    | None => ()
  }
}

// Handle server notification
fn handle_notification(client : Client, resp : rpc/msgpack/RpcResponse) -> Unit {
  // Emit the notification event
  emit(client, resp.method, resp.result)

  // Handle message notifications specially
  if resp.method == EVENT_NOTIFY_CREATE_MESSAGE || resp.method == "create_message" {
    // TODO: Parse and emit as ReceivedMessage
    ()
  }
}

// === Helper Functions ===

// Get next message ID
pub fn next_msg_id(client : Client) -> Int64 {
  client.msg_id = client.msg_id + 1L
  client.msg_id
}

// Check if authenticated
pub fn is_authenticated(client : Client) -> Bool {
  client.authenticated
}

// Check if connected
pub fn is_connected(client : Client) -> Bool {
  client.connected
}

// Get configuration
pub fn get_config(client : Client) -> Config {
  client.config
}

// Set metrics
pub fn set_metrics(client : Client, metrics : config/Metrics) -> Unit {
  client.metrics = metrics
}

// Get talk domains cache
pub fn get_talk_domains(client : Client) -> Map[String, String] {
  client.talk_domains
}

// Add to talk domains cache
pub fn cache_talk_domain(client : Client, talk_id : String, domain_id : String) -> Unit {
  client.talk_domains.insert(talk_id, domain_id)
}

// Get domain for talk
pub fn get_domain_for_talk(client : Client, talk_id : String) -> Option[String] {
  client.talk_domains.get(talk_id)
}
