---
allowed-tools:
  - Bash(cmux-delegate:*)
  - Bash(cmux:*)
description: "別ペインで AI エージェントを起動し、インタラクティブに監視・結果収集する"
---

## Context

- `cmux-delegate` は cmux の IPC プリミティブを組み合わせた委任スクリプト
- 別ペインで AI エージェント（claude / gemini）や任意コマンドを起動し、完了を待って結果を収集する
- エージェント種別: `claude`（インタラクティブ）、`gemini`（ワンショット）、`cmd`（任意コマンド）

## 環境チェック

まず cmux 環境で実行されているか確認する:
```bash
cmux ping
```
失敗した場合は「cmux 環境外で実行されています」と伝えて終了する。

## 引数パース

`$ARGUMENTS` を解析する:
- 形式: `<agent_type> <prompt>`
- `agent_type` が省略された場合は `claude` をデフォルトとする
- 先頭トークンが `claude` / `gemini` / `cmd` のいずれでもない場合、全体をプロンプトとして扱い `claude` をデフォルトにする

例:
- `/delegate claude "このリポジトリの構成を説明して"` → agent=claude, prompt="このリポジトリの構成を説明して"
- `/delegate gemini "Goのベストプラクティスを教えて"` → agent=gemini
- `/delegate cmd "go test ./..."` → agent=cmd
- `/delegate "このリポジトリの構成を説明して"` → agent=claude (デフォルト)

## 実行フロー

### 1. エージェント起動

```bash
cmux-delegate start <agent_type> "<prompt>"
```

出力をパースして TASK_ID と SURFACE_REF を取得する:
```
TASK_ID=delegate-1709312345-12345
SURFACE_REF=surface:2
```

ユーザーに起動完了を報告する。

### 2. 完了待機

```bash
cmux-delegate wait <task_id> 600
```

- 最大600秒（10分）待機する
- タイムアウトした場合はその旨を報告し、`cmux-delegate read` で途中結果を取得するか判断する

### 3. 結果取得

```bash
cmux-delegate read <task_id> <surface_ref>
```

- `gemini` / `cmd` の場合: `/tmp/<task_id>.out` から読み取り
- `claude` の場合: `read-screen --scrollback` でペイン出力を取得

### 4. 結果分析と報告

取得した結果を分析し、ユーザーにわかりやすく報告する:
- 要約を提示
- エラーがあれば指摘
- 追加アクションが必要であれば提案

### 5. クリーンアップ

```bash
cmux-delegate cleanup <task_id>
```

一時ファイルを削除する。ペインはユーザーが確認できるよう残す。

## 注意事項

- `claude` エージェントは `--dangerously-skip-permissions` で起動されるため、信頼できるプロンプトのみ委任する
- 長時間タスクの場合は `cmux-delegate status <task_id> "進捗メッセージ"` でステータスを更新できる
- 複数のエージェントを同時に起動して並行作業させることも可能
