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
  let (email, password) = match prompt_credentials() {
    Ok(result) => result
    Err(msg) => return Err("failed to read credentials: " + msg)
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
  let cfg = @config.new_config("")
  let cfg = @config.with_endpoint(cfg, endpoint)
  let cfg = if proxy_url != "" {
    @config.with_proxy(cfg, proxy_url)
  } else {
    cfg
  }
  let client = @rpc_client.new_client(cfg)
  let result = @async.with_task_group(fn(tasks) {
    match @rpc_client.connect(client, tasks) {
      Ok(_) => {
        println("Authenticating...")
        let params = [
          @types.JsonString(email),
          @types.JsonString(password),
          @types.JsonString(login_device_name),
          @types.JsonString(login_device_info),
          @types.JsonString(""),
        ]
        let call_result = @rpc_client.call(
          client,
          @constants.METHOD_CREATE_ACCESS_TOKEN,
          params,
        )
        ignore(@rpc_client.close(client))
        Ok(call_result)
      }
      Err(err) => Err(err)
    }
  })
  match result {
    Ok(call_result) =>
      match call_result {
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
        Err(err) => {
          let msg = "login failed\n\n" +
            "Troubleshooting:\n" +
            "  - Verify your email and password are correct\n" +
            "  - Make sure the account is a bot account\n" +
            "  - Check if the account is active\n" +
            "  Error: " +
            @errors.direct_error_to_string(err)
          Err(msg)
        }
      }
    Err(err) => {
      let msg = "failed to connect\n\n" +
        "Troubleshooting:\n" +
        "  - Check your network connection\n" +
        "  - Verify the endpoint URL is correct: " +
        endpoint +
        "\n" +
        "  - Check if a proxy is required\n" +
        "  Error: " +
        @errors.direct_error_to_string(err)
      Err(msg)
    }
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
async fn read_line(
  reader : @stdio.Input,
) -> Result[String, String] {
  match reader.read_until("\n") {
    Some(line) => Ok(line.trim().to_string())
    None => Err("stdin closed")
  }
}

///|
async fn read_password(
  reader : @stdio.Input,
) -> Result[String, String] {
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
