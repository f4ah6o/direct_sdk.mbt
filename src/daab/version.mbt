///|
// Template dependency versions and runtime version resolution.

///|
let default_direct_sdk_version : String = "0.5.0"

///|
let default_async_version : String = "0.16.0"

///|
let default_moon_x_version : String = "0.4.38"

///|
fn resolve_direct_sdk_version() -> String {
  match find_direct_sdk_version() {
    Some(version) => version
    None => default_direct_sdk_version
  }
}

///|
fn find_direct_sdk_version() -> String? {
  match resolve_daab_executable_path() {
    Some(exe_path) => find_version_from_executable(exe_path)
    None => None
  }
}

///|
fn resolve_daab_executable_path() -> String? {
  let args = @sys.get_cli_args()
  let argv0 = match args.get(0) {
    Some(value) => value
    None => ""
  }
  if argv0 == "" {
    return None
  }
  if looks_like_path(argv0) {
    return Some(resolve_path(argv0))
  }
  find_executable_in_path(argv0)
}

///|
fn looks_like_path(value : String) -> Bool {
  let sep = @path.sep.to_string()
  value.contains(sep) || value.contains("/") || value.contains("\\")
}

///|
fn resolve_path(value : String) -> String {
  @path.Path::resolve(@path.Path(value)).to_string()
}

///|
fn find_executable_in_path(exe_name : String) -> String? {
  let path_env = match @sys.get_env_var("PATH") {
    Some(value) => value
    None => return None
  }
  let delimiter = @path.delimiter.to_string()
  for dir_view in path_env.split(delimiter) {
    let dir = dir_view.to_string()
    if dir == "" {
      continue
    }
    let candidate = @path.Path::join(@path.Path(dir), @path.Path(exe_name)).to_string()
    match resolve_existing_path(candidate) {
      Some(found) => return Some(found)
      None => ()
    }
    if !exe_name.has_suffix(".exe") {
      let candidate_exe = candidate + ".exe"
      match resolve_existing_path(candidate_exe) {
        Some(found) => return Some(found)
        None => ()
      }
    }
  }
  None
}

///|
fn resolve_existing_path(path : String) -> String? {
  if @fs.path_exists(path) {
    Some(resolve_path(path))
  } else {
    None
  }
}

///|
fn find_version_from_executable(exe_path : String) -> String? {
  let start_dir = @path.Path::dirname(@path.Path(exe_path))
  find_version_from_dir(start_dir)
}

///|
fn find_version_from_dir(dir : @path.Path) -> String? {
  let mod_path = @path.Path::join(dir, @path.Path("moon.mod.json")).to_string()
  if @fs.path_exists(mod_path) {
    match read_direct_sdk_version(mod_path) {
      Some(version) => return Some(version)
      None => ()
    }
  }
  let parent = @path.Path::dirname(dir)
  if @path.Path::equal(parent, dir) {
    return None
  }
  find_version_from_dir(parent)
}

///|
fn read_direct_sdk_version(path : String) -> String? {
  try @fs.read_file_to_string(path) catch {
    _ => None
  } noraise {
    content => parse_direct_sdk_version(content)
  }
}

///|
fn parse_direct_sdk_version(content : String) -> String? {
  try @json.parse(content) catch {
    _ => None
  } noraise {
    json =>
      match json {
        Json::Object(obj) => {
          let name = match obj.get("name") {
            Some(Json::String(value)) => value
            _ => ""
          }
          if name != "f4ah6o/direct_sdk" {
            return None
          }
          match obj.get("version") {
            Some(Json::String(value)) => Some(value)
            _ => None
          }
        }
        _ => None
      }
  }
}
