#!/usr/bin/env bash

# タスクファイルを追加するスクリプト
# git管理されているディレクトリから呼ばれた場合はそのディレクトリに、
# そうでない場合は~/Documents/Obsidian\ Vault/tasksに配置する

# デフォルトのタスクディレクトリ
DEFAULT_TASK_DIR="$HOME/Documents/Obsidian Vault/tasks"

# 現在のディレクトリを取得
CURRENT_DIR=$(pwd)

# gitリポジトリかどうかをチェック
is_git_repo() {
    git rev-parse --is-inside-work-tree &>/dev/null
}

# タスクファイルを配置するディレクトリを決定
if is_git_repo; then
    # gitリポジトリの場合は現在のディレクトリを使用
    TASK_DIR="$CURRENT_DIR"
    echo "Git repository detected. Using current directory."
else
    # gitリポジトリでない場合はデフォルトディレクトリを使用
    TASK_DIR="$DEFAULT_TASK_DIR"
    echo "Not a git repository. Using default task directory."
fi

# 引数チェック
if [ $# -eq 0 ]; then
    echo "使用方法: $0 <タスクファイル名>"
    echo "例: $0 new_feature.md"
    exit 1
fi

# タスクファイル名
TASK_FILE="$1"

# ディレクトリが存在しない場合は作成
mkdir -p "$TASK_DIR"

# タスクファイルのフルパス
TASK_PATH="$TASK_DIR/$TASK_FILE"

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

# タスクファイルの作成（基本的なテンプレート）
cat > "$TASK_PATH" << EOF
# タスク名

## 概要

## タスクの詳細


- [ ] 

## メモ

---
作成日: $(date +"%Y-%m-%d %H:%M:%S")
EOF

# 結果を表示
if [ -f "$TASK_PATH" ]; then
    echo "タスクファイルを作成しました: $TASK_PATH"
    if is_git_repo; then
        echo "注: このファイルはgitリポジトリ内に作成されました。"
    else
        echo "注: このファイルはデフォルトのタスクディレクトリに作成されました。"
    fi
else
    echo "エラー: タスクファイルの作成に失敗しました。"
    exit 1
fi
