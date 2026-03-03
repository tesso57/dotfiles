---
name: delegate-knowledge
description: "delegate スキル（/delegate）を使用する際の内部知識。cmux-delegate のサブコマンド仕様、エージェントプロファイル、モード判定ロジック、統合レポート手順を提供する。delegate コマンド実行時に自動参照される。"
---

# Delegate スキル内部知識

## このスキルの目的

`/delegate` コマンド実行時に参照する知識ベース。delegate.md のコマンド定義を補完し、判断に迷いやすいポイントを明文化する。

---

## cmux-delegate サブコマンド一覧

| サブコマンド | 書式 | 用途 |
|---|---|---|
| `start` | `start <agent> <prompt>` | ペイン作成 + エージェント起動。TASK_ID, SURFACE_REF を返す |
| `wait-poll` | `wait-poll <task_id> [timeout] [interval] [surface_ref] [agent_type]` | ポーリング待機。PROGRESS 出力。frozen→return 2、timeout→return 1 |
| `probe` | `probe <task_id> [surface_ref] [agent_type]` | 状態判定: completed / active / idle / waiting / frozen / stalled / unknown |
| `wait` | `wait <task_id> [timeout]` | ブロック待ち（レガシー。wait-poll を優先） |
| `read` | `read <task_id> [surface_ref] [lines]` | 結果取得。lines でスクリーン行数を指定可（デフォルト 200） |
| `status` | `status <task_id> <msg> [icon]` | サイドバーステータス更新 |
| `cleanup` | `cleanup <task_id> [surface_ref] [grace_period]` | クリーンアップ。grace_period 秒待ってから実行 |

---

## エージェントプロファイル

タイムアウト・ポーリング・クリーンアップの設定値。これらは wait-poll / cleanup に渡す具体的な数値。

| 特性 | claude | codex | gemini | cmd |
|---|---|---|---|---|
| デフォルトタイムアウト | 900s | 3600s（終了通知まで粘る） | 180s | 180s |
| 推奨ポーリング間隔 | 60s | 30s | N/A（wait で十分） | N/A（wait で十分） |
| 完了検出 | done シグナル | done シグナル + `›` idle | done シグナル | done シグナル |
| 結果取得方法 | read-screen 200行 | read-screen 200行 | /tmp ファイル | /tmp ファイル |
| フリーズ判定 | 60s 画面変化なし | 60s 画面変化なし + Working なし | ファイルサイズ不変 | ファイルサイズ不変 |
| クリーンアップ猶予 | 3s | 5s | 0s | 0s |

**使い方の例**:
```bash
# claude エージェントの場合
cmux-delegate wait-poll "$TASK_ID" 900 60 "$SURFACE_REF" claude
cmux-delegate cleanup "$TASK_ID" "$SURFACE_REF" 3

# codex エージェントの場合（3600s = 終了通知まで粘る）
cmux-delegate wait-poll "$TASK_ID" 3600 30 "$SURFACE_REF" codex
cmux-delegate cleanup "$TASK_ID" "$SURFACE_REF" 5

# gemini の場合（wait で十分、ポーリング不要）
cmux-delegate wait "$TASK_ID" 180
cmux-delegate cleanup "$TASK_ID"
```

---

## モード判定ロジック（迷いやすいケース）

### 判定フロー
1. **明示指定**: `commander` → Commander、`single` → Single
2. **エージェント指定**: `claude`/`codex`/`gemini`/`cmd` → Single
3. **タスク性質推論**: プロンプト内のキーワードで判定

### 推論の判断例

| ユーザー入力 | 推論結果 | 理由 |
|---|---|---|
| `"このリポジトリの構成を調査して"` | Commander + Divide | 「調査」キーワード |
| `"認証方法を比較して"` | Commander + Brainstorm | 「比較」キーワード |
| `"PRをレビューして"` | Commander + Review | 「レビュー」キーワード |
| `"AのテストとBのリファクタをやって"` | Commander + Divide | 複数の独立作業 |
| `"この関数を修正して"` | Single (Serial) | 単一の実装タスク |
| `"依存関係を調べて"` | Single (Parallel) | 調査系だがスコープが狭い → Single + 並列探索 |

### Single の Serial vs Parallel 判定
- **重要**: Parallel 判定は**モード判定ステップ 2（エージェント指定）で Single に確定した場合のみ**適用される。ステップ 3 推論で Commander に振り分けられた場合は Parallel にはならない。
- **Parallel 条件**: 調査/探索/比較系 **かつ** agent_type が claude/codex
- **それ以外は Serial**: 実装タスク、cmd、gemini、明確な単一作業

---

## タイムアウト時のフォールバック手順

```
wait-poll タイムアウト (return 1)
  ↓
probe で状態確認
  ├─ active → 追加 60s の wait-poll（1 回のみ）
  ├─ idle → 完了扱い → read → cleanup（codex 固有）
  ├─ waiting → 権限確認待ち → 待機継続（タイムアウトせず積極的に待つ）
  ├─ frozen/stalled → read で途中結果取得 → cleanup
  ├─ completed → read → cleanup（タイミングのズレ）
  └─ unknown → read 試行 → cleanup

wait-poll frozen 検出 (return 2)
  ↓
即座に read → cleanup
```

**結果末尾が不完全な場合**（claude/codex のみ）:
- 追加 5s 待ち → 再 read → それでも不完全なら部分結果として報告

---

## 統合レポート 5 ステップ（B/C/D 共通）

どの戦略でも統合レポートは以下の 5 ステップで作成する:

1. **結果収集チェック** — 各サブタスクの COMPLETED / PARTIAL / FAILED を確認
2. **キーファインディング抽出** — 出典（サブタスク名）付き箇条書き
3. **クロスリファレンス** — 高信頼度（複数一致）/ 要確認（片方のみ）/ 矛盾（相反）
4. **ギャップ分析** — Commander ステップ 1 の完了条件と突き合わせ
5. **統合レポート出力** — テンプレートに沿って構造化出力

---

## プロンプトテンプレート必須要素

委任先に渡すプロンプトには以下を含めること:

1. **親タスク** — Commander の分析概要（Single の場合は省略可）
2. **コンテキスト** — リポジトリ / ブランチ / 関連ファイル
3. **タスク** — 具体的な指示
4. **スコープ制約** — 範囲外変更の禁止、追加発見は別セクションに記載
5. **完了条件** — 明確な達成基準
6. **出力形式** — 結果サマリ / 詳細 / 追加発見 / ステータス（COMPLETED/PARTIAL/FAILED）

**エージェント別の調整**:
- codex → `git diff` 出力を含めるよう追加指示
- gemini → 簡潔版（親タスク・スコープ制約を省略可）
- cmd → 出力形式の指示は不要

---

## Commander-delegated Single

Commander がステップ 2 で Single が最適と判断した場合の特殊フロー。通常の Single モードとの違い:

1. ステップ 1 の分析結果（種類・規模・成果物・完了条件・選択理由）をプロンプトに組み込む
2. エージェント選定基準表で最適なエージェントを選択（デフォルト claude ではなく、タスクの性質に応じて判断）
3. 完了条件を分析結果から導出してプロンプトに明記
4. Serial/Parallel 判定 → 実行フローに進む

---

## 戦略の連鎖

前の戦略の結果を次の戦略のプロンプトに組み込んで連鎖実行できる。

| パターン | 説明 | 自動/手動 |
|---|---|---|
| Divide → Review | 実装後に変更をレビュー | **自動連鎖**（明示的に不要と指示されない限り） |
| Brainstorm → Single | アイデア出し後、採用案を実装 | 手動（ユーザーに採用案を確認してから） |
| Brainstorm → Divide | アイデア出し後、採用案を分割実装 | 手動 |

---

## エージェント選定基準

| エージェント | 特性 | 選定場面 |
|---|---|---|
| **codex** | コード変更に強い | 新機能追加、リファクタリング、バグ修正 |
| **claude** | 分析・設計に強い | 設計、調査、ドキュメント作成 |
| **gemini** | 高速ワンショット | 短い質問、要約、簡単な変換 |
| **cmd** | 任意コマンド実行 | `go test ./...`, `npm run build`, リンター |

**必須ルール**:
- 実装を伴うタスクでは **codex を第一候補**
- レビュー（戦略 D）では **codex を必ず含める**
- プラン策定では **codex を含めることを推奨**

---

## codex idle 検出の設計

codex の完了検出は二重構造になっている:

### 一次検出（ランチャー内ポーリング）
- codex 起動直後からバックグラウンドでスクリーンを監視
- `›` プロンプト表示 + `Working` 非表示を idle パターンとして検出
- **安定性閾値**: 3 回連続（各 5s 間隔 = 約 15s）で idle パターンを検出してから done シグナル送信
- 初期待機: `CODEX_INITIAL_WAIT` 環境変数（デフォルト 30s）— codex 起動+初回応答を待つ
- read-screen は `--lines 15` で十分な画面コンテキストを取得

### 二次検出（probe コマンド）
- `wait-poll` から interval ごとに呼ばれるフォールバック
- 単発チェック（安定性閾値なし）だが、wait-poll が複数回呼ぶことで信頼度を担保
- probe も `--lines 15` を使用（ランチャーと統一）

### 権限確認待ち検出
- `Allow ...?`、`y/n`、`approve`、`permission` パターンを検出
- ランチャー: idle カウントをリセット（done シグナルを送らない）
- probe: `STATUS=waiting` を返す（frozen/idle より優先判定）
- wait-poll: `waiting` は active 扱いで待機継続（タイムアウトしない）

### 誤検知の防止策
- 初期待機を 30s に延長（codex の起動フェーズを確実にスキップ）
- 3 回連続一致を要求（思考フェーズ中の一時的な `›` 表示を排除）
- `--lines 15` で広い画面コンテキストを取得（UI 要素の見落とし防止）
- 権限待ちパターンを frozen/idle より先に検出（誤った完了/凍結判定を防止）

---

## エラーハンドリング要約

| 状況 | 対応 |
|---|---|
| `start` 失敗 | 1 回リトライ → 失敗ならスキップし報告 |
| `wait-poll` タイムアウト | probe → active なら追加 60s → frozen/stalled なら途中結果取得 → idle なら完了扱い |
| frozen 検出 | read で途中結果 → cleanup |
| 一部タスク失敗 | 成功分のみで統合レポート、失敗タスクを明示 |
| 全タスク失敗 | エラー原因を分析して報告 |
| 同一ファイルの競合変更 | 競合箇所を明示、手動マージを提案 |
| 結果末尾が不完全 | claude/codex: 追加 5s 待ち + 再 read |

---

## 運用制約

- `claude` / `codex` はスキップパーミッションで起動 — 信頼できるプロンプトのみ
- 並列数は最大 4 ペイン
- 長時間タスクでは `status` でステータスを更新
- Review の統合判定は保守的（疑わしい場合は NEEDS_FIX）
- wait-poll はバックグラウンド実行を推奨（PROGRESS 出力で進捗追跡可能）
