# cmux-delegate Command Reference

This is cmux, NOT tmux. Always use `cmux-delegate`.

## start — Launch agent

```bash
cmux-delegate start <agent_type> "<prompt>"
```

| Arg | Required | Description |
|-----|----------|-------------|
| agent_type | yes | `claude` / `codex` / `gemini` / `cmd` |
| prompt | yes | Wrap in double quotes. `$(...)` and backticks are forbidden |

**Output:**
```
TASK_ID=delegate-1234567890-12345
SURFACE_REF=surface:5
```

Parse both values and pass them to subsequent commands.

## wait — Wait for completion

```bash
cmux-delegate wait <task_id> [timeout] [surface_ref] [agent_type]
```

| Arg | Required | Default | Description |
|-----|----------|---------|-------------|
| task_id | yes | - | From start output |
| timeout | no | 900 | Seconds. Recommended: codex=3600 |
| surface_ref | no | - | Required for idle detection. Always pass it |
| agent_type | no | - | Required for idle detection. Always pass it |

**Recommended timeouts:** claude=900, codex=3600, gemini=180, cmd=180

**Output:** `OK` (success) or `TIMEOUT` (timed out)

**Important:** surface_ref and agent_type are technically optional, but required for claude/codex idle detection. Always pass them.

## read — Read results

```bash
cmux-delegate read <task_id> [surface_ref] [lines]
```

| Arg | Required | Default | Description |
|-----|----------|---------|-------------|
| task_id | yes | - | From start output |
| surface_ref | no | - | For screen fallback |
| lines | no | 200 | Line count for screen fallback |

**Read priority:**
1. `/tmp/<task_id>.result` — Result file written by the agent
2. `/tmp/<task_id>.out` — stdout capture (gemini/cmd)
3. screen buffer — Fallback (may be truncated)

## probe — Check status

```bash
cmux-delegate probe <task_id> [surface_ref] [agent_type]
```

**Output:** `STATUS=completed|active|idle|waiting|frozen|stalled|unknown`

| Status | Meaning |
|--------|---------|
| completed | `.done` file exists (gemini/cmd) |
| active | Screen changes detected / file size increasing |
| idle | Prompt visible (claude: `❯`, codex: `›`) |
| waiting | Waiting for permission confirmation |
| frozen | No screen changes |
| stalled | No file size changes (gemini/cmd) |

## cleanup — Clean up

```bash
cmux-delegate cleanup <task_id> [surface_ref] [grace_period]
```

| Arg | Required | Default | Description |
|-----|----------|---------|-------------|
| task_id | yes | - | |
| surface_ref | no | - | Required to close the pane |
| grace_period | no | 0 | Seconds. Recommended: claude=3, codex=5 |

Deletes temp files + clears status + closes pane. **Always call this.**

## status — Update sidebar

```bash
cmux-delegate status <task_id> "<message>" [icon]
```

For displaying progress on long-running tasks.

## Typical Flow

```bash
# 1. Launch
cmux-delegate start claude "task description"
# → TASK_ID=delegate-xxx SURFACE_REF=surface:N

# 2. Wait (always pass surface_ref and agent_type)
cmux-delegate wait delegate-xxx 900 surface:N claude

# 3. Read results
cmux-delegate read delegate-xxx surface:N

# 4. Cleanup (always run)
cmux-delegate cleanup delegate-xxx surface:N 3
```
