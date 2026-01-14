-- repo root を取る
local function git_root()
  local out = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })
  if vim.v.shell_error ~= 0 then return nil end
  local root = out[1]
  if not root or root == "" then return nil end
  return vim.fs.normalize(root)
end

-- カレントバッファの「repo ルート相対パス」を返す
local function current_repo_relative_path()
  local root = git_root()
  if not root then
    vim.notify("Gitリポジトリ内ではありません（git root を取得できません）", vim.log.levels.WARN)
    return nil
  end

  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)

  if not name or name == "" then
    vim.notify("このバッファはファイルではありません（名前がありません）", vim.log.levels.WARN)
    return nil
  end

  local rel = vim.fs.relpath(root, vim.fs.normalize(name))
  if not rel or rel == "" or rel:match("^%.%.") then
    vim.notify("このファイルはリポジトリ外です（repo 相対パスにできません）", vim.log.levels.WARN)
    return nil
  end

  return rel
end

-- コピー本体（@あり/なしを切り替え）
local function copy_current_file_repo_relative(prefix_at)
  local rel = current_repo_relative_path()
  if not rel then return end

  local text = (prefix_at and ("@" .. rel) or rel)
  vim.fn.setreg("+", text)
  vim.notify(("コピーしました: %s"):format(text), vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("RepoCopyPathAt", function()
  copy_current_file_repo_relative(true)
end, {
  desc = "Copy current file as @repo-relative path (for Claude Code/Codex)",
})

vim.api.nvim_create_user_command("RepoCopyPath", function()
  copy_current_file_repo_relative(false)
end, {
  desc = "Copy current file as repo-relative path",
})

vim.keymap.set("n", "<F3>", "<cmd>RepoCopyPathAt<cr>", {
  desc = "Copy @repo-relative path",
})
-- vim.keymap.set("n", "<F4>", "<cmd>RepoCopyPath<cr>", {
--   desc = "Copy repo-relative path",
-- })
