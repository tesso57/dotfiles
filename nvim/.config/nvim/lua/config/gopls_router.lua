local M = {}

function M.bin()
  local router = vim.env.GOPLS_ROUTER_BIN or vim.fn.exepath("gopls-router")
  if router == "" then
    router = vim.fn.expand("~/.local/bin/gopls-router")
  end
  return router
end

function M.find_root(name)
  local root = vim.fs.root(name, ".git")
    or vim.fs.root(name, "go.work")
    or vim.fs.root(name, "go.mod")
    or vim.fn.getcwd()
  return root
end

function M.root_dir(bufnr_or_name, on_dir)
  if type(on_dir) == "function" then
    on_dir(M.find_root(vim.api.nvim_buf_get_name(bufnr_or_name)))
    return
  end
  return M.find_root(bufnr_or_name)
end

function M.cmd_env()
  return {
    GOMEMLIMIT = "8GiB",
    GOPLS_ROUTER_PROXY = "1",
    GOPLS_ROUTER_SCOPE = "lazy-directories",
    GOPLS_ROUTER_SCOPE_GRANULARITY = "3",
    GOPLS_ROUTER_SCOPE_DEBOUNCE = "500ms",
    GOPLS_ROUTER_SCOPE_EVICT = "10m",
    GOPLS_ROUTER_SCOPE_IMPORTERS = "true",
    GOPLS_ROUTER_SCOPE_IMPORTER_WAIT = "5s",
    GOPLS_ROUTER_SCOPE_RELOAD_WAIT = "0",
    GOPLS_ROUTER_LOG = vim.fn.stdpath("state") .. "/gopls-router/router.log",
  }
end

function M.settings()
  return {
    gopls = {
      gofumpt = true,
      analyses = { unusedparams = true },
      directoryFilters = { "-**/node_modules", "-**/vendor", "-**/dist", "-**/.git" },
    },
  }
end

function M.server()
  return {
    cmd = { M.bin() },
    cmd_env = M.cmd_env(),
    root_dir = M.root_dir,
    settings = M.settings(),
  }
end

return M
