///|
let usage_text : String =
  #|daab - Direct bot helper CLI
  #|
  #|Usage:
  #|  daab login [--env <path>] [--token <token>]
  #|  daab create <project-name> [--template <name>]
  #|  daab init <project-name>
  #|  daab run [--env <path>]
  #|  daab --help
  #|
  #|Commands:
  #|  login   Login and save access token into .env
  #|  create  Create a new bot project from a template
  #|  init    Create a new bot project
  #|  run     Run the bot in the current directory
  #|  help    Show this help
  #|
  #|Environment:
  #|  HUBOT_DIRECT_TOKEN       Access token used by run
  #|  HUBOT_DIRECT_ENDPOINT    Override WebSocket endpoint
  #|  HUBOT_DIRECT_PROXY_URL   Proxy URL for WebSocket
  #|  DIRECT4B_BOT_USER_ID     Login user id (for daab login)
  #|  DIRECT4B_USER_PASSWORD   Login password (for daab login)
  #|  HTTPS_PROXY              Proxy URL (fallback)
  #|  HTTP_PROXY               Proxy URL (fallback)
  #|

///|
let login_help_text : String =
  #|Usage:
  #|  daab login [--env <path>] [--token <token>]
  #|
  #|Options:
  #|  --env <path>   Path to the env file (default: .env)
  #|  --token <token>  Save the token directly without prompting
  #|
  #|Notes:
  #|  Login prompts for email and password unless --token is provided.
  #|  If DIRECT4B_BOT_USER_ID and DIRECT4B_USER_PASSWORD are set, prompt is skipped.
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
let create_help_text : String =
  #|Usage:
  #|  daab create <project-name> [--template <name>]
  #|
  #|Options:
  #|  --template <name>  Template name (empty, ping-bot, selectstamp-bot)
  #|
  #|Notes:
  #|  The default template is "empty" (same as daab init).
  #|

///|
let run_help_text : String =
  #|Usage:
  #|  daab run [--env <path>]
  #|
  #|Runs the bot by executing `moon run cmd/main` in the current directory.
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
pub fn print_create_help() -> Unit {
  println(create_help_text)
}

///|
pub fn print_run_help() -> Unit {
  println(run_help_text)
}
