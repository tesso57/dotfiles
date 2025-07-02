---
# Explicitly specify the Bash subcommands that Claude Code is allowed to execute
allowed-tools:
  - Bash(git status:*      )
  - Bash(git diff:*        )
  - Bash(git branch:*      )
  - Bash(git push:*        )
  - Bash(gh pr create:*    )
description: "Create a draft PR from the current branch"
---

## Context
- **Current branch**: !`git branch --show-current`
- **Git status**:     !`git status --short`
- **Diff summary**:   !`git diff --stat origin/develop`

## Your task
1. Read the context above and create a **PR Title** (in Japanese) that summarizes the main points within 60 characters.
2. Create a **PR Body** (in Markdown, Japanese) that includes the following sections.
    - If the project has a `.github/PR_TEMPLATE.md`, refer to it.
    - Otherwise, include the following sections:
        - Background / Purpose
        - Details of Changes
        - Impact Range
        - How to Verify
        - Related Issues / Tickets
        - Review Points
3. Use the generated title and body to execute the following **Bash** command and output the URL:
```bash
gh pr create --title "$TITLE" --body "$BODY" --base develop --draft --assignee tesso57 --label "auto-generated, claude code"
```