#!/usr/bin/env bash
set -euo pipefail

# 汎用的なタスク作成スクリプト
# Git管理下のファイルを検索し、判定コマンドで評価後、テンプレートを使用してタスクを作成

# デフォルト値
MODE="all"
BASE_BRANCH="develop"
DRY_RUN=true
declare -a PATTERNS=()
declare -a EXCLUDES=()
TAGS=""

# カウンター
created_count=0
excluded_count=0
error_count=0

# ヘルプ表示
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

汎用的なタスク作成スクリプト

必須オプション:
  -t, --template <file>    タスクテンプレートファイル
  -j, --judge <command>    判定コマンド

オプション:
  -p, --pattern <glob>     対象ファイルパターン（複数指定可）
  -x, --exclude <pattern>  除外パターン（複数指定可）
  -m, --mode <mode>        検索モード: all|diff（デフォルト: all）
  -b, --base <branch>      比較元ブランチ（mode=diffの場合、デフォルト: develop）
  --tags <tags>            タスクに付けるタグ（カンマ区切り）
  --dry-run               実行をシミュレート
  -h, --help              このヘルプを表示

例:
  # すべてのGoファイルでテストタスク作成
  $(basename "$0") -t ~/.claude/templates/add_tests.md -j "claude /judge-testable-go" -p '*.go' -x '*_test.go'

  # 変更されたTypeScriptファイルのみ
  $(basename "$0") -t template.md -j judge.sh -p '*.ts' -m diff
EOF
}

# オプション解析
parse_options() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -t|--template)
                TEMPLATE="$2"
                shift 2
                ;;
            -j|--judge)
                JUDGE_CMD="$2"
                shift 2
                ;;
            -p|--pattern)
                PATTERNS+=("$2")
                shift 2
                ;;
            -x|--exclude)
                EXCLUDES+=("$2")
                shift 2
                ;;
            -m|--mode)
                MODE="$2"
                shift 2
                ;;
            -b|--base)
                BASE_BRANCH="$2"
                shift 2
                ;;
            --tags)
                TAGS="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "❌ 不明なオプション: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # 必須オプションチェック
    if [[ -z "${TEMPLATE:-}" ]]; then
        echo "❌ エラー: テンプレートファイルが指定されていません"
        show_help
        exit 1
    fi

    if [[ -z "${JUDGE_CMD:-}" ]]; then
        echo "❌ エラー: 判定コマンドが指定されていません"
        show_help
        exit 1
    fi

    # テンプレートファイルの存在確認
    if [[ ! -f "$TEMPLATE" ]]; then
        echo "❌ エラー: テンプレートファイルが見つかりません: $TEMPLATE"
        exit 1
    fi
}

# ファイルリストを取得
get_file_list() {
    local files

    if [[ "$MODE" == "all" ]]; then
        # すべてのGit管理ファイル
        if [[ ${#PATTERNS[@]} -eq 0 ]]; then
            files=$(git ls-files)
        else
            # パターンが指定されている場合
            local pattern_args=()
            for pattern in "${PATTERNS[@]}"; do
                pattern_args+=("$pattern")
            done
            files=$(git ls-files "${pattern_args[@]}")
        fi
    else
        # 変更されたファイルのみ
        files=$(git diff --name-only --diff-filter=d "$BASE_BRANCH"...HEAD)
        
        # パターンフィルタ
        if [[ ${#PATTERNS[@]} -gt 0 ]]; then
            local pattern_regex=$(IFS='|'; echo "${PATTERNS[*]}" | sed 's/\*/.*/g')
            files=$(echo "$files" | grep -E "$pattern_regex" || true)
        fi
    fi

    # 除外パターンフィルタ
    if [[ ${#EXCLUDES[@]} -gt 0 ]] && [[ -n "$files" ]]; then
        local exclude_regex=$(IFS='|'; echo "${EXCLUDES[*]}" | sed 's/\*/.*/g')
        files=$(echo "$files" | grep -v -E "$exclude_regex" || true)
    fi

    echo "$files"
}

# 判定コマンドを実行
judge_file() {
    local file="$1"
    local result

    # 判定コマンドを実行
    if ! result=$(timeout 60 $JUDGE_CMD "$file" 2>/dev/null); then
        return 1
    fi

    # JSON形式のレスポンスをチェック
    if ! echo "$result" | jq -e . >/dev/null 2>&1; then
        return 1
    fi

    echo "$result"
}

# テンプレート変数を置換
replace_template_vars() {
    local file="$1"
    local content="$2"

    local file_name=$(basename "$file")
    local file_dir=$(dirname "$file")
    local file_ext="${file_name##*.}"
    local base_name="${file_name%.*}"
    
    # Goファイルの場合のパッケージパス
    local pkg_path=""
    if [[ "$file_ext" == "go" ]]; then
        pkg_path="${file_dir#./}"
        pkg_path="${pkg_path#pkg/}"
    fi

    # テンプレート変数を置換
    echo "$content" | sed \
        -e "s|{FILE}|$file|g" \
        -e "s|{FILE_NAME}|$file_name|g" \
        -e "s|{FILE_DIR}|$file_dir|g" \
        -e "s|{FILE_EXT}|$file_ext|g" \
        -e "s|{BASE_NAME}|$base_name|g" \
        -e "s|{PKG_PATH}|$pkg_path|g"
}

# タスクファイルを作成
create_task() {
    local file="$1"
    local file_rel="${file#./}"
    
    # ファイル名用のタイトル（スラッシュをハイフンに、アンダースコアは保持）
    local title_for_filename="${file_rel//_/@@UNDERSCORE@@}"
    title_for_filename="${title_for_filename//\//-}"
    title_for_filename="${title_for_filename//@@UNDERSCORE@@/_}"
    
    # テンプレートから本文を生成
    local template_content=$(cat "$TEMPLATE")
    local body=$(replace_template_vars "$file" "$template_content")
    
    # タイトルを生成（テンプレートの最初の#行または一般的なタイトル）
    local title=$(echo "$body" | grep -m1 '^#' | sed 's/^#\+\s*//' || echo "タスク: $file_rel")
    
    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] タスク作成: $title_for_filename"
        return 0
    fi
    
    # locusコマンドでタスク作成
    local result
    local locus_args=("add" "$title_for_filename" "--body" "$body")
    
    # タグが指定されている場合
    if [[ -n "$TAGS" ]]; then
        locus_args+=("--tags" "$TAGS")
    fi
    
    if result=$(locus "${locus_args[@]}" 2>&1); then
        # 作成されたファイル名を抽出
        local task_file
        task_file=$(echo "$result" | grep "タスクを作成しました:" | sed 's/.*タスクを作成しました: //' | xargs -I {} basename "{}")
        
        if [[ -n "$task_file" ]]; then
            # 追加のメタデータ
            locus tags set "$task_file" "source_file" "$file_rel" >/dev/null 2>&1
            echo "$task_file"
            return 0
        fi
    fi
    
    return 1
}

# メイン処理
main() {
    parse_options "$@"

    echo "🔍 対象ファイルを検索中..."
    echo "モード: $MODE"
    
    if [[ "$MODE" == "diff" ]]; then
        echo "比較元ブランチ: $BASE_BRANCH"
    fi
    
    if [[ ${#PATTERNS[@]} -gt 0 ]]; then
        echo "対象パターン: ${PATTERNS[*]}"
    fi
    
    if [[ ${#EXCLUDES[@]} -gt 0 ]]; then
        echo "除外パターン: ${EXCLUDES[*]}"
    fi
    
    echo

    # ファイルリストを取得
    local files
    if ! files=$(get_file_list); then
        echo "❌ ファイルリストの取得に失敗しました"
        exit 1
    fi

    # ファイル数を確認
    local file_count=0
    if [[ -n "$files" ]]; then
        file_count=$(echo "$files" | grep -c . || echo 0)
    fi

    if [[ $file_count -eq 0 ]]; then
        echo "✅ 対象ファイルはありません"
        exit 0
    fi

    echo "📊 対象ファイル数: $file_count"
    echo

    # 結果格納用の配列
    local created_tasks=()
    local excluded_files=()
    local error_files=()

    # 各ファイルを処理
    local current=0
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        current=$((current + 1))
        echo "[$current/$file_count] 処理中: $file"

        # 判定処理
        local judge_result
        if ! judge_result=$(judge_file "$file"); then
            echo "  ❌ 判定エラー"
            error_files+=("$file|判定エラー")
            error_count=$((error_count + 1))
            continue
        fi

        local is_testable=$(echo "$judge_result" | jq -r '.testable // false')
        local reason=$(echo "$judge_result" | jq -r '.reason // "unknown"')

        if [[ "$is_testable" == "true" ]]; then
            echo "  ✅ タスク対象として判定"

            if task_file=$(create_task "$file"); then
                if [[ -n "$task_file" ]]; then
                    echo "  📝 タスク作成: $task_file"
                    created_tasks+=("$file|$task_file")
                    created_count=$((created_count + 1))
                else
                    echo "  ❌ タスク作成失敗: ファイル名を取得できませんでした"
                    error_files+=("$file|ファイル名取得エラー")
                    error_count=$((error_count + 1))
                fi
            else
                echo "  ❌ タスク作成失敗"
                error_files+=("$file|タスク作成失敗")
                error_count=$((error_count + 1))
            fi
        else
            echo "  ⏭️  除外: $reason"
            excluded_files+=("$file|$reason")
            excluded_count=$((excluded_count + 1))
        fi
        echo
    done <<<"$files"

    # 結果サマリー
    echo "📊 処理結果サマリー"
    echo "===================="

    if [[ $created_count -gt 0 ]]; then
        echo
        echo "✅ 作成したタスク ($created_count件):"
        for item in "${created_tasks[@]}"; do
            IFS='|' read -r file task <<<"$item"
            echo "  - $file → $task"
        done
    fi

    if [[ $excluded_count -gt 0 ]]; then
        echo
        echo "⏭️  除外したファイル ($excluded_count件):"
        for item in "${excluded_files[@]}"; do
            IFS='|' read -r file reason <<<"$item"
            echo "  - $file: $reason"
        done
    fi

    if [[ $error_count -gt 0 ]]; then
        echo
        echo "❌ エラー ($error_count件):"
        for item in "${error_files[@]}"; do
            IFS='|' read -r file error <<<"$item"
            echo "  - $file: $error"
        done
    fi

    echo
    echo "合計: 作成 $created_count / 除外 $excluded_count / エラー $error_count / 総数 $file_count"

    if [[ "$DRY_RUN" == true ]]; then
        echo
        echo "📝 [DRY RUN モード] 実際のタスクは作成されていません"
    fi
}

main "$@"