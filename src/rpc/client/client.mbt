// RPC Client for Direct SDK
// Reference: direct-go-sdk/direct-go/client.go

// Main client type with WebSocket and MessagePack RPC protocol
///|
pub struct Client {
  config : @config.Config
  mut ws : @rpc_websocket.WebSocketConnection?
  mut msg_id : Int64
  mut connected : Bool
  mut authenticated : Bool
  mut pending_requests : Map[Int64, RequestPromise]
  event_handlers : Map[String, Array[EventHandler]]
  message_channel : MessageChannel?
  done_channel : DoneChannel?
  mut talk_domains : Map[String, String] // talk_id -> domain_id
  mut metrics : @config.Metrics
  dispatcher : @events_handler.EventDispatcher // Event dispatcher
}

// Request promise for async RPC calls

///|
pub struct RequestPromise {
  result_ch : ResultChannel
  error_ch : ErrorChannel
}

// Channel types (will use moonbitlang/async channels when available)

///|
pub type ResultChannel = Unit // Placeholder

///|
pub type ErrorChannel = Unit // Placeholder

///|
pub type MessageChannel = Unit // Placeholder

///|
pub type DoneChannel = Unit // Placeholder

// Event handler type

///|
pub type EventHandler = (@types.JsonValue) -> Unit

// Response handler for RPC calls (for callback-style API)

///|
pub struct ResponseHandler {
  method : String
  on_success : (@types.JsonValue) -> Unit
  on_error : (@types.JsonValue) -> Unit
}

// Create a new client with the given configuration

///|
pub fn new_client(config : @config.Config) -> Client {
  {
    config,
    ws: None,
    msg_id: 0L,
    connected: false,
    authenticated: false,
    pending_requests: Map::new(),
    event_handlers: Map::new(),
    message_channel: None,
    done_channel: None,
    talk_domains: Map::new(),
    metrics: @config.noop_metrics(),
    dispatcher: @events_handler.new_dispatcher(),
  }
}

// Create a new client with default configuration

///|
pub fn new_client_with_token(token : String) -> Client {
  let cfg = @config.new_config(token)
  new_client(cfg)
}

// Connect to the WebSocket server and start background tasks
// cfg(target="native")

///|
pub async fn connect(client : Client) -> Result[Unit, @errors.DirectError] {
  // Check if already connected
  match client.ws {
    Some(_) => return Err(@errors.already_connected("Already connected"))
    None => ()
  }

  // Create WebSocket configuration
  let ws_config = @rpc_websocket.default_websocket_config(
    client.config.endpoint,
  )

  // Connect to WebSocket
  let ws = match @rpc_websocket.connect(ws_config) {
    Ok(conn) => conn
    Err(e) => return Err(@rpc_websocket.ws_error_to_direct(e))
  }
  client.ws = Some(ws)
  client.connected = true

  // Record connection state
  (client.metrics.record_connection_state)("connected")

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

///|
pub async fn close(client : Client) -> Result[Unit, @errors.DirectError] {
  match client.ws {
    Some(ws) =>
      match @rpc_websocket.close(ws) {
        Ok(_) => ()
        Err(e) => return Err(@rpc_websocket.ws_error_to_direct(e))
      }
    None => ()
  }

  // Clear pending requests
  client.pending_requests = Map::new()

  // Clear talk domains cache
  client.talk_domains = Map::new()
  client.connected = false
  client.authenticated = false
  client.ws = None

  // Record disconnection
  (client.metrics.record_connection_state)("disconnected")
  Ok(())
}

// Get health status

///|
pub fn health(client : Client) -> @config.HealthStatus {
  let connected = match client.ws {
    Some(ws) => @rpc_websocket.is_connected(ws)
    None => false
  }
  if connected {
    @config.healthy_health_status(client.config.endpoint)
  } else {
    @config.unhealthy_health_status(client.config.endpoint, "not connected")
  }
}

// === RPC Calls ===

// Generic RPC call (async, with timeout)
// cfg(target="native")

///|
pub async fn call(
  client : Client,
  method : String,
  params : Array[@types.JsonValue],
) -> Result[@types.JsonValue, @errors.DirectError] {
  if !client.connected {
    return Err(@errors.not_connected("Not connected"))
  }

  // Generate message ID
  client.msg_id = client.msg_id + 1L
  let msg_id = client.msg_id

  // Create RPC request
  let req = @rpc_msgpack.create_request(msg_id, method, params)

  // Encode request
  let data = match @rpc_msgpack.encode_request(req) {
    Ok(bytes) => bytes
    Err(e) => return Err(e)
  }

  // Send request
  match client.ws {
    Some(ws) =>
      match @rpc_websocket.send_binary(ws, data) {
        Ok(_) => ()
        Err(e) => return Err(@rpc_websocket.ws_error_to_direct(e))
      }
    None => return Err(@errors.not_connected("WebSocket not connected"))
  }

  // Wait for response with timeout
  // TODO: Implement async wait with timeout using TaskGroup
  // For now, return an error
  Err(@errors.timeout("Response timeout not yet implemented"))
}

// Synchronous-style RPC call with timeout

///|
pub fn call_sync(
  client : Client,
  method : String,
  params : Array[@types.JsonValue],
  timeout_ms : Int,
) -> Result[@types.JsonValue, @errors.DirectError] {
  if !client.connected {
    return Err(@errors.not_connected("Not connected"))
  }

  // TODO: Implement blocking wait with timeout
  Err(@errors.timeout("Sync call not yet implemented"))
}

// Send a text message (convenience method)

///|
pub async fn send_text(
  client : Client,
  room_id : String,
  text : String,
) -> Result[Unit, @errors.DirectError] {
  let params = [
    @types.JsonString(room_id),
    @types.JsonNumber(
      Float::from_int(@types.msg_type_to_wire(@types.MsgTypeText)),
    ),
    @types.JsonString(text),
  ]
  match call(client, @constants.METHOD_CREATE_MESSAGE, params) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

// === Authentication ===

// Create a session with the server

///|
async fn create_session(client : Client) -> Result[Unit, @errors.DirectError] {
  let params = [
    @types.JsonString(client.config.token),
    @types.JsonString(@constants.API_VERSION),
    @types.JsonString("MoonBit"),
  ]
  match call(client, @constants.METHOD_CREATE_SESSION, params) {
    Ok(result) => {
      client.authenticated = true

      // Emit session_created event
      emit(client, @constants.EVENT_SESSION_CREATED, result)

      // Start notification
      // TODO: await start_notification(client)

      Ok(())
    }
    Err(e) => {
      emit(
        client,
        @constants.EVENT_SESSION_ERROR,
        @types.JsonString(e |> @errors.direct_error_to_string),
      )
      Err(e)
    }
  }
}

// === Event Handling ===

// Register an event handler

///|
pub fn on(client : Client, event : String, handler : EventHandler) -> Unit {
  let handlers = match client.event_handlers.get(event) {
    Some(h) => h
    None => []
  }
  handlers.push(handler)
  client.event_handlers[event] = handlers
}

// Register a message handler

///|
pub fn on_message(
  client : Client,
  handler : (@types.ReceivedMessage) -> Unit,
) -> Unit {
  // TODO: Add to message handlers list
  @events_handler.on_message(client.dispatcher, handler)
}

// Register a talk handler

///|
pub fn on_talk(client : Client, handler : (@types.Talk) -> Unit) -> Unit {
  @events_handler.on_talk(client.dispatcher, handler)
}

// Register a user handler

///|
pub fn on_user(client : Client, handler : (@types.UserInfo) -> Unit) -> Unit {
  @events_handler.on_user(client.dispatcher, handler)
}

// Register a domain handler

///|
pub fn on_domain(
  client : Client,
  handler : (@types.DomainInfo) -> Unit,
) -> Unit {
  @events_handler.on_domain(client.dispatcher, handler)
}

// Register a conference handler

///|
pub fn on_conference(
  client : Client,
  handler : (@types.ConferenceInfo) -> Unit,
) -> Unit {
  @events_handler.on_conference(client.dispatcher, handler)
}

// Emit an event to all registered handlers

///|
pub fn emit(client : Client, event : String, data : @types.JsonValue) -> Unit {
  // Emit to legacy handlers
  match client.event_handlers.get(event) {
    Some(handlers) =>
      for h in handlers {
        h(data)
      }
    None => ()
  }

  // Also emit to dispatcher
  @events_handler.emit(client.dispatcher, event, data)
}

// === Background Loops ===

// Read loop for incoming WebSocket messages

///|
async fn read_loop(client : Client) -> Unit {
  // TODO: Implement using TaskGroup
  // loop {
  //   match client.ws {
  //     | Some(ws) => {
  //       match await rpc/websocket.receive(ws) {
  //         | Ok(data) => handle_message(client, data)
  //         | Err(e) => {
  //           emit(client, @constants.EVENT_ERROR, @types.JsonString(e |> @rpc_websocket.ws_error_to_string))
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

///|
async fn ping_loop(client : Client) -> Unit {
  // TODO: Implement using TaskGroup and interval
  // let ticker = async/interval(client.config.timeout / 2)
  // loop {
  //   select {
  //     _ = await ticker.tick() => {
  //       match client.ws {
  //         | Some(ws) => {
  //           match await @rpc_websocket.ping(ws) {
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

///|
fn handle_message(client : Client, data : Array[Byte]) -> Unit {
  match @rpc_msgpack.decode_response(data) {
    Ok(resp) =>
      if resp.msg_type == @constants.RPC_RESPONSE {
        handle_response(client, resp)
      } else if resp.msg_type == @constants.RPC_REQUEST {
        handle_notification(client, resp)
      }
    Err(e) =>
      emit(
        client,
        @constants.EVENT_DECODE_ERROR,
        @types.JsonString(e |> @errors.direct_error_to_string),
      )
  }
}

// Handle RPC response

///|
fn handle_response(client : Client, resp : @rpc_msgpack.RpcResponse) -> Unit {
  match client.pending_requests.get(resp.msg_id) {
    Some(promise) => {
      client.pending_requests.remove(resp.msg_id)
      match resp.error {
        Some(err) =>
          // TODO: Send to error channel
          ()
        None =>
          // TODO: Send result to result channel
          ()
      }
    }
    None => ()
  }
}

// Handle server notification

///|
fn handle_notification(
  client : Client,
  resp : @rpc_msgpack.RpcResponse,
) -> Unit {
  let _ = client
  let _ = resp
  // TODO: RpcResponse does not expose method information yet.
}

// === Helper Functions ===

// Get next message ID

///|
pub fn next_msg_id(client : Client) -> Int64 {
  client.msg_id = client.msg_id + 1L
  client.msg_id
}

// Check if authenticated

///|
pub fn is_authenticated(client : Client) -> Bool {
  client.authenticated
}

// Check if connected

///|
pub fn is_connected(client : Client) -> Bool {
  client.connected
}

// Get configuration

///|
pub fn get_config(client : Client) -> @config.Config {
  client.config
}

// Set metrics

///|
pub fn set_metrics(client : Client, metrics : @config.Metrics) -> Unit {
  client.metrics = metrics
}

// Get talk domains cache

///|
pub fn get_talk_domains(client : Client) -> Map[String, String] {
  client.talk_domains
}

// Add to talk domains cache

///|
pub fn cache_talk_domain(
  client : Client,
  talk_id : String,
  domain_id : String,
) -> Unit {
  client.talk_domains[talk_id] = domain_id
}

// Get domain for talk

///|
pub fn get_domain_for_talk(client : Client, talk_id : String) -> String? {
  client.talk_domains.get(talk_id)
}
