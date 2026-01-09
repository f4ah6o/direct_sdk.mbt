// Tests for config module
// Reference: direct-go-sdk/direct-go/config_test.go

///|
test "default_config creates valid configuration" {
  let cfg = @config.default_config()
  inspect(cfg.endpoint, content="wss://api.direct4b.com/albero-app-server/api")
  inspect(cfg.timeout, content="30000")
  inspect(cfg.debug, content="false")
}

///|
test "with_token sets token" {
  let cfg = @config.default_config() |> @config.with_token("test-token")
  inspect(cfg.token, content="test-token")
}

///|
test "with_endpoint sets endpoint" {
  let cfg = @config.default_config()
    |> @config.with_endpoint("wss://example.com/api")
  inspect(cfg.endpoint, content="wss://example.com/api")
}

///|
test "with_proxy sets proxy_url" {
  let cfg = @config.default_config()
    |> @config.with_proxy("http://proxy.example.com")
  inspect(cfg.proxy_url, content="Some(\"http://proxy.example.com\")")
}

///|
test "with_timeout sets timeout" {
  let cfg = @config.default_config() |> @config.with_timeout(60000)
  inspect(cfg.timeout, content="60000")
}

///|
test "with_debug sets debug mode" {
  let cfg = @config.default_config() |> @config.with_debug(true)
  inspect(cfg.debug, content="true")
}

///|
test "validate rejects empty token" {
  let cfg = @config.default_config()
  let result = @config.validate(cfg)
  match result {
    Ok(_) => fail("expected error")
    Err(msg) => inspect(msg, content="config: Token is required")
  }
}

///|
test "validate accepts valid config" {
  let cfg = @config.default_config() |> @config.with_token("valid-token")
  let result = @config.validate(cfg)
  inspect(result is Ok(_), content="true")
}

///|
test "new_client_with_token creates client" {
  let client = @rpc_client.new_client_with_token("test-token")
  inspect(client.config.token, content="test-token")
  inspect(client.connected, content="false")
  inspect(client.authenticated, content="false")
}
