///|
pub const ENV_TOKEN_KEY : String = "HUBOT_DIRECT_TOKEN"

///|
pub const DEFAULT_ENV_PATH : String = ".env"

///|
pub const ENV_ENDPOINT_KEY : String = "HUBOT_DIRECT_ENDPOINT"

///|
pub const ENV_PROXY_KEY : String = "HUBOT_DIRECT_PROXY_URL"

///|
pub const ENV_HTTPS_PROXY_KEY : String = "HTTPS_PROXY"

///|
pub const ENV_HTTP_PROXY_KEY : String = "HTTP_PROXY"

///|
pub const ENV_BOT_USER_ID_KEY : String = "DIRECT4B_BOT_USER_ID"

///|
pub const ENV_USER_PASSWORD_KEY : String = "DIRECT4B_USER_PASSWORD"

///|
fn parse_env_value(content : String, key : String) -> String? {
  let lines = content.split("\n").collect()
  for line_view in lines {
    let line = line_view.trim().to_owned()
    if line != "" && !line.has_prefix("#") {
      let parts = line.split("=").collect()
      if parts.length() >= 2 {
        let name = parts[0].trim().to_owned()
        if name == key {
          let value = parts[1:].exact_view().join("=").trim().to_owned()
          return Some(value)
        }
      }
    }
  }
  None
}

///|
pub fn read_env_value(path : String, key : String) -> Result[String?, String] {
  match read_file_or_empty(path) {
    Ok(content) => Ok(parse_env_value(content, key))
    Err(msg) => Err(msg)
  }
}

///|
pub fn set_env_value(
  path : String,
  key : String,
  value : String,
) -> Result[Unit, String] {
  match read_file_or_empty(path) {
    Ok(content) => {
      let out : Array[String] = []
      let mut found = false
      let lines = content.split("\n").collect()
      for line_view in lines {
        let line = line_view.to_owned()
        let trimmed = line.trim().to_owned()
        if trimmed.has_prefix(key + "=") {
          found = true
          if value != "" {
            out.push(key + "=" + value)
          }
        } else if line != "" {
          out.push(line)
        }
      }
      if !found && value != "" {
        out.push(key + "=" + value)
      }
      let new_content = if out.length() == 0 {
        ""
      } else {
        out.join("\n") + "\n"
      }
      write_file(path, new_content)
    }
    Err(msg) => Err(msg)
  }
}

///|
pub fn resolve_token(env_path : String) -> Result[String?, String] {
  match @env.get_env_var(ENV_TOKEN_KEY) {
    Some(token) => Ok(Some(token))
    None => read_env_value(env_path, ENV_TOKEN_KEY)
  }
}

///|
pub fn has_token(env_path : String) -> Result[Bool, String] {
  match resolve_token(env_path) {
    Ok(Some(_)) => Ok(true)
    Ok(None) => Ok(false)
    Err(msg) => Err(msg)
  }
}

///|
pub fn load_env_file(path : String) -> Result[Unit, String] {
  match read_file_or_empty(path) {
    Ok(content) => {
      let lines = content.split("\n").collect()
      for line_view in lines {
        let line = line_view.trim().to_owned()
        if line == "" || line.has_prefix("#") {
          continue
        }
        let parts = line.split("=").collect()
        if parts.length() >= 2 {
          let key = parts[0].trim().to_owned()
          if @env.get_env_var(key) is None {
            let value = parts[1:].exact_view().join("=").trim().to_owned()
            @env.set_env_var(key, value)
          }
        }
      }
      Ok(())
    }
    Err(msg) => Err(msg)
  }
}
