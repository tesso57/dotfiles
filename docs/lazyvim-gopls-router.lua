-- LazyVim example: put this in ~/.config/nvim/lua/plugins/gopls-router.lua.
--
-- It expects config.gopls_router to exist at:
--   ~/.config/nvim/lua/config/gopls_router.lua
--
-- gopls-router itself is managed by Mason. The private gopls-router repository
-- provides the Mason Lua registry used below.

local gopls_router_registry = {
  name = "gopls-router-mason-registry",
  url = vim.env.GOPLS_ROUTER_REPO_URL or "git@github.com:tesso57/gopls-router.git",
  lazy = true,
}

return {
  {
    "mason-org/mason.nvim",
    dependencies = { gopls_router_registry },
    opts = function(_, opts)
      opts.registries = opts.registries or { "github:mason-org/mason-registry" }
      for _, registry in ipairs(opts.registries) do
        if registry == "lua:gopls_router_mason_registry.index" then
          return
        end
      end
      table.insert(opts.registries, 1, "lua:gopls_router_mason_registry.index")
    end,
  },

  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      for _, tool in ipairs(opts.ensure_installed) do
        if tool == "gopls-router" or (type(tool) == "table" and tool[1] == "gopls-router") then
          return
        end
      end
      table.insert(opts.ensure_installed, {
        "gopls-router",
        condition = function()
          return vim.fn.executable("git") == 1 and (vim.fn.executable("go") == 1 or vim.fn.executable("mise") == 1)
        end,
      })
    end,
  },

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
