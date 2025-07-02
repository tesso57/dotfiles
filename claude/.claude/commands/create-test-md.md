---
allowed-tools:
description: |
  テストがないファイルを検出する。
  ファイルごとに、テスト作成タスクテンプレートを指定の場所に作成する。
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
