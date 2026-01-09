///|
let usage_text : String =
  #|daab - Direct bot helper CLI
  #|
  #|Usage:
  #|  daab login [--token <token>] [--env <path>]
  #|  daab init <project-name>
  #|  daab run [--env <path>]
  #|  daab --help
  #|
  #|Commands:
  #|  login   Save access token into .env
  #|  init    Create a new bot project
  #|  run     Run the bot in the current directory
  #|  help    Show this help
  #|
  #|Environment:
  #|  HUBOT_DIRECT_TOKEN  Access token used by login/run when --token is not set
  #|

///|
let login_help_text : String =
  #|Usage:
  #|  daab login [--token <token>] [--env <path>]
  #|
  #|Options:
  #|  --token <token>   Access token to save into .env
  #|  --env <path>      Path to the env file (default: .env)
  #|
  #|Notes:
  #|  If --token is omitted, daab uses HUBOT_DIRECT_TOKEN from the environment.
  #|

///|
let init_help_text : String =
  #|Usage:
  #|  daab init <project-name>
  #|
  #|Creates a new bot project directory with a MoonBit layout.
  #|

///|
let run_help_text : String =
  #|Usage:
  #|  daab run [--env <path>]
  #|
  #|Checks the current directory for a MoonBit bot project and prints
  #|the command to run it.
  #|

///|
pub fn print_usage() -> Unit {
  println(usage_text)
}

///|
pub fn print_login_help() -> Unit {
  println(login_help_text)
}

///|
pub fn print_init_help() -> Unit {
  println(init_help_text)
}

///|
pub fn print_run_help() -> Unit {
  println(run_help_text)
}
