///|
pub const ENV_TOKEN_KEY : String = "HUBOT_DIRECT_TOKEN"

///|
pub const DEFAULT_ENV_PATH : String = ".env"

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
      let lines = content.split("\n").to_array()
      for line_view in lines {
        let line = line_view.to_string()
        let trimmed = line.trim().to_string()
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
  match @sys.get_env_var(ENV_TOKEN_KEY) {
    Some(token) => Ok(Some(token))
    None => read_env_value(env_path, ENV_TOKEN_KEY)
  }
}
