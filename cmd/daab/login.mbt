///|
pub fn run_login(args : ArrayView[String]) -> Result[Unit, String] {
  if has_flag(args, "--help") || has_flag(args, "-h") {
    print_login_help()
    return Ok(())
  }
  let env_path = match flag_value(args, "--env") {
    Some(path) => path
    None => DEFAULT_ENV_PATH
  }
  let token = match flag_value(args, "--token") {
    Some(value) => value
    None =>
      match @sys.get_env_var(ENV_TOKEN_KEY) {
        Some(value) => value
        None => ""
      }
  }
  if token == "" {
    return Err("token is required (use --token or set HUBOT_DIRECT_TOKEN)")
  }
  match set_env_value(env_path, ENV_TOKEN_KEY, token) {
    Ok(_) => {
      println("Saved token to " + env_path)
      Ok(())
    }
    Err(msg) => Err(msg)
  }
}
