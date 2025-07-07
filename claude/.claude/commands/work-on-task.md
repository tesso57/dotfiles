---
arguments:
  - name: task_path
    description: タスクファイルへのパス（例: no9jp/no9-title-server/task.md、またはフルパス）
    type: string
allowed-tools:
  # ファイル読み込み
  - Read(~/Documents/Obsidian Vault/tasks/*/*/*)
  - Read(*)
  # TODO管理
  - TodoWrite()
  - TodoRead()
  # スクリプト実行
  - Bash(~/.claude/scripts/find_task_files.sh:*)
  - Bash(find:*)
  - Bash(basename:*)
  - Bash(dirname:*)
  # Git操作
  - Bash(git:*)
  # ディレクトリ操作
  - Bash(cd:*)
  - Bash(pwd:*)
  # ファイル操作
  - Glob()
  - Grep()
  - Edit()
  - MultiEdit()
  - Write()
  # 他のツール
  - Task()
  - mcp__o3__o3-search()
description: |
  Obsidian Vaultのタスクファイルを読み込んで作業を開始する。
  TODO リストを自動的にTodoWriteツールに登録し、タスクを遂行する。
---

## Workflow for Claude

1. **タスクファイルパスの解決**
   - 引数が相対パス（`/`で始まらない）の場合:
     ```bash
     TASK_BASE="$HOME/Documents/Obsidian Vault/tasks"
     FULL_PATH="$TASK_BASE/$task_path"
     ```
   - 引数が絶対パスの場合: そのまま使用
   - ファイルが`.md`で終わらない場合は`.md`を追加

2. **タスクファイルの読み込み**
   ```
   Read($FULL_PATH)
   ```

3. **タスク内容の解析**
   - YAMLフロントマターからメタデータを抽出
     - `source_file`: 対象となるソースファイル
     - `assigner`: タスクの割り当て者
     - `tags`: タグ情報
   - TODO リストの抽出（`- [ ]` で始まる行）

4. **TodoWriteツールへの登録**
   - マークダウンのTODOリストを解析
   - 各タスクを以下の形式で登録:
     ```json
     {
       "id": "task_1",
       "content": "タスクの内容",
       "status": "pending",
       "priority": "medium"
     }
     ```
   - 最初のタスク（通常はworktree作成）を `priority: "high"` に設定

5. **タスクの実行開始**
   - 最初のタスクを `in_progress` に変更
   - worktree作成の場合は、記載されたコマンドを実行
   - 各タスクを順次実行し、完了したら `completed` に更新

### エラーハンドリング
- タスクファイルが見つからない場合は、利用可能なタスクファイルをリストアップ
- TODO形式が正しくない場合は、内容を表示して確認を求める

### 使用例
```
/work-on-task no9jp/no9-title-server/pkg-adaptor-gateway-dataserverserviceimplgo.md
```

または

```
/work-on-task ~/Documents/Obsidian Vault/tasks/no9jp/no9-title-server/pkg-adaptor-gateway-dataserverserviceimplgo.md
```