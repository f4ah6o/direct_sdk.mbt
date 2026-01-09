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
  {
    token: "",
    endpoint: @constants.DEFAULT_ENDPOINT,
    proxy_url: None,
    timeout: @constants.DEFAULT_REQUEST_TIMEOUT,
    name: "direct-moonbit",
    debug: false,
  }
}

// Create a Config with minimal required fields

///|
pub fn new_config(token : String) -> Config {
  let cfg = default_config()
  cfg.token = token
  cfg
}

// Builder pattern: Set endpoint

///|
pub fn with_endpoint(cfg : Config, endpoint : String) -> Config {
  cfg.endpoint = endpoint
  cfg
}

// Builder pattern: Set token

///|
pub fn with_token(cfg : Config, token : String) -> Config {
  cfg.token = token
  cfg
}

// Builder pattern: Set proxy URL

///|
pub fn with_proxy(cfg : Config, proxy_url : String) -> Config {
  cfg.proxy_url = Some(proxy_url)
  cfg
}

// Builder pattern: Set timeout (milliseconds)

///|
pub fn with_timeout(cfg : Config, timeout_ms : Int) -> Config {
  cfg.timeout = timeout_ms
  cfg
}

// Builder pattern: Set name

///|
pub fn with_name(cfg : Config, name : String) -> Config {
  cfg.name = name
  cfg
}

// Builder pattern: Set debug mode

///|
pub fn with_debug(cfg : Config, debug : Bool) -> Config {
  cfg.debug = debug
  cfg
}

// Validate configuration
// Returns Ok(config) if valid, Err with error message otherwise

///|
pub fn validate(cfg : Config) -> Result[Config, String] {
  // Token is required
  if cfg.token == "" {
    return Err("config: Token is required")
  }

  // Validate timeout range (100ms to 5 minutes)
  if cfg.timeout < 100 {
    return Err("config: Timeout must be at least 100ms")
  }
  if cfg.timeout > 300_000 {
    return Err("config: Timeout must be at most 5 minutes (300000ms)")
  }

  // Validate endpoint format (basic check)
  if !cfg.endpoint.has_prefix("ws://") && !cfg.endpoint.has_prefix("wss://") {
    return Err("config: Endpoint must start with ws:// or wss://")
  }
  Ok(cfg)
}

// Apply defaults to empty fields

///|
pub fn apply_defaults(cfg : Config) -> Config {
  let result = cfg
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

// Create and validate a Config in one step

///|
pub fn create_config(token : String) -> Result[Config, String] {
  let cfg = new_config(token)
  let cfg = apply_defaults(cfg)
  validate(cfg)
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
  {
    endpoint: cfg.endpoint,
    access_token: cfg.token,
    proxy_url: match cfg.proxy_url {
      Some(url) => url
      None => ""
    },
    name: cfg.name,
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
