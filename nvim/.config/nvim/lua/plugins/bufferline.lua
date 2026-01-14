return {
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons", -- アイコン用（推奨）
    event = "VeryLazy",
    opts = {
      options = {
        -- LSPの診断をバッファタブに出したいならON（好み）
        diagnostics = "nvim_lsp",
      },
    },
    keys = {
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "次のバッファ" },
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "前のバッファ" },

      { "<leader>bc", "<cmd>bd<cr>", desc = "バッファを閉じる" },
      { "<leader>bp", "<cmd>BufferLinePick<cr>", desc = "バッファを選んで移動（Pick）" },
      { "<leader>bP", "<cmd>BufferLinePickClose<cr>", desc = "バッファを選んで閉じる（PickClose）" },
    },
  },
}

