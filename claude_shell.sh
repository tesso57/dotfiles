#!/usr/bin/env zsh

RESULT=$(~/.claude/local/claude -p "$@" --output-format text)

echo "$RESULT"
