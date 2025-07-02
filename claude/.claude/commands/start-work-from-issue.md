---
arguments:
  - name: issue_number
    description: 着手したい Issue 番号
    type: string
allowed-tools:
  # worktree 作成 + TODO チェック
  - Bash(~/.claude/scripts/setup_worktree_and_check_todo.sh:*)
description: |
  指定 Issue の TODO を読み取り、最初のタスク
  「作業ブランチ & worktree 作成」を実行してチェックを付ける。
---

## Workflow for Claude

1. 引数 `issue_number` を受け取る。  
2. 作業ブランチと worktree を作成する。
   ```bash
   WORKTREE=$(~/.claude/scripts/setup_worktree_and_check_todo.sh {issue_number})
   cd $WORKTREE
   ```
3. issue を読み込み、作業を進める。
   - issue の bodyを読み込む。
   - TODO リストを構成する。
   - TODO リストを解消する。 