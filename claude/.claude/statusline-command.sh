#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract data from JSON
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
output_style=$(echo "$input" | jq -r '.output_style.name // empty')

# Initialize output parts array
parts=()

# Directory (shortened like fish_style_pwd_dir_length = 1)
if [ -n "$current_dir" ]; then
    # Split path and shorten all but the last component
    IFS='/' read -ra path_parts <<< "$current_dir"
    shortened=""
    for ((i=0; i<${#path_parts[@]}-1; i++)); do
        if [ -n "${path_parts[i]}" ]; then
            shortened+="/${path_parts[i]:0:1}"
        fi
    done
    if [ ${#path_parts[@]} -gt 0 ]; then
        shortened+="/${path_parts[-1]}"
    fi
    parts+=("$(printf '\033[1;38;5;208m%s\033[0m' "${shortened#/}")")
fi

# Git branch and status (if in git repo)
if [ -n "$current_dir" ] && git -C "$current_dir" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$current_dir" branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        parts+=("[$(printf '\033[38;5;99m\033[0m')$(printf '\033[38;5;99m%s\033[0m' "$branch")]")

        # Git status
        if ! git -C "$current_dir" diff --quiet 2>/dev/null || ! git -C "$current_dir" diff --cached --quiet 2>/dev/null; then
            parts+=("[$(printf '\033[38;5;196m*\033[0m')]")
        fi
    fi
fi

# Time
current_time=$(date '+%H:%M:%S')
parts+=("[$(printf '\033[38;5;246m%s\033[0m' "$current_time")]")

# Model and context info
if [ -n "$model" ]; then
    model_short="${model#Claude }"
    parts+=("[$(printf '\033[38;5;33m%s\033[0m' "$model_short")]")
fi

if [ -n "$remaining" ]; then
    parts+=("[$(printf '\033[38;5;226mctx:%s%%\033[0m' "$remaining")]")
fi

# Output style
if [ -n "$output_style" ] && [ "$output_style" != "default" ]; then
    parts+=("[$(printf '\033[38;5;141m%s\033[0m' "$output_style")]")
fi

# Join all parts with space
output=""
for part in "${parts[@]}"; do
    if [ -n "$output" ]; then
        output+=" "
    fi
    output+="$part"
done

# Print final output
printf "%s\n" "$output"
