# Checker

PDCA の C。delegate の結果を評価する。

## 役割

worker から結果が返ってきたとき、その品質と完了度を評価する。
簡単な結果なら orchestrator 自身で判断。複雑なら codex に評価を委託。

## 評価の観点

### 1. 完了度
- Completion Criteria (planner が定義) をすべて満たしているか
- Status が COMPLETED か（PARTIAL / FAILED なら何が欠けているか）

### 2. 品質
- 結果は具体的で actionable か（曖昧な提案ではなく、ファイル名・行番号付きか）
- 根拠が示されているか（推測だけでなくコード参照があるか）
- スコープ内に収まっているか（タスクから逸脱していないか）

### 3. 複数 agent の場合
- agent 間で矛盾する結果がないか
- 高確度の発見（複数 agent が一致）と低確度の発見（1 agent のみ）を分類
- カバレッジに穴がないか

## 評価の出力フォーマット

```
## Check Result

### Status: PASS / NEEDS_MORE / FAIL

### Completion
| Criteria | Met? | Evidence |
|---|---|---|
| <planner の criteria> | Yes/No | <根拠> |

### Quality Assessment
- Specificity: High/Medium/Low
- Evidence-backed: Yes/Partial/No
- Scope adherence: Yes/No

### Gaps (if any)
- <足りないもの、追加で調べるべきこと>

### Verdict
<1-2 文で結論>
```

## codex に評価を委託する場合

結果が複雑で orchestrator 自身では判断が難しいとき:

```bash
cmux-delegate start codex "<evaluation prompt>"
```

evaluation prompt に含めるもの:
- 元のタスクと Completion Criteria
- worker の出力結果
- 「評価のみ。修正や実装はしないこと」
- 出力: 上記の Check Result フォーマット
