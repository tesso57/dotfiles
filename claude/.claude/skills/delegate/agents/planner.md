# Planner

PDCA の P。タスクを分析し、delegation plan を作る。

## 役割

orchestrator がタスクを受け取ったとき、最初にこのフレームワークで計画を立てる。
簡単なタスクなら orchestrator 自身がインラインで判断。複雑なら codex に委託。

## 計画の出力フォーマット

```
## Delegation Plan

### Goal
<達成したいこと>

### Tasks
| # | 内容 | Agent type | 理由 |
|---|---|---|---|
| 1 | <具体的なタスク> | claude/codex/gemini/cmd | <なぜこの agent か> |

### Context (worker に渡す情報)
- Repository: <repo_path>
- Branch: <current_branch>
- Relevant files: <file_list>
- Background: <orchestrator が事前に集めた情報>

### Completion Criteria
<何をもって完了とするか>

### Prompt Draft
<worker に渡すプロンプトの下書き>
```

## Agent type 選択の指針

| Agent | 得意 | 用途 |
|---|---|---|
| **claude** | 仕様に忠実な実行 | 実装、リファクタリング、設計済み機能 |
| **codex** | 複合的分析・多角的判断 | レビュー、アーキテクチャ分析、タスク分解 |
| **gemini** | 高速ワンショット | 短い質問、要約、簡単な変換 |
| **cmd** | 任意コマンド | `go test ./...`, `npm run build`, linters |

- 実装 → claude
- 分析・レビュー → codex
- codex rate limit → claude にフォールバック
- 多角的な意見が欲しい → claude + codex を並列で

## 設計・アーキテクチャタスクの計画

「設計して」「API を生やしたい」「アーキテクチャを考えて」のような設計タスクでは、
**Brainstorm strategy（`references/strategies.md`）を積極的に使う**。

設計には正解がなく、複数の視点からの提案がより良い判断を導く。
単一 agent で設計させるよりも、異なる観点を持つ複数 agent を並列で走らせることで、
tradeoff が明確になり、orchestrator（またはユーザー）がより informed な判断を下せる。

**推奨パターン:**
- Agent A (codex): 堅牢性・拡張性重視の設計
- Agent B (claude or codex): DX・シンプルさ重視の設計

**設計タスクの判断基準:**
- 正解が1つではない → Brainstorm
- 主観的判断が必要 → Brainstorm → ESCALATE（ユーザー確認）
- 既存パターンに従うだけ → 単一 agent で十分

## 複雑なタスクで codex に計画を委託する場合

orchestrator 自身では分解が難しいとき、codex に計画策定を委託できる:

```bash
cmux-delegate start codex "<planning prompt>"
```

planning prompt に含めるもの:
- コードベースの概要
- 達成したい目標
- 「分析と計画のみ。実装はしないこと」
- 出力: 上記の Delegation Plan フォーマット

## Worker プロンプトの必須要素

どんなタスクでも worker プロンプトには以下を含める:
- 具体的なタスク内容
- 必要なコンテキスト（ファイルパス、ブランチ、背景情報）
- スコープの制限（範囲外の発見は "Additional Findings" に報告）
- **「do not use cmux-delegate」**（worker が再帰的に delegate しないように）
- 完了条件
- 出力フォーマット（Summary / Details / Additional Findings / Status）
