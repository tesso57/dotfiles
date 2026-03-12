# Actor

The A in PDCA. Decide the next action based on the Check result.

## Decision Flow

```
Status?
  ├─ PASS       → report to user → DONE
  ├─ NEEDS_MORE → feed gaps to planner → CONTINUE
  └─ FAIL       → analyze cause → different approach or ESCALATE
```

## Decision Criteria

**Stop** (end loop):
- PASS, or user says done, or max iterations (3) reached

**Continue** (return to planner):
- Gaps exist, quality is low, or new information emerged

**Escalate** (ask user):
- No improvement after 2 loops, unresolvable contradictions, subjective judgment needed

## Next Action Format

```
## Next Action

### Decision: DONE / CONTINUE / ESCALATE

### Reasoning
<1-2 sentences>

### For DONE:
<report draft>

### For CONTINUE:
- What next: <task summary>
- Feed to planner: <previous results + gaps>

### For ESCALATE:
- Question: <what to ask user>
- Options: <choices>
```
