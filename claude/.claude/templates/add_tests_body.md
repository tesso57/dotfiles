## 概要

`{FILE}` には現在、自動テスト (`*_test.go`) が存在しません。  
本 Issue では当該ファイルにユニットテストを追加し、以下の TODO を完了させてください。

対象ファイル名: `{FILE}`

## TODO

- [ ] 作業ブランチ & worktree を作成（最優先）
  ```bash
  BRANCH="test/{FILE}"
  WORKTREE=".git/worktree/${BRANCH//\//_}"
  git worktree add -b "$BRANCH" "$WORKTREE" develop
  cd "$WORKTREE"
  ```

* **⚠️ 以降のすべての作業は必ず `$WORKTREE` 内で行うこと。**
* [ ] docs/test_strategy.md を解析して対象モジュールのテスト方針を確認
* [ ] ファイル名 `{FILE}` を解析し、テスト対象となる関数・メソッド・振る舞いを洗い出す
* [ ] 必要なテスト項目を列挙
* [ ] テストを実装し、`go test {PKG_PATH}` がパスすることを確認
* [ ] テストが成功するまで改善を繰り返す
* [ ] docs/cording-standards.md を読み、コーディング規約を遵守
* [ ] o3 mcp を活用してレビューを依頼し、リファクタリングを行う
* [ ] 上記タスクがすべて完了したことを確認（チェックボックスをすべて ✔︎）
* [ ] `/create-pr` コマンドで PR を作成
