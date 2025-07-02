#!/usr/bin/env bash

# タスクファイルを追加するスクリプト
# git管理されているディレクトリから呼ばれた場合はそのリポジトリ名のディレクトリに、
# そうでない場合は~/Documents/Obsidian\ Vault/tasksに配置する

# エラーハンドリングの強化
set -euo pipefail
IFS=$'\n\t'

# デフォルトのタスクディレクトリ
DEFAULT_TASK_DIR="$HOME/Documents/Obsidian Vault/tasks"

# 現在のディレクトリを取得
CURRENT_DIR=$(pwd)

# gitコマンドが存在するかチェック
has_git() {
    command -v git &>/dev/null
}

# gitリポジトリかどうかをチェック
is_git_repo() {
    if has_git; then
        git -C "$CURRENT_DIR" rev-parse --is-inside-work-tree &>/dev/null
    else
        return 1
    fi
}

# gitリポジトリのルートディレクトリを取得
get_git_root() {
    if has_git; then
        git -C "$CURRENT_DIR" rev-parse --show-toplevel 2>/dev/null
    else
        return 1
    fi
}

# 引数チェック
if [ $# -lt 2 ]; then
    echo "使用方法: $0 <タスクファイル名> <ファイル内容>" >&2
    echo "例: $0 new_feature.md \"新機能の実装タスク\"" >&2
    exit 1
fi

# タスクファイル名とファイル内容
TASK_FILE="$1"
TASK_CONTENT="$2"

# ファイル名の安全性チェック（パストラバーサル対策）
case "$TASK_FILE" in
    */* | *..*) 
        echo "エラー: ファイル名に不正な文字（/や..）が含まれています" >&2
        exit 2
        ;;
esac

# タスクファイルを配置するディレクトリを決定
if is_git_repo; then
    # gitリポジトリのルートディレクトリを取得
    GIT_ROOT=$(get_git_root)
    # リポジトリ名を取得（ルートディレクトリのベース名）
    REPO_NAME=$(basename -- "$GIT_ROOT")
    # デフォルトディレクトリ配下にリポジトリ名のディレクトリを作成
    TASK_DIR="$DEFAULT_TASK_DIR/$REPO_NAME"
    echo "Git repository '$REPO_NAME' detected. Using task directory: $TASK_DIR"
else
    # gitリポジトリでない場合はデフォルトディレクトリを使用
    TASK_DIR="$DEFAULT_TASK_DIR"
    echo "Not a git repository. Using default task directory."
fi

# ディレクトリが存在しない場合は作成（パーミッション設定付き）
if ! mkdir -p -m 700 "$TASK_DIR"; then
    echo "エラー: ディレクトリの作成に失敗しました: $TASK_DIR" >&2
    exit 3
fi

# タスクファイルのフルパス
TASK_PATH="$TASK_DIR/$TASK_FILE"

# シンボリックリンクチェック
if [ -L "$TASK_PATH" ]; then
    echo "エラー: '$TASK_PATH' はシンボリックリンクです。安全のため処理を中止します。" >&2
    exit 4
fi

# ファイルが既に存在する場合の確認
if [ -f "$TASK_PATH" ]; then
    echo "警告: ファイル '$TASK_PATH' は既に存在します。"
    read -p "上書きしますか？ (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "操作をキャンセルしました。"
        exit 0
    fi
fi

# 一時ファイルを使用して安全に作成
TEMP_FILE=$(mktemp) || {
    echo "エラー: 一時ファイルの作成に失敗しました" >&2
    exit 5
}

# 中断時の後処理
trap 'rm -f "$TEMP_FILE"; echo "中断されました" >&2; exit 130' INT TERM

# タスクファイルの内容を一時ファイルに作成
{
    echo "$TASK_CONTENT"
    echo
    echo "---"
    echo "作成日: $(date +"%Y-%m-%d %H:%M:%S")"
} > "$TEMP_FILE" || {
    rm -f "$TEMP_FILE"
    echo "エラー: ファイルの書き込みに失敗しました" >&2
    exit 6
}

# 一時ファイルを目的のパスに移動（パーミッション設定付き）
if install -m 600 "$TEMP_FILE" "$TASK_PATH"; then
    rm -f "$TEMP_FILE"
    echo "タスクファイルを作成しました: $TASK_PATH"
    if is_git_repo; then
        echo "注: このファイルはgitリポジトリ '$REPO_NAME' のタスクとして作成されました。"
    else
        echo "注: このファイルはデフォルトのタスクディレクトリに作成されました。"
    fi
else
    rm -f "$TEMP_FILE"
    echo "エラー: タスクファイルの作成に失敗しました。" >&2
    exit 7
fi