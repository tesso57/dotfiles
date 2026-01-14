return {
  {
    "mvllow/modes.nvim",
    tag = "v0.3.0",
    config = function()
      require("modes").setup({
        -- まずはデフォルトでOK。必要ならここで調整できます
        -- line_opacity = 0.15,
        -- set_cursor = true,
        -- set_cursorline = true,
        -- set_number = true,
        -- set_signcolumn = true,
        -- ignore = { "NvimTree", "TelescopePrompt", "!minifiles" },
      })

      -- もし起動時に "Press ENTER" が出る場合は、README の回避策として
      -- modes.setup() の「後」で cmdheight を 0 にします
      -- vim.o.cmdheight = 0
    end,
  },
}

