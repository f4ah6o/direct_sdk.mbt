///|
async fn dispatch(args : Array[String]) -> Result[Unit, String] {
  if args.length() <= 1 {
    print_usage()
    return Ok(())
  }
  let command = args[1]
  let rest = args[2:]
  match command {
    "--help" | "-h" | "help" => {
      print_usage()
      Ok(())
    }
    "login" => run_login(rest)
    "create" => run_create(rest)
    "init" => run_init(rest)
    "run" => run_run(rest)
    _ => Err("unknown command: " + command)
  }
}

///|
fn main {
  @async.run_async_main(() => {
    let args = @sys.get_cli_args()
    match dispatch(args) {
      Ok(_) => ()
      Err(msg) => {
        println("Error: " + msg)
        println("Run 'daab --help' for usage.")
        print_usage()
      }
    }
  })
}
