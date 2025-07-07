#!/usr/bin/env bash
set -euo pipefail

# タスクファイルを検索してリスト表示する補助スクリプト

# デフォルトのタスクディレクトリ
TASK_BASE="${HOME}/Documents/Obsidian Vault/tasks"

# 引数処理
SEARCH_PATH="${1:-}"
PATTERN="${2:-*.md}"

# ヘルプ表示
show_help() {
    cat <<EOF
使用方法: find_task_files.sh [PATH] [PATTERN]

Obsidian Vaultのタスクファイルを検索します。

引数:
  PATH     検索するパス（省略時はすべてのタスクを検索）
           例: no9jp/no9-title-server
  PATTERN  ファイル名パターン（省略時は*.md）

例:
  # すべてのタスクファイルを表示
  find_task_files.sh

  # 特定の組織/リポジトリのタスクを表示
  find_task_files.sh no9jp/no9-title-server

  # 特定のパターンに一致するタスクを表示
  find_task_files.sh "" "*test*.md"
EOF
}

# ヘルプオプション
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_help
    exit 0
fi

# 検索パスの構築
if [[ -n "$SEARCH_PATH" ]]; then
    FULL_SEARCH_PATH="$TASK_BASE/$SEARCH_PATH"
else
    FULL_SEARCH_PATH="$TASK_BASE"
fi

# ディレクトリの存在確認
if [[ ! -d "$FULL_SEARCH_PATH" ]]; then
    echo "ERROR: Directory not found: $FULL_SEARCH_PATH" >&2
    exit 1
fi

# タスクファイルの検索と表示
echo "Searching task files in: $FULL_SEARCH_PATH"
echo

# ファイル数をカウント
file_count=$(find "$FULL_SEARCH_PATH" -name "$PATTERN" -type f 2>/dev/null | wc -l | tr -d ' ')

if [[ "$file_count" -eq 0 ]]; then
    echo "No task files found"
    exit 0
fi

echo "Found task files ($file_count files):"
echo

# ファイルを相対パスで表示（タスクベースディレクトリからの相対パス）
find "$FULL_SEARCH_PATH" -name "$PATTERN" -type f 2>/dev/null | while read -r file; do
    # タスクベースディレクトリからの相対パス
    rel_path="${file#$TASK_BASE/}"
    
    # ファイルの最終更新日時を取得
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        mod_date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$file")
    else
        # Linux
        mod_date=$(stat -c "%y" "$file" | cut -d' ' -f1-2 | cut -d'.' -f1)
    fi
    
    # タスクのステータスを取得（YAMLフロントマターから）
    status=$(grep -m1 "^status:" "$file" 2>/dev/null | sed 's/status: *//' || echo "unknown")
    
    # 表示
    printf "%-60s [%s] %s\n" "$rel_path" "$status" "$mod_date"
done | sort

echo
echo "Hint: Use '/work-on-task <path>' to start working on a task"