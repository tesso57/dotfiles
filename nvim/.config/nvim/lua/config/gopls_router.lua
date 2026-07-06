local M = {}
local cached_goroot = false

function M.bin()
  if vim.env.GOPLS_ROUTER_BIN and vim.env.GOPLS_ROUTER_BIN ~= "" then
    return vim.env.GOPLS_ROUTER_BIN
  end

  local mason_router = vim.fn.stdpath("data") .. "/mason/bin/gopls-router"
  if vim.fn.executable(mason_router) == 1 then
    return mason_router
  end

  local router = vim.fn.exepath("gopls-router")
  if router ~= "" then
    return router
  end

  router = vim.fn.expand("~/.local/bin/gopls-router")
  return router
end

function M.goroot()
  if cached_goroot ~= false then
    return cached_goroot
  end

  local goroot = vim.env.GOROOT
  if not goroot or goroot == "" then
    local go = vim.fn.exepath("go")
    if go ~= "" then
      local out = vim.fn.system({ go, "env", "GOROOT" })
      if vim.v.shell_error == 0 then
        goroot = vim.trim(out)
      end
    end
  end

  if goroot and goroot ~= "" then
    cached_goroot = vim.fs.normalize(vim.fn.expand(goroot))
  else
    cached_goroot = nil
  end

  return cached_goroot
end

function M.is_under(parent, name)
  if not parent or parent == "" or not name or name == "" then
    return false
  end

  parent = vim.fs.normalize(vim.fn.expand(parent))
  name = vim.fs.normalize(vim.fn.expand(name))
  return name == parent or vim.startswith(name, parent .. "/")
end

function M.is_go_toolchain_file(name)
  local goroot = M.goroot()
  return goroot ~= nil and M.is_under(goroot .. "/src", name)
end

function M.find_root(name)
  if M.is_go_toolchain_file(name) then
    return nil
  end

  local root = vim.fs.root(name, ".git")
    or vim.fs.root(name, "go.work")
    or vim.fs.root(name, "go.mod")
    or vim.fn.getcwd()
  return root
end

function M.root_dir(bufnr_or_name, on_dir)
  local name = bufnr_or_name
  if type(on_dir) == "function" then
    name = vim.api.nvim_buf_get_name(bufnr_or_name)
  end

  local root = M.find_root(name)
  if not root then
    return nil
  end

  if type(on_dir) == "function" then
    on_dir(root)
    return
  end
  return root
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
