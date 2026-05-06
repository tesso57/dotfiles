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
