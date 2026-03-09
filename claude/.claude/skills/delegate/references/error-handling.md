# Error Handling

## Error Response Table

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

## Timeout Fallback Flow

```
wait timeout
  |
probe for status
  |-- active    -> extra 60s wait (once only)
  |-- idle      -> treat as completed -> read -> cleanup (codex specific)
  |-- waiting   -> permission prompt detected -> keep waiting (don't timeout)
  |-- frozen    -> read partial results -> cleanup
  |-- completed -> read -> cleanup (timing lag)
  +-- unknown   -> try read -> cleanup
```

## Result Reading: 3-Level Fallback

This is the most failure-prone step. Always be prepared to fall back:

```bash
# Level 1: cmux-delegate read (normal route)
cmux-delegate read <task_id> [surface_ref] [lines]

# Level 2: If read fails (Surface is not a terminal, etc.) -> read file directly
cat /tmp/<task_id>.result 2>/dev/null || cat /tmp/<task_id>.out 2>/dev/null

# Level 3: If no result files -> check work artifacts directly
git diff --stat  # Did the agent make changes?
```

When Level 1 returns `SOURCE=screen_buffer` and content appears truncated, increase lines:
```bash
cmux-delegate read <task_id> <surface_ref> 500
```
