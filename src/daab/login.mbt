///|
let login_device_name : String = "daabgo"

///|
let login_device_info : String = "Go Bot Client"

///|
pub async fn run_login(args : ArrayView[String]) -> Result[Unit, String] {
  if has_flag(args, "--help") || has_flag(args, "-h") {
    print_login_help()
    return Ok(())
  }
  let env_path = match flag_value(args, "--env") {
    Some(path) => path
    None => DEFAULT_ENV_PATH
  }
  let token_flag = flag_value(args, "--token")
  if has_flag(args, "--token") && token_flag is None {
    return Err("token is required")
  }
  match token_flag {
    Some(token) => {
      if token == "" {
        return Err("token is required")
      }
      match set_env_value(env_path, ENV_TOKEN_KEY, token) {
        Ok(_) => {
          println("Token saved to: " + env_path)
          return Ok(())
        }
        Err(msg) => return Err("failed to save token: " + msg)
      }
    }
    None => ()
  }
  match has_token(env_path) {
    Ok(true) => {
      println("Already logged in.")
      println(
        "Remove HUBOT_DIRECT_TOKEN or delete " +
        env_path +
        " to login with a different account.",
      )
      return Ok(())
    }
    Ok(false) => ()
    Err(msg) => return Err(msg)
  }
  match load_env_file(env_path) {
    Ok(_) => ()
    Err(msg) => println("Warning: could not load " + env_path + ": " + msg)
  }
  let endpoint = match @sys.get_env_var(ENV_ENDPOINT_KEY) {
    Some(value) => value
    None => @constants.DEFAULT_ENDPOINT
  }
  let proxy_url = resolve_proxy_url()
  let (email, password) = match resolve_credentials() {
    Ok(result) => result
    Err(msg) => return Err(msg)
  }
  if email == "" {
    return Err("email is required")
  }
  if password == "" {
    return Err("password is required")
  }
  println("")
  println("Connecting to direct for authentication...")
  println("Endpoint: " + endpoint)
  println("Authenticating...")
  match request_access_token(endpoint, proxy_url, email, password) {
    Ok(value) => {
      let token = extract_token(value)
      if token == "" {
        return Err(
          "failed to extract token from response: " +
          value.to_string() +
          "\n\n" +
          "The server returned an unexpected response format.\n" +
          "Please contact support if the problem persists.",
        )
      }
      match set_env_value(env_path, ENV_TOKEN_KEY, token) {
        Ok(_) => {
          println("Logged in successfully!")
          println("Token saved to: " + env_path)
          Ok(())
        }
        Err(msg) => Err("failed to save token: " + msg)
      }
    }
    Err(err) if err.has_prefix("connect:") => {
      let err_msg = err[8:].to_string()
      let msg = "failed to connect\n\n" +
        "Troubleshooting:\n" +
        "  - Check your network connection\n" +
        "  - Verify the endpoint URL is correct: " +
        endpoint +
        "\n" +
        "  - Check if a proxy is required\n" +
        "  Error: " +
        err_msg
      Err(msg)
    }
    Err(err) if err == "timeout" => {
      let msg = "login timed out\n\n" +
        "Troubleshooting:\n" +
        "  - The server may be slow or dropping responses\n" +
        "  - Check if a proxy/firewall is interfering\n" +
        "  - Retry, or use `daab login --token <token>` as a workaround"
      Err(msg)
    }
    Err(err) => {
      let err_msg = if err.has_prefix("auth:") {
        err[5:].to_string()
      } else {
        err
      }
      let msg = "login failed\n\n" +
        "Troubleshooting:\n" +
        "  - Verify your email and password are correct\n" +
        "  - Make sure the account is a bot account\n" +
        "  - Check if the account is active\n" +
        "  Error: " +
        err_msg
      Err(msg)
    }
  }
}

///|
async fn request_access_token(
  endpoint : String,
  proxy_url : String,
  email : String,
  password : String,
) -> Result[@types.JsonValue, String] {
  let ws_cfg = @rpc_websocket.default_websocket_config(endpoint)
  let ws_cfg = if proxy_url != "" {
    @rpc_websocket.with_proxy(ws_cfg, proxy_url)
  } else {
    ws_cfg
  }
  let ws = match @rpc_websocket.connect(ws_cfg) {
    Ok(conn) => conn
    Err(err) =>
      return Err(
        "connect:" +
        @errors.direct_error_to_string(@rpc_websocket.ws_error_to_direct(err)),
      )
  }
  let params = [
    @types.JsonString(email),
    @types.JsonString(password),
    @types.JsonString(login_device_name),
    @types.JsonString(login_device_info),
    @types.JsonString(""),
  ]
  let request = @rpc_msgpack.create_request(
    1L,
    @constants.METHOD_CREATE_ACCESS_TOKEN,
    params,
  )
  let payload = match @rpc_msgpack.encode_request(request) {
    Ok(bytes) => bytes
    Err(err) => {
      ignore(@rpc_websocket.close(ws))
      return Err("auth:" + @errors.direct_error_to_string(err))
    }
  }
  match @rpc_websocket.send_binary(ws, payload) {
    Ok(_) => ()
    Err(err) => {
      ignore(@rpc_websocket.close(ws))
      return Err(
        "auth:" +
        @errors.direct_error_to_string(@rpc_websocket.ws_error_to_direct(err)),
      )
    }
  }
  let result = @async.with_timeout_opt(@constants.DEFAULT_REQUEST_TIMEOUT, () => {
    wait_for_login_response(ws, request.msg_id)
  })
  ignore(@rpc_websocket.close(ws))
  match result {
    Some(Ok(value)) => Ok(value)
    Some(Err(err)) => Err("auth:" + @errors.direct_error_to_string(err))
    None => Err("timeout")
  }
}

///|
async fn wait_for_login_response(
  ws : @rpc_websocket.WebSocketConnection,
  msg_id : Int64,
) -> Result[@types.JsonValue, @errors.DirectError] {
  while true {
    let data = match @rpc_websocket.receive(ws) {
      Ok(bytes) => bytes
      Err(err) => return Err(@rpc_websocket.ws_error_to_direct(err))
    }
    match @rpc_msgpack.decode_message(data) {
      Ok(@rpc_msgpack.Response(resp)) => {
        if resp.msg_id != msg_id {
          continue
        }
        match resp.error {
          Some(err) => return Err(rpc_error_from_json(err))
          None => return Ok(resp.result)
        }
      }
      Ok(@rpc_msgpack.Request(req)) =>
        // Some servers emit token-change notification during login.
        if req.rpc_method == @constants.EVENT_ACCESS_TOKEN_CHANGED {
          let token = extract_token(@types.JsonArray(req.params))
          if token != "" {
            return Ok(@types.JsonString(token))
          }
        }
      Err(_) => ()
    }
  }
  abort("unreachable")
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

///|
pub fn extract_token(result : @types.JsonValue) -> String {
  match result {
    @types.JsonString(token) => token
    @types.JsonObject(obj) =>
      match obj.get("access_token") {
        Some(@types.JsonString(token)) => token
        _ => ""
      }
    @types.JsonArray(arr) =>
      match arr.get(0) {
        Some(@types.JsonString(token)) => token
        _ => ""
      }
    _ => ""
  }
}

///|
async fn prompt_credentials() -> Result[(String, String), String] {
  let reader = @stdio.stdin
  @stdio.stdout.write("Email: ")
  let email = match read_line(reader) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  @stdio.stdout.write("Password: ")
  let password = match read_password(reader) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  Ok((email, password))
}

///|
async fn resolve_credentials() -> Result[(String, String), String] {
  let user_id = match @sys.get_env_var(ENV_BOT_USER_ID_KEY) {
    Some(value) if value != "" => Some(value)
    _ => None
  }
  let user_password = match @sys.get_env_var(ENV_USER_PASSWORD_KEY) {
    Some(value) if value != "" => Some(value)
    _ => None
  }
  match (user_id, user_password) {
    (Some(email), Some(password)) => {
      println("Using credentials from environment variables.")
      Ok((email, password))
    }
    _ =>
      match prompt_credentials() {
        Ok(result) => Ok(result)
        Err(msg) => Err("failed to read credentials: " + msg)
      }
  }
}

///|
async fn read_line(reader : @stdio.Input) -> Result[String, String] {
  match reader.read_until("\n") {
    Some(line) => Ok(line.trim().to_string())
    None => Err("stdin closed")
  }
}

///|
async fn read_password(reader : @stdio.Input) -> Result[String, String] {
  let echo_disabled = set_tty_echo(false)
  let result = read_line(reader)
  if echo_disabled {
    ignore(set_tty_echo(true))
    println("")
  }
  result
}

///|
async fn set_tty_echo(enabled : Bool) -> Bool {
  let arg = if enabled { "echo" } else { "-echo" }
  try
    @process.run(
      "stty",
      [arg],
      stdin=@stdio.stdin,
      stdout=@stdio.stdout,
      stderr=@stdio.stderr,
    )
  catch {
    _ => false
  } noraise {
    code => code == 0
  }
}

///|
fn resolve_proxy_url() -> String {
  match @sys.get_env_var(ENV_PROXY_KEY) {
    Some(value) => value
    None =>
      match @sys.get_env_var(ENV_HTTPS_PROXY_KEY) {
        Some(value) => value
        None =>
          match @sys.get_env_var(ENV_HTTP_PROXY_KEY) {
            Some(value) => value
            None => ""
          }
      }
  }
}
