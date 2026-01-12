///|
fn module_name_for(project_name : String) -> String {
  match project_name.find("/") {
    Some(_) => project_name
    None => "local/" + project_name
  }
}

///|
fn join_path(base : String, leaf : String) -> String {
  @path.Path::join(@path.Path(base), @path.Path(leaf)).to_string()
}

///|
fn moon_mod_template(module_name : String) -> String {
  (
    $|{
    $|  "name": "\{module_name}",
    $|  "version": "0.1.0",
    $|  "deps": {
    $|    "f4ah6o/direct_sdk": "*",
    $|    "moonbitlang/async": "*"
    $|  },
    $|  "readme": "README.md",
    $|  "description": "daab bot project"
    $|}
  )
}

///|
fn root_pkg_template() -> String {
  (
    #|{
    #|  "readme": "README.md"
    #|}
  )
}

///|
fn cmd_pkg_template() -> String {
  (
    #|{
    #|  "is-main": true
    #|}
  )
}

///|
fn main_template() -> String {
  (
    #|///|
    #|fn main {
    #|  println("daab bot template")
    #|  println("Edit cmd/main/main.mbt to implement your bot.")
    #|  println("Run 'daab login' (or 'daab login --token ...') to save your token in .env.")
    #|}
  )
}

///|
fn readme_template(project_name : String) -> String {
  (
    $|# \{project_name}
    $|
    $|This is a daab bot project scaffolded by `daab`.
    $|
    $|## Getting Started
    $|
    $|1. Save your access token in `.env`:
    $|   - Run `daab login` or `daab login --token <token>`
    $|2. Edit `cmd/main/main.mbt` with your bot logic.
    $|3. Run the bot:
    $|   - `daab run` (or `moon run cmd/main`)
    $|
    $|## Environment
    $|
    $|- `HUBOT_DIRECT_TOKEN`: Access token for the Direct API.
    $|
  )
}

///|
fn env_template() -> String {
  (
    #|HUBOT_DIRECT_TOKEN=
  )
}

///|
fn gitignore_template() -> String {
  (
    #|.env
    #|target/
  )
}

///|
fn scaffold_project(project_name : String) -> Result[Unit, String] {
  if @fs.path_exists(project_name) {
    return Err("path already exists: " + project_name)
  }
  let module_name = module_name_for(project_name)
  let cmd_dir = join_path(project_name, "cmd")
  let cmd_main_dir = join_path(cmd_dir, "main")
  match create_dir(project_name) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match create_dir(cmd_dir) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match create_dir(cmd_main_dir) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match
    write_file(
      join_path(project_name, "moon.mod.json"),
      moon_mod_template(module_name),
    ) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match
    write_file(join_path(project_name, "moon.pkg.json"), root_pkg_template()) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match
    write_file(join_path(cmd_main_dir, "moon.pkg.json"), cmd_pkg_template()) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match write_file(join_path(cmd_main_dir, "main.mbt"), main_template()) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match
    write_file(
      join_path(project_name, "README.md"),
      readme_template(project_name),
    ) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match write_file(join_path(project_name, ".env"), env_template()) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  match
    write_file(join_path(project_name, ".gitignore"), gitignore_template()) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  Ok(())
}

///|
pub fn run_init(args : ArrayView[String]) -> Result[Unit, String] {
  if has_flag(args, "--help") || has_flag(args, "-h") {
    print_init_help()
    return Ok(())
  }
  let project_name = match first_non_flag(args) {
    Some(name) => name
    None => return Err("project name is required")
  }
  match scaffold_project(project_name) {
    Ok(_) => ()
    Err(msg) => return Err(msg)
  }
  println("Initialized daab bot project in " + project_name)
  println("Next steps:")
  println("  1. cd " + project_name)
  println("  2. daab login --token <token>")
  println("  3. moon run cmd/main")
  Ok(())
}
