# Direct SDK for Moonbit
<!-- bdg:begin -->
[![moonbit](https://img.shields.io/badge/moonbit-f4ah6o/direct_sdk-informational)](https://mooncakes.io/docs/f4ah6o/direct_sdk)
<!-- bdg:end -->

MoonBit用のDirect4B WebSocket API SDKです。`direct-go-sdk`を移植したものです。

## Features

- **WebSocket通信**: MessagePack RPCプロトコルによる非同期通信
- **完全なAPIカバレッジ**: 69個のRPCメソッド、40種類のイベント
- **型安全**: MoonBitの型システムによる静的型チェック
- **イベント駆動**: サーバー通知のハンドラー登録
- **非同期I/O**: `async`関数による効率的な並行処理

## Installation

```sh
moon add f4ah6o/direct_sdk
moon add moonbitlang/async
```

Then import the packages used by your application in its `moon.pkg` file:

```moonbit
import {
  "moonbitlang/async" @async,
  "f4ah6o/direct_sdk/config" @config,
  "f4ah6o/direct_sdk/rpc/client" @rpc_client,
  "f4ah6o/direct_sdk/types" @types,
  "f4ah6o/direct_sdk/errors" @errors,
  "f4ah6o/direct_sdk/api/users" @api_users,
  "f4ah6o/direct_sdk/api/talks" @api_talks,
}
pkgtype(kind: "executable")
```

## Quick Start

```moonbit
// クライアント作成
let client = @rpc_client.new_client_with_token("your-access-token")

@async.with_task_group(fn(tasks) {
  // 接続
  match @rpc_client.connect(client, tasks) {
    Ok(_) => println("Connected!")
    Err(e) => {
        println("Failed: \${@errors.direct_error_to_string(e)}")
        return
      }
  }

  // ユーザー情報取得
  match @api_users.get_me(client) {
    Ok(user) => println("Hello, \${user.display_name}!")
    Err(e) => ()
  }

  // トーク一覧取得
  match @api_talks.get_talks(client) {
    Ok(talks) => {
      for talk in talks {
        println("Talk: \${talk.name}")
      }
    }
    Err(e) => ()
  }

  // メッセージ送信
  let content = @types.JsonObject(Map::from_array([
    ("text", @types.JsonString("Hello, World!"))
  ]))
  let params = [
    @types.id_to_json(@types.IDString("talk-id")),
    @types.JsonNumber(@types.msg_type_to_wire(@types.MsgTypeText).to_float()),
    content,
  ]
  match @rpc_client.call(client, "create_message", params) {
    Ok(_) => println("Message sent!")
    Err(e) => ()
  }
})
```

## Event Handling

```moonbit
// メッセージ受信ハンドラー
@rpc_client.on_message(client, fn(msg) {
  println("Received: \${msg.text}")
})

// トークイベントハンドラー
@rpc_client.on_talk(client, fn(talk) {
  println("New talk: \${talk.name}")
})

// 汎用イベントハンドラー
@rpc_client.on(client, "session_created", fn(data) {
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
| `api/files` | ファイルのアップロード/ダウンロード認証、添付ファイル |
| `api/conference` | 会議/通話機能 |
| `api/announcements` | お知らせ機能 |
| `api/departments` | 組織図/部門 |
| `events/handler` | イベントディスパッチャー |

## Configuration

```moonbit
///|
let client = @rpc_client.new_client(
  @config.default_config()
    .with_token("your-token")
    .with_endpoint("wss://custom.example.com/api")
    .with_proxy("http://proxy:8080")
    .with_timeout(60000),
)
```

## Examples

実行可能な bot のひな形は `daab` CLI から生成できます。テンプレートは現在の `moon.mod` / `moon.pkg` 形式を使います。

```bash
moon run src/daab -- create my-ping-bot --template ping-bot
moon run src/daab -- create my-selectstamp-bot --template selectstamp-bot
```

リポジトリ内の `examples/` は旧実装の参照用で、現在の compiler では型チェックされず、公開 package にも含めません。新しいプロジェクトでは上記の生成テンプレートを使ってください。

## CLI (daab)

```bash
# Login to obtain access token
daab login

# Or save a token directly
daab login --token <token>

# Initialize a new bot project
daab init my-bot

# Create a new bot project from a template
daab create my-bot --template ping-bot

# Run the bot
cd my-bot
daab run

# Show available commands
daab --help
```

Environment variables used by `daab login`:

- `DIRECT4B_BOT_USER_ID` (optional, with `DIRECT4B_USER_PASSWORD`)
- `DIRECT4B_USER_PASSWORD` (optional, with `DIRECT4B_BOT_USER_ID`)
- `HUBOT_DIRECT_ENDPOINT` (optional)
- `HUBOT_DIRECT_PROXY_URL` (optional)
- `HTTPS_PROXY` / `HTTP_PROXY` (fallback)

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
