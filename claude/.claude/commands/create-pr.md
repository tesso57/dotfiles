---
# Claude Code が実行してよい Bash サブコマンドを明示
allowed-tools:
  - Bash(git status:*      )
  - Bash(git diff:*        )
  - Bash(git branch:*      )
  - Bash(git push:*        )
  - Bash(gh pr create:*    )
description: "現在のブランチからドラフト PR を作成する"
---

## Context
- **Current branch**: !`git branch --show-current`
- **Git status**:     !`git status --short`
- **Diff summary**:   !`git diff --stat origin/develop`

## Your task
1. 上記コンテキストを読み取り、60 字以内で要点を表す **PR タイトル**（日本語）。
2. 以下の項目を含む **PR 本文**（Markdown、日本語）。
    - プロジェクトに `.github/PR_TEMPLATE.md` がある場合は，それを参照してください．
    - ない場合は，以下の項目を含む
        - 背景 / 目的  
        - 変更点の詳細  
        - 影響範囲  
        - 動作確認方法  
        - 関連 Issue / チケット  
        - レビューポイント
3. 生成したタイトル・本文を使って **Bash**: 
```bash
gh pr create --title "$TITLE" --body "$BODY" --base develop --draft -a tesso57
```
を実行しURLを出力してください．