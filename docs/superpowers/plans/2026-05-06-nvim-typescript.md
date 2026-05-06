# Neovim TypeScript / JavaScript / React Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 既存の Neovim 設定 (`nvim/.config/nvim/`) に TypeScript / JavaScript / React (TSX/JSX) のサポートを追加する。

**Architecture:** vtsls を TS/JS 用 LSP、biome を lint 用 LSP + フォーマッタ(conform 経由)、nvim-ts-autotag で JSX 自動タグ閉じ。既存の Mason + lspconfig + conform + nvim-cmp スタックに統合する。

**Tech Stack:** Neovim, lazy.nvim, mason.nvim, nvim-lspconfig, nvim-treesitter (master branch), conform.nvim, nvim-ts-autotag, vtsls, biome.

**Spec:** [docs/superpowers/specs/2026-05-06-nvim-typescript-design.md](../specs/2026-05-06-nvim-typescript-design.md)

---

## ファイル構造

| ファイル | 役割 | 操作 |
|---|---|---|
| `nvim/.config/nvim/lua/plugins/lsp.lua` | LSP 設定一式 | 修正 |
| `nvim/.config/nvim/lua/plugins/conform.lua` | フォーマッタ登録 | 修正 |
| `nvim/.config/nvim/lua/plugins/treesitter.lua` | parser 一覧 + highlight 有効化 | 修正(ほぼ書き換え) |
| `nvim/.config/nvim/lua/plugins/ts-autotag.lua` | JSX 自動タグ閉じ | 新規作成 |

各タスクの後にコミットを置き、何かおかしくなったら `git revert` 1発で戻せるようにする。

**重要な前提**: 現在の `treesitter.lua` は `require("nvim-treesitter").setup({})` を呼んでいるが、このメソッドはコマンド登録のみで設定オプションは受け取らない(master branch の API)。本来の設定エントリポイントは `require("nvim-treesitter.configs").setup({...})`。Task 3 でこれを正しい呼び出しに置き換える。

---

## Task 1: vtsls + biome の LSP 設定を追加

**Files:**
- Modify: `nvim/.config/nvim/lua/plugins/lsp.lua`

このタスクの目的は LSP サーバの登録とアタッチ、TS 系 filetype での `BufWritePre` ハンドラ(organize imports)、inlay hint トグルキー追加。

- [ ] **Step 1: `lsp.lua` の現状をもう一度確認**

```bash
cat nvim/.config/nvim/lua/plugins/lsp.lua
```

確認ポイント:
- `mason-lspconfig` の `ensure_installed` に `gopls`, `lua_ls`, `marksman` がある
- `automatic_enable = false` なので明示的に `vim.lsp.enable(...)` が必要
- LspAttach コールバックで filetype 別に BufWritePre を分岐している(go と proto の前例)

- [ ] **Step 2: `mason-lspconfig.nvim` の `ensure_installed` に vtsls と biome を追加**

`nvim/.config/nvim/lua/plugins/lsp.lua` の現状の `ensure_installed`:

```lua
ensure_installed = { "gopls", "lua_ls", "marksman" },
```

これを以下に変更:

```lua
ensure_installed = { "gopls", "lua_ls", "marksman", "vtsls", "biome" },
```

- [ ] **Step 3: vtsls の `vim.lsp.config` を追加**

`vim.lsp.enable("lua_ls")` の後、Proto セクションの直前に以下を挿入する:

```lua
      -- =========================
      -- TypeScript / JavaScript: vtsls
      -- =========================
      vim.lsp.config("vtsls", {
        settings = {
          typescript = {
            inlayHints = {
              parameterNames = { enabled = "literals" },
              parameterTypes = { enabled = true },
              variableTypes = { enabled = false },
              propertyDeclarationTypes = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              enumMemberValues = { enabled = true },
            },
          },
          javascript = {
            inlayHints = {
              parameterNames = { enabled = "literals" },
              parameterTypes = { enabled = true },
              variableTypes = { enabled = false },
              propertyDeclarationTypes = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              enumMemberValues = { enabled = true },
            },
          },
          vtsls = {
            -- format は conform→biome に一本化するため LSP 側を無効化
            autoUseWorkspaceTsdk = true,
          },
        },
        on_init = function(client)
          -- formatProvider を無効化(conform に任せる)
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end,
      })
      vim.lsp.enable("vtsls")
```

- [ ] **Step 4: biome の `vim.lsp.config` を追加**

vtsls ブロックの直後に以下を挿入:

```lua
      -- =========================
      -- Biome (JS/TS lint via LSP)
      -- =========================
      -- Format は conform から呼ぶので、LSP 側 format は無効化しておく
      vim.lsp.config("biome", {
        on_init = function(client)
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end,
      })
      vim.lsp.enable("biome")
```

- [ ] **Step 5: TS 系 filetype 用の BufWritePre ハンドラを LspAttach に追加**

既存の Go / Proto の `if ft == ... then` ブロックの後、LspAttach コールバックの末尾に以下を追加:

```lua
          -- TS/JS/JSX/TSX: vtsls の organizeImports を保存時に実行
          local ts_fts = { typescript = true, typescriptreact = true, javascript = true, javascriptreact = true }
          if ts_fts[ft] and client and client.name == "vtsls" then
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = format_group,
              buffer = bufnr,
              callback = function()
                pcall(vim.lsp.buf.code_action, {
                  context = { only = { "source.organizeImports" } },
                  apply = true,
                })
              end,
            })

            -- inlay hint を有効化
            if vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable then
              pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })
            end

            -- <leader>ih: inlay hint トグル
            vim.keymap.set("n", "<leader>ih", function()
              if not (vim.lsp.inlay_hint and vim.lsp.inlay_hint.is_enabled) then
                return
              end
              local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
              vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
            end, { buffer = bufnr, desc = "Toggle inlay hints" })
          end
```

(注: `format` は conform.nvim 側の `format_on_save` が後段で走るので、ここでは format を呼ばなくてよい。Go や Proto では LSP format を直接呼んでいるが、TS は conform 経由で biome を呼ぶ。)

- [ ] **Step 6: 構文チェック(luac で軽くチェック)**

```bash
luac -p nvim/.config/nvim/lua/plugins/lsp.lua && echo OK
```

Expected: `OK`(構文エラーなし)

luac が無い環境なら `nvim --headless -c 'luafile nvim/.config/nvim/lua/plugins/lsp.lua' -c 'qa'` で代替。

- [ ] **Step 7: コミット**

```bash
git add nvim/.config/nvim/lua/plugins/lsp.lua
git commit -m "$(cat <<'EOF'
feat(nvim): add vtsls + biome LSP for TypeScript/React

Why: extend nvim setup beyond Go/Lua/Proto/Markdown to cover
Node.js + React (.ts/.tsx/.js/.jsx). vtsls handles type info and
auto-import; biome handles lint diagnostics. Format is delegated to
conform (Task 2) to avoid duplication.

How to apply: open a TS file - LSP attaches and BufWritePre runs
source.organizeImports via vtsls; inlay hints toggle via <leader>ih.
EOF
)"
```

---

## Task 2: conform.nvim に biome を登録

**Files:**
- Modify: `nvim/.config/nvim/lua/plugins/conform.lua`

- [ ] **Step 1: 現状確認**

```bash
cat nvim/.config/nvim/lua/plugins/conform.lua
```

`formatters_by_ft` には `go = { "goimports" }` と `proto = { "buf", "clang-format", stop_after_first = true }` のみ。

- [ ] **Step 2: `formatters_by_ft` に biome を追加**

`nvim/.config/nvim/lua/plugins/conform.lua` の `formatters_by_ft` を以下に置き換える:

```lua
      formatters_by_ft = {
        go = { "goimports" },

        proto = { "buf", "clang-format", stop_after_first = true },

        javascript     = { "biome" },
        javascriptreact = { "biome" },
        typescript     = { "biome" },
        typescriptreact = { "biome" },
        json  = { "biome" },
        jsonc = { "biome" },
      },
```

- [ ] **Step 3: 構文チェック**

```bash
luac -p nvim/.config/nvim/lua/plugins/conform.lua && echo OK
```

Expected: `OK`

- [ ] **Step 4: コミット**

```bash
git add nvim/.config/nvim/lua/plugins/conform.lua
git commit -m "$(cat <<'EOF'
feat(nvim): register biome formatter for js/ts/jsx/tsx/json

Why: keep format-on-save consistent across languages - biome handles
JS/TS family while conform's lsp_format=fallback prevents duplicate
runs from the LSPs.
EOF
)"
```

---

## Task 3: nvim-treesitter で TS/TSX 系 parser を ensure

**Files:**
- Modify: `nvim/.config/nvim/lua/plugins/treesitter.lua`

このタスクは現状の no-op 設定 (`require("nvim-treesitter").setup({})`) を、master branch の正規エントリポイント (`require("nvim-treesitter.configs").setup({...})`) に置き換える。

- [ ] **Step 1: 現状確認**

```bash
cat nvim/.config/nvim/lua/plugins/treesitter.lua
cat nvim/.config/nvim/lazy-lock.json | grep -A2 nvim-treesitter
```

- `branch: "master"` であることを確認(nvim-treesitter の master API を使う)
- 既存の `setup({})` 呼び出しは設定として効いていない(`nvim-treesitter.lua` の M.setup はコマンド登録のみ)ことを認識する

- [ ] **Step 2: `treesitter.lua` を以下に置き換える**

`nvim/.config/nvim/lua/plugins/treesitter.lua` 全体:

```lua
return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,        -- nvim-treesitter は lazy-loading 非対応
    build = ":TSUpdate", -- プラグイン更新時にパーサも更新
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          -- 既存環境で使っている言語
          "go",
          "lua",
          "luadoc",
          "proto",
          "markdown",
          "markdown_inline",
          "vim",
          "vimdoc",
          "query",
          "bash",
          -- TS/JS/React 追加分
          "typescript",
          "tsx",
          "javascript",
          "jsdoc",
          "html",
          "css",
          "json",
          "jsonc",
        },
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
      })
    end,
  },
}
```

ポイント:
- `auto_install = true` で未インストールの parser があれば自動インストール
- `highlight.enable = true` を明示(nvim-treesitter master では default off)
- 既存の go/lua/proto/markdown 等も載せる(再インストールにはならない)

- [ ] **Step 3: 構文チェック**

```bash
luac -p nvim/.config/nvim/lua/plugins/treesitter.lua && echo OK
```

Expected: `OK`

- [ ] **Step 4: コミット**

```bash
git add nvim/.config/nvim/lua/plugins/treesitter.lua
git commit -m "$(cat <<'EOF'
feat(nvim): properly configure treesitter parsers + highlight

Why: existing setup({}) on master branch was a no-op (commands only).
Switching to nvim-treesitter.configs.setup({...}) actually applies
ensure_installed, highlight.enable, indent.enable - and adds tsx/jsx
parsers needed for React.
EOF
)"
```

---

## Task 4: nvim-ts-autotag を追加

**Files:**
- Create: `nvim/.config/nvim/lua/plugins/ts-autotag.lua`

- [ ] **Step 1: 新規ファイル作成**

`nvim/.config/nvim/lua/plugins/ts-autotag.lua`:

```lua
return {
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
      },
    },
  },
}
```

- [ ] **Step 2: 構文チェック**

```bash
luac -p nvim/.config/nvim/lua/plugins/ts-autotag.lua && echo OK
```

Expected: `OK`

- [ ] **Step 3: コミット**

```bash
git add nvim/.config/nvim/lua/plugins/ts-autotag.lua
git commit -m "$(cat <<'EOF'
feat(nvim): add nvim-ts-autotag for JSX/TSX tag completion

Why: typing <div> in TSX should auto-insert </div>. Triggered on
buffer read/new so it's available before first JSX edit.
EOF
)"
```

---

## Task 5: 動作検証 (手動)

**Files:** 実コードはなし。動作確認のみ。

このタスクは書いた設定が実機で動くかの確認。

- [ ] **Step 1: Neovim を起動して Mason / Lazy 同期**

```bash
# 一旦 Neovim を起動
nvim
```

Neovim 内で:

```vim
:Lazy sync
:MasonInstall vtsls biome
```

(`mason-lspconfig` の `ensure_installed` に追加した `vtsls` / `biome` は Lazy sync 後に自動インストールされる想定だが、念のため `:MasonInstall` も流す)

確認:
```vim
:Mason
```
で `vtsls` と `biome` が `installed` になっていること。

- [ ] **Step 2: TS parser インストール確認**

```vim
:TSInstallInfo
```

`typescript`, `tsx`, `javascript`, `jsdoc`, `html`, `css`, `json`, `jsonc` が `installed` になっていること。
されていなければ `:TSInstall typescript tsx javascript jsdoc html css json jsonc`。

- [ ] **Step 3: 検証用ファイルを作成**

worktree 内の使い捨てパスに置く(コミット対象外):

```bash
mkdir -p /tmp/nvim-ts-test && cd /tmp/nvim-ts-test
cat > sample.tsx <<'EOF'
import { useState } from "react"
import { unused } from "fs"

export function App() {
  const [count, setCount] = useState(0)
  return <div onClick={() => setCount(count + 1)}>{count}</div>
}
EOF
nvim sample.tsx
```

- [ ] **Step 4: LSP 起動確認**

Neovim 内で:

```vim
:LspInfo
```

`vtsls` と `biome` の両方が attached になっていることを確認。

- [ ] **Step 5: 補完 / hover の確認**

- `useState` の上で `K` を押して hover が出るか
- 適当に `useS` まで打って `<C-n>` または `<C-Space>` で補完候補が出るか
- `gd` で `useState` の定義へジャンプできるか(react の型定義に飛ぶ)

- [ ] **Step 6: 自動タグ閉じ確認**

新しい行で `<span>` と打つと `</span>` が自動挿入されることを確認。

- [ ] **Step 7: organize imports + format on save の確認**

`unused` が未使用なので、`:w` で保存したとき:
1. 未使用 import が消える(vtsls の organizeImports)
2. インデント / 改行が biome により整形される

その後 `:e!` で再読み込みしてバッファ内容を確認、または `git diff` で変化を見る。

- [ ] **Step 8: 診断確認**

`return <div>{count}</div>` 行を `return <div>{count}` のように壊して保存しないまま表示を見る:
- vtsls から構文 / 型エラーが出る
- biome から lint 警告が出る

`:Trouble diagnostics` でも同じ内容が見えること(既存の trouble.nvim 連携)。

- [ ] **Step 9: inlay hint トグル確認**

- 関数引数や戻り値に inlay hint が表示されている
- `<leader>ih` で表示/非表示が切り替わる

- [ ] **Step 10: 既存 Go ファイルの非破壊確認**

```bash
# dotfiles の中の任意の .go ファイルを開く(無ければ /tmp に作る)
nvim ~/Documents/repos/<any go file>.go
```

`:LspInfo` で gopls が attached、`gd` で動く、保存時に goimports + format が走ることを確認。

- [ ] **Step 11: `:checkhealth` で全体エラーがないこと**

```vim
:checkhealth lsp
:checkhealth nvim-treesitter
:checkhealth mason
```

`ERROR` が新規に出ていないこと(既存の WARN は無視可)。

---

## Task 6: 仕上げ

- [ ] **Step 1: 検証用一時ファイルを削除**

```bash
rm -rf /tmp/nvim-ts-test
```

- [ ] **Step 2: lazy-lock.json の更新分(あれば)を取り込み**

```bash
git status
```

`lazy-lock.json` に nvim-ts-autotag のエントリが増えていれば:

```bash
git add nvim/.config/nvim/lazy-lock.json
git commit -m "chore(nvim): update lazy-lock.json for nvim-ts-autotag"
```

- [ ] **Step 3: ブランチ全体の差分を確認**

```bash
git log --oneline main..HEAD
git diff main...HEAD --stat
```

期待:
- 4〜5 コミット(Task 1〜4 + 場合により lazy-lock)
- 修正ファイル: `lsp.lua`, `conform.lua`, `treesitter.lua`, `ts-autotag.lua`(新規), `lazy-lock.json`(自動更新), `docs/superpowers/specs/...`(既存), `docs/superpowers/plans/...`(本文書)

- [ ] **Step 4: 完了報告**

PR 作成や merge は別タスク(`finishing-a-development-branch` skill)で扱う。本プランはここまで。

---

## Self-review summary

**Spec coverage:**
- §2 ツール構成 → Task 1 (vtsls/biome), Task 2 (biome via conform), Task 3 (treesitter parsers), Task 4 (ts-autotag) ✓
- §3.1 既存ファイル更新 → Task 1/2/3 ✓
- §3.2 新規ファイル → Task 4 ✓
- §4 データフロー → Task 1 step 5 (organizeImports), Task 2 (format) ✓
- §5 重複・競合の扱い → Task 1 step 3/4 (formatProvider 無効化) ✓
- §6 キーマップ → Task 1 step 5 (`<leader>ih`) ✓
- §7 既知の判断 → 設計書側で完結、プランに重複なし ✓
- §8 テスト戦略 → Task 5 ✓
- §9 実装順序 → Task 1〜4 が同順序 ✓

**Placeholder scan:** TBD/TODO なし。すべてのコードブロックは具体値。

**Type / 命名整合性:** `format_group` (Task 1 既存)、`ts_fts` (Task 1 step 5 で定義)、`bufnr` (LspAttach 引数で取得)。再利用変数は元の lsp.lua のものに揃えている。
