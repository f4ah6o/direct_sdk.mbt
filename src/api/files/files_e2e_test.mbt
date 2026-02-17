///|
let e2e_gate_env : String = "DIRECT_SDK_E2E"

///|
let e2e_talk_id_env : String = "DIRECT_SDK_E2E_TALK_ID"

///|
let e2e_talk_id_env_alt1 : String = "DIRECT4B_E2E_TALK_ID"

///|
let e2e_talk_id_env_alt2 : String = "DIRECT4B_TALK_ID"

///|
let e2e_peer_email_env : String = "DIRECT_SDK_E2E_PEER_EMAIL"

///|
let e2e_self_email_env : String = "DIRECT_SDK_E2E_SELF_EMAIL"

///|
let e2e_total_timeout_ms : Int = 180_000

///|
let download_timeout_ms : Int = 30_000

///|
let direct_api_timeout_ms : Int = 90_000

///|
let direct_api_dir : String = "../direct-api.mbt"

///|
let direct_api_opz_profile : String = "direct-api-dev"

///|
let create_pair_retry_count : Int = 5

///|
let create_pair_retry_interval_ms : Int = 2_000

///|
let create_download_auth_retry_count : Int = 10

///|
let create_download_auth_retry_interval_ms : Int = 1_000

///|
let session_wait_attempts : Int = 100

///|
let session_wait_interval_ms : Int = 200

///|
let temp_file_name : String = ".tmp_direct_sdk_e2e_download_auth.txt"

///|
let daab_login_env_path : String = direct_api_dir +
  "/.tmp_direct_sdk_e2e_daab_login.env"

///|
let daab_login_timeout_ms : Int = 90_000

///|
struct SentFileMeta {
  talk_id : String
  message_id : String
  file_id : String
}

///|
fn log_step(name : String) -> Unit {
  println("[e2e] step: " + name)
}

///|
fn env_non_empty(key : String) -> String? {
  match @sys.get_env_var(key) {
    Some(value) if value != "" => Some(value)
    _ => None
  }
}

///|
fn push_unique_token(tokens : Array[String], token : String) -> Unit {
  if !tokens.contains(token) {
    tokens.push(token)
  }
}

///|
fn parse_env_value(content : String, key : String) -> String? {
  let lines = content.split("\n").to_array()
  for line_view in lines {
    let line = line_view.trim().to_string()
    if line != "" && !line.has_prefix("#") {
      let parts = line.split("=").to_array()
      if parts.length() >= 2 {
        let name = parts[0].trim().to_string()
        if name == key {
          let value = parts[1:].to_array().join("=").trim().to_string()
          if value != "" {
            return Some(value)
          }
        }
      }
    }
  }
  None
}

///|
fn read_direct_api_env_value(key : String) -> String? {
  let path = direct_api_dir + "/.env"
  if !@fs.path_exists(path) {
    return None
  }
  try @fs.read_file_to_string(path) catch {
    _ => None
  } noraise {
    content => parse_env_value(content, key)
  }
}

///|
fn remove_file_quiet(path : String) -> Unit {
  if @fs.path_exists(path) {
    try @fs.remove_file(path) catch {
      _ => ()
    } noraise {
      _ => ()
    }
  }
}

///|
fn read_env_value_if_exists(path : String, key : String) -> String? {
  if !@fs.path_exists(path) {
    return None
  }
  try @fs.read_file_to_string(path) catch {
    _ => None
  } noraise {
    content => parse_env_value(content, key)
  }
}

///|
async fn refresh_token_via_daab_login() -> Result[String?, String] {
  let has_user_id = env_non_empty(@daab.ENV_BOT_USER_ID_KEY) is Some(_)
  let has_password = env_non_empty(@daab.ENV_USER_PASSWORD_KEY) is Some(_)
  if !has_user_id || !has_password {
    return Ok(None)
  }
  remove_file_quiet(daab_login_env_path)
  log_step("refresh-token-daab-login")
  let result = @async.with_timeout_opt(daab_login_timeout_ms, () => {
    @daab.run_login(["--env", daab_login_env_path])
  })
  match result {
    None =>
      return Err(
        "daab login timed out after " + daab_login_timeout_ms.to_string() + "ms",
      )
    Some(Err(msg)) => return Err("daab login failed: " + msg)
    Some(Ok(_)) => ()
  }
  let token = read_env_value_if_exists(daab_login_env_path, @daab.ENV_TOKEN_KEY)
  remove_file_quiet(daab_login_env_path)
  match token {
    Some(value) if value != "" => Ok(Some(value))
    _ => Err("daab login completed but no token was written")
  }
}

///|
fn resolve_e2e_tokens() -> Array[String] {
  let tokens = []
  match env_non_empty("DIRECT_SDK_E2E_TOKEN") {
    Some(token) => push_unique_token(tokens, token)
    None => ()
  }
  match env_non_empty("HUBOT_DIRECT_TOKEN") {
    Some(token) => push_unique_token(tokens, token)
    None => ()
  }
  match env_non_empty("DIRECT4B_API_TOKEN") {
    Some(token) => push_unique_token(tokens, token)
    None => ()
  }
  match env_non_empty("DIRECT_API_ACCESS_TOKEN") {
    Some(token) => push_unique_token(tokens, token)
    None => ()
  }
  match read_direct_api_env_value("HUBOT_DIRECT_TOKEN") {
    Some(token) => push_unique_token(tokens, token)
    None => ()
  }
  match read_direct_api_env_value("DIRECT4B_API_TOKEN") {
    Some(token) => push_unique_token(tokens, token)
    None => ()
  }
  match read_direct_api_env_value("DIRECT_API_ACCESS_TOKEN") {
    Some(token) => push_unique_token(tokens, token)
    None => ()
  }
  tokens
}

///|
fn resolve_endpoint() -> String? {
  env_non_empty("HUBOT_DIRECT_ENDPOINT")
}

///|
fn resolve_talk_id_override() -> String? {
  for key in [e2e_talk_id_env, e2e_talk_id_env_alt1, e2e_talk_id_env_alt2] {
    match env_non_empty(key) {
      Some(value) => return Some(value)
      None => ()
    }
  }
  None
}

///|
fn decode_data(data : &@io.Data) -> String {
  @utf8.decode_lossy(data.binary().view())
}

///|
fn temp_file_path() -> String {
  direct_api_dir + "/" + temp_file_name
}

///|
fn cleanup_temp_file() -> Unit {
  remove_file_quiet(temp_file_path())
}

///|
fn close_client_quiet(client : @rpc_client.Client) -> Unit {
  ignore(@rpc_client.close(client))
}

///|
fn last_non_empty_line(text : String) -> String? {
  let lines = text.split("\n").to_array()
  let mut index = lines.length()
  while index > 0 {
    index = index - 1
    let line = lines[index].trim().to_string()
    if line != "" {
      return Some(line)
    }
  }
  None
}

///|
fn json_string_field(obj : Map[String, Json], key : String) -> String? {
  match obj.get(key) {
    Some(Json::String(value)) if value != "" => Some(value)
    Some(Json::Number(value, ..)) => Some(value.to_int64().to_string())
    _ => None
  }
}

///|
fn parse_json_object_line(line : String) -> Result[Map[String, Json], String] {
  try @json.parse(line) catch {
    _ => Err("failed to parse json line: " + line)
  } noraise {
    json =>
      match json {
        Json::Object(obj) => Ok(obj)
        _ => Err("expected JSON object line: " + line)
      }
  }
}

///|
fn parse_talk_id_from_output(stdout_text : String) -> Result[String, String] {
  let line = match last_non_empty_line(stdout_text) {
    Some(value) => value
    None => return Err("direct-api output is empty")
  }
  let obj = match parse_json_object_line(line) {
    Ok(value) => value
    Err(msg) => return Err(msg + "\nfull output:\n" + stdout_text)
  }
  match json_string_field(obj, "talk_id") {
    Some(value) => Ok(value)
    None => Err("talk_id not found in output: " + line)
  }
}

///|
fn parse_sent_file_meta_from_output(
  stdout_text : String,
) -> Result[SentFileMeta, String] {
  let line = match last_non_empty_line(stdout_text) {
    Some(value) => value
    None => return Err("direct-api output is empty")
  }
  let obj = match parse_json_object_line(line) {
    Ok(value) => value
    Err(msg) => return Err(msg + "\nfull output:\n" + stdout_text)
  }
  let talk_id = match json_string_field(obj, "talk_id") {
    Some(value) => value
    None => return Err("talk_id not found in output: " + line)
  }
  let message_id = match json_string_field(obj, "message_id") {
    Some(value) => value
    None => return Err("message_id not found in output: " + line)
  }
  let file_id = match json_string_field(obj, "file_id") {
    Some(value) => value
    None => return Err("file_id not found in output: " + line)
  }
  Ok({ talk_id, message_id, file_id })
}

///|
fn command_expects_json_output(command_args : Array[String]) -> Bool {
  match command_args.get(0) {
    Some("pair-talk-by-email") => true
    Some("create-pair-talk") => true
    Some("send-file-meta") => true
    _ => false
  }
}

///|
fn output_looks_like_json_object(stdout_text : String) -> Bool {
  match last_non_empty_line(stdout_text) {
    Some(line) => line.has_prefix("{") && line.has_suffix("}")
    None => false
  }
}

///|
fn output_is_valid_for_command(
  command_args : Array[String],
  stdout_text : String,
) -> Bool {
  if command_expects_json_output(command_args) {
    return output_looks_like_json_object(stdout_text)
  }
  match command_args.get(0) {
    Some("me") => stdout_text.contains("User ID:")
    _ => true
  }
}

///|
async fn run_direct_api_command(
  command_args : Array[String],
  direct_api_token : String?,
) -> Result[String, String] {
  if !@fs.path_exists(direct_api_dir + "/moon.mod.json") {
    return Err("direct-api repo not found at " + direct_api_dir)
  }
  let args = ["run", "src/main", "--target", "native", "--"] + command_args
  let extra_env : Map[String, String] = {}
  match direct_api_token {
    Some(token) => extra_env["DIRECT_API_ACCESS_TOKEN"] = token
    None => ()
  }
  let errors = []

  let opz_output = @async.with_timeout_opt(direct_api_timeout_ms, () => {
    @process.collect_output(
      "opz",
      [direct_api_opz_profile, "--", "just", "run"] + command_args,
      extra_env~,
      cwd=direct_api_dir,
    )
  })
  match opz_output {
    Some((opz_code, opz_stdout, opz_stderr)) => {
      let stdout_text = decode_data(opz_stdout)
      let stderr_text = decode_data(opz_stderr)
      if opz_code == 0 {
        if !output_is_valid_for_command(command_args, stdout_text) {
          errors.push(
            "opz runner returned unexpected output\nstdout:\n" +
            stdout_text +
            "\nstderr:\n" +
            stderr_text,
          )
        } else {
          return Ok(stdout_text)
        }
      } else {
        errors.push(
          "opz runner failed (exit=" +
          opz_code.to_string() +
          ")\nstdout:\n" +
          stdout_text +
          "\nstderr:\n" +
          stderr_text,
        )
      }
    }
    None =>
      errors.push(
        "opz runner timed out after " + direct_api_timeout_ms.to_string() + "ms",
      )
  }

  let moon_output = @async.with_timeout_opt(direct_api_timeout_ms, () => {
    @process.collect_output("moon", args, extra_env~, cwd=direct_api_dir)
  })
  match moon_output {
    Some((moon_code, moon_stdout, moon_stderr)) => {
      let stdout_text = decode_data(moon_stdout)
      let stderr_text = decode_data(moon_stderr)
      if moon_code == 0 {
        if !output_is_valid_for_command(command_args, stdout_text) {
          errors.push(
            "moon runner returned unexpected output\nstdout:\n" +
            stdout_text +
            "\nstderr:\n" +
            stderr_text,
          )
        } else {
          return Ok(stdout_text)
        }
      } else {
        errors.push(
          "moon runner failed (exit=" +
          moon_code.to_string() +
          ")\nstdout:\n" +
          stdout_text +
          "\nstderr:\n" +
          stderr_text,
        )
      }
    }
    None =>
      errors.push(
        "moon runner timed out after " +
        direct_api_timeout_ms.to_string() +
        "ms",
      )
  }
  Err(errors.join("\n\n"))
}

///|
async fn refresh_direct_api_token_if_possible(
  direct_api_token : String?,
) -> Unit {
  let extra_env : Map[String, String] = {}
  match direct_api_token {
    Some(token) => extra_env["DIRECT_API_ACCESS_TOKEN"] = token
    None => ()
  }
  let _ = @async.with_timeout_opt(direct_api_timeout_ms, () => {
    @process.collect_output(
      "opz",
      [direct_api_opz_profile, "--", "just", "run", "refresh-token"],
      extra_env~,
      cwd=direct_api_dir,
    )
  })
}

///|
async fn resolve_talk_id_via_direct_api(
  peer_email : String,
  direct_api_token : String?,
) -> Result[String, String] {
  let cmd_args = ["pair-talk-by-email", peer_email]
  match env_non_empty(e2e_self_email_env) {
    Some(self_email) => {
      cmd_args.push("--self-email")
      cmd_args.push(self_email)
    }
    None => ()
  }
  let stdout_text = match run_direct_api_command(cmd_args, direct_api_token) {
    Ok(text) => text
    Err(msg) => {
      if !msg.contains("pair talk not found") {
        return Err(msg)
      }
      let mut create_error = "create-pair-talk failed"
      for _ in 0..<create_pair_retry_count {
        let create_stdout = match
          run_direct_api_command(
            ["create-pair-talk", peer_email],
            direct_api_token,
          ) {
          Ok(text) => text
          Err(create_err) => {
            create_error = create_err
            if create_err.contains("API is currently unavailable") ||
              create_err.contains("(503)") {
              @async.sleep(create_pair_retry_interval_ms)
              continue
            }
            return Err(create_err)
          }
        }
        return parse_talk_id_from_output(create_stdout)
      }
      return Err(create_error)
    }
  }
  parse_talk_id_from_output(stdout_text)
}

///|
async fn send_file_meta_via_direct_api(
  talk_id : String,
  direct_api_token : String?,
) -> Result[SentFileMeta, String] {
  let stdout_text = match
    run_direct_api_command(
      ["send-file-meta", talk_id, "./" + temp_file_name, "--text", "sdk-e2e"],
      direct_api_token,
    ) {
    Ok(text) => text
    Err(msg) => return Err(msg)
  }
  parse_sent_file_meta_from_output(stdout_text)
}

///|
fn resolve_direct_api_token() -> String? {
  match env_non_empty("DIRECT_SDK_E2E_DIRECT_API_TOKEN") {
    Some(token) => Some(token)
    None => read_direct_api_env_value("DIRECT_API_ACCESS_TOKEN")
  }
}

///|
fn parse_email_from_me_output(stdout_text : String) -> String? {
  let lines = stdout_text.split("\n").to_array()
  for line_view in lines {
    let line = line_view.trim().to_string()
    if line.has_prefix("Email:") {
      let value = line.split(":").to_array()[1:]
        .to_array()
        .join(":")
        .trim()
        .to_string()
        .to_lower()
      if value != "" {
        return Some(value)
      }
    }
  }
  None
}

///|
fn parse_sdk_email(value : @types.JsonValue) -> String? {
  match value {
    @types.JsonObject(obj) =>
      match obj.get("email") {
        Some(@types.JsonString(email)) if email != "" => Some(email.to_lower())
        _ => None
      }
    _ => None
  }
}

///|
async fn resolve_sdk_email(
  client : @rpc_client.Client,
) -> Result[String, String] {
  match @rpc_client.call(client, @constants.METHOD_GET_ME, []) {
    Ok(value) =>
      match parse_sdk_email(value) {
        Some(email) => Ok(email)
        None => Err("get_me response does not include email")
      }
    Err(err) => Err("get_me failed: " + @errors.direct_error_to_string(err))
  }
}

///|
async fn resolve_talk_id_with_fallback(
  _client : @rpc_client.Client,
  direct_api_token : String?,
) -> Result[String, String] {
  match resolve_talk_id(direct_api_token) {
    Ok(value) => Ok(value)
    Err(msg) => {
      if resolve_talk_id_override() is Some(_) {
        return Err(msg)
      }
      let me_output = match run_direct_api_command(["me"], direct_api_token) {
        Ok(text) => text
        Err(me_err) => return Err(msg + "\n\nsender resolve failed: " + me_err)
      }
      let sdk_email = match parse_email_from_me_output(me_output) {
        Some(value) => value
        None =>
          return Err(
            msg +
            "\n\nsender resolve failed: email not found in direct-api me output",
          )
      }
      resolve_talk_id_via_direct_api(sdk_email, direct_api_token)
    }
  }
}

///|
async fn resolve_talk_id(direct_api_token : String?) -> Result[String, String] {
  match resolve_talk_id_override() {
    Some(value) => Ok(value)
    None =>
      match env_non_empty(e2e_peer_email_env) {
        Some(peer_email) =>
          resolve_talk_id_via_direct_api(peer_email, direct_api_token)
        None =>
          Err(
            "talk id is not set. set " +
            e2e_talk_id_env +
            " or " +
            e2e_peer_email_env,
          )
      }
  }
}

///|
async fn download_with_auth(auth : DownloadAuth) -> Result[Bytes, String] {
  let result = @async.with_timeout_opt(download_timeout_ms, () => {
    let (resp, body) = @http.get(auth.url, headers=auth.headers)
    if resp.code < 200 || resp.code >= 300 {
      Err("download HTTP failed: " + resp.code.to_string() + " " + resp.reason)
    } else {
      Ok(body.binary())
    }
  })
  match result {
    Some(v) => v
    None =>
      Err("download timed out after " + download_timeout_ms.to_string() + "ms")
  }
}

///|
async fn create_download_auth_with_retry(
  client : @rpc_client.Client,
  talk_id : @types.ID,
  message_id : @types.ID,
  file_id : @types.ID,
) -> Result[DownloadAuth, String] {
  let mut last_error = "create_download_auth failed"
  for _ in 0..<create_download_auth_retry_count {
    match create_download_auth(client, talk_id, message_id, file_id) {
      Ok(value) => return Ok(value)
      Err(err) => {
        let msg = @errors.direct_error_to_string(err)
        last_error = msg
        if msg.contains("RPC error 400") {
          @async.sleep(create_download_auth_retry_interval_ms)
          continue
        }
        return Err(msg)
      }
    }
  }
  Err(last_error)
}

///|
fn is_auth_session_error(msg : String) -> Bool {
  let lower = msg.to_lower()
  lower.contains("invalid session") ||
  lower.contains("rpc error 401") ||
  lower.contains("unauthorized")
}

///|
async fn wait_for_rpc_session(
  client : @rpc_client.Client,
) -> Result[Unit, String] {
  let mut last_error = "session not ready after wait"
  for _ in 0..<session_wait_attempts {
    match @rpc_client.call(client, @constants.METHOD_UPDATE_LAST_USED_AT, []) {
      Ok(_) => return Ok(())
      Err(err) => {
        let msg = @errors.direct_error_to_string(err)
        last_error = msg
        if is_auth_session_error(msg) {
          @async.sleep(session_wait_interval_ms)
          continue
        }
        return Err("session check failed: " + msg)
      }
    }
  }
  Err(last_error)
}

///|
async fn resolve_file_id_from_attachments(
  client : @rpc_client.Client,
  talk_id : @types.ID,
  message_id_str : String,
  fallback_file_id : @types.ID,
) -> @types.ID {
  let attachments = match get_attachments(client, talk_id, 100) {
    Ok(value) => value
    Err(err) => {
      println(
        "[e2e] get_attachments failed: " + @errors.direct_error_to_string(err),
      )
      return fallback_file_id
    }
  }
  for att in attachments {
    if @types.id_to_string(att.message_id) == message_id_str {
      println(
        "[e2e] file_id resolved from attachments: " +
        @types.id_to_string(att.file_id),
      )
      return att.file_id
    }
  }
  println(
    "[e2e] file_id fallback from direct-api output: " +
    @types.id_to_string(fallback_file_id),
  )
  fallback_file_id
}

///|
async fn run_e2e_flow(client : @rpc_client.Client) -> Result[Unit, String] {
  let mut direct_api_token = resolve_direct_api_token()

  log_step("refresh-direct-api-token")
  refresh_direct_api_token_if_possible(direct_api_token)
  direct_api_token = resolve_direct_api_token()

  log_step("resolve-talk")
  let mut talk_id_str = match
    resolve_talk_id_with_fallback(client, direct_api_token) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  let mut sdk_email : String? = None
  match @rpc_client.call(client, @constants.METHOD_GET_ME, []) {
    Ok(value) => {
      println("[e2e] sdk raw get_me=" + value.to_string())
      sdk_email = parse_sdk_email(value)
    }
    Err(err) =>
      println(
        "[e2e] sdk raw get_me failed: " + @errors.direct_error_to_string(err),
      )
  }
  let mut contains_target = false
  match @api_talks.get_talks(client) {
    Ok(talks) => {
      for talk in talks {
        if @types.id_to_string(talk.id) == talk_id_str {
          contains_target = true
          break
        }
      }
      println(
        "[e2e] sdk visible talks=" +
        talks.length().to_string() +
        " contains_target=" +
        contains_target.to_string(),
      )
    }
    Err(err) =>
      println("[e2e] get_talks failed: " + @errors.direct_error_to_string(err))
  }
  if !contains_target {
    log_step("resolve-talk-fallback")
    let mut resolved_fallback = false
    let mut fallback_error = "talk fallback is not available"
    match sdk_email {
      Some(email) =>
        match resolve_talk_id_via_direct_api(email, direct_api_token) {
          Ok(fallback_talk_id) => {
            talk_id_str = fallback_talk_id
            resolved_fallback = true
            println(
              "[e2e] fallback talk resolved via direct-api: " + talk_id_str,
            )
          }
          Err(msg) => {
            fallback_error = msg
            println("[e2e] direct-api fallback talk resolve failed: " + msg)
          }
        }
      None =>
        match resolve_sdk_email(client) {
          Ok(email) =>
            match resolve_talk_id_via_direct_api(email, direct_api_token) {
              Ok(fallback_talk_id) => {
                talk_id_str = fallback_talk_id
                resolved_fallback = true
                println(
                  "[e2e] fallback talk resolved via direct-api: " + talk_id_str,
                )
              }
              Err(msg) => {
                fallback_error = msg
                println("[e2e] direct-api fallback talk resolve failed: " + msg)
              }
            }
          Err(msg) => {
            fallback_error = msg
            println("[e2e] sdk email resolve failed: " + msg)
          }
        }
    }
    if !resolved_fallback {
      return Err(
        "target talk is not visible to sdk user and fallback talk resolve failed: " +
        fallback_error,
      )
    }
  }

  log_step("prepare-temp-file")
  let expected_text = "direct-sdk-e2e-create-download-auth\n"
  let expected_bytes = @utf8.encode(expected_text)
  @fs.write_string_to_file(temp_file_path(), expected_text)

  log_step("send-file-via-direct-api")
  let sent = match
    send_file_meta_via_direct_api(talk_id_str, direct_api_token) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }

  log_step("create-download-auth")
  let talk_id : @types.ID = @types.IDString(sent.talk_id)
  let message_id : @types.ID = @types.IDString(sent.message_id)
  let file_id = resolve_file_id_from_attachments(
    client,
    talk_id,
    sent.message_id,
    @types.IDString(sent.file_id),
  )
  println(
    "[e2e] ids talk=" +
    @types.id_to_string(talk_id) +
    " message=" +
    @types.id_to_string(message_id) +
    " file=" +
    @types.id_to_string(file_id),
  )
  let auth = match
    create_download_auth_with_retry(client, talk_id, message_id, file_id) {
    Ok(value) => value
    Err(msg) => return Err("create_download_auth failed: " + msg)
  }

  log_step("download-file")
  let downloaded = match download_with_auth(auth) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  if downloaded != expected_bytes {
    return Err("downloaded bytes do not match uploaded file")
  }
  Ok(())
}

///|
fn build_e2e_client(token : String) -> @rpc_client.Client {
  let cfg = match resolve_endpoint() {
    Some(endpoint) =>
      @config.default_config()
      |> @config.with_token(token)
      |> @config.with_endpoint(endpoint)
      |> @config.with_timeout(5_000)
    None =>
      @config.default_config()
      |> @config.with_token(token)
      |> @config.with_timeout(5_000)
  }
  @rpc_client.new_client(cfg)
}

///|
async fn run_create_download_auth_e2e_with_token(
  token : String,
) -> Result[Unit, String] {
  let client = build_e2e_client(token)
  let result : Result[Unit, String] = @async.with_task_group(tasks => {
    log_step("connect")
    match @rpc_client.connect(client, tasks) {
      Ok(_) => ()
      Err(err) => {
        close_client_quiet(client)
        tasks.return_immediately(
          Err("connect failed: " + @errors.direct_error_to_string(err)),
        )
        abort("unreachable")
      }
    }
    log_step("wait-session")
    match wait_for_rpc_session(client) {
      Ok(_) => ()
      Err(msg) => {
        cleanup_temp_file()
        close_client_quiet(client)
        tasks.return_immediately(Err(msg))
        abort("unreachable")
      }
    }

    let result = run_e2e_flow(client)
    cleanup_temp_file()
    close_client_quiet(client)
    tasks.return_immediately(result)
    abort("unreachable")
  })
  result
}

///|
async fn run_create_download_auth_e2e() -> Result[Unit, String] {
  let tokens = resolve_e2e_tokens()
  if tokens.length() == 0 {
    match refresh_token_via_daab_login() {
      Ok(Some(token)) => push_unique_token(tokens, token)
      Ok(None) =>
        return Err(
          "token not found: set DIRECT_SDK_E2E_TOKEN, HUBOT_DIRECT_TOKEN, " +
          "DIRECT4B_API_TOKEN, or DIRECT_API_ACCESS_TOKEN, " +
          "or set DIRECT4B_BOT_USER_ID and DIRECT4B_USER_PASSWORD for auto login",
        )
      Err(msg) => return Err(msg)
    }
  }
  let mut last_error = "e2e failed"
  let mut index = 0
  let mut tried_daab_login = false
  while index < tokens.length() {
    let token = tokens[index]
    index = index + 1
    match run_create_download_auth_e2e_with_token(token) {
      Ok(_) => return Ok(())
      Err(msg) => {
        last_error = msg
        if !is_auth_session_error(msg) {
          return Err(last_error)
        }
        if !tried_daab_login && index >= tokens.length() {
          tried_daab_login = true
          match refresh_token_via_daab_login() {
            Ok(Some(new_token)) => push_unique_token(tokens, new_token)
            Ok(None) => ()
            Err(login_err) => return Err(login_err + "\nlast rpc error: " + msg)
          }
        }
      }
    }
  }
  if is_auth_session_error(last_error) && tried_daab_login {
    Err(last_error + "\ntried daab login token refresh once")
  } else {
    Err(last_error)
  }
}

///|
async test "e2e create_download_auth downloads attached file" {
  if @sys.get_env_var(e2e_gate_env) != Some("1") {
    println("skip e2e: set DIRECT_SDK_E2E=1 to enable")
    return
  }
  match
    @async.with_timeout_opt(e2e_total_timeout_ms, () => {
      run_create_download_auth_e2e()
    }) {
    Some(Ok(_)) => ()
    Some(Err(msg)) => fail(msg)
    None => fail("e2e timeout after " + e2e_total_timeout_ms.to_string() + "ms")
  }
}
