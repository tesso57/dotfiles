-- ============================================================
-- インデント / タブ
-- ============================================================
vim.opt_local.expandtab = false
vim.opt_local.tabstop = 8
vim.opt_local.shiftwidth = 0   -- 0 にすると tabstop に追従（好みで 8 でもOK）
vim.opt_local.softtabstop = 0

-- ============================================================
-- Treesitter highlighting
-- ============================================================
vim.treesitter.start()

