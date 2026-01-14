return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,          -- ※重要: nvim-treesitter は lazy-loading 非対応
    build = ":TSUpdate",   -- プラグイン更新時にパーサを更新するのが推奨
    config = function()
      -- デフォルトで動く（設定必須ではない）
      -- 必要なら install_dir を指定できる
      require("nvim-treesitter").setup({
        -- install_dir = vim.fn.stdpath("data") .. "/site",
      })
    end,
  },
}

