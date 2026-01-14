-- ~/.config/nvim/lua/plugin/todo-comments.lua
return {
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" }, -- 検索に使う
    event = "VeryLazy",
    opts = {
      -- まずはデフォルトでOK
      -- signs = true,
      -- keywords = { ... },
      -- highlight = { ... },
      -- search = { command = "rg", ... },
    },
    keys = {
      -- 次/前の TODO コメントへジャンプ
      { "]t", function() require("todo-comments").jump_next() end, desc = "次のTODOコメントへ" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "前のTODOコメントへ" },

      -- よく使う一覧系（READMEの Usage にあるコマンド）
      { "<leader>tq", "<cmd>TodoQuickFix<cr>", desc = "TODO一覧（Quickfix）" },
      { "<leader>tl", "<cmd>TodoLocList<cr>",  desc = "TODO一覧（Location List）" },
    },
  },
}

