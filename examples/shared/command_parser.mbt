// Command parser for Direct SDK bot examples
// Parses text commands and extracts parameters

// Result of command parsing

///|
pub enum CommandMatch {
  NoMatch
  ExactMatch                         // Exact match like "ping"
  PrefixMatch(String)                // Prefix with remaining text like "echo hello"
  SuffixMatch(String)                // Suffix with preceding text like "hello!"
}

// Parse command and return match result

///|
pub fn parse_command(text : String, pattern : CommandPattern) -> CommandMatch {
  match pattern {
    | ExactPattern(cmd) => {
      let trimmed = trim(text)
      if trimmed == cmd {
        ExactMatch
      } else {
        NoMatch
      }
    }
    | PrefixPattern(prefix) => {
      let trimmed = trim(text)
      if starts_with(trimmed, prefix) {
        let remaining = trimmed.substring(prefix.length(), trimmed.length())
        PrefixMatch(trim(remaining))
      } else {
        NoMatch
      }
    }
    | SuffixPattern(suffix) => {
      let trimmed = trim(text)
      if ends_with(trimmed, suffix) {
        let preceding = trimmed.substring(0, trimmed.length() - suffix.length())
        SuffixMatch(trim(preceding))
      } else {
        NoMatch
      }
    }
  }
}

// Command pattern definitions

///|
pub enum CommandPattern {
  ExactPattern(String)  // Exact match: "ping"
  PrefixPattern(String) // Starts with: "echo "
  SuffixPattern(String) // Ends with: "!"
}

// Match "ping" command

///|
pub fn match_ping(text : String) -> Bool {
  let trimmed = trim(text)
  trimmed == "ping"
}

// Match "time" command

///|
pub fn match_time(text : String) -> Bool {
  let trimmed = trim(text)
  trimmed == "time"
}

// Match "echo <text>" command and return the text to echo

///|
pub fn match_echo(text : String) -> Option[String] {
  let trimmed = trim(text)
  let prefix = "echo "
  if starts_with(trimmed, prefix) {
    let echoed = trim(trimmed.substring(prefix.length(), trimmed.length()))
    if echoed.length() > 0 {
      Some(echoed)
    } else {
      None
    }
  } else {
    None
  }
}

// Match "shout <text>" command and return the text to shout

///|
pub fn match_shout(text : String) -> Option[String] {
  let trimmed = trim(text)
  let prefix = "shout "
  if starts_with(trimmed, prefix) {
    let shouted = trim(trimmed.substring(prefix.length(), trimmed.length()))
    if shouted.length() > 0 {
      Some(shouted)
    } else {
      None
    }
  } else {
    None
  }
}

// Match "menu" or "メニュー" command

///|
pub fn match_menu(text : String) -> Bool {
  let trimmed = trim(text)
  trimmed == "menu" || trimmed == "メニュー"
}

// Split command and arguments

///|
pub fn split_command(text : String) -> (String, String) {
  let trimmed = trim(text)
  let parts = trimmed.split(" ")
  if parts.length() > 0 {
    let cmd = parts[0]
    let args = if parts.length() > 1 {
      String::join(" ", parts.slice(1, parts.length()))
    } else {
      ""
    }
    (cmd, trim(args))
  } else {
    ("", "")
  }
}

// Get first word from text

///|
pub fn first_word(text : String) -> String {
  let trimmed = trim(text)
  let space_idx = trimmed.index_of(" ")
  match space_idx {
    Some(idx) => trimmed.substring(0, idx)
    None => trimmed
  }
}

// Get remaining text after first word

///|
pub fn remaining_text(text : String) -> String {
  let trimmed = trim(text)
  let space_idx = trimmed.index_of(" ")
  match space_idx {
    Some(idx) => trim(trimmed.substring(idx + 1, trimmed.length()))
    None => ""
  }
}

// Check if text matches any of the given patterns

///|
pub fn matches_any(text : String, patterns : Array[String]) -> Bool {
  for pattern in patterns {
    if trim(text) == trim(pattern) {
      return true
    }
  }
  false
}

// Trim whitespace from text

///|
pub fn trim(text : String) -> String {
  let mut start = 0
  let mut end = text.length()

  while start < end {
    let ch = text.char_at(start)
    if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
      start = start + 1
    } else {
      break
    }
  }

  while end > start {
    let ch = text.char_at(end - 1)
    if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
      end = end - 1
    } else {
      break
    }
  }

  if start == 0 && end == text.length() {
    text
  } else {
    text.substring(start, end)
  }
}

// Check if text starts with prefix

///|
pub fn starts_with(text : String, prefix : String) -> Bool {
  text.length() >= prefix.length()
    && text.substring(0, prefix.length()) == prefix
}

// Check if text ends with suffix

///|
pub fn ends_with(text : String, suffix : String) -> Bool {
  let text_len = text.length()
  let suffix_len = suffix.length()
  text_len >= suffix_len
    && text.substring(text_len - suffix_len, text_len) == suffix
}

// Tokenize text by spaces

///|
pub fn tokenize(text : String) -> Array[String] {
  let trimmed = trim(text)
  if trimmed.length() == 0 {
    return []
  }

  let mut tokens = []
  let mut current = ""

  for i in range(0, trimmed.length()) {
    let ch = trimmed.char_at(i)
    if ch == ' ' {
      if current.length() > 0 {
        tokens.push(current)
        current = ""
      }
    } else {
      current = current + ch.to_string()
    }
  }

  if current.length() > 0 {
    tokens.push(current)
  }

  tokens
}

// Find command by prefix in text

///|
pub fn find_command(text : String, commands : Array[String]) -> Option[String] {
  let trimmed = trim(text)
  for cmd in commands {
    if starts_with(trimmed, cmd ++ " ") {
      return Some(cmd)
    }
  }
  None
}
