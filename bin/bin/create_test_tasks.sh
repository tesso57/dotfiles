#!/bin/bash
set -euo pipefail

# テストファイルが存在しないGoファイルに対してテストタスクを作成するスクリプト
# Claudeの判定機能と組み合わせて使用

# 一時ファイル
UNTESTED_FILES="/tmp/untested_files.txt"
RESULTS_LOG="/tmp/test_task_results.log"

# カウンター
CREATED_COUNT=0
EXCLUDED_COUNT=0
ERROR_COUNT=0

# 結果ログをクリア
>"$RESULTS_LOG"

echo "🔍 テストが無いGoファイルを検索中..."

# テストが無いGoファイルのリストを取得
~/.claude/scripts/list_untested_go.sh >"$UNTESTED_FILES"

TOTAL_FILES=$(wc -l <"$UNTESTED_FILES" | tr -d ' ')
echo "📊 対象ファイル数: $TOTAL_FILES"
echo ""

# 進捗表示の準備
CURRENT=0

# 各ファイルを処理
while IFS= read -r file; do
    ((CURRENT++))
    echo "[$CURRENT/$TOTAL_FILES] 処理中: $file"

    # Claudeに判定を依頼
    # claude code /judge-testable-go コマンドを呼び出し
    # 注: このコマンドはJSON形式で結果を返す前提
    if JUDGE_RESULT=$(claude -p /judge-testable-go "$file" 2>/dev/null); then
        # JSONから値を抽出
        IS_TESTABLE=$(echo "$JUDGE_RESULT" | jq -r '.testable // false')
        REASON=$(echo "$JUDGE_RESULT" | jq -r '.reason // "unknown"')

        if [[ "$IS_TESTABLE" == "true" ]]; then
            # テスト対象ファイルの場合
            echo "  ✅ テスト対象として判定"

            # ファイルパスの処理
            FILE_REL="${file#./}"
            PKG_PATH="${FILE_REL%/*}"
            PKG_PATH="${PKG_PATH#pkg/}"

            # タスクファイル名を生成
            BASE_NAME=$(basename "$FILE_REL" .go)
            TASK_FILE_NAME="test_${BASE_NAME}.md"

            # タイトルと本文の準備
            TITLE="📦 テスト追加: ${FILE_REL}"

            # テンプレートを読み込んで変数を置換
            BODY=$(sed -e "s/{FILE}/${FILE_REL//\//\\/}/g" \
                -e "s/{PKG_PATH}/${PKG_PATH//\//\\/}/g" \
                <~/.claude/templates/add_tests_body.md)

            # タスク内容を作成
            TASK_CONTENT="${TITLE}

${BODY}"

            # タスクファイルを作成
            if ~/bin/add_task.sh "$TASK_FILE_NAME" "$TASK_CONTENT" >/dev/null 2>&1; then
                # 現在のブランチ名を取得
                CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")

                # 属性を追加
                ~/bin/md_prop.sh add "$TASK_FILE_NAME" "source_branch" "$CURRENT_BRANCH" >/dev/null
                ~/bin/md_prop.sh add "$TASK_FILE_NAME" "tags" "auto generated" >/dev/null
                ~/bin/md_prop.sh add "$TASK_FILE_NAME" "assigner" "claude code" >/dev/null
                ~/bin/md_prop.sh add "$TASK_FILE_NAME" "created_date" "$(date '+%Y-%m-%d')" >/dev/null
                ~/bin/md_prop.sh add "$TASK_FILE_NAME" "source_file" "$FILE_REL" >/dev/null

                echo "  📝 タスクファイル作成: $TASK_FILE_NAME"
                echo "CREATED|$file|$TASK_FILE_NAME" >>"$RESULTS_LOG"
                ((CREATED_COUNT++))
            else
                echo "  ❌ タスクファイル作成失敗"
                echo "ERROR|$file|Task creation failed" >>"$RESULTS_LOG"
                ((ERROR_COUNT++))
            fi
        else
            # 除外対象ファイルの場合
            echo "  ⏭️  除外: $REASON"
            echo "EXCLUDED|$file|$REASON" >>"$RESULTS_LOG"
            ((EXCLUDED_COUNT++))
        fi
    else
        # Claude判定でエラーが発生した場合
        echo "  ❌ 判定エラー"
        echo "ERROR|$file|Judge command failed" >>"$RESULTS_LOG"
        ((ERROR_COUNT++))
    fi

    echo ""
done <"$UNTESTED_FILES"

# 結果サマリーを表示
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 処理結果サマリー"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 作成したタスクの一覧
if [[ $CREATED_COUNT -gt 0 ]]; then
    echo "✅ 作成したタスク: $CREATED_COUNT 件"
    echo ""
    echo "| ファイル | タスクファイル名 |"
    echo "|----------|-----------------|"
    grep "^CREATED" "$RESULTS_LOG" | while IFS='|' read -r _ file task; do
        echo "| $file | $task |"
    done
    echo ""
fi

# 除外したファイルの一覧
if [[ $EXCLUDED_COUNT -gt 0 ]]; then
    echo "⏭️  除外したファイル: $EXCLUDED_COUNT 件"
    echo ""
    echo "| ファイル | 理由 |"
    echo "|----------|------|"
    grep "^EXCLUDED" "$RESULTS_LOG" | while IFS='|' read -r _ file reason; do
        echo "| $file | $reason |"
    done
    echo ""
fi

# エラーの一覧
if [[ $ERROR_COUNT -gt 0 ]]; then
    echo "❌ エラー: $ERROR_COUNT 件"
    echo ""
    echo "| ファイル | エラー |"
    echo "|----------|--------|"
    grep "^ERROR" "$RESULTS_LOG" | while IFS='|' read -r _ file error; do
        echo "| $file | $error |"
    done
    echo ""
fi

# 最終サマリー
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ タスク作成: $CREATED_COUNT 件"
echo "⏭️  除外: $EXCLUDED_COUNT 件"
echo "❌ エラー: $ERROR_COUNT 件"
echo "📊 処理ファイル数: $TOTAL_FILES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 一時ファイルをクリーンアップ
rm -f "$UNTESTED_FILES" "$RESULTS_LOG"
