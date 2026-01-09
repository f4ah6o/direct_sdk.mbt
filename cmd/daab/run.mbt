///|
pub fn run_run(args : ArrayView[String]) -> Result[Unit, String] {
  if has_flag(args, "--help") || has_flag(args, "-h") {
    print_run_help()
    return Ok(())
  }
  let env_path = match flag_value(args, "--env") {
    Some(path) => path
    None => DEFAULT_ENV_PATH
  }
  if !@fs.path_exists("moon.mod.json") {
    return Err("moon.mod.json not found (run 'daab init <project-name>' first)")
  }
  match resolve_token(env_path) {
    Ok(Some(_)) => ()
    Ok(None) => return Err("token not found (run 'daab login' first)")
    Err(msg) => return Err(msg)
  }
  println("Token loaded. To run your bot:")
  println("  moon run cmd/main")
  Ok(())
}
