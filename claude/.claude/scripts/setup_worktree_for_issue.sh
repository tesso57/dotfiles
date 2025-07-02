#!/usr/bin/env bash
# ------------------------------------------------------------
# 引数 : ISSUE_NUMBER
# 役割 : Issue タイトル／本文を読んで対象ファイルを特定し、
#        test/<FILE> ブランチを worktree に追加してパスを返す。
# ------------------------------------------------------------
set -euo pipefail

ISSUE=${1:? "Usage: setup_worktree_for_issue.sh <ISSUE_NUMBER>"}

# 1) Issue 情報取得（JSON で title と body を取る）
META=$(gh issue view "$ISSUE" --json title,body)
TITLE=$(echo "$META" | jq -r '.title')
BODY=$(echo "$META" | jq -r '.body')

# 2) 対象ファイルを推定
# 優先: タイトル「📦 テスト追加: <FILE>」
FILE=$(echo "$TITLE" | sed -n -E 's/^.+テスト追加:\s*(.+\.go)\s*$/\1/p')

# 補助: 本文のコードブロック内 `BRANCH="test/<FILE>"` から抽出
if [[ -z "$FILE" ]]; then
    FILE=$(echo "$BODY" | grep -Eo 'BRANCH="test/[^"]+"' | head -1 | sed -E 's/BRANCH="test\/(.+)"/\1/')
fi

[[ -z "$FILE" ]] && {
    echo "❌ ファイルパスを Issue から取得できませんでした" >&2
    exit 1
}

BRANCH="test/$FILE"
WORKTREE=".git/worktree/${BRANCH//\//_}"

# 3) 既に worktree が存在する場合はスキップ
if [[ -d "$WORKTREE" ]]; then
    echo "ℹ️  Worktree already exists at $WORKTREE"
else
    git worktree add -b "$BRANCH" "$WORKTREE" develop
    echo "✅  Worktree created: $WORKTREE"
fi

# 4) Issue にコメントを残す
gh issue comment "$ISSUE" \
    --body "🔧 作業ブランチ \`$BRANCH\` を worktree (\`$WORKTREE\`) に作成しました。$(cd $WORKTREE) で作業を開始してください。"

# 5) スクリプト呼び出し元に作成パスを返す
echo "$WORKTREE"
