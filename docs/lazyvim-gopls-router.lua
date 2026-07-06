-- LazyVim example: put this in ~/.config/nvim/lua/plugins/gopls-router.lua.
--
-- It expects config.gopls_router to exist in:
--   ~/.config/nvim/lua/config/gopls_router.lua
--
-- Install/update the private router binary with:
--   install-gopls-router

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.gopls = vim.tbl_deep_extend(
        "force",
        opts.servers.gopls or {},
        require("config.gopls_router").server()
      )
    end,
  },
}
