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
}

// Channel types (will use moonbitlang/async channels when available)

///|
pub type ResultChannel = @async.Queue[
  Result[@types.JsonValue, @errors.DirectError],
]

///|
pub type ErrorChannel = @async.Queue[@errors.DirectError]

///|
pub type MessageChannel = Unit // Placeholder

///|
pub type DoneChannel = Unit // Placeholder

// Event handler type

///|
pub type EventHandler = (@types.JsonValue) -> Unit

// Response handler for RPC calls (for callback-style API)

///|
#warnings("-struct_never_constructed")
pub struct ResponseHandler {
  rpc_method : String
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
pub async fn[T] connect(
  client : Client,
  tasks : @async.TaskGroup[T],
) -> Result[Unit, @errors.DirectError] {
  // Check if already connected
  match client.ws {
    Some(_) => return Err(@errors.already_connected("Already connected"))
    None => ()
  }

  // Create WebSocket configuration
  let ws_config = @rpc_websocket.default_websocket_config(
    client.config.endpoint,
  )
  let ws_config = match client.config.proxy_url {
    Some(url) => @rpc_websocket.with_proxy(ws_config, url)
    None => ws_config
  }

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
  tasks.spawn_bg(() => { read_loop(client) })
  tasks.spawn_bg(() => { ping_loop(client) })

  // Create session if token is provided
  if client.config.token != "" {
    tasks.spawn_bg(() => { ignore(create_session(client)) })
  }
  Ok(())
}

// Close the WebSocket connection and cleanup
// cfg(target="native")

///|
pub fn close(client : Client) -> Result[Unit, @errors.DirectError] {
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
  rpc_method : String,
  params : Array[@types.JsonValue],
) -> Result[@types.JsonValue, @errors.DirectError] {
  if !client.connected {
    return Err(@errors.not_connected("Not connected"))
  }

  // Generate message ID
  client.msg_id = client.msg_id + 1L
  let msg_id = client.msg_id

  // Create RPC request
  let req = @rpc_msgpack.create_request(msg_id, rpc_method, params)

  // Encode request
  let data = match @rpc_msgpack.encode_request(req) {
    Ok(bytes) => bytes
    Err(e) => return Err(e)
  }
  let promise = { result_ch: @async.Queue::new(kind=Unbounded) }
  client.pending_requests[msg_id] = promise

  // Send request
  match client.ws {
    Some(ws) =>
      match @rpc_websocket.send_binary(ws, data) {
        Ok(_) => ()
        Err(e) => {
          client.pending_requests.remove(msg_id)
          return Err(@rpc_websocket.ws_error_to_direct(e))
        }
      }
    None => return Err(@errors.not_connected("WebSocket not connected"))
  }
  let result = @async.with_timeout_opt(client.config.timeout, () => {
    promise.result_ch.get()
  })
  client.pending_requests.remove(msg_id)
  match result {
    Some(Ok(value)) => Ok(value)
    Some(Err(err)) => Err(err)
    None => Err(@errors.timeout("Response timeout"))
  }
}

///|
fn rpc_error_from_json(value : @types.JsonValue) -> @errors.DirectError {
  match value {
    @types.JsonString(msg) => @errors.rpc_error(0, msg)
    @types.JsonObject(obj) => {
      let code = match obj.get("code") {
        Some(@types.JsonInt(i)) => {
          let int_val = i.to_int()
          if Int64::from_int(int_val) == i {
            int_val
          } else {
            0
          }
        }
        Some(@types.JsonNumber(n)) => {
          let int_val = n.to_int()
          if Float::from_int(int_val) == n {
            int_val
          } else {
            0
          }
        }
        _ => 0
      }
      let msg = match obj.get("message") {
        Some(@types.JsonString(text)) => text
        _ => value.to_string()
      }
      @errors.rpc_error(code, msg)
    }
    _ => @errors.rpc_error(0, value.to_string())
  }
}

// Synchronous-style RPC call with timeout

///|
pub fn call_sync(
  client : Client,
  _rpc_method : String,
  _params : Array[@types.JsonValue],
  _timeout_ms : Int,
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
  let talk_id = @types.string_to_id(room_id)
  let params = [
    @types.id_to_json(talk_id),
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
      ignore(start_notification(client))
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

///|
async fn start_notification(
  client : Client,
) -> Result[Unit, @errors.DirectError] {
  let start_result = call(client, @constants.METHOD_START_NOTIFICATION, [])
  match start_result {
    Ok(@types.JsonBool(false)) =>
      match call(client, @constants.METHOD_RESET_NOTIFICATION, []) {
        Ok(_) =>
          match call(client, @constants.METHOD_START_NOTIFICATION, []) {
            Ok(_) => {
              let update_result = call(
                client,
                @constants.METHOD_UPDATE_LAST_USED_AT,
                [],
              )
              match update_result {
                Ok(value) => {
                  emit(client, @constants.EVENT_DATA_RECOVERED, value)
                  Ok(())
                }
                Err(_) => {
                  emit(client, @constants.EVENT_DATA_RECOVERED, @types.JsonNull)
                  Ok(())
                }
              }
            }
            Err(err) => {
              emit(
                client,
                @constants.EVENT_NOTIFICATION_ERROR,
                @types.JsonString(@errors.direct_error_to_string(err)),
              )
              Err(err)
            }
          }
        Err(err) => {
          emit(
            client,
            @constants.EVENT_NOTIFICATION_ERROR,
            @types.JsonString(@errors.direct_error_to_string(err)),
          )
          Err(err)
        }
      }
    Ok(value) => {
      emit(client, @constants.EVENT_DATA_RECOVERED, value)
      Ok(())
    }
    Err(err) => {
      emit(
        client,
        @constants.EVENT_NOTIFICATION_ERROR,
        @types.JsonString(@errors.direct_error_to_string(err)),
      )
      Err(err)
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
  while true {
    match client.ws {
      Some(ws) =>
        match @rpc_websocket.receive(ws) {
          Ok(data) => handle_message(client, data)
          Err(e) => {
            emit(
              client,
              @constants.EVENT_ERROR,
              @types.JsonString(@rpc_websocket.ws_error_to_string(e)),
            )
            ignore(close(client))
            break
          }
        }
      None => break
    }
  }
}

// Ping loop for keepalive

///|
async fn ping_loop(client : Client) -> Unit {
  let interval = if client.config.timeout > 0 {
    client.config.timeout / 2
  } else {
    @constants.DEFAULT_REQUEST_TIMEOUT / 2
  }
  while true {
    @async.sleep(interval)
    match client.ws {
      Some(ws) =>
        match @rpc_websocket.ping(ws) {
          Ok(_) => ()
          Err(_) => {
            ignore(close(client))
            break
          }
        }
      None => break
    }
  }
}

// Handle incoming message

///|
async fn handle_message(client : Client, data : Bytes) -> Unit {
  match @rpc_msgpack.decode_message(data) {
    Ok(@rpc_msgpack.Response(resp)) => handle_response(client, resp)
    Ok(@rpc_msgpack.Request(req)) => handle_notification(client, req)
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
async fn handle_response(
  client : Client,
  resp : @rpc_msgpack.RpcResponse,
) -> Unit {
  match client.pending_requests.get(resp.msg_id) {
    Some(promise) => {
      client.pending_requests.remove(resp.msg_id)
      let result = match resp.error {
        Some(err) => Err(rpc_error_from_json(err))
        None => Ok(resp.result)
      }
      promise.result_ch.put(result)
    }
    None => ()
  }
}

// Handle server notification

///|
fn handle_notification(client : Client, req : @rpc_msgpack.RpcRequest) -> Unit {
  let data = if req.params.length() == 0 {
    @types.JsonNull
  } else if req.params.length() == 1 {
    req.params[0]
  } else {
    @types.JsonArray(req.params)
  }
  emit(client, req.rpc_method, data)
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
