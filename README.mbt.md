# Direct SDK for Moonbit

MoonBit用のDirect4B WebSocket API SDKです。`direct-go-sdk`を移植したものです。

## Features

- **WebSocket通信**: MessagePack RPCプロトコルによる非同期通信
- **完全なAPIカバレッジ**: 68個のRPCメソッド、40種類のイベント
- **型安全**: MoonBitの型システムによる静的型チェック
- **イベント駆動**: サーバー通知のハンドラー登録
- **非同期I/O**: `async`/`await`による効率的な並行処理

## Installation

```json
{
  "dependencies": {
    "moonbitlang/async": "*",
    "f4ah6o/direct_sdk": "*"
  }
}
```

## Quick Start

```moonbit
// クライアント作成
let client = rpc/client/new_client_with_token("your-access-token")

// 接続
match await rpc/client/connect(client) {
  | Ok(_) => println("Connected!")
  | Err(e) => println("Failed: \${errors/direct_error_to_string(e)}")
}

// ユーザー情報取得
match await api/users/get_me(client) {
  | Ok(user) => println("Hello, \${user.display_name}!")
  | Err(e) => ()
}

// トーク一覧取得
match await api/talks/get_talks(client) {
  | Ok(talks) => {
    for talk in talks {
      println("Talk: \${talk.name}")
    }
  }
  | Err(e) => ()
}

// メッセージ送信
let content = types/JsonObject(Map::from_array([
  ("text", types/JsonString("Hello, World!"))
]))
let params = [
  types/id_to_json(types/IDString("talk-id")),
  types/JsonNumber(types/msg_type_to_wire(types/MsgTypeText).to_float()),
  content,
]
match await rpc/client/call(client, "create_message", params) {
  | Ok(_) => println("Message sent!")
  | Err(e) => ()
}
```

## Event Handling

```moonbit
// メッセージ受信ハンドラー
rpc/client/on_message(client, fn(msg) {
  println("Received: \${msg.text}")
})

// トークイベントハンドラー
rpc/client/on_talk(client, fn(talk) {
  println("New talk: \${talk.name}")
})

// 汎用イベントハンドラー
rpc/client/on(client, "session_created", fn(data) {
  println("Session created!")
})
```

## API Modules

| Module | Description |
|--------|-------------|
| `rpc/client` | メインクライアント、接続、RPC呼び出し |
| `api/users` | ユーザー情報、プロフィール、フレンド |
| `api/talks` | トーク/部屋の管理 |
| `api/messages` | メッセージ送受信、検索 |
| `api/domains` | ドメイン/組織の管理 |
| `api/files` | ファイルアップロード、添付ファイル |
| `api/conference` | 会議/通話機能 |
| `api/announcements` | お知らせ機能 |
| `api/departments` | 組織図/部門 |
| `events/handler` | イベントディスパッチャー |

## Configuration

```moonbit
///|
let client = rpc /
  client /
  new_client(
    (config / default_config())
    |> config / with_token("your-token")
    |> config / with_endpoint("wss://custom.example.com/api")
    |> config / with_proxy(Some("http://proxy:8080"))
    |> config / with_timeout(60000),
  )
```

## Examples

- `examples/basic_usage.mbt` - 基本的な使用方法
- `examples/bot_example.mbt` - ボット実装パターン

## CLI (daab)

```bash
# Save access token to .env
daab login --token <token>

# Initialize a new bot project
daab init my-bot

# Run the bot (prints the command to run)
cd my-bot
daab run

# Show available commands
daab --help
```

## Development

```bash
# チェック
moon check

# ビルド
moon build

# テスト
moon test
```

## License

Apache-2.0

## References

- [direct-go-sdk](https://github.com/f4ah6o/direct-go-sdk) - Go版SDK
- [Direct4B](https://www.direct4b.com/) - サービスサイト
