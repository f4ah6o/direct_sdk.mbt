///|
let e2e_gate_env : String = "DIRECT_SDK_E2E"

///|
let e2e_receive_gate_env : String = "DIRECT_SDK_E2E_RECEIVE_ONLY"

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
let download_max_redirects : Int = 5

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
let session_wait_attempts : Int = 100

///|
let session_wait_interval_ms : Int = 200

///|
let message_event_wait_timeout_ms : Int = 30_000

///|
let message_text_tag_prefix : String = "direct-sdk-e2e-create-download-auth-"

///|
let message_event_poll_interval_ms : Int = 100

///|
let message_event_wait_attempts : Int = 300

///|
let receive_end_message : String = "end."

///|
let receive_poll_interval_ms : Int = 200

///|
let receive_wait_attempts : Int = 3000

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
struct DownloadRequest {
  url : String
  headers : Map[String, String]
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
    @daab.run_login(["--force", "--env", daab_login_env_path])
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
    _ =>
      match env_non_empty(@daab.ENV_TOKEN_KEY) {
        Some(value) => Ok(Some(value))
        None => Err("daab login completed but no token was written")
      }
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
  match read_direct_api_env_value("HUBOT_DIRECT_TOKEN") {
    Some(token) => push_unique_token(tokens, token)
    None => ()
  }
  match read_direct_api_env_value("DIRECT4B_API_TOKEN") {
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
  text_tag : String,
) -> Result[SentFileMeta, String] {
  let stdout_text = match
    run_direct_api_command(
      ["send-file-meta", talk_id, "./" + temp_file_name, "--text", text_tag],
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
async fn download_with_request(req : DownloadRequest) -> Result[Bytes, String] {
  let result = @async.with_timeout_opt(download_timeout_ms, () => {
    follow_download_redirect(req, 0)
  })
  match result {
    Some(v) => v
    None =>
      Err("download timed out after " + download_timeout_ms.to_string() + "ms")
  }
}

///|
async fn follow_download_redirect(
  req : DownloadRequest,
  redirects : Int,
) -> Result[Bytes, String] {
  let (resp, body) = @http.get(req.url, headers=req.headers)
  if resp.code >= 200 && resp.code < 300 {
    return Ok(body.binary())
  }
  if resp.code == 301 ||
    resp.code == 302 ||
    resp.code == 303 ||
    resp.code == 307 ||
    resp.code == 308 {
    if redirects >= download_max_redirects {
      return Err(
        "download redirect exceeded " + download_max_redirects.to_string(),
      )
    }
    let location = match resp.headers.get("location") {
      Some(value) if value != "" => value
      _ =>
        return Err(
          "download redirect missing location header (" +
          resp.code.to_string() +
          ")",
        )
    }
    return follow_download_redirect(
      { url: location, headers: req.headers },
      redirects + 1,
    )
  }
  Err("download HTTP failed: " + resp.code.to_string() + " " + resp.reason)
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
fn build_message_text_tag() -> String {
  message_text_tag_prefix + @env.now().to_int().to_string()
}

///|
fn is_matching_message_event(
  msg : @types.ReceivedMessage,
  talk_id : String,
  message_id : String,
  text_tag : String,
) -> Bool {
  if msg.talk_id != talk_id {
    return false
  }
  if msg.id == message_id {
    return true
  }
  msg.text != "" && msg.text.contains(text_tag)
}

///|
async fn wait_for_message_event(
  events : Array[@types.ReceivedMessage],
  talk_id : String,
  message_id : String,
  text_tag : String,
) -> Result[@types.ReceivedMessage, String] {
  let mut index = 0
  for _ in 0..<message_event_wait_attempts {
    while index < events.length() {
      let msg = events[index]
      index = index + 1
      if is_matching_message_event(msg, talk_id, message_id, text_tag) {
        return Ok(msg)
      }
    }
    @async.sleep(message_event_poll_interval_ms)
  }
  Err(
    "message event timeout after " +
    message_event_wait_timeout_ms.to_string() +
    "ms",
  )
}

///|
async fn run_e2e_flow(client : @rpc_client.Client) -> Result[Unit, String] {
  let mut direct_api_token = resolve_direct_api_token()

  log_step("refresh-direct-api-token")
  refresh_direct_api_token_if_possible(direct_api_token)
  direct_api_token = resolve_direct_api_token()

  log_step("resolve-talk")
  let talk_id_str = match resolve_talk_id(direct_api_token) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }

  let message_events : Array[@types.ReceivedMessage] = []
  log_step("listen-message")
  @rpc_client.on_message(client, fn(msg) {
    if msg.talk_id == talk_id_str {
      message_events.push(msg)
    }
  })

  let text_tag = build_message_text_tag()

  log_step("prepare-temp-file")
  let expected_text = "direct-sdk-e2e-create-download-auth\n"
  let expected_bytes = @utf8.encode(expected_text)
  @fs.write_string_to_file(temp_file_path(), expected_text)

  log_step("send-file-via-direct-api")
  let sent = match
    send_file_meta_via_direct_api(talk_id_str, direct_api_token, text_tag) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  println(
    "[e2e] sent file message_id=" + sent.message_id + " file_id=" + sent.file_id,
  )

  log_step("wait-message-event")
  let observed = match
    wait_for_message_event(
      message_events,
      talk_id_str,
      sent.message_id,
      text_tag,
    ) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  println(
    "[e2e] observed message id=" +
    observed.id +
    " talk=" +
    observed.talk_id +
    " text=" +
    observed.text,
  )

  log_step("resolve-download-request")
  let talk_id : @types.ID = @types.string_to_id(sent.talk_id)
  let req_raw = match resolve_receive_only_download_request(observed) {
    Some(value) => value
    None => {
      let attachment = match
        find_attachment_for_message(client, talk_id, sent.message_id) {
        Ok(Some(value)) => value
        Ok(None) =>
          return Err(
            "attachment not found for sent message: " +
            sent.message_id +
            " (talk=" +
            sent.talk_id +
            ")",
          )
        Err(msg) => return Err("get_attachments failed: " + msg)
      }
      if attachment.url == "" {
        return Err(
          "attachment url not found for sent message: " + sent.message_id,
        )
      }
      println(
        "[e2e] attachment url resolved from get_attachments message=" +
        sent.message_id +
        " url=" +
        attachment.url,
      )
      { url: attachment.url, headers: Map::new() }
    }
  }
  let req = with_bearer_auth(req_raw, @rpc_client.get_config(client).token)
  println(
    "[e2e] attachment url found message=" + sent.message_id + " url=" + req.url,
  )

  log_step("download-file")
  let downloaded = match download_with_request(req) {
    Ok(value) => value
    Err(msg) => return Err(msg)
  }
  if downloaded != expected_bytes {
    return Err("downloaded bytes do not match uploaded file")
  }
  Ok(())
}

///|
async fn find_attachment_for_message(
  client : @rpc_client.Client,
  talk_id : @types.ID,
  message_id_str : String,
) -> Result[Attachment?, String] {
  let attachments = match get_attachments(client, talk_id, 100) {
    Ok(value) => value
    Err(err) => return Err(@errors.direct_error_to_string(err))
  }
  for att in attachments {
    if @types.id_to_string(att.message_id) == message_id_str {
      return Ok(Some(att))
    }
  }
  Ok(None)
}

///|
fn url_from_object(obj : Map[String, @types.JsonValue]) -> String? {
  for key in ["url", "get_url", "download_url", "attachment_url"] {
    match obj.get(key) {
      Some(@types.JsonString(value)) if value != "" => return Some(value)
      _ => ()
    }
  }
  None
}

///|
fn first_file_url_in_content(content : @types.JsonValue) -> String? {
  match content {
    @types.JsonObject(obj) => {
      match url_from_object(obj) {
        Some(url) => return Some(url)
        None => ()
      }
      for key in ["file", "attachment", "files", "attachments"] {
        match obj.get(key) {
          Some(next) =>
            match first_file_url_in_content(next) {
              Some(url) => return Some(url)
              None => ()
            }
          None => ()
        }
      }
      None
    }
    @types.JsonArray(items) => {
      for item in items {
        match first_file_url_in_content(item) {
          Some(url) => return Some(url)
          None => ()
        }
      }
      None
    }
    _ => None
  }
}

///|
fn resolve_receive_only_download_request(
  msg : @types.ReceivedMessage,
) -> DownloadRequest? {
  let url = if msg.attachment_url != "" {
    msg.attachment_url
  } else {
    match first_file_url_in_content(msg.content) {
      Some(value) => value
      None => ""
    }
  }
  if url == "" {
    return None
  }
  Some({ url, headers: Map::new() })
}

///|
fn with_bearer_auth(req : DownloadRequest, token : String) -> DownloadRequest {
  if token == "" {
    return req
  }
  let mut url = req.url
  if (
      url.has_prefix("https://api.direct4b.com/") ||
      url.has_prefix("http://api.direct4b.com/")
    ) &&
    !url.contains("Authorization=") {
    let separator = if url.contains("?") { "&" } else { "?" }
    // Match direct-js behavior for file download authentication.
    url = url + separator + "Authorization=ALB%20" + token
  }
  { url, headers: req.headers }
}

///|
fn map_has_key(obj : Map[String, @types.JsonValue], key : String) -> Bool {
  match obj.get(key) {
    Some(_) => true
    None => false
  }
}

///|
fn content_has_file_hint(content : @types.JsonValue) -> Bool {
  match content {
    @types.JsonObject(obj) =>
      map_has_key(obj, "file_id") ||
      map_has_key(obj, "file_id_str") ||
      map_has_key(obj, "file") ||
      map_has_key(obj, "attachment") ||
      map_has_key(obj, "files") ||
      map_has_key(obj, "attachments")
    @types.JsonArray(items) => {
      for item in items {
        if content_has_file_hint(item) {
          return true
        }
      }
      false
    }
    _ => false
  }
}

///|
fn maybe_file_message(msg : @types.ReceivedMessage) -> Bool {
  msg.msg_type == @types.MsgTypeFile ||
  msg.msg_type == @types.MsgTypeTextMultipleFile ||
  msg.attachment_url != "" ||
  content_has_file_hint(msg.content)
}

///|
async fn run_receive_only_flow(
  client : @rpc_client.Client,
) -> Result[Unit, String] {
  let token = @rpc_client.get_config(client).token
  let message_events : Array[@types.ReceivedMessage] = []
  log_step("listen-message(receive-only)")
  @rpc_client.on_message(client, fn(msg) { message_events.push(msg) })

  let mut consumed_index = 0
  let processed_ids : Array[String] = []
  let mut downloaded_count = 0

  println(
    "[e2e] receive-only started. send file to bot and send `" +
    receive_end_message +
    "` to finish.",
  )

  for _ in 0..<receive_wait_attempts {
    while consumed_index < message_events.length() {
      let msg = message_events[consumed_index]
      consumed_index = consumed_index + 1

      if processed_ids.contains(msg.id) {
        continue
      }
      processed_ids.push(msg.id)
      println(
        "[e2e] observed message id=" +
        msg.id +
        " type=" +
        @types.msg_type_to_wire(msg.msg_type).to_string() +
        " talk=" +
        msg.talk_id +
        " text=" +
        msg.text,
      )

      if msg.text.trim() == receive_end_message {
        if downloaded_count > 0 {
          println(
            "[e2e] receive-only finished. downloaded files=" +
            downloaded_count.to_string(),
          )
          return Ok(())
        }
        return Err(
          "end received but no file was downloaded (send file before end.)",
        )
      }

      if !maybe_file_message(msg) {
        continue
      }
      let req_raw = match resolve_receive_only_download_request(msg) {
        Some(value) => value
        None => {
          println("[e2e] file-like message had no downloadable url: " + msg.id)
          continue
        }
      }
      let req = with_bearer_auth(req_raw, token)
      println(
        "[e2e] attachment url found message=" + msg.id + " url=" + req.url,
      )
      match download_with_request(req) {
        Ok(bytes) => {
          downloaded_count = downloaded_count + 1
          println(
            "[e2e] downloaded attachment bytes=" +
            bytes.length().to_string() +
            " message=" +
            msg.id,
          )
        }
        Err(err) =>
          return Err("download failed for message=" + msg.id + ": " + err)
      }
    }
    @async.sleep(receive_poll_interval_ms)
  }
  Err("receive-only timeout waiting for `" + receive_end_message + "`")
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
          "or DIRECT4B_API_TOKEN (DIRECT_API_ACCESS_TOKEN is REST-only), " +
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
async fn run_receive_only_e2e_with_token(
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
        close_client_quiet(client)
        tasks.return_immediately(Err(msg))
        abort("unreachable")
      }
    }

    let result = run_receive_only_flow(client)
    close_client_quiet(client)
    tasks.return_immediately(result)
    abort("unreachable")
  })
  result
}

///|
async fn run_receive_only_e2e() -> Result[Unit, String] {
  let tokens = resolve_e2e_tokens()
  if tokens.length() == 0 {
    match refresh_token_via_daab_login() {
      Ok(Some(token)) => push_unique_token(tokens, token)
      Ok(None) =>
        return Err(
          "token not found: set DIRECT_SDK_E2E_TOKEN, HUBOT_DIRECT_TOKEN, " +
          "or DIRECT4B_API_TOKEN (DIRECT_API_ACCESS_TOKEN is REST-only), " +
          "or set DIRECT4B_BOT_USER_ID and DIRECT4B_USER_PASSWORD for auto login",
        )
      Err(msg) => return Err(msg)
    }
  }
  let mut last_error = "receive-only e2e failed"
  let mut index = 0
  let mut tried_daab_login = false
  while index < tokens.length() {
    let token = tokens[index]
    index = index + 1
    match run_receive_only_e2e_with_token(token) {
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
  Err(last_error)
}

///|
async test "e2e send-file and download attached file" {
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

///|
async test "e2e receive-only downloads attached file until end message" {
  if @sys.get_env_var(e2e_receive_gate_env) != Some("1") {
    println(
      "skip receive-only e2e: set DIRECT_SDK_E2E_RECEIVE_ONLY=1 to enable",
    )
    return
  }
  match
    @async.with_timeout_opt(e2e_total_timeout_ms, () => run_receive_only_e2e()) {
    Some(Ok(_)) => ()
    Some(Err(msg)) => fail(msg)
    None =>
      fail(
        "receive-only e2e timeout after " +
        e2e_total_timeout_ms.to_string() +
        "ms",
      )
  }
}
