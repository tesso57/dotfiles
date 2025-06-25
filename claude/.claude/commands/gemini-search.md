---
# Explicitly specify the Bash subcommand that Claude Code is allowed to execute
allowed-tools:
  - Bash(gemini:*)
description: "Performs a web search using the gemini cli"
---

## Context
- `gemini` is google gemini cli.
- It is good at web search.
- You can use this with `gemini -p "WebSearch: ..."`
   - NOTE : ...  where in the above commands is what you want to search. 

## Your task
1. Read the context above to understand gemini.
2. If $ARGUMENTS are explicitly provided, use them. Otherwise, devise a search query based on the preceding context.
3. Use the generated title and body to execute **Bash**: 
```bash
gemini -p "WebSearch: $ARGUMENTS"
```
and incorporate the results.