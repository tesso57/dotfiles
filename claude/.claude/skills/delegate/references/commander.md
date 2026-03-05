# Commander Strategies

## Commander-delegated Single

When Commander determines Single mode is optimal:

1. Embed Step 1 analysis (type, scale, deliverable, criteria, rationale) into the prompt
2. Select optimal agent using Agent Selection table + Agent Profiles
3. Derive completion criteria from Step 1 analysis
4. Proceed to Single mode Serial/Parallel flow

---

## Strategy B: Divide -- Decompose -> Parallel Execute -> Integrate

**When to use**: Task decomposes into independent subtasks.

### B-1. Decompose

For each subtask determine:
- Subtask name
- Agent type (reference Agent Selection + Agent Profiles)
- Prompt (use Prompt Template)

### B-2. Parallel Launch

```bash
cmux-delegate start <agent1> "<prompt1>"
# -> record TASK_ID, SURFACE_REF

cmux-delegate start <agent2> "<prompt2>"
# -> record TASK_ID, SURFACE_REF
```

Report launch status to user as a table.

### B-3. Collect Results

**Method A: Sequential foreground wait (recommended)**
Wait for each task sequentially: `wait` -> `read` -> next task.

**Method B: Background parallel wait**
Launch all `wait` with `run_in_background: true`, do other work, end turn. Process results when notifications arrive.

**CAUTION**: After background `wait`, never call `TaskOutput(block=true)`. It blocks the turn and prevents delivery of background task notifications. End your turn and wait for notifications.

### B-4. Integration Report -- 5 Steps

1. **Status check**: Confirm each subtask status (COMPLETED / PARTIAL / FAILED). Mark failures explicitly; proceed with successes only.
2. **Extract key findings**: Bullet-point important discoveries with source attribution (subtask name).
3. **Cross-reference**:
   - **High confidence**: Findings matching across multiple subtasks
   - **Needs verification**: Single-source or ambiguous findings
   - **Contradiction**: Conflicting results between subtasks
4. **Gap analysis**: Compare against Step 1 completion criteria; identify unmet items.
5. **Output**:

```
## Integration Result

### Completion Status
| Subtask | Status | Agent |
|---|---|---|
| ... | COMPLETED/PARTIAL/FAILED | claude/codex/... |

### Key Findings
- [High confidence] ... (Source: Subtask A, B)
- [Needs verification] ... (Source: Subtask A)
- [Contradiction] ... (A: ..., B: ...)

### Gaps
- Unmet: ...

### Next Actions
- ...
```

### B-5. Cleanup

All tasks: `cleanup` with Agent Profile grace periods.

---

## Strategy C: Brainstorm -- Multi-perspective Ideation

**When to use**: No single correct answer. Design decisions, naming, architecture selection.

### C-1. Build Prompts

Common base prompt + **different perspectives/constraints** per agent. Commander decides perspectives based on task nature.

Example - Architecture:
- Agent A: "Prioritize simplicity and maintainability"
- Agent B: "Prioritize performance and scalability"

Example - API Design:
- Agent A: "Prioritize developer experience"
- Agent B: "Prioritize implementation simplicity"

### C-2. Parallel Launch

2-3 agents (different agent types recommended for diversity).

### C-3. Collect Results

`wait` + timeout probe fallback.

### C-4. Integration Report -- 5 Steps

1. **Status check**: Each agent's status.
2. **Extract proposals**: Structure each agent's proposals (perspective, content, rationale, tradeoffs).
3. **Cross-reference**:
   - **Common points**: Proposals agreed on across agents
   - **Unique points**: Only one agent raised
   - **Opposing points**: Conflicting proposals with rationales
4. **Gap analysis**: Against Step 1 criteria.
5. **Output**:

```
## Brainstorm Integration

### Agent Proposals
| Agent | Perspective | Proposal Summary |
|---|---|---|
| A (claude) | Simplicity | ... |
| B (codex) | Performance | ... |

### Common Points
- ...

### Opposing Points
| Issue | Agent A | Agent B |
|---|---|---|
| ... | ... | ... |

### Commander's Recommendation
- Recommended: ...
- Rationale: ...
```

### C-5. Cleanup

---

## Strategy D: Review -- Code Change Quality Verification

**When to use**: Reviewing implemented code changes. May chain after Divide.

### D-1. Get Diff

```bash
git diff <base_ref>
git diff --name-only <base_ref>
```
- No `base_ref` specified: use `--cached` if staged changes exist, otherwise `HEAD~1`
- Empty diff -> "No changes to review" and stop

### D-2. Build Review Prompt

Include these 5 perspectives:
1. **Bugs**: Logic errors, unhandled edge cases, nil/null references
2. **Security**: Injection, auth gaps, credential exposure
3. **Performance**: N+1 problems, unnecessary allocations, complexity issues
4. **Design**: SOLID principles, separation of concerns, interface design
5. **Conventions**: Language idioms, naming, error handling

Specify output format: `file:line [perspective] severity(BLOCKING/WARNING/INFO) - description`
End with overall verdict (LGTM / NEEDS_FIX / BLOCKING).

### D-3. Launch Agents

- Always include codex for code reviews
- 50+ line diff: codex + claude in parallel
- <50 line diff: codex only

### D-4. Collect Results

### D-5. Integration Review Report -- 5 Steps

1. **Status check**: Each reviewer's status.
2. **Extract findings**: Normalize to `file:line [perspective] severity - description`.
3. **Cross-reference**:
   - **High confidence**: Both reviewers agree -> priority display
   - **Reference**: Single reviewer -> display as reference
   - **Contradiction**: Opposing findings -> present both rationales
4. **Gap analysis**: Check all 5 perspectives are covered.
5. **Output**:

```
## Review Integration

### Findings
| # | file:line | Perspective | Severity | Confidence | Description |
|---|---|---|---|---|---|
| 1 | ... | Bug | BLOCKING | High confidence | ... |
| 2 | ... | Design | WARNING | Reference | ... |

### Overall Verdict: LGTM / NEEDS_FIX / BLOCKING
- Rationale: ...

### Recommended Actions
- ...
```

Verdict logic: Both LGTM -> LGTM / Either BLOCKING -> BLOCKING / Otherwise -> NEEDS_FIX

### D-6. Cleanup

---

## Strategy Chaining

Commander can chain strategies. Embed previous strategy results into next strategy's prompts.

Typical patterns:
- **Divide -> Review**: Review after implementation
- **Brainstorm -> Single**: Implement chosen idea with 1 agent
- **Brainstorm -> Divide**: Implement chosen idea in parallel

Chaining rules:
- After Divide implementation -> Auto-chain Review (unless explicitly told not to)
- After Brainstorm -> Confirm chosen approach with user before next strategy

---

## Difficulty Assessment and Delegation

```
Receive task
-> Can Commander decompose/plan on its own?
   Yes -> Delegate implementation directly to claude
   No  -> Delegate task decomposition to codex (Analyze phase)
          -> Use decomposition to delegate implementation to claude
```

**Analyze phase (codex for task decomposition):**
```bash
cmux-delegate start codex "<task analysis prompt>"
```

Include in analysis prompt:
- Codebase overview
- Goal to achieve
- "Analyze and decompose only; do not implement"
- Output format: subtask list (specific changes, target files, completion criteria per subtask)

After receiving analysis, Commander launches claude for each subtask.
