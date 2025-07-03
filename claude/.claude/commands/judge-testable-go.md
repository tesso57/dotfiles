---
allowed-tools:
  - Read(*:*)
  - Bash(cat:*)
  - Bash(echo:*)
description: |
  単一のGoファイルがテスト対象かどうかを判定する。
  JSON形式で結果を返す: {"testable": true/false, "reason": "説明"}
  
  使用例: claude code /judge-testable-go "pkg/domains/user.go"
---

## 重要な注意事項
**このコマンドはJSONのみを出力します。説明文や解説は一切出力しません。**

## 使用方法
ファイルパスを引数として受け取り、そのファイルがテスト対象かどうかを判定します。

## 判定基準

### 除外すべきファイル:
1. インターフェース定義のみのファイル
2. テスト支援用ファイル（mock, fixture, testutil等）
3. 生成されたファイル（.pb.go, _gen.go等）

### テスト対象にすべきファイル:
- 実装ロジックを含むGoファイル

## 出力形式
```json
{
  "testable": true,
  "reason": ""
}
```
または
```json
{
  "testable": false,  
  "reason": "interface only file"
}
```

---

## Workflow (for Claude)

重要: このコマンドはJSONのみを出力します。説明や解説は一切含めません。

1. ユーザーから提供されたファイルパスを取得（コマンドライン引数として渡される）
2. ファイルの存在を確認し、存在しない場合は `{"testable": false, "reason": "file not found"}` を返す
3. ファイルを読み込む（cat または Read）
4. 以下の条件で判定:
5. 最後に必ずJSONのみを出力（説明文は一切含めない）

### 除外条件（testable: false）
- ファイルパスに以下を含む:
  - mock, mocks, mockclient
  - fixture, fixtures  
  - testutil, testhelper, testing
  - fake, fakes, stub, stubs
  - _test_utils, _testdata, testdata
  - dummy, example, sample
- ファイル名が以下のパターン:
  - .pb.go (Protocol Buffers)
  - _gen.go, _generated.go
- ファイル内容が:
  - `// Code generated ... DO NOT EDIT.` を含む
  - interface定義のみ（実装メソッドなし）

### JSON出力（必須）
必ず以下の形式でJSONのみを出力してください。説明や解説は一切含めず、JSONだけを返してください:
```json
{"testable": true, "reason": ""}
```
または  
```json
{"testable": false, "reason": "mock file"}
```

重要: 
- JSONのみを出力し、それ以外のテキスト（説明、解説、考察など）は一切出力しない
- 出力は1行のJSON形式とする
- ファイルの内容に関する説明は不要