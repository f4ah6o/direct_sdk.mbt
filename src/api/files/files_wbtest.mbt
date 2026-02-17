///|
test "parse_download_auth handles object payload" {
  let headers = Map::from_array([
    ("Authorization", @types.JsonString("Bearer token")),
    ("X-Ignore", @types.JsonInt(1)),
  ])
  let obj = Map::from_array([
    ("file_id", @types.JsonString("file-1")),
    ("get_url", @types.JsonString("https://example.test/download")),
    ("get_headers", @types.JsonObject(headers)),
  ])
  match parse_download_auth(obj) {
    Ok(auth) => {
      inspect(auth.file_id, content="IDString(\"file-1\")")
      inspect(auth.url, content="https://example.test/download")
      inspect(
        auth.headers.get("Authorization"),
        content="Some(\"Bearer token\")",
      )
      inspect(auth.headers.get("X-Ignore"), content="None")
    }
    Err(e) =>
      inspect(@errors.direct_error_to_string(e), content="unexpected error")
  }
}

///|
test "parse_download_auth handles missing fields" {
  let obj = Map::new()
  match parse_download_auth(obj) {
    Ok(auth) => {
      inspect(auth.file_id, content="IDString(\"\")")
      inspect(auth.url, content="")
      inspect(auth.headers.is_empty(), content="true")
    }
    Err(e) =>
      inspect(@errors.direct_error_to_string(e), content="unexpected error")
  }
}
