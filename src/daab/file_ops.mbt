///|
pub fn read_file_or_empty(path : String) -> Result[String, String] {
  if !@fs.path_exists(path) {
    return Ok("")
  }
  try @fs.read_file_to_string(path) catch {
    err => Err("failed to read " + path + ": " + err.to_string())
  } noraise {
    content => Ok(content)
  }
}

///|
pub fn write_file(path : String, content : String) -> Result[Unit, String] {
  try @fs.write_string_to_file(path, content) catch {
    err => Err("failed to write " + path + ": " + err.to_string())
  } noraise {
    _ => Ok(())
  }
}

///|
pub fn create_dir(path : String) -> Result[Unit, String] {
  try @fs.create_dir(path) catch {
    err => Err("failed to create directory " + path + ": " + err.to_string())
  } noraise {
    _ => Ok(())
  }
}
