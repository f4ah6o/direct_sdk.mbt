///|
let usage_text : String =
  #|daab - Direct bot helper CLI
  #|
  #|Usage:
  #|  daab login [--env <path>]
  #|  daab init <project-name>
  #|  daab run [--env <path>]
  #|  daab --help
  #|
  #|Commands:
  #|  login   Login and save access token into .env
  #|  init    Create a new bot project
  #|  run     Run the bot in the current directory
  #|  help    Show this help
  #|
  #|Environment:
  #|  HUBOT_DIRECT_TOKEN       Access token used by run
  #|  HUBOT_DIRECT_ENDPOINT    Override WebSocket endpoint
  #|  HUBOT_DIRECT_PROXY_URL   Proxy URL for WebSocket
  #|  HTTPS_PROXY              Proxy URL (fallback)
  #|  HTTP_PROXY               Proxy URL (fallback)
  #|

///|
let login_help_text : String =
  #|Usage:
  #|  daab login [--env <path>]
  #|
  #|Options:
  #|  --env <path>   Path to the env file (default: .env)
  #|
  #|Notes:
  #|  Login prompts for email and password.
  #|  Endpoint/proxy settings are read from environment variables.
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
