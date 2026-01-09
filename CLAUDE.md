# Direct SDK for Moonbit - Claude Code Guide

direct-go-sdk（Go版Direct4B WebSocket API SDK）をMoonbitに移植するプロジェクトです。

## プロジェクト概要

- **ターゲット**: Direct4B WebSocket API (MessagePack RPC)
- **元実装**: `direct-go-sdk/direct-go`
- **現在の状態**: 骨格プロジェクトのみ（fib, sum関数のみ実装）

## 並列開発ワークフロー

各機能は独立したタスク（Issue）として管理し、git worktreeで並列実行します。

### 新規タスクの開始手順

```bash
# 1. Issueを作成（GitHub CLI）
gh issue create --title "feat: core types and constants" --body "実装内容の詳細"

# 2. Worktree用ディレクトリ作成
mkdir -p ../direct_sdk.worktrees/

# 3. Worktreeを作成してブランチを切る
git worktree add ../direct_sdk.worktrees/core-types -b feat-core-types

# 4. 作業ディレクトリへ移動
cd ../direct_sdk.worktrees/core-types

# 5. 実装作業
# ... ファイル編集 ...

# 6. テスト
moon test

# 7. コミット
git add .
git commit -m "feat: core types and constants"

# 8. プルリクエスト作成
gh pr create --title "feat: core types and constants" --body "実装内容"

# 9. マージ後、worktreeを削除
cd ..
git worktree remove core-types
```

### 複数タスクの並列実行例

```bash
# タスク1: 基礎型と定数
git worktree add ../direct_sdk.worktrees/task1-types -b feat-types
cd ../direct_sdk.worktrees/task1-types
# ... 実装 ...

# タスク3: MessagePack（タスク1に依存）
git worktree add ../direct_sdk.worktrees/task3-msgpack -b feat-msgpack
cd ../direct_sdk.worktrees/task3-msgpack
# ... 実装 ...

# タスク4: WebSocket（独立して実行可能）
git worktree add ../direct_sdk.worktrees/task4-websocket -b feat-websocket
cd ../direct_sdk.worktrees/task4-websocket
# ... 実装 ...
```

## タスク一覧（依存関係付き）

| タスク | Issueタイトル | 依存 | ファイル |
|--------|---------------|------|---------|
| 1 | `feat: core types and constants` | なし | `src/types.mbt`, `src/constants.mbt`, `src/errors.mbt` |
| 2 | `feat: config and client initialization` | 1 | `src/config.mbt` |
| 3 | `feat: msgpack rpc protocol` | 1 | `src/rpc/msgpack.mbt` |
| 4 | `feat: websocket connection` | なし | `src/rpc/websocket.mbt` |
| 5 | `feat: rpc client core` | 3, 4 | `src/rpc/client.mbt` |
| 6 | `feat: users api` | 5 | `src/api/users.mbt` |
| 7 | `feat: talks api` | 5 | `src/api/talks.mbt` |
| 8 | `feat: messages api` | 5 | `src/api/messages.mbt` |
| 9 | `feat: domains api` | 5 | `src/api/domains.mbt` |
| 10 | `feat: event handling` | 1 | `src/events/types.mbt`, `src/events/handler.mbt` |
| 11 | `feat: additional api methods` | 5, 10 | `src/api/files.mbt`, `src/api/conference.mbt`, etc. |
| 12 | `test: add tests and documentation` | 全て | `tests/*.mbt`, `examples/` |

## 参照ファイル（Go SDK）

各タスク実装時の参照元ファイル：

| 実装ファイル | 参照元Goファイル |
|-------------|------------------|
| `src/types.mbt` | `direct-go-sdk/direct-go/messages.go` |
| `src/constants.mbt` | `direct-go-sdk/direct-go/events.go`, `constants.go` |
| `src/errors.mbt` | `direct-go-sdk/direct-go/errors.go` |
| `src/config.mbt` | `direct-go-sdk/direct-go/config.go` |
| `src/rpc/client.mbt` | `direct-go-sdk/direct-go/client.go` |
| `src/api/users.mbt` | `direct-go-sdk/direct-go/users.go` |
| `src/api/talks.mbt` | `direct-go-sdk/direct-go/talks.go` |

## Moonbit依存関係

```json
{
  "dependencies": {
    "moonbitlang/async": "*",
    "moonbit-community/msgpack": "*"
  }
}
```

## 開発環境

```bash
# チェック
moon check

# ビルド
moon build

# テスト
moon test

# テスト（更新モード）
moon test --update
```

## プロジェクト構成（目標）

```
direct_sdk/
├── moon.mod.json
├── CLAUDE.md              （このファイル）
├── README.mbt.md
├── src/
│   ├── types.mbt         （コア型）
│   ├── constants.mbt     （定数）
│   ├── errors.mbt        （エラー型）
│   ├── config.mbt        （設定）
│   ├── rpc/
│   │   ├── msgpack.mbt   （MessagePack RPC）
│   │   ├── websocket.mbt （WebSocket接続）
│   │   └── client.mbt    （メインクライアント）
│   ├── api/
│   │   ├── users.mbt
│   │   ├── talks.mbt
│   │   ├── messages.mbt
│   │   └── domains.mbt
│   └── events/
│       ├── types.mbt
│       └── handler.mbt
├── tests/
│   └── *_test.mbt
└── examples/
    └── simple/
```

## セッション開始時のフック

SessionStart フックで以下を自動実行：
1. Git worktreeの一覧表示
2. 現在のブランチ確認
3. moon check の実行

## 現在の進捗

- [x] プロジェクト構成
- [ ] タスク1: 基礎型と定数
- [ ] タスク2: 設定
- [ ] タスク3: MessagePack
- [ ] タスク4: WebSocket
- [ ] タスク5: RPCクライアント
- [ ] タスク6-12: 各種API
