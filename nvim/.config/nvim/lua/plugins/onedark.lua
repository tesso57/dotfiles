return {
  {
    "navarasu/onedark.nvim",
    priority = 1000, -- 他のプラグインより先に読みたい（色関連の崩れ防止）
    config = function()
      require("onedark").setup({
        style = "warmer",
      })
      require("onedark").load()
    end,
  },
}
