---
allowed-tools:
  # スクリプト実行
  - Bash(~/.claude/scripts/list_untested_go.sh:*)
  - Bash(~/bin/add_task.sh:*)
  - Bash(~/bin/md_prop.sh:*)
  # ファイル操作
  - Bash(cat:*)
  - Bash(echo:*)
  - Bash(sed:*)
  # テンプレート読み込み
  - Read(~/.claude/templates/add_tests_body.md)
  # Git操作
  - Bash(git:*)
  # ユーティリティ
  - Bash(date:*)
  - Bash(basename:*)
  - Bash(wc:*)
description: |
  Go ファイルで *_test.go が無いものを検出し、
  interface 定義しか無いファイルや mock／fixture 等は AI が内容を読んで除外し、
  残ったファイルに対して TODO リスト付きタスクファイルを作成する。
  
  作成されたタスクファイルには以下の属性が自動付与される:
  - source_branch: タスク作成時のGitブランチ名
  - tags: "auto generated"
  - assigner: "claude code"
  - created_date: 作成日（YYYY-MM-DD形式）
  - source_file: 元のGoファイルパス
---

<!-- 
判定の具体例:
1. 除外: "pkg/mock/client.go" → ファイル名に mock を含む
2. 除外: インターフェースのみの例
   ```go
   package reader
   type Reader interface {
       Read([]byte) (int, error)
   }
   ```
3. 対象: 実装を含むファイル
   ```go
   package handler
   type Handler struct { ... }
   func (h *Handler) Process() error { ... }  // 実装がある
   ```
-->

---

## Workflow (for Claude)

1. 候補リスト取得
   ```bash
   ~/.claude/scripts/list_untested_go.sh > /tmp/untested_files.txt
   ```
2. 対象ファイルの処理

   `/tmp/untested_files.txt` の各ファイルに対して:
   * `cat <FILE>` で内容取得
   * Claude が以下の除外条件を判定:
     
     ### 除外すべきファイル:
     1. インターフェース定義のみのファイル
        - `type XXX interface { ... }` のみで実装を含まないファイル
        - 例: `reader.go` に `type Reader interface { Read() }` だけのファイル
     
     2. テスト支援用ファイル（ファイル名またはパスに以下を含む）
        - `mock` / `mocks` / `mockclient` など
        - `fixture` / `fixtures`
        - `testutil` / `testhelper` / `testing`
        - `fake` / `fakes` / `stub` / `stubs`
        - `_test_utils` / `_testdata` / `testdata`
        - `dummy` / `example` / `sample`
     
     3. 生成されたファイル
        - `// Code generated ... DO NOT EDIT.` を含むファイル
        - `.pb.go` (Protocol Buffers)
        - `_gen.go` / `_generated.go`
     
     ### テスト対象にすべきファイル:
     - 上記に該当せず、実装ロジックを含む Go ファイル
     - 例: ビジネスロジック、ユーティリティ関数、構造体とそのメソッド実装
   
   * テスト対象ファイルの場合：タスクファイルを作成
     ```bash
     FILE_REL="${FILE#./}"
     PKG_PATH="${FILE_REL%/*}" ; PKG_PATH="${PKG_PATH#pkg/}"

     # ファイル名から.goを除去してタスクファイル名を生成
     BASE_NAME=$(basename "$FILE_REL" .go)
     TASK_FILE_NAME="test_${BASE_NAME}.md"

     title="📦 テスト追加: ${FILE_REL}"
     body=$(sed -e "s/{FILE}/${FILE_REL//\//\\/}/g" \
                -e "s/{PKG_PATH}/${PKG_PATH//\//\\/}/g" \
           < ~/.claude/templates/add_tests_body.md)

     # タスクファイルの本文を作成
     task_content="${title}

${body}"

     # タスクファイルを作成
     if ~/bin/add_task.sh "$TASK_FILE_NAME" "$task_content"; then
         # 作成されたタスクファイルのパスを取得（gitリポジトリ内に作成される）
         TASK_FILE_PATH="$TASK_FILE_NAME"
         
         # 現在のブランチ名を取得
         CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
         
         # 属性を追加
         ~/bin/md_prop.sh add "$TASK_FILE_PATH" "source_branch" "$CURRENT_BRANCH"
         ~/bin/md_prop.sh add "$TASK_FILE_PATH" "tags" "auto generated"
         ~/bin/md_prop.sh add "$TASK_FILE_PATH" "assigner" "claude code"
         ~/bin/md_prop.sh add "$TASK_FILE_PATH" "created_date" "$(date '+%Y-%m-%d')"
         ~/bin/md_prop.sh add "$TASK_FILE_PATH" "source_file" "$FILE_REL"
     fi
     ```
3. 結果報告
   Claude が処理結果を報告:
   
   作成したタスク:
   | File | Task File Name | Properties |
   
   除外したファイル:
   | File | Reason |
   
   サマリー:
   ```
   ✅ タスク作成: <N> 件
   ⏭️  除外: <M> 件
   📊 処理ファイル数: <全体のファイル数>
   ```

### エラーハンドリング
- `add_task.sh` の実行に失敗した場合はエラーメッセージを表示して次のファイルへ
- ファイルが存在しない場合はスキップ
- 権限エラーの場合はスキップして理由を表示