return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim", -- 必須（描画/UI）
      {
        "rcarriga/nvim-notify", -- 任意（通知ビューに使う。無いと mini がfallback）
        opts = {
          -- 環境によっては NotifyBackground が無くて警告が出ることがあるので保険
          background_colour = "#000000",
        },
      },
    },
    opts = {
      -- LSPのmarkdown表示をNoice側で良い感じにする（推奨例）
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true, -- nvim-cmp を入れたら有効化（README例）
        },
      },

      -- cmdline を popup 表示にする（Noice のデフォルトも cmdline_popup）
      cmdline = {
        view = "cmdline_popup",
      },

      -- “入れるだけで嬉しい” preset（READMEの suggested setup に近い）
      presets = {
        bottom_search = true,         -- 検索は下に出す（クラシック）
        command_palette = true,       -- cmdline と popupmenu をまとめて表示
        long_message_to_split = true, -- 長いメッセージは split に送る
        inc_rename = false,
        lsp_doc_border = false,
      },
    },
  },
}

