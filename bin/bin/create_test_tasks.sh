#!/usr/bin/env bash
set -euo pipefail

# Goテスト作成タスクのラッパースクリプト
# create_tasks.sh を使用してGoファイルのテストタスクを作成

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# デフォルト設定
TEMPLATE="${TEMPLATE:-$HOME/.claude/templates/add_tests_body.md}"
JUDGE="${JUDGE:-$HOME/.claude/local/claude /judge-testable-go}"

# create_tasks.sh を呼び出し
exec "$SCRIPT_DIR/create_tasks.sh" \
    --template "$TEMPLATE" \
    --judge "$JUDGE" \
    --pattern '*.go' \
    --exclude '*_test.go' \
    --exclude '*.pb.go' \
    --exclude 'vendor/*' \
    --exclude 'main.go' \
    --exclude '*_mock.go' \
    --exclude '*.sql.go' \
    --mode all \
    --tags "test,go,auto_generated" \
    "$@"