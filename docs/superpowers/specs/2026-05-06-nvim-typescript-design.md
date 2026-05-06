# Neovim TypeScript / JavaScript / React 対応 設計書

- Date: 2026-05-06
- Scope: `nvim/.config/nvim/` 配下の Neovim 設定に TS/JS/React のサポートを追加
- 既存方針(plugin-per-file、Mason + lspconfig + conform + nvim-cmp)に揃える

## 1. 目的

Go / Lua / Proto / Markdown のみだった Neovim 設定に、Node.js + React (TSX/JSX) の編集サポートを追加する。

成功条件:

- `.ts` / `.tsx` / `.js` / `.jsx` / `.json` / `.jsonc` を開いたときに LSP 補完・診断・hover が動く
- 保存時に import 整理 → Biome フォーマットが自動で走る
- JSX で開きタグを書いたら閉じタグが自動で挿入される
- 既存の Go ワークフローに副作用がない

## 2. ツール構成

| 役割 | ツール | 入手 | 備考 |
|---|---|---|---|
| TS/JS LSP | `vtsls` | Mason | `typescript-language-server` 上位互換、補完が速い |
| Lint 診断 + 一部補助 | `biome` (LSP) | Mason | `biome lsp-proxy` を起動 |
| Formatter | `biome` | Mason (conform 経由で呼び出し) | `js/ts/jsx/tsx/json/jsonc` |
| Tree-sitter parser | `typescript`, `tsx`, `javascript`, `jsdoc`, `html`, `css`, `json` | nvim-treesitter | 既存の `nvim-treesitter` をそのまま利用 |
| JSX 自動タグ閉じ | `nvim-ts-autotag` | lazy.nvim | 新規プラグイン |

## 3. 変更対象ファイル

### 3.1 既存ファイル更新

1. `nvim/.config/nvim/lua/plugins/lsp.lua`
   - `mason-lspconfig.nvim` の `ensure_installed` に `vtsls` と `biome` を追加
   - `vim.lsp.config("vtsls", {...})` を追加し `vim.lsp.enable("vtsls")`
   - `vim.lsp.config("biome", {...})` を追加し `vim.lsp.enable("biome")`
   - `LspAttach` の中で TS 系 filetype の時に `BufWritePre` で `source.organizeImports` を実行(Go と同じパターン)
   - vtsls 側では `formatProvider` を無効化(format は conform に一本化)
   - inlay hint を vtsls で有効化、`<leader>ih` トグルキーを追加

2. `nvim/.config/nvim/lua/plugins/conform.lua`
   - `formatters_by_ft` に以下を追加:
     - `javascript`, `javascriptreact`, `typescript`, `typescriptreact`, `json`, `jsonc` → `{ "biome" }`

3. `nvim/.config/nvim/lua/plugins/treesitter.lua`
   - 起動時に `typescript`, `tsx`, `javascript`, `jsdoc`, `html`, `css`, `json` parser を ensure
   - 実装時に `lazy-lock.json` の `nvim-treesitter` バージョンを確認し、新API (`require("nvim-treesitter").install({...})`) か旧API (`require("nvim-treesitter.configs").setup({ ensure_installed = {...} })`) かを判定して合わせる

### 3.2 新規ファイル

4. `nvim/.config/nvim/lua/plugins/ts-autotag.lua`(新規)
   - `windwp/nvim-ts-autotag` を `event = { "BufReadPre", "BufNewFile" }` で遅延ロード
   - `filetypes` 既定で TSX/JSX/HTML/Vue/Svelte をカバー

ftplugin は当面追加しない(インデント等は global の options に従う)。必要が出てから追加する。

## 4. データフロー

### 4.1 ファイルを開いたとき(*.tsx 想定)

1. `BufReadPre` で nvim-ts-autotag が ftplugin 登録(JSX タグ閉じ有効化)
2. ファイルタイプ判定で `typescriptreact`
3. lspconfig が `vtsls` と `biome` を起動 → どちらも attach
4. nvim-treesitter が tsx parser を使ってシンタックスハイライト
5. nvim-cmp が両 LSP の capability を集約して補完を提供

### 4.2 保存時

1. `LspAttach` で登録された `BufWritePre` が走る
2. vtsls 経由で `source.organizeImports` を `code_action(apply=true)` で実行(失敗しても止めない)
3. conform.nvim の `format_on_save` が biome を呼んで整形(`lsp_format = "fallback"` のため LSP は呼ばれない)
4. バッファに書き戻し

## 5. 重複・競合の扱い

- **diagnostics**: vtsls(TS の型エラー) + biome(lint) が併存する。重複しないので並列でよい。
- **formatting**: conform→biome に一本化。vtsls の `formatProvider` を `false` に、biome LSP の format は conform 側で `lsp_format = "fallback"` のため呼ばれない。
- **`organizeImports`**: vtsls 側の code action を使う(biome の organize-imports は構文ベースで限定的なため)。

## 6. キーマップ

| キー | 動作 | スコープ |
|---|---|---|
| `<leader>ih` | inlay hint トグル | TS/JS/JSX/TSX バッファ(LspAttach 内で `vim.bo.filetype` で ts 系 ft をガード) |

既存 LSP キーマップ(`gd`, `gr`, `K`, `<leader>rn`, `<leader>ca`, `<leader>f`)は LspAttach 共通で既に定義済みのため流用。

## 7. 既知の判断・制約

- `biome.json` はプロジェクト側に**なくてよい**(biome はデフォルトルールで動く)
- TypeScript 本体は vtsls がワークスペース依存(`node_modules/typescript`)を優先、なければ Mason に落ちる
- DAP / debugging は本スコープ外(将来別タスクで `nvim-dap` + `vscode-js-debug` を検討)
- Tailwind CSS / GraphQL / package.json 補完は本スコープ外(将来必要になれば追加)
- 大規模 monorepo での vtsls メモリ使用量増加には注意(必要時 `vtsls.tsserver.maxTsServerMemory` を引き上げる)

## 8. テスト戦略

設定変更は手動検証で確認する:

1. 新規 `.ts` ファイルを開いて補完・hover が動く
2. 新規 `.tsx` ファイルで `<div>` を入力 → `</div>` が自動挿入される
3. 未使用変数を残して保存 → biome の lint 警告(例: `noUnusedVariables`)が virtual text に出る
4. 不要な import を入れて保存 → vtsls の organizeImports で削除される
5. 整形されていないコードを保存 → biome がフォーマット
6. 既存の Go ファイルを開いて gopls が今まで通り動く
7. `:checkhealth lsp` および `:Mason` でエラーがない

## 9. 実装順序(後続の plan に渡す材料)

1. `lsp.lua` を更新(vtsls + biome、organizeImports、inlay hint)
2. `conform.lua` を更新(biome を formatters_by_ft に登録)
3. `treesitter.lua` を更新(TS 系 parser を install)
4. `ts-autotag.lua` を新規作成
5. Neovim を再起動して上記テスト戦略を実行
6. 動作確認後にコミット
