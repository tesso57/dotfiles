return {
  {
    "WilliamHsieh/overlook.nvim",
    opts = {},
    keys = {
      { "<leader>pd", function() require("overlook.api").peek_definition() end, desc = "Overlook: 定義をポップアップで覗く" },
      { "<leader>pp", function() require("overlook.api").peek_cursor() end, desc = "Overlook: カーソル位置をポップアップで覗く" },
      { "<leader>pu", function() require("overlook.api").restore_popup() end, desc = "Overlook: 最後のポップアップを復元" },
      { "<leader>pU", function() require("overlook.api").restore_all_popups() end, desc = "Overlook: 全ポップアップを復元" },
      { "<leader>pc", function() require("overlook.api").close_all() end, desc = "Overlook: 全ポップアップを閉じる" },
      { "<leader>pf", function() require("overlook.api").switch_focus() end, desc = "Overlook: フォーカス切替" },
      { "<leader>ps", function() require("overlook.api").open_in_split() end, desc = "Overlook: split で開く" },
      { "<leader>pv", function() require("overlook.api").open_in_vsplit() end, desc = "Overlook: vsplit で開く" },
    },
  },
}

