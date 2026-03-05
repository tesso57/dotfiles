---
name: delegate
description: "AI \u30a8\u30fc\u30b8\u30a7\u30f3\u30c8\u59d4\u4efb \u2014 cmux-delegate \u3067\u5225\u30da\u30a4\u30f3\u306e AI \u30a8\u30fc\u30b8\u30a7\u30f3\u30c8\u306b\u30bf\u30b9\u30af\u3092\u59d4\u4efb\u3057\u3001\u7d50\u679c\u3092\u53ce\u96c6\u30fb\u7d71\u5408\u3059\u308b\u3002\u30e6\u30fc\u30b6\u30fc\u304c\u300c\u59d4\u4efb\u3057\u3066\u300d\u300c\u30a8\u30fc\u30b8\u30a7\u30f3\u30c8\u306b\u3084\u3089\u305b\u3066\u300d\u300cdelegate\u300d\u300c\u4e26\u5217\u3067\u3084\u3063\u3066\u300d\u300c\u5206\u62c5\u3057\u3066\u300d\u3068\u8a00\u3063\u305f\u3068\u304d\u3001\u307e\u305f\u306f\u8907\u6570\u306e\u72ec\u7acb\u30bf\u30b9\u30af\u3092\u5225\u306e AI \u306b\u4efb\u305b\u305f\u3044\u3068\u304d\u306b\u4f7f\u3046\u3002Single \u30e2\u30fc\u30c9\uff081\u30a8\u30fc\u30b8\u30a7\u30f3\u30c8\uff09\u3068 Commander \u30e2\u30fc\u30c9\uff08\u5206\u6790\u21d2\u5206\u89e3\u21d2\u4e26\u5217\u59d4\u4efb\u21d2\u7d71\u5408\uff09\u3092\u30b5\u30dd\u30fc\u30c8\u3002/delegate \u30b3\u30de\u30f3\u30c9\u3067\u3082\u30c8\u30ea\u30ac\u30fc\u3055\u308c\u308b\u3002"
allowed-tools:
  - Bash(cmux-delegate:*)
  - Bash(cmux:*)
  - Bash(git diff*)
  - Bash(git log*)
  - Bash(cat /tmp/delegate*)
---

## What is cmux-delegate

cmux-delegate is a delegation script that launches AI agents (claude, codex, gemini) or arbitrary commands in separate tmux panes, waits for completion, and collects results. It builds on cmux's IPC primitives.

## Environment Check

Always verify cmux is available first:
```bash
cmux ping
```
If this fails, tell the user "cmux environment is not available" and stop.

---

## Agent Profiles

Reference this table for timeouts, result retrieval, and cleanup throughout all phases.

| Property | claude | codex | gemini | cmd |
|---|---|---|---|---|
| Default timeout | 900s | 3600s | 180s | 180s |
| Completion detection | Process exit -> launcher signals | Process exit -> launcher signals | Process exit -> signal | Process exit -> signal |
| Result retrieval (priority) | 1. `.result` file 2. screen fallback | 1. `.result` file 2. screen fallback | `/tmp/<task_id>.out` | `/tmp/<task_id>.out` |
| On timeout | probe once -> +60s if active | probe once -> +60s if active | Immediate TIMEOUT | Immediate TIMEOUT |
| Cleanup grace period | 3s | 5s | 0s | 0s |

### Agent Characteristics (Practical Knowledge)

**claude** -- 仕様に忠実な実装者
- 設計済みの仕様・プロンプトに沿った中〜小規模コーディングに強い
- 「機能が動くか」に集中する力がある。プロンプトの指示を忠実に実行する
- `.result` ファイルを安定して書き出す（結果取得の信頼性が高い）
- 弱み: 大規模・高抽象度のタスクでは指示が曖昧だと方向を見失いやすい
- 得意: リファクタリング実装、バグ修正、テスト追加、設計済み機能の実装

**codex** -- 複合的思考の分析者
- 抽象的・複合的な思考タスクに強い。「複数の状態を同時に考慮する」力がある
- タスク分解、講義資料作成、コードレビューなど、多角的な判断が必要な作業が得意
- 弱み: 実装を任せると細部で指示から逸脱することがある。rate limit に達しやすい
- `.result` ファイルを書き出さないことがある（フォールバック読み取りの準備が必要）
- 得意: コードレビュー、アーキテクチャ分析、タスク分解、設計方針の策定

**gemini** -- 高速ワンショット
- 短い質問、要約、簡単な変換に最適。起動→完了が速い
- 対話的な作業は不向き。1 回のプロンプトで完結するタスク専用

**cmd** -- 任意コマンド
- `go test ./...`, `npm run build`, リンター等の定型コマンド実行用

### Agent Selection Rules

| Agent | Strength | Use for |
|---|---|---|
| **claude** | Implementation, design, analysis | Coding, refactoring, design, review, investigation |
| **codex** | Task decomposition, analysis, review | Difficulty assessment, task breakdown, code review, strategy |
| **gemini** | Fast one-shot | Short questions, summaries, simple transforms |
| **cmd** | Arbitrary command execution | `go test ./...`, `npm run build`, linters |

**Rules:**
- Implementation tasks -> claude first
- codex is for analysis/task-decomposition/review. Don't ask codex to implement directly.
- If Commander can't assess difficulty -> ask codex to decompose, then delegate implementation to claude.
- Review (Strategy D) -> always include codex.
- If codex hits rate limit -> switch to claude. claude can handle analysis tasks too, just with less depth on multi-faceted reasoning.
- For Brainstorm (Strategy C) -> mix agent types for diversity (e.g., claude + codex). Same agent type gives less divergent perspectives.

---

## Mode Selection

Analyze `$ARGUMENTS` to determine the mode:

### 1. Explicit

| First token | Mode |
|---|---|
| `commander` | Commander mode |
| `single` | Single mode (forced) |

### 2. Agent specified (Single mode)

First token is `claude` / `codex` / `gemini` / `cmd` -> Single mode

### 3. Task nature inference

If first token matches none of the above, analyze the full prompt:

| Keywords/pattern | Inference |
|---|---|
| investigate/explore/search/list/structure | Commander + Divide |
| compare/design/which/architecture | Commander + Brainstorm |
| review/check/verify/quality | Commander + Review |
| Multiple independent tasks ("do A and B") | Commander + Divide |
| Single task not matching above | Single |

Report the reasoning in one line before executing:
> Mode: "refactoring" keyword detected -> Commander + Brainstorm

---

## Single Mode

### Parse arguments

Format: `[agent_type] <prompt>` (remove `single` prefix if present)
- First token matches agent type -> use it, rest is prompt
- No match -> entire string is prompt, default to `claude`

### Serial Flow

#### 1. Launch

```bash
cmux-delegate start <agent_type> "<prompt>"
```
Parse output to get TASK_ID and SURFACE_REF.

#### 2. Wait

```bash
cmux-delegate wait <task_id> <timeout> [surface_ref] [agent_type]
```
Use timeout from Agent Profiles table. On timeout, `wait` internally probes once and extends by 60s if active.

#### 3. Read results (3-level fallback)

This is the most failure-prone step. Always be prepared to fall back:

```bash
# Level 1: cmux-delegate read (normal route)
cmux-delegate read <task_id> [surface_ref] [lines]

# Level 2: If read fails (Surface is not a terminal, etc.) -> read file directly
cat /tmp/<task_id>.result 2>/dev/null || cat /tmp/<task_id>.out 2>/dev/null

# Level 3: If no result files -> check work artifacts directly
git diff --stat  # Did the agent make changes?
```

**When Level 1 returns `SOURCE=screen_buffer`** and content appears truncated, increase lines:
```bash
cmux-delegate read <task_id> <surface_ref> 500
```

#### 4. Analyze and report

Summarize results for the user. Flag errors. Suggest follow-up actions.

#### 5. Cleanup

```bash
cmux-delegate cleanup <task_id> <surface_ref> <grace_period>
```
- Always pass `surface_ref` (otherwise the pane leaks)
- Multiple cleanups can be chained: `cleanup <id1> <ref1> 3 && cleanup <id2> <ref2> 3`
- Cleanup failures are non-fatal; suppress with `2>/dev/null` if needed

### Parallel Flow (for investigation tasks)

When Single mode task is investigative AND agent is claude or codex:
- Agent A: Direct approach
- Agent B: Context exploration (git log, imports, call sites)
- Wait for both, integrate findings

---

## Commander Mode

Read `references/commander.md` for full strategy details (Divide, Brainstorm, Review).

You are the **Commander**: analyze the task, choose the optimal strategy, and orchestrate workers.

### Step 1: Task Analysis

| Field | Content |
|---|---|
| Type | Implementation / Investigation / Design / Review / Ideation / Test |
| Scale | Small (1 agent) / Medium (2-3 parallel) / Large (4 parallel) |
| Deliverable | Code changes / Report / Design proposal / Review result |
| Completion criteria | Derive from analysis |
| Rationale | 1-2 sentences on why this type/scale |

### Step 2: Strategy Selection

```
Can the task be decomposed into independent subtasks?
Yes -> Strategy B: Divide
No -> Does the problem need diverse perspectives?
      Yes -> Strategy C: Brainstorm
      No -> Is this a review of existing changes?
            Yes -> Strategy D: Review
            No -> Commander-delegated Single
```

For each strategy's detailed steps, read `references/commander.md`.

---

## User-Initiated Completion

When `wait` is backgrounded or the user says "done" / "finished":

1. Skip waiting -- go straight to result reading
2. Read all task results in parallel (apply 3-level fallback)
3. Verify work artifacts (run tests)
4. Cleanup -> Report

---

## Batch Execution Pattern

For large refactoring or cross-cutting changes with 5+ subtasks:

```
Batch 1: Independent, easy tasks (parallel)
  -> Collect results -> Test -> Commit

Batch 2: Tasks depending on Batch 1, or next easiest
  -> Collect results -> Test -> Commit

Batch N: Remaining tasks
  -> ...
```

**Batching rules:**
- Tasks touching same files go in different batches
- Order: easy -> medium -> hard
- Max 3-4 tasks per batch (pane limit)
- Batch = commit unit; verify tests pass before committing
- If an agent hits rate limits, switch to another type (codex -> claude)

---

## Two-Layer Execution Model

### Commander (you)

- **Use cmux-delegate actively**: analysis, decomposition, delegation, integration
- Don't implement or investigate directly; delegate via cmux-delegate
- Exception: lightweight info gathering for analysis (git diff, file listing)

### Worker (launched agent)

- **Never use cmux-delegate**: workers use their native tools (Agent tool, Read, Grep, etc.)
- Include "do not use cmux-delegate" in every worker prompt

---

## Prompt Template for Workers

Workers launch in isolated sessions. Include sufficient context:

```
## Parent Task
<Commander's analysis: type, scale, overall goal>

## Context
- Repository: <repo_path>
- Branch: <current_branch>
- Relevant files: <file_list>

## Task
<Specific instructions>

## Scope Constraints
- Do not make changes outside the above task scope
- Report out-of-scope findings in "Additional Findings" section
- **Do not use cmux-delegate** -- use your native tools

## Completion Criteria
<Clear acceptance criteria>

## Output Format
### Result Summary
<1-3 sentence summary>

### Details
<Specific changes or findings>

### Additional Findings
<Out-of-scope but noteworthy findings, or "None">

### Status
COMPLETED / PARTIAL / FAILED
```

**Agent-specific notes:**
- **codex**: Add "include git diff output in results"
- **gemini**: Use abbreviated prompt (skip Parent Task, Scope Constraints)
- **cmd**: No output format needed (stdout is the result)

---

## Error Handling

| Situation | Response |
|---|---|
| `start` fails | Retry once -> skip and report on second failure |
| `wait` timeout | `wait` probes internally -> +60s if active -> TIMEOUT |
| After TIMEOUT | Try `read` for partial results (`.result` may exist) -> `cleanup` |
| Some tasks fail | Integrate successful results, clearly mark failed tasks |
| All tasks fail | Analyze error causes, suggest manual alternatives |
| Conflicting file changes | Highlight conflicts in integration report, suggest manual merge |
| `SOURCE=screen_buffer` truncated | Re-read with increased `lines` (200 -> 500 -> 1000) |
| `Surface is not a terminal` | Fall back to `cat /tmp/<task_id>.result` |
| Rate limit on agent | Switch to different agent type |

### Timeout Fallback Flow

```
wait timeout
  ↓
probe for status
  ├─ active   → extra 60s wait (once only)
  ├─ idle     → treat as completed → read → cleanup (codex specific)
  ├─ waiting  → permission prompt detected → keep waiting (don't timeout)
  ├─ frozen   → read partial results → cleanup
  ├─ completed → read → cleanup (timing lag)
  └─ unknown  → try read → cleanup
```

---

## Notes

- claude/codex agents launch with skip-permissions -- only delegate trusted prompts
- Max 4 parallel panes; Commander decides based on task
- Use `cmux-delegate status <task_id> "progress message"` for long-running tasks
- Completion detection relies on `.result` file existence check (every 15s). cmux signals are supplementary.
- Never use subshell expansion `$(...)` or backticks in cmux-delegate commands. Pass prompt strings directly.
