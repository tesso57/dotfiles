return {
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- 任意（ファイルアイコン）
    },
    opts = {}, -- まずはデフォルトでOK
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "診断一覧（Trouble）" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "バッファ診断（Trouble）" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix（Trouble）" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List（Trouble）" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "シンボル（Trouble）" },
    },
  },
}

