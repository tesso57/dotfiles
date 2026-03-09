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
  version: 3.0.0
---

## Critical Rules

1. **Broad delegation by default.** Complex tasks (review, design, investigation, architecture, performance analysis, security audits) benefit from a dedicated agent's focused attention. Only handle simple, direct edits inline. When in doubt, delegate.

2. **Environment check is mandatory.** Always run `cmux ping` first. If it fails, tell the user "cmux environment is not available" and stop.

3. **Always cleanup panes.** Pass `surface_ref` to `cmux-delegate cleanup` after every task. Leaked panes waste resources.

4. **Skip-permissions risk.** claude/codex agents launch with skip-permissions. Only delegate trusted prompts.

---

## You Are the Orchestrator

When this skill fires, you become the orchestrator. You run a PDCA loop:

```
┌→ P (Plan)    : agents/planner.md — タスク分析、delegation plan 作成
│     ↓
│  D (Do)      : cmux-delegate で agent 起動 → 待機 → 結果収集
│     ↓
│  C (Check)   : agents/checker.md — 結果の品質・完了度を評価
│     ↓
└─ A (Act)     : agents/actor.md — 次のアクション判断
                    → DONE: ユーザーに報告
                    → CONTINUE: planner に戻る
                    → ESCALATE: ユーザーに判断を仰ぐ
```

各フェーズの詳細は `agents/` の対応ファイルを読むこと。
簡単なタスクなら P→D→報告 で完了。フルループは複雑なタスク向け。

---

## P: Plan

`agents/planner.md` を読んで delegation plan を作る。

- 何を誰に頼むか（タスク内容 + agent type）
- worker に渡すコンテキスト（ファイルパス、ブランチ、背景情報）
- 完了条件

簡単なタスク（"codex にレビューさせて"）なら即座にインラインで計画。
複雑なタスクなら `agents/planner.md` のフレームワークに従う。

---

## D: Do

計画に基づいて agent を起動し、結果を収集する。

### Launch

```bash
cmux-delegate start <agent_type> "<prompt>"
```
Parse output to get TASK_ID and SURFACE_REF.

### Wait

```bash
cmux-delegate wait <task_id> <timeout> [surface_ref] [agent_type]
```
Timeouts: claude=900s, codex=3600s, gemini=180s, cmd=180s

### Read (3-level fallback)

```bash
# Level 1: normal
cmux-delegate read <task_id> [surface_ref] [lines]

# Level 2: file fallback
cat /tmp/<task_id>.result 2>/dev/null || cat /tmp/<task_id>.out 2>/dev/null

# Level 3: artifact check
git diff --stat
```

See `references/error-handling.md` for full fallback flow.

### Cleanup

```bash
cmux-delegate cleanup <task_id> <surface_ref> <grace_period>
```
Grace periods: claude=3s, codex=5s, gemini/cmd=0s. **Never skip.**

---

## C: Check

`agents/checker.md` を読んで結果を評価する。

- 完了条件を満たしているか
- 結果は具体的で actionable か
- 複数 agent なら結果間の矛盾・カバレッジを確認

---

## A: Act

`agents/actor.md` を読んで次のアクションを決定する。

- **DONE**: ユーザーに報告して終了
- **CONTINUE**: gaps を planner にフィードして再計画 → ループ継続
- **ESCALATE**: ユーザーに判断を仰ぐ

ループ上限: 最大 3 回。3 回目で PASS にならなければ結果をまとめて報告。

---

## 複数 agent の並列実行

複数 agent を使う場合（並列調査、brainstorm 等）は `references/strategies.md` を参照。

**Pre-launch checklist:**
- [ ] 各タスクのスコープが明確
- [ ] 同じファイルを触るタスクが同時に走らない
- [ ] Worker プロンプトに "do not use cmux-delegate" を含む

**Batch pattern** (5+ subtasks):
```
Batch 1: Independent easy tasks (max 4 parallel)
  → Collect → Test → Commit
Batch 2: Dependent or harder tasks
  → Collect → Test → Commit
```

---

## Examples

### Simple: Explicit agent request
```
User: "codex に PR をレビューさせて"
→ P: codex で PR レビュー。即座に計画。
→ D: cmux-delegate start codex "<review prompt>" → wait → read
→ ユーザーに報告 → cleanup
```

### Simple: Auto-delegate
```
User: "この diff をレビューして"
→ P: セキュリティ含むコードレビュー → codex, 1 agent
→ D: start → wait → read
→ ユーザーに報告 → cleanup
```

### Full loop: Complex investigation
```
User: "API のレスポンスが遅いから原因調べて"
→ P: パフォーマンス調査 → codex (analyzer), 1 agent
→ D: start codex → wait → read
→ C: 結果を評価 → "DB クエリが遅いと判明。具体的なクエリは特定できていない"
→ A: CONTINUE — 追加調査が必要
→ P: 具体的なクエリ特定 → claude, 1 agent (前回の結果をコンテキストに)
→ D: start claude → wait → read
→ C: "N+1 クエリを3箇所特定。修正案付き" → PASS
→ A: DONE → ユーザーに報告 → cleanup
```

### Parallel: Multiple agents
```
User: "キャッシュ戦略について別エージェントの意見も聞きたい"
→ P: 2 agents で brainstorm (references/strategies.md)
→ D: start claude + start codex (異なる視点) → wait both → read both
→ C: 両方の提案を cross-reference
→ A: DONE → 統合報告 → cleanup
```

### Do NOT trigger
```
User: "src/auth/handler.go のバグを修正して"
→ Simple single-file fix. Handle directly.
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Delegation was unnecessary | Simple task — do it directly |
| Agent doesn't start | `cmux ping`. Check pane limit (max 4) |
| Results truncated | Re-read: 500 → 1000 lines |
| Agent hits rate limit | Switch: codex → claude |
| Cleanup didn't close pane | `cmux close-surface --surface <ref>` |

See `references/error-handling.md` for the full error table.

---

## Notes

- Max 4 parallel panes
- `cmux-delegate status <task_id> "message"` for long-running tasks
- Completion detection: `.done` file (process exit)
- Never use `$(...)` or backticks in cmux-delegate commands
