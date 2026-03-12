# Checker

The C in PDCA. Evaluate worker results for quality and completeness.

## Evaluation Criteria

1. **Completeness** — Does it meet all Completion Criteria from the plan?
2. **Quality** — Specific and actionable (file names, line numbers)? Evidence-backed (code references)? Within scope?
3. **Multi-agent** — Contradictions between agents? High confidence (multiple agree) vs low confidence (single source)? Coverage gaps?

## Check Result Format

```
## Check Result

### Status: PASS / NEEDS_MORE / FAIL

### Completion
| Criteria | Met? | Evidence |
|---|---|---|
| <criteria> | Yes/No | <evidence> |

### Quality Assessment
- Specificity: High/Medium/Low
- Evidence-backed: Yes/Partial/No
- Scope adherence: Yes/No

### Gaps (if any)
- <what's missing>

### Verdict
<1-2 sentence conclusion>
```

## Delegating Evaluation to Codex

For complex results the orchestrator can't easily judge:

```bash
cmux-delegate start codex "<evaluation prompt>"
```

Include: original task + criteria, worker output, "Evaluation only. Do not implement.", Check Result format.
