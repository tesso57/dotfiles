#!/usr/bin/env bash
# -- Go ファイルのうち *_test.go が存在しないものを列挙 ---------------

set -euo pipefail

rg --files \
    -g '*.go' \
    -g '!*.pb.go' \
    -g '!*.sql.go' \
    -g '!*_test.go' \
    -g '!*_mock.go' \
    -g '!vendor/**' \
    -g '!main.go' |
    while read -r src; do
        test_file="${src%.go}_test.go"
        [[ ! -f "$test_file" ]] && echo "$src"
    done
