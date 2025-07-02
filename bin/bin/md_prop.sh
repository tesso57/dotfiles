#!/bin/bash

# Markdown frontmatter property editor
# Usage: md_prop.sh <command> <file> [property] [value]

set -euo pipefail

# Display usage information
usage() {
    cat <<EOF
Usage: $(basename "$0") <command> <file> [property] [value]

Commands:
    list       <file>                    List all properties in the frontmatter
    properties <file>                    List only property names
    get        <file> <property>         Get the value of a specific property
    add        <file> <property> <value> Add or update a property
    rm         <file> <property>         Remove a property
    clear      <file>                    Remove all properties (clear frontmatter)

Examples:
    $(basename "$0") list document.md
    $(basename "$0") properties document.md
    $(basename "$0") get document.md title
    $(basename "$0") add document.md title "My Document"
    $(basename "$0") rm document.md draft
    $(basename "$0") clear document.md
EOF
}

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

# Main function
main() {
    if [[ $# -lt 2 ]]; then
        usage
        exit 1
    fi

    local command="$1"
    local file="$2"

    case "$command" in
    list)
        list_properties "$file"
        ;;
    properties)
        list_property_names "$file"
        ;;
    get)
        if [[ $# -lt 3 ]]; then
            echo "Error: 'get' command requires property name" >&2
            usage
            exit 1
        fi
        get_property "$file" "$3"
        ;;
    add)
        if [[ $# -lt 4 ]]; then
            echo "Error: 'add' command requires property and value" >&2
            usage
            exit 1
        fi
        add_property "$file" "$3" "$4"
        ;;
    rm)
        if [[ $# -lt 3 ]]; then
            echo "Error: 'rm' command requires property name" >&2
            usage
            exit 1
        fi
        remove_property "$file" "$3"
        ;;
    clear)
        clear_properties "$file"
        ;;
    *)
        echo "Error: Unknown command '$command'" >&2
        usage
        exit 1
        ;;
    esac
}

main "$@"
