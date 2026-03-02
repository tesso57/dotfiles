---
allowed-tools:
  - Bash(cmux:*)
description: "cmux ターミナルのペイン操作・出力読取・ステータス管理を行う"
---

## Context

- **cmux** は macOS 向けターミナルアプリで、複数の AI コーディングエージェントセッションを管理する
- CLI (`cmux`) を通じてペイン分割・コマンド送信・出力読取・サイドバー制御が可能
- 環境変数 `CMUX_WORKSPACE_ID`, `CMUX_SURFACE_ID` が自動設定されるため、多くのコマンドで明示指定不要

## 環境チェック

まず cmux 環境で実行されているか確認する:
```bash
cmux ping
```
失敗した場合は「cmux 環境外で実行されています。cmux ターミナル内で再実行してください。」と伝えて終了する。

## アクション

`$ARGUMENTS` の先頭トークンを **action** として解釈し、残りを引数とする。

### `layout` — 現在のペイン構成を表示

1. ワークスペース情報を取得:
```bash
cmux current-workspace --json
```
2. ペイン一覧を取得:
```bash
cmux list-panes --json
```
3. 各ペインのサーフェス一覧を取得:
```bash
cmux list-pane-surfaces --json
```
4. サイドバー状態を取得:
```bash
cmux sidebar-state --json
```
5. 結果を整形して表示する。各ペイン/サーフェスの ref を明示する。

### `run` — 新ペインでコマンド実行

引数: `run <command>`

1. 新しいペインを右方向に分割して作成:
```bash
cmux new-split right --json
```
2. 返された surface ref を記録する。
3. コマンドを送信:
```bash
cmux send --surface <ref> "<command>"
cmux send-key --surface <ref> Enter
```
4. サイドバーにステータスを設定:
```bash
cmux set-status "task" "Running: <command の先頭30文字>" --icon "▶️"
```
5. 作成したペイン/サーフェスの ref をユーザーに報告する。

### `read` — ペインの出力を読み取る

引数: `read [surface_ref] [--lines N]`

1. surface ref が指定されていない場合、`list-pane-surfaces` で一覧を表示し、どのサーフェスを読むか判断する。
2. 出力を読み取る:
```bash
cmux read-screen --surface <ref> --lines <N|50>
```
3. 出力内容を分析し、エラーがあれば報告する。
4. 結果に応じてステータスを更新:
   - 成功時: `cmux set-status "task" "Done" --icon "✅"`
   - エラー時: `cmux set-status "task" "Error detected" --icon "❌"`

### `send` — 既存ペインにコマンド送信

引数: `send <surface_ref> <command>`

1. 指定サーフェスにコマンドを送信:
```bash
cmux send --surface <ref> "<command>"
cmux send-key --surface <ref> Enter
```
2. 送信完了を報告する。

### `status` — サイドバーのステータス更新

引数: `status <key> <value> [--icon <icon>]` または `status clear [key]` または `status log <message>`

- **設定**: `cmux set-status "<key>" "<value>" --icon "<icon>"`
- **クリア**: `cmux clear-status "<key>"`
- **プログレス**: `cmux set-progress <0.0-1.0> --label "<text>"`
- **ログ**: `cmux log -- "<message>"`
- **一覧**: `cmux list-status --json`

## 注意事項

- `--json` フラグを積極的に使い、出力をパースしやすくする
- surface ref は `surface:N` 形式で指定する
- `send` でコマンドを送った後、実行するには `send-key Enter` が必要
