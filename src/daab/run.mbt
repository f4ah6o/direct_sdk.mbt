///|
pub async fn run_run(args : ArrayView[String]) -> Result[Unit, String] {
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
  match load_env_file(env_path) {
    Ok(_) => ()
    Err(msg) => println("Warning: could not load " + env_path + ": " + msg)
  }
  match resolve_token(env_path) {
    Ok(Some(_)) => ()
    Ok(None) => return Err("token not found (run 'daab login' first)")
    Err(msg) => return Err(msg)
  }
  println("Running: moon run cmd/main")
  let exit_code = try
    @process.run(
      "moon",
      ["run", "cmd/main"],
      stdin=@stdio.stdin,
      stdout=@stdio.stdout,
      stderr=@stdio.stderr,
    )
  catch {
    err => return Err("failed to run moon: " + err.to_string())
  } noraise {
    code => code
  }
  if exit_code != 0 {
    return Err("moon run cmd/main exited with code " + exit_code.to_string())
  }
  Ok(())
}
