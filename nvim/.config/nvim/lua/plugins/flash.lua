return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash: ジャンプ" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash: Treesitter ジャンプ" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Flash: リモート操作" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Flash: Treesitter 検索" },
      { "<C-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Flash: 検索トグル" },
    },
  },
}

