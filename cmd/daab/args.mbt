///|
pub fn has_flag(args : ArrayView[String], flag : String) -> Bool {
  for arg in args {
    if arg == flag {
      return true
    }
  }
  false
}

///|
pub fn flag_value(args : ArrayView[String], flag : String) -> String? {
  for i = 0; i < args.length(); i = i + 1 {
    if args[i] == flag && i + 1 < args.length() {
      return Some(args[i + 1])
    }
  }
  None
}

///|
pub fn first_non_flag(args : ArrayView[String]) -> String? {
  for arg in args {
    if !arg.has_prefix("-") {
      return Some(arg)
    }
  }
  None
}
