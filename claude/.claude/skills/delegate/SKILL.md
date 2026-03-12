---
name: delegate
description: "AI agent delegation — launch AI agents (claude, codex, gemini) in separate cmux panes, wait for completion, and collect/integrate results. Use this skill for: (1) explicit delegation ('delegate', 'have codex/claude/gemini do it', 'ask another model', 'second opinion', 'fan out', 'parallelize', 'split the work', 'run in parallel', '別エージェント', '並列で'), (2) complex analysis tasks like code review, architecture design, investigation, debugging root causes, performance analysis, or security audits — these benefit from a dedicated agent's focused attention, (3) running commands in separate panes ('別ペインで', 'go test and npm lint simultaneously'). Also triggered by /delegate command. Do NOT use for simple direct edits: single-file bug fixes, README updates, dependency cleanup, or straightforward configuration changes that you can handle inline without delegation."
allowed-tools:
  - Bash(cmux-delegate:*)
  - Bash(cmux:*)
  - Bash(git diff*)
  - Bash(git log*)
  - Bash(cat /tmp/delegate-*)
metadata:
  author: tesso57
  version: 3.1.0
---

## Critical Rules

These prevent the most common failure modes observed in practice:

1. **cmux, NOT tmux.** This skill uses only `cmux` and `cmux-delegate`. `tmux` commands (`tmux send-keys`, `tmux split-window`, `tmux capture-pane`) look similar but are a completely different system — using them will silently fail.

2. **Delegate broadly.** Complex tasks (review, design, investigation, architecture, performance, security) benefit from a dedicated agent's focused attention. Only handle simple, direct edits inline. When in doubt, delegate.

3. **Ping first.** Run `cmux ping` before any delegation. If it fails, tell the user "cmux environment is not available" and stop.

4. **Always cleanup.** Pass `surface_ref` to `cmux-delegate cleanup` after every task. Leaked panes consume resources and clutter the workspace.

5. **Permission model.** Claude agents launch with `--permission-mode acceptEdits --allowedTools 'Bash(cat > /tmp/*)'`, letting workers write `.result` files without permission prompts. Codex uses its own model. Only delegate trusted prompts.

---

## Agent Selection

| Agent | Best for | Notes |
|---|---|---|
| **codex** | Reviews, analysis, architecture, task decomposition | Default for anything analytical |
| **claude** | Implementation, refactoring, pre-designed features | Faithful execution to spec |
| **gemini** | Quick questions, summaries, simple conversions | Fast one-shot |
| **cmd** | Shell commands | `go test`, `npm run build`, linters |

- **Review → always codex** — no exceptions, even under rate limits (wait for recovery)
- Implementation → claude
- Multiple perspectives → claude + codex in parallel
- Design/architecture → Brainstorm strategy (`references/strategies.md`)

---

## Simple Delegation

Most delegations (80%) follow this pattern. For exact command args, see `references/cmux-delegate-api.md`.

```bash
# 1. Launch
cmux-delegate start claude "task description"
# → TASK_ID=delegate-xxx SURFACE_REF=surface:N

# 2. Wait (always pass surface_ref and agent_type — needed for idle detection)
cmux-delegate wait delegate-xxx 900 surface:N claude

# 3. Read results
cmux-delegate read delegate-xxx surface:N

# 4. Cleanup (always run)
cmux-delegate cleanup delegate-xxx surface:N 3
```

Every worker prompt must include:
- Specific task + context (file paths, branch, background)
- Completion criteria
- **"do not use cmux-delegate"** (prevents recursive delegation)

---

## Complex Tasks: PDCA Loop

For tasks that may need iteration (investigation, multi-step analysis):

```
┌→ P (Plan)  → D (Do)  → C (Check)  → A (Act) ─┐
│                                                  │
│  CONTINUE ←──────────────────────────────────────┘
│  DONE → report to user
│  ESCALATE → ask user for guidance
```

Each phase has its own reference file in `agents/`:
- **P**: `agents/planner.md` — plan format, worker prompt checklist, difficulty assessment
- **C**: `agents/checker.md` — evaluation criteria, Check Result format
- **A**: `agents/actor.md` — decision flow, stop/continue/escalate criteria

Read only the phase you need. Max 3 iterations. For simple tasks, skip C and A — just P→D→report.

---

## Parallel Execution

For multi-agent tasks, see `references/strategies.md`:
- **Divide**: Independent subtasks in parallel
- **Brainstorm**: Multiple perspectives on design/architecture
- **Review**: Code change quality verification

Pre-launch checklist:
- [ ] Each task has a clear, non-overlapping scope
- [ ] No tasks modify the same files simultaneously
- [ ] Worker prompts include "do not use cmux-delegate"
- [ ] Max 4 parallel panes

---

## Examples

### Simple: Explicit request
```
User: "have codex review this PR"
→ codex, PR review
→ start → wait → read → report → cleanup
```

### Simple: Auto-delegate
```
User: "review this diff"
→ codex (reviews always use codex), 1 agent
→ start → wait → read → report → cleanup
```

### PDCA: Complex investigation
```
User: "API response is slow, investigate"
→ P: codex for performance investigation
→ D: start codex → wait → read
→ C: "DB queries slow, specific queries not identified" → NEEDS_MORE
→ A: CONTINUE
→ P: claude to identify specific queries (with previous results as context)
→ D: start claude → wait → read
→ C: "N+1 queries in 3 places, fix proposals included" → PASS
→ A: DONE → report → cleanup
```

### Parallel: Brainstorm
```
User: "get another agent's opinion on caching strategy"
→ 2 agents, Brainstorm strategy
→ start claude + start codex → wait both → read both
→ Cross-reference → integrated report → cleanup
```

### Do NOT trigger
```
User: "fix the bug in src/auth/handler.go"
→ Simple single-file fix. Handle directly.
```

---

## Reference Index

| File | When to read |
|---|---|
| `agents/planner.md` | Planning a delegation (plan format, worker prompt checklist) |
| `agents/checker.md` | Evaluating results (Check Result format, quality criteria) |
| `agents/actor.md` | Deciding next action (stop / continue / escalate) |
| `references/cmux-delegate-api.md` | Need exact command arguments or defaults |
| `references/strategies.md` | Multi-agent delegation (Divide / Brainstorm / Review) |
| `references/error-handling.md` | Something went wrong (timeout, truncation, failures) |

---

## Troubleshooting

| Problem | Quick fix |
|---|---|
| Agent doesn't start | Run `cmux ping`. Check pane limit (max 4) |
| Results truncated | Re-read with more lines: `cmux-delegate read <id> <surface> 500` |
| Agent hits rate limit | Switch agent type (except reviews — wait for codex recovery) |
| Cleanup didn't close pane | `cmux close-surface --surface <ref>` |

See `references/error-handling.md` for the full error table, timeout fallback flow, and 3-level result reading fallback.

---

## Notes

- Always respond to the user in Japanese
- Completion detection: idle prompt for claude/codex, `.done` file for gemini/cmd
- Never use `$(...)` or backticks in cmux-delegate commands
