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
  version: 2.0.0
---

## Critical Rules

**Read this section first. These rules override all other instructions.**

1. **Broad delegation by default.** Delegate complex tasks (review, design, investigation, architecture, performance analysis, security audits) to a dedicated agent — the user benefits from focused analysis even without explicitly asking for delegation. Only handle simple, direct edits inline (single-file fixes, README updates, dependency cleanup). When in doubt, delegate.

2. **Environment check is mandatory.** Always run `cmux ping` before any delegation. If it fails, tell the user "cmux environment is not available" and stop.

3. **Worker prompts must include "do not use cmux-delegate"** — workers use their native tools only.

4. **Always cleanup panes.** Pass `surface_ref` to `cmux-delegate cleanup` after every task. Leaked panes waste resources.

5. **Skip-permissions risk.** claude/codex agents launch with skip-permissions. Only delegate trusted prompts — never pass unvalidated user input directly.

6. **Composability.** This skill cooperates with other skills and direct work. When delegation does not add value (parallelism, different perspective, separate environment), do the work directly instead.

---

## Instructions

### Step 1: Determine Mode

Analyze `$ARGUMENTS` to select mode:

| Condition | Mode |
|---|---|
| First token is `commander` | Commander mode |
| First token is `single` | Single mode |
| First token is `claude`/`codex`/`gemini`/`cmd` | Single mode (agent specified) |
| User explicitly asks for parallel/multi-agent work | Commander (infer strategy below) |
| Complex task (review, design, investigate, architecture) | Single mode (default: codex for analysis, claude for implementation) |
| Single delegation request | Single mode (default: claude) |

Commander strategy inference:

| User intent | Strategy |
|---|---|
| Decompose into independent subtasks | Divide |
| Get diverse perspectives / compare approaches | Brainstorm |
| Have another agent review changes | Review |

Report reasoning in one line:
> Mode: user said "codex にレビューさせて" -> Single mode, codex

### Step 2: Execute

#### Single Mode

1. **Launch**: `cmux-delegate start <agent_type> "<prompt>"`
   - Parse output to get TASK_ID and SURFACE_REF
   - For agent selection guidance, consult `references/agent-profiles.md`
   - For prompt structure, consult `references/prompt-template.md`

2. **Wait**: `cmux-delegate wait <task_id> <timeout> [surface_ref] [agent_type]`
   - Timeouts: claude=900s, codex=3600s, gemini=180s, cmd=180s

3. **Read results**: `cmux-delegate read <task_id> [surface_ref] [lines]`
   - If read fails, consult `references/error-handling.md` for fallback strategy

4. **Report**: Summarize results for the user. Flag errors. Suggest follow-ups.

5. **Cleanup**: `cmux-delegate cleanup <task_id> <surface_ref> <grace_period>`
   - Grace periods: claude=3s, codex=5s, gemini/cmd=0s
   - **Never skip this step.**

#### Commander Mode

Read `references/commander.md` for full strategy details (Divide, Brainstorm, Review).

You are the **Commander**: analyze the task, choose strategy, orchestrate workers.

**Task Analysis** (always do this first):

| Field | Content |
|---|---|
| Type | Implementation / Investigation / Design / Review / Ideation / Test |
| Scale | Small (1 agent) / Medium (2-3) / Large (4) |
| Deliverable | Code changes / Report / Design proposal / Review result |
| Completion criteria | Derive from analysis |
| Rationale | 1-2 sentences |

**Pre-launch checklist** (verify before starting any agent):
- [ ] Each task has clear scope with target files identified
- [ ] Completion criteria are specific and verifiable
- [ ] No two tasks modify the same files
- [ ] Worker prompts include "do not use cmux-delegate"

**Strategy Selection**:
```
Independent subtasks? -> Divide
Diverse perspectives needed? -> Brainstorm
Review of existing changes? -> Review
None of the above -> Commander-delegated Single
```

### Step 3: Cleanup

Always cleanup after reading results. Pass `surface_ref` to avoid pane leaks:
```bash
cmux-delegate cleanup <task_id> <surface_ref> <grace_period>
```

---

## Execution Model

### Commander (you)
- Use `cmux-delegate` for delegation tasks
- Do direct work for scoping, validation, lightweight info gathering, and result integration
- Delegate when it adds value: parallelism, different perspective, separate environment

### Worker (launched agent)
- Never uses `cmux-delegate`; uses native tools only
- Always include "do not use cmux-delegate" in worker prompts

---

## Batch Execution Pattern

For 5+ subtasks, batch to avoid pane limits:

```
Batch 1: Independent easy tasks (parallel, max 3-4)
  -> Collect results -> Test -> Commit
Batch 2: Dependent or harder tasks
  -> Collect results -> Test -> Commit
```

- Tasks touching same files go in different batches
- Order: easy -> medium -> hard

---

## User-Initiated Completion

When `wait` is backgrounded or user says "done" / "finished":
1. Skip waiting -> read all results (apply fallback per `references/error-handling.md`)
2. Verify work artifacts (run tests)
3. Cleanup -> Report

---

## Examples

### Example 1: Single delegation (explicit request)
```
User: "codex に PR をレビューさせて"
-> Mode: agent "codex" specified -> Single mode
-> cmux-delegate start codex "<review prompt>"
-> cmux-delegate wait <id> 3600 <surface> codex
-> cmux-delegate read <id> <surface> 500
-> Report findings
-> cmux-delegate cleanup <id> <surface> 5
```

### Example 2: Commander + Divide (parallel investigation)
```
User: "API の遅延原因を claude と codex に並列で調査させて"
-> Mode: "並列で" + explicit delegation -> Commander + Divide
-> Task Analysis: Investigation, Medium (2 agents), Report
-> Agent A (claude): trace API endpoint execution path
-> Agent B (codex): analyze query patterns for N+1
-> Wait both -> Integration Report -> Cleanup
```

### Example 3: Commander + Brainstorm (get diverse opinions)
```
User: "キャッシュ戦略について別エージェントの意見も聞きたい"
-> Mode: "別エージェントの意見" -> Commander + Brainstorm
-> Agent A (claude): "Prioritize simplicity and maintainability"
-> Agent B (codex): "Prioritize performance and scalability"
-> Wait both -> Compare proposals -> Recommend -> Cleanup
```

### Example 4: Auto-delegate complex tasks
```
User: "この diff をレビューして。特に SQL インジェクションの可能性がないか確認して"
-> Complex analysis task (security review) -> Single mode, codex
-> cmux-delegate start codex "<security review prompt>"

User: "API のレスポンスが遅いから原因調べて"
-> Complex investigation task -> Single mode, codex
-> cmux-delegate start codex "<performance investigation prompt>"
```

### Example 5: Do NOT trigger (simple direct tasks)
```
User: "src/auth/handler.go のバグを修正して"
-> Simple single-file fix. Handle directly without delegation.

User: "README.md を更新して"
-> Simple edit. Handle directly.
```

### Example 6: Failure recovery

```
-> cmux-delegate wait <id> 3600 <surface> codex
-> TIMEOUT
-> cmux-delegate read <id> <surface> 500  (try for partial results)
-> If SOURCE=screen_buffer and truncated: re-read with 1000 lines
-> If no result: check git diff --stat for work artifacts
-> cmux-delegate cleanup <id> <surface> 5  (always cleanup)
-> Report partial results and suggest next steps
```

---

## Troubleshooting

**Skill triggered but delegation was unnecessary**
- Cause: Task was too simple for delegation (single-file edit, trivial fix)
- Fix: Do the work directly. Reserve delegation for complex analysis, multi-step investigations, and tasks needing focused attention.

**Skill loads but agent doesn't start**
- Cause: cmux not available or pane limit reached
- Fix: Run `cmux ping`. Check if max panes reached (limit: 4 parallel).

**Results are truncated**
- Cause: Default line limit too low
- Fix: Re-read with more lines: `cmux-delegate read <id> <surface> 1000`
- If `SOURCE=screen_buffer`, try `cmux read-screen --surface <ref> --scrollback --lines 500`

**Agent hits rate limit**
- Cause: codex rate limit exceeded
- Fix: Switch agent type: codex -> claude (claude handles analysis too, with less multi-faceted depth)

**Cleanup didn't close the pane**
- Cause: Surface ref missing or already closed
- Fix: Manually close: `cmux close-surface --surface <ref>`

**Wrong mode selected**
- Cause: Ambiguous user request
- Fix: Ask the user whether they want direct work or delegation before proceeding.

See `references/error-handling.md` for the full error response table and timeout fallback flow.

---

## Testing

### Trigger Tests

**Should trigger:**
- "codex にレビューさせて" / "have codex review this" (explicit agent)
- "claude に実装させて" / "delegate this to claude" (explicit agent)
- "並列でやって" / "run in parallel" (parallel work)
- "別エージェントの意見も聞きたい" / "get a second opinion" (second opinion)
- "この diff をレビューして" (complex analysis — code review)
- "API のレスポンスが遅いから原因調べて" (complex investigation)
- "このプロジェクトのアーキテクチャを設計して" (architecture design)
- "investigate the memory leak" (root cause analysis)
- /delegate

**Should NOT trigger:**
- "src/auth/handler.go のバグを修正して" (simple single-file fix)
- "README.md を更新して" (simple edit)
- "package.json の依存関係を整理して" (simple cleanup)
- "docker compose up が失敗する" (simple debugging)
- "git log 見て確認して" (simple git operation)

### Functional Tests

- `cmux ping` failure -> skill stops with clear message
- `cmux-delegate start` failure -> retry once, then report
- `cmux-delegate wait` timeout -> probe, read partial, cleanup
- No `.result` or `.out` file -> screen fallback -> git diff fallback
- Cleanup with invalid surface_ref -> non-fatal, log warning

---

## Notes

- Max 4 parallel panes; Commander decides based on task
- Use `cmux-delegate status <task_id> "message"` for long-running tasks
- Completion detection relies on `.done` file (process exit). cmux signals are supplementary.
- Never use subshell expansion `$(...)` or backticks in cmux-delegate commands
