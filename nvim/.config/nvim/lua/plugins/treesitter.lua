return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",     -- v1.0+ の新アーキテクチャ。Neovim 0.11+/0.12 対応（master は 0.12 非対応）
    lazy = false,        -- nvim-treesitter は lazy-loading 非対応
    build = ":TSUpdate", -- プラグイン更新時にパーサも更新
    config = function()
      local parsers = {
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
      }

      -- jsonc parser installation can be brittle across tree-sitter parser
      -- changes. Keep JSONC usable without installing a separate parser.
      vim.treesitter.language.register("json", "jsonc")

      local ts = require("nvim-treesitter")
      if ts.install then
        -- main では ensure_installed ではなく install() でパーサを入れる（非同期）
        ts.install(parsers)
      else
        -- 従来 API が読み込まれた環境でも起動を止めない。
        require("nvim-treesitter.configs").setup({
          ensure_installed = parsers,
          sync_install = false,
          highlight = { enable = true },
          indent = { enable = true },
        })
      end

      -- main には classic の highlight/indent モジュールが無いため、
      -- FileType ごとに treesitter を自前で有効化する
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          -- パーサが使える FileType のときだけ highlight を開始
          if pcall(vim.treesitter.start, args.buf) then
            -- indent（main では experimental。崩れる場合はこの行を削除）
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
}
