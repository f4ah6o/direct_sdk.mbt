// Client configuration for Direct SDK
// Reference: direct-go-sdk/direct-go/config.go

// Configuration for the Direct client

///|
pub struct Config {
  mut token : String // Authentication token (required)
  mut endpoint : String // WebSocket API endpoint
  mut proxy_url : String? // HTTP proxy URL for WebSocket
  mut timeout : Int // Request timeout in milliseconds
  mut name : String // Bot name for log messages
  mut debug : Bool // Enable debug logging
}

// Default configuration values

///|
pub fn default_config() -> Config {
  Config::default()
}

// Create a Config with minimal required fields

///|
pub fn new_config(token : String) -> Config {
  Config::new(token)
}

// Builder pattern: Set endpoint

///|
pub fn with_endpoint(cfg : Config, endpoint : String) -> Config {
  cfg.with_endpoint(endpoint)
}

// Builder pattern: Set token

///|
pub fn with_token(cfg : Config, token : String) -> Config {
  cfg.with_token(token)
}

// Builder pattern: Set proxy URL

///|
pub fn with_proxy(cfg : Config, proxy_url : String) -> Config {
  cfg.with_proxy(proxy_url)
}

// Builder pattern: Set timeout (milliseconds)

///|
pub fn with_timeout(cfg : Config, timeout_ms : Int) -> Config {
  cfg.with_timeout(timeout_ms)
}

// Builder pattern: Set name

///|
pub fn with_name(cfg : Config, name : String) -> Config {
  cfg.with_name(name)
}

// Builder pattern: Set debug mode

///|
pub fn with_debug(cfg : Config, debug : Bool) -> Config {
  cfg.with_debug(debug)
}

// Validate configuration
// Returns Ok(config) if valid, Err with error message otherwise

///|
pub fn validate(cfg : Config) -> Result[Config, String] {
  cfg.validate()
}

// Apply defaults to empty fields

///|
pub fn apply_defaults(cfg : Config) -> Config {
  cfg.apply_defaults()
}

// Create and validate a Config in one step

///|
pub fn create_config(token : String) -> Result[Config, String] {
  Config::create(token)
}

// Options type for backward compatibility with Go SDK API
// This represents the same data as Config but with optional semantics

///|
pub struct Options {
  endpoint : String
  access_token : String
  proxy_url : String
  name : String
}

// Convert Config to Options

///|
pub fn to_options(cfg : Config) -> Options {
  cfg.to_options()
}

///|
pub fn Config::default() -> Config {
  {
    token: "",
    endpoint: @constants.DEFAULT_ENDPOINT,
    proxy_url: None,
    timeout: @constants.DEFAULT_REQUEST_TIMEOUT,
    name: "direct-moonbit",
    debug: false,
  }
}

///|
/// Create a config with the provided token and allow chaining.
///
/// # Example
/// ```mbt check
/// test {
///   let cfg = Config::new("token")
///     .with_endpoint("wss://example.invalid")
///     .with_name("bot")
///   let opts = cfg.to_options()
///   inspect(opts.access_token, content="token")
///   inspect(opts.name, content="bot")
/// }
/// ```
pub fn Config::new(token : String) -> Config {
  let cfg = Config::default()
  cfg.token = token
  cfg
}

///|
pub fn Config::with_endpoint(self : Config, endpoint : String) -> Config {
  self.endpoint = endpoint
  self
}

///|
pub fn Config::with_token(self : Config, token : String) -> Config {
  self.token = token
  self
}

///|
pub fn Config::with_proxy(self : Config, proxy_url : String) -> Config {
  self.proxy_url = Some(proxy_url)
  self
}

///|
pub fn Config::with_timeout(self : Config, timeout_ms : Int) -> Config {
  self.timeout = timeout_ms
  self
}

///|
pub fn Config::with_name(self : Config, name : String) -> Config {
  self.name = name
  self
}

///|
pub fn Config::with_debug(self : Config, debug : Bool) -> Config {
  self.debug = debug
  self
}

///|
pub fn Config::validate(self : Config) -> Result[Config, String] {
  if self.token == "" {
    return Err("config: Token is required")
  }
  if self.timeout < 100 {
    return Err("config: Timeout must be at least 100ms")
  }
  if self.timeout > 300_000 {
    return Err("config: Timeout must be at most 5 minutes (300000ms)")
  }
  if !self.endpoint.has_prefix("ws://") && !self.endpoint.has_prefix("wss://") {
    return Err("config: Endpoint must start with ws:// or wss://")
  }
  Ok(self)
}

///|
pub fn Config::apply_defaults(self : Config) -> Config {
  let result = self
  if result.endpoint == "" {
    result.endpoint = @constants.DEFAULT_ENDPOINT
  }
  if result.timeout == 0 {
    result.timeout = @constants.DEFAULT_REQUEST_TIMEOUT
  }
  if result.name == "" {
    result.name = "direct-moonbit"
  }
  result
}

///|
/// Create, apply defaults, and validate in one step.
///
/// # Example
/// ```mbt check
/// test {
///   let result = Config::create("token")
///   let ok = match result {
///     Ok(_) => true
///     Err(_) => false
///   }
///   inspect(ok, content="true")
/// }
/// ```
pub fn Config::create(token : String) -> Result[Config, String] {
  let cfg = Config::new(token)
  let cfg = cfg.apply_defaults()
  cfg.validate()
}

///|
pub fn Config::to_options(self : Config) -> Options {
  {
    endpoint: self.endpoint,
    access_token: self.token,
    proxy_url: match self.proxy_url {
      Some(url) => url
      None => ""
    },
    name: self.name,
  }
}

// Health status type

///|
pub struct HealthStatus {
  connected : Bool
  authenticated : Bool
  endpoint : String
  error : String?
}

// Create a healthy health status

///|
pub fn healthy_health_status(endpoint : String) -> HealthStatus {
  { connected: true, authenticated: true, endpoint, error: None }
}

// Create an unhealthy health status

///|
pub fn unhealthy_health_status(
  endpoint : String,
  error_msg : String,
) -> HealthStatus {
  { connected: false, authenticated: false, endpoint, error: Some(error_msg) }
}

// Metrics interface for observability

///|
pub struct Metrics {
  record_request : (String, Int64) -> Unit
  record_error : (String, @errors.DirectError) -> Unit
  record_connection_state : (String) -> Unit
}

// No-op metrics implementation

///|
pub fn noop_metrics() -> Metrics {
  {
    record_request: fn(_method : String, _duration_ms : Int64) -> Unit { () },
    record_error: fn(_method : String, _error : @errors.DirectError) -> Unit {
      ()
    },
    record_connection_state: fn(_state : String) -> Unit { () },
  }
}
