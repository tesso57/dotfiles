# Planner

The P in PDCA. Create a delegation plan before launching any agent.

## Plan Format

```
## Delegation Plan

### Goal
<what to achieve>

### Tasks
| # | Description | Agent type | Rationale |
|---|---|---|---|
| 1 | <specific task> | claude/codex/gemini/cmd | <why this agent> |

### Context (pass to worker)
- Repository: <repo_path>
- Branch: <current_branch>
- Relevant files: <file_list>
- Background: <info gathered by orchestrator>

### Completion Criteria
<what defines done>

### Prompt Draft
<worker prompt draft>
```

## Worker Prompt Checklist

Every worker prompt must include:
- Specific task description
- Required context (file paths, branch, background)
- Scope constraints (out-of-scope findings → "Additional Findings")
- **"do not use cmux-delegate"** (prevents recursive delegation)
- Completion criteria
- Output format (Summary / Details / Additional Findings / Status)

## Difficulty Assessment

```
Receive task
→ Can the orchestrator decompose on its own?
   Yes → delegate implementation directly to claude
   No  → delegate task decomposition to codex first
         → use decomposition to delegate implementation to claude
```

## Delegating Planning to Codex

When the task is too complex for the orchestrator to decompose:

```bash
cmux-delegate start codex "<planning prompt>"
```

Include: codebase overview, goal, "Analysis and planning only. Do not implement.", expected output in Delegation Plan format.

## Design & Architecture Tasks

Design has no single correct answer — multiple perspectives lead to better decisions.
Use the **Brainstorm strategy** (`references/strategies.md`) to run agents with different viewpoints in parallel, making tradeoffs explicit.

Decision criteria:
- No single correct answer → Brainstorm
- Subjective judgment needed → Brainstorm → ESCALATE (user confirmation)
- Just following existing patterns → single agent is sufficient
