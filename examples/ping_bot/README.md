# Ping Bot Example

A simple bot for the Direct SDK that responds to various commands.

## Features

- **ping** - Responds with "PONG"
- **echo <text>** - Echoes back the given text
- **time** - Shows the current server time
- **shout <text>** - Sends text to the room (same as echo, semantically different)
- **Logging** - Optionally logs all incoming messages

## Setup

1. Set your Direct access token:
   ```bash
   export DIRECT_ACCESS_TOKEN="your-token-here"
   ```

2. Run the bot:
   ```bash
   moon run
   ```

## Usage

Send a message to the bot in any Direct room:

```
you: ping
bot: PONG

you: echo hello world
bot: hello world

you: time
bot: Server time: <current_time>

you: shout This is important!
bot: This is important!
```

## Implementation

This bot demonstrates:
- Using `@rpc_client.on_message()` to handle incoming messages
- Command parsing with simple string matching
- Sending text messages with `@rpc_client.send_text()`
- Basic bot state management

## Reference

This is a port of the Go example at:
`direct-go-sdk/daab-go-examples/ping/main.go`
