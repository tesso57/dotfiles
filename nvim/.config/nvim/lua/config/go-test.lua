-- repo root を取る
local function git_root()
  local out = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })
  if vim.v.shell_error ~= 0 then return nil end
  local root = out[1]
  if not root or root == "" then return nil end
  return vim.fs.normalize(root)
end

-- カレントバッファの「絶対パス」を返す（ファイルでなければ nil）
local function current_file_abs_path()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  if not name or name == "" then
    vim.notify("このバッファはファイルではありません（名前がありません）", vim.log.levels.WARN)
    return nil
  end
  return vim.fs.normalize(name)
end

-- カレントバッファの「ディレクトリ」を返す（絶対パス）
local function current_file_dir_abs()
  local file = current_file_abs_path()
  if not file then return nil end
  return vim.fs.dirname(file)
end

-- カレントファイルのディレクトリを「git root から」相対にして返す
-- 例: root=~/test, file=~/test/hoge/fuga.go -> hoge
local function current_dir_rel_from_repo_root()
  local root = git_root()
  if not root then
    vim.notify("Gitリポジトリ内ではありません（git root を取得できません）", vim.log.levels.WARN)
    return nil
  end

  local dir_abs = current_file_dir_abs()
  if not dir_abs then return nil end

  local rel = vim.fs.relpath(root, dir_abs)
  if not rel or rel == "" then
    -- dir_abs == root のケース（root直下）はOK
    rel = "."
  end

  if rel:match("^%.%.") then
    vim.notify("このファイルはリポジトリ外です（repo 配下のディレクトリではありません）", vim.log.levels.WARN)
    return nil
  end

  return rel
end

-- go test コマンドを生成してコピー
local function copy_go_test_cmd_for_current_dir()
  local rel_dir = current_dir_rel_from_repo_root()
  if not rel_dir then return end

  -- root直下なら "."、それ以外は "./<rel>"
  local pkg = (rel_dir == ".") and "." or ("./" .. rel_dir)

  local cmd = ("go test %s -run '^Test' -cover -v"):format(pkg)
  vim.fn.setreg("+", cmd)
  vim.notify(("コピーしました: %s"):format(cmd), vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("RepoGoTestCmdCopy", function()
  copy_go_test_cmd_for_current_dir()
end, {
  desc = "Copy go test command for current file directory (relative to repo root)",
})

-- 好きならキーマップも（例: F4）
vim.keymap.set("n", "<F4>", "<cmd>RepoGoTestCmdCopy<cr>", {
  desc = "Copy go test command for current dir",
})
