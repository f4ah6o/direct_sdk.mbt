///|
pub fn read_file_or_empty(path : String) -> Result[String, String] {
  if !@fs.path_exists(path) {
    return Ok("")
  }
  try @fs.read_file_to_string(path) catch {
    @fs.IOError::IOError(message) =>
      Err("failed to read " + path + ": " + message)
  } noraise {
    content => Ok(content)
  }
}

///|
pub fn write_file(path : String, content : String) -> Result[Unit, String] {
  try @fs.write_string_to_file(path, content) catch {
    @fs.IOError::IOError(message) =>
      Err("failed to write " + path + ": " + message)
  } noraise {
    _ => Ok(())
  }
}

///|
pub fn create_dir(path : String) -> Result[Unit, String] {
  try @fs.create_dir(path) catch {
    @fs.IOError::IOError(message) =>
      Err("failed to create directory " + path + ": " + message)
  } noraise {
    _ => Ok(())
  }
}
