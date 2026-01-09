# Select Stamp Bot Example

A bot for the Direct SDK that demonstrates interactive menus using select stamps.

## Features

- **Interactive Menu** - Sends a select stamp with two options:
  1. uuid 占い - Fortune telling based on UUID
  2. ミラサポplus事例表示 - Display a case study from Mirasapo+ API

- **Automatic Resend** - After handling a selection, the menu is resent for continuous operation

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

1. Send `menu` or `メニュー` to the bot
2. Click on one of the select stamp options
3. The bot responds with the result and resends the menu

### Menu Options

#### 1. UUID Fortune (uuid 占い)

Generates a random UUID and maps it to one of six fortunes:
- 大吉 (Great blessing)
- 中吉 (Middle blessing)
- 小吉 (Small blessing)
- 吉 (Blessing)
- 末吉 (Future blessing)
- 凶 (Misfortune)

Example output:
```
uuid 占いの結果です。
UUID: 123e4567-e89b-12d3-a456-426614174000
運勢: 大吉
```

#### 2. Mirasapo+ Case Study (ミラサポplus事例表示)

Displays a random case study from the Mirasapo+ API.

Note: HTTP client integration is pending in MoonBit SDK.

## Implementation

This bot demonstrates:
- Using `@action_stamps.send_select()` to send interactive select stamps
- Parsing select stamp replies with `@action_stamps.parse_select_content()`
- State tracking to correlate responses with sent menus
- Message type filtering (`MsgTypeSelectReply`)

## Reference

This is a port of the Go example at:
`direct-go-sdk/daab-go-examples/selectstamp/main.go`

## Notes

- The UUID generation uses a simple pseudo-random implementation
- For production use, replace with a proper cryptographic random number generator
- The Mirasapo+ API integration is pending HTTP client support in MoonBit
