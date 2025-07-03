#!/usr/bin/env bash

# タスク管理スクリプト
# git管理されているディレクトリから呼ばれた場合はそのリポジトリ名のディレクトリに、
# そうでない場合は~/Documents/Obsidian\ Vault/tasksに配置する

# エラーハンドリングの強化
set -euo pipefail
IFS=$'\n\t'

# デフォルトのタスクディレクトリ
DEFAULT_TASK_DIR="$HOME/Documents/Obsidian Vault/tasks"

# === Markdown Frontmatter Property Helper Functions ===

# Check if file exists
check_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "Error: File '$file' not found" >&2
        exit 1
    fi
}

# Extract frontmatter from file
extract_frontmatter() {
    local file="$1"
    local in_frontmatter=false
    local frontmatter=""
    local dash_count=0

    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            dash_count=$((dash_count + 1))
            if [[ $dash_count -eq 1 ]]; then
                in_frontmatter=true
                continue
            elif [[ $dash_count -eq 2 ]]; then
                break
            fi
        fi

        if [[ "$in_frontmatter" == true ]]; then
            frontmatter+="$line"$'\n'
        fi
    done <"$file"

    echo "$frontmatter"
}

# Extract content after frontmatter
extract_content() {
    local file="$1"
    local in_content=false
    local content=""
    local dash_count=0
    local has_fm=false

    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            dash_count=$((dash_count + 1))
            if [[ $dash_count -eq 1 ]]; then
                has_fm=true
            elif [[ $dash_count -eq 2 ]]; then
                in_content=true
                continue
            fi
        elif [[ $dash_count -eq 0 ]]; then
            # No frontmatter, include all content
            content+="$line"$'\n'
        fi

        if [[ "$in_content" == true ]]; then
            content+="$line"$'\n'
        fi
    done <"$file"

    # Remove trailing newline only if there's content
    if [[ -n "$content" ]]; then
        content="${content%$'\n'}"
    fi
    echo -n "$content"
}

# Check if file has frontmatter
has_frontmatter() {
    local file="$1"
    local first_line
    first_line=$(head -n 1 "$file" 2>/dev/null || echo "")
    [[ "$first_line" == "---" ]]
}

# Get a specific property value
get_property() {
    local file="$1"
    local property="$2"
    check_file "$file"

    if ! has_frontmatter "$file"; then
        return 1
    fi

    local frontmatter
    frontmatter=$(extract_frontmatter "$file")

    if [[ -z "$frontmatter" ]]; then
        return 1
    fi

    local in_multiline=false
    local current_key=""
    local current_value=""
    local indent_level=0
    local found=false
    
    while IFS= read -r line; do
        # Check if this is a key-value line
        if [[ "$line" =~ ^[[:space:]]*([^:]+):[[:space:]]*(.*)$ ]]; then
            # Output previous multiline value if it matches
            if [[ "$in_multiline" == true && "$current_key" == "$property" ]]; then
                echo "$current_value"
                found=true
                break
            fi
            
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            # Trim whitespace from key
            key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            # Check if this is the property we're looking for
            if [[ "$key" == "$property" ]]; then
                # Check if value starts with | or > (multiline indicators)
                if [[ "$value" =~ ^[[:space:]]*[\|\>][[:space:]]*$ ]]; then
                    in_multiline=true
                    current_key="$key"
                    current_value=""
                    # Calculate indent level for multiline content
                    [[ "$line" =~ ^([[:space:]]*) ]] && indent_level=${#BASH_REMATCH[1]}
                else
                    # Single line value - output and exit
                    echo "$value"
                    found=true
                    break
                fi
            else
                in_multiline=false
                current_key=""
                current_value=""
            fi
        elif [[ "$in_multiline" == true && "$current_key" == "$property" ]]; then
            # Part of multiline value for our property
            # Remove the base indentation
            local content="$line"
            if [[ ${#line} -gt $indent_level ]]; then
                content="${line:$((indent_level+2))}"
            elif [[ -z "$line" ]]; then
                content=""
            fi
            if [[ -n "$current_value" ]]; then
                current_value+=$'\n'"$content"
            else
                current_value="$content"
            fi
        else
            # We've reached the end of multiline value
            if [[ "$in_multiline" == true && "$current_key" == "$property" ]]; then
                echo "$current_value"
                found=true
                break
            fi
        fi
    done <<< "$frontmatter"
    
    # Output last multiline value if it matches and we haven't already output it
    if [[ "$in_multiline" == true && "$current_key" == "$property" && "$found" == false ]]; then
        echo "$current_value"
        found=true
    fi

    if [[ "$found" == false ]]; then
        return 1
    fi
}

# List only property names
list_property_names() {
    local file="$1"
    check_file "$file"

    if ! has_frontmatter "$file"; then
        return 0
    fi

    local frontmatter
    frontmatter=$(extract_frontmatter "$file")

    if [[ -z "$frontmatter" ]]; then
        return 0
    fi

    while IFS= read -r line; do
        # Check if this is a key-value line
        if [[ "$line" =~ ^[[:space:]]*([^:]+):[[:space:]]*(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            # Trim whitespace from key
            key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            echo "$key"
        fi
    done <<< "$frontmatter"
}

# List all properties
list_properties() {
    local file="$1"
    check_file "$file"

    if ! has_frontmatter "$file"; then
        echo "No frontmatter found in file"
        return 0
    fi

    local frontmatter
    frontmatter=$(extract_frontmatter "$file")

    if [[ -z "$frontmatter" ]]; then
        echo "Empty frontmatter"
        return 0
    fi

    echo "Properties in $file:"
    local in_multiline=false
    local current_key=""
    local current_value=""
    local indent_level=0
    
    while IFS= read -r line; do
        # Check if this is a key-value line
        if [[ "$line" =~ ^[[:space:]]*([^:]+):[[:space:]]*(.*)$ ]]; then
            # Output previous multiline value if exists
            if [[ "$in_multiline" == true && -n "$current_key" ]]; then
                echo "  $current_key: |"
                echo "$current_value" | sed 's/^/    /'
                in_multiline=false
                current_value=""
            fi
            
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            # Trim whitespace from key
            key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            # Check if value starts with | or > (multiline indicators)
            if [[ "$value" =~ ^[[:space:]]*[\|\>][[:space:]]*$ ]]; then
                in_multiline=true
                current_key="$key"
                current_value=""
                # Calculate indent level for multiline content
                [[ "$line" =~ ^([[:space:]]*) ]] && indent_level=${#BASH_REMATCH[1]}
            else
                # Single line value
                echo "  $key: $value"
            fi
        elif [[ "$in_multiline" == true ]]; then
            # Part of multiline value
            # Remove the base indentation
            local content="$line"
            if [[ ${#line} -gt $indent_level ]]; then
                content="${line:$((indent_level+2))}"
            elif [[ -z "$line" ]]; then
                content=""
            fi
            if [[ -n "$current_value" ]]; then
                current_value+=$'\n'"$content"
            else
                current_value="$content"
            fi
        fi
    done <<< "$frontmatter"
    
    # Output last multiline value if exists
    if [[ "$in_multiline" == true && -n "$current_key" ]]; then
        echo "  $current_key: |"
        echo "$current_value" | sed 's/^/    /'
    fi
}

# Add or update a property
add_property() {
    local file="$1"
    local property="$2"
    local value="$3"
    check_file "$file"

    local frontmatter=""
    local content=""
    local has_fm=false

    if has_frontmatter "$file"; then
        frontmatter=$(extract_frontmatter "$file")
        content=$(extract_content "$file")
        has_fm=true
    else
        content=$(cat "$file")
    fi

    # Check if property already exists
    local updated_frontmatter=""
    local property_found=false

    if [[ -n "$frontmatter" ]]; then
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*${property}:[[:space:]]*.*$ ]]; then
                updated_frontmatter+="${property}: ${value}"$'\n'
                property_found=true
            else
                updated_frontmatter+="$line"$'\n'
            fi
        done <<<"$frontmatter"

        # Remove trailing newline
        updated_frontmatter="${updated_frontmatter%$'\n'}"
    fi

    # Add property if not found
    if [[ "$property_found" == false ]]; then
        if [[ -n "$updated_frontmatter" ]]; then
            updated_frontmatter+=$'\n'
        fi
        updated_frontmatter+="${property}: ${value}"
    fi

    # Write back to file
    {
        echo "---"
        echo "$updated_frontmatter"
        echo "---"
        echo -n "$content"
    } >"$file"

    echo "Property '$property' added/updated in $file"
}

# Remove a property
remove_property() {
    local file="$1"
    local property="$2"
    check_file "$file"

    if ! has_frontmatter "$file"; then
        echo "No frontmatter found in file"
        return 1
    fi

    local frontmatter
    frontmatter=$(extract_frontmatter "$file")
    local content
    content=$(extract_content "$file")

    # Remove the property
    local updated_frontmatter=""
    local property_found=false

    while IFS= read -r line; do
        if [[ ! "$line" =~ ^[[:space:]]*${property}:[[:space:]]*.*$ ]]; then
            if [[ -n "$line" ]]; then
                updated_frontmatter+="$line"$'\n'
            fi
        else
            property_found=true
        fi
    done <<<"$frontmatter"

    # Remove trailing newline
    updated_frontmatter="${updated_frontmatter%$'\n'}"

    if [[ "$property_found" == false ]]; then
        echo "Property '$property' not found in $file"
        return 1
    fi

    # Write back to file
    if [[ -z "$updated_frontmatter" ]]; then
        # If no properties left, remove frontmatter entirely
        echo -n "$content" >"$file"
    else
        {
            echo "---"
            echo "$updated_frontmatter"
            echo "---"
            echo -n "$content"
        } >"$file"
    fi

    echo "Property '$property' removed from $file"
}

# Clear all properties
clear_properties() {
    local file="$1"
    check_file "$file"

    if ! has_frontmatter "$file"; then
        echo "No frontmatter found in file"
        return 0
    fi

    local content
    content=$(extract_content "$file")

    # Write back only the content
    echo -n "$content" >"$file"

    echo "All properties cleared from $file"
}

# Get task file path from task name
get_task_file_path() {
    local task_name="$1"
    
    # Determine task directory based on git repo
    if is_git_repo; then
        GIT_ROOT=$(get_git_root)
        REPO_NAME=$(basename -- "$GIT_ROOT")
        TASK_DIR="$DEFAULT_TASK_DIR/$REPO_NAME"
    else
        TASK_DIR="$DEFAULT_TASK_DIR"
    fi
    
    # Add .md extension if not present
    if [[ "$task_name" != *.md ]]; then
        task_name="${task_name}.md"
    fi
    
    echo "$TASK_DIR/$task_name"
}

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

# ヘルプメッセージ
show_help() {
    echo "使用方法: $0 <command> [arguments]"
    echo ""
    echo "コマンド:"
    echo "  add <タスクファイル名> <ファイル内容>      タスクファイルを追加"
    echo "  tags list <タスクファイル名>               タスクファイルのプロパティ一覧を表示"
    echo "  tags get <タスクファイル名> <プロパティ>    特定のプロパティ値を取得"
    echo "  tags add <タスクファイル名> <プロパティ> <値> プロパティを追加/更新"
    echo "  tags rm <タスクファイル名> <プロパティ>     プロパティを削除"
    echo "  tags clear <タスクファイル名>              全プロパティを削除"
    echo "  help                                      このヘルプメッセージを表示"
    echo ""
    echo "例:"
    echo "  $0 add new_feature.md \"新機能の実装タスク\""
    echo "  $0 tags add new_feature.md status \"in-progress\""
    echo "  $0 tags list new_feature.md"
    echo "  $0 tags get new_feature.md status"
    echo ""
    echo "注: タスクファイル名には .md 拡張子が自動的に追加されます"
    exit 0
}

# 引数チェック
if [ $# -eq 0 ]; then
    show_help
fi

# コマンドの解析
COMMAND="$1"
shift

case "$COMMAND" in
    add)
        # 引数チェック
        if [ $# -lt 2 ]; then
            echo "使用方法: $0 add <タスクファイル名> <ファイル内容>" >&2
            echo "例: $0 add new_feature.md \"新機能の実装タスク\"" >&2
            exit 1
        fi
        ;;
    tags)
        # タグサブコマンド処理
        if [ $# -eq 0 ]; then
            echo "エラー: tagsコマンドにはサブコマンドが必要です" >&2
            echo "使用可能なサブコマンド: list, get, add, rm, clear" >&2
            exit 1
        fi
        
        TAGS_SUBCOMMAND="$1"
        shift
        
        case "$TAGS_SUBCOMMAND" in
            list)
                if [ $# -lt 1 ]; then
                    echo "使用方法: $0 tags list <タスクファイル名>" >&2
                    exit 1
                fi
                TASK_FILE=$(get_task_file_path "$1")
                list_properties "$TASK_FILE"
                exit $?
                ;;
            get)
                if [ $# -lt 2 ]; then
                    echo "使用方法: $0 tags get <タスクファイル名> <プロパティ>" >&2
                    exit 1
                fi
                TASK_FILE=$(get_task_file_path "$1")
                get_property "$TASK_FILE" "$2"
                exit $?
                ;;
            add)
                if [ $# -lt 3 ]; then
                    echo "使用方法: $0 tags add <タスクファイル名> <プロパティ> <値>" >&2
                    exit 1
                fi
                TASK_FILE=$(get_task_file_path "$1")
                add_property "$TASK_FILE" "$2" "$3"
                exit $?
                ;;
            rm)
                if [ $# -lt 2 ]; then
                    echo "使用方法: $0 tags rm <タスクファイル名> <プロパティ>" >&2
                    exit 1
                fi
                TASK_FILE=$(get_task_file_path "$1")
                remove_property "$TASK_FILE" "$2"
                exit $?
                ;;
            clear)
                if [ $# -lt 1 ]; then
                    echo "使用方法: $0 tags clear <タスクファイル名>" >&2
                    exit 1
                fi
                TASK_FILE=$(get_task_file_path "$1")
                clear_properties "$TASK_FILE"
                exit $?
                ;;
            *)
                echo "エラー: 不明なtagsサブコマンド '$TAGS_SUBCOMMAND'" >&2
                echo "使用可能なサブコマンド: list, get, add, rm, clear" >&2
                exit 1
                ;;
        esac
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "エラー: 不明なコマンド '$COMMAND'" >&2
        echo "ヘルプを表示するには '$0 help' を実行してください" >&2
        exit 1
        ;;
esac

# addコマンドの処理を継続
if [ "$COMMAND" != "add" ]; then
    # add以外のコマンドは上記で処理済みなのでここには来ない
    exit 0
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
# .md拡張子を自動追加
if [[ "$TASK_FILE" != *.md ]]; then
    TASK_FILE="${TASK_FILE}.md"
fi
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

# タスクファイルの内容を一時ファイルに作成（frontmatter付き）
{
    echo "---"
    echo "created: $(date +"%Y-%m-%d %H:%M:%S")"
    echo "status: pending"
    echo "---"
    echo
    echo "$TASK_CONTENT"
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