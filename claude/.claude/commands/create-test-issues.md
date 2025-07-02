---
allowed-tools:
  # テスト未実装 Go ファイルの列挙
  - Bash(~/.claude/scripts/list_untested_go.sh:*)
  # ファイル内容を読むため
  - Bash(cat:*)
  # GitHub Issue 発行
  - Bash(gh issue create:*)
  # Issue 本文テンプレート読み込み
  - Read(~/.claude/templates/add_tests_body.md)
  # 進捗ファイル更新（echo >>）
  - Bash(echo:*)
  # 候補リスト取得
  - Bash(~/.claude/scripts/list_untested_go.sh > /tmp/untested_files.txt)
  # 進捗ファイルの作成
  - Bash(mkdir -p ~/.claude/state && touch ~/.claude/state/created_issues.csv)
  - Bash(head:*)
description: |
  Go ファイルで *_test.go が無いものを検出し、
  1 回につき未処理ファイルの先頭 BATCH 件だけ Issue 化する自動バッチ。
  interface 定義しか無いファイルや mock／fixture 等は **AI が内容を読んで除外** し、
  残ったファイルに対して TODO リスト付き Issue を発行する。
---

## Parameters & Constants
- **BATCH**: 50          <!-- 必要なら変更 -->
- **STATE_FILE**: `~/.claude/state/created_issues.csv`
  - フォーマット: `FILE_PATH|ISSUE_URL`
  - 存在しなければコマンド内で自動生成
---

## Workflow (for Claude)

1. 候補リスト取得
   ```bash
   ~/.claude/scripts/list_untested_go.sh > /tmp/untested_files.txt
   ```
2. 進捗ファイル読み込み／初期化
   ```bash
   mkdir -p ~/.claude/state
   touch "$STATE_FILE"
   ```
3. 未処理ファイルを先頭から BATCH 件選出
   Claude が
   * `cut -d'|' -f1 "$STATE_FILE"` で “発行済みファイル一覧” を取得
   * `/tmp/untested_files.txt` を読みながら **未発行の先頭 BATCH 件** をメモリに保持

4. ループ処理
   For each target file:
   * `cat <FILE>` で内容取得
   * **Claude が判断**
     * interfaceの宣言 だけなら “除外”
     * ファイルパスや内容に `mock`, `fixture`, `testutil`, `fake`, `_testdata`, `dummy` など テスト補助に関するファイルと判断できれば “除外”
   * **対象の場合のみ**
     ```bash
     FILE_REL="${FILE#./}"
     PKG_PATH="${FILE_REL%/*}" ; PKG_PATH="${PKG_PATH#pkg/}"

     title="📦 テスト追加: ${FILE_REL}"
     body=$(sed -e "s/{FILE}/${FILE_REL//\//\\/}/g" \
                -e "s/{PKG_PATH}/${PKG_PATH//\//\\/}/g" \
           < ~/.claude/templates/add_tests_body.md)

     issue_url=$(gh issue create \
                   --title "${title}" \
                   --body  "${body}" \
                   --label "auto generated,claude code" \
                   --assignee "tesso57" 2>&1)
     ```
     * 正常なら `echo "${FILE_REL}|${issue_url}" >> "$STATE_FILE"`
     * 1 秒 sleep（API レート制限対策）
5. 結果報告
   Claude が今回発行した
   \| File | Issue URL |
   をテーブルで返し、末尾に
   ```
   ✅ 発行: <N> 件
   💾 Progress saved to: ~/.claude/state/created_issues.csv
   ```
   を添える。
6. 次なるBATCH 件を対象にして処理を継続する。
