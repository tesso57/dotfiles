---
allowed-tools:
  # ファイル読み取り
  - Read
  # ファイル内容取得用
  - Bash(cat:*)
description: |
  指定されたGoファイルがテスト対象として適切かどうかを判定するヘルパーコマンド。
  
  このコマンドは単一のGoファイルパスを入力として受け取り、
  そのファイルがテストを書くべきかどうかを判定して、
  JSON形式で結果を返します。
  
  返却形式:
  - テスト対象の場合: {"testable": true}
  - テスト対象外の場合: {"testable": false, "reason": "除外理由"}
  
  除外基準:
  - インターフェース定義のみのファイル
  - テスト支援用ファイル（mock, fixture, testutil等）
  - 自動生成されたファイル（.pb.go, _gen.go等）
---

# judge-testable-go

指定されたGoファイルがテスト対象として適切かどうかを判定します。

## 使用方法

```
judge-testable-go <go_file_path>
```

## 処理フロー

1. 引数で指定されたGoファイルパスを受け取る
2. ファイルの内容を読み取る
3. 以下の除外条件をチェック：
   - インターフェース定義のみのファイル
   - テスト支援用ファイル（mock, fixture等）
   - 自動生成されたファイル
4. JSON形式で結果を返す

## 除外判定の詳細

### 1. インターフェース定義のみのファイル
- `type XXX interface { ... }` のみで実装を含まないファイル

### 2. テスト支援用ファイル（ファイル名またはパスに以下を含む）
- `mock` / `mocks` / `mockclient`
- `fixture` / `fixtures`
- `testutil` / `testhelper` / `testing`
- `fake` / `fakes` / `stub` / `stubs`
- `_test_utils` / `_testdata` / `testdata`
- `dummy` / `example` / `sample`

### 3. 生成されたファイル
- `// Code generated ... DO NOT EDIT.` を含むファイル
- `.pb.go` (Protocol Buffers)
- `_gen.go` / `_generated.go`

## Workflow (for Claude)

1. 引数チェック
   - 引数が1つ提供されているか確認
   - 引数がGoファイル（.go拡張子）であるか確認

2. ファイル内容の読み取り
   ```bash
   cat <file_path>
   ```

3. 除外条件の判定
   - ファイルパスに基づく判定（テスト支援用ファイル、生成ファイル）
   - ファイル内容に基づく判定（インターフェースのみ、自動生成コメント）

4. 結果のJSON出力
   - テスト対象の場合：
     ```json
     {"testable": true}
     ```
   - テスト対象外の場合：
     ```json
     {"testable": false, "reason": "除外理由の説明"}
     ```

## エラーハンドリング
- ファイルが存在しない場合：`{"testable": false, "reason": "File not found"}`
- 読み取り権限がない場合：`{"testable": false, "reason": "Permission denied"}`
- Goファイルでない場合：`{"testable": false, "reason": "Not a Go file"}`