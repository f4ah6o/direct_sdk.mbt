///|
test "extract_token supports common formats" {
  inspect(@daab.extract_token(@types.JsonString("token-1")), content="token-1")
  let obj = Map::from_array([("access_token", @types.JsonString("token-2"))])
  inspect(@daab.extract_token(@types.JsonObject(obj)), content="token-2")
  let arr = [@types.JsonString("token-3")]
  inspect(@daab.extract_token(@types.JsonArray(arr)), content="token-3")
}

///|
test "set_env_value writes token to env file" {
  let path = ".tmp_daab_env"
  if @fs.path_exists(path) {
    try @fs.remove_file(path) catch {
      _ => ()
    } noraise {
      _ => ()
    }
  }
  match @daab.set_env_value(path, @daab.ENV_TOKEN_KEY, "token-4") {
    Ok(_) => ()
    Err(msg) => fail(msg)
  }
  match @daab.read_env_value(path, @daab.ENV_TOKEN_KEY) {
    Ok(Some(value)) => inspect(value, content="token-4")
    Ok(None) => fail("expected token")
    Err(msg) => fail(msg)
  }
  if @fs.path_exists(path) {
    try @fs.remove_file(path) catch {
      _ => ()
    } noraise {
      _ => ()
    }
  }
}
