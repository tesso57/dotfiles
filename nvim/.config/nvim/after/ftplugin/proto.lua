-- ============================================================
-- Treesitter highlighting
-- ============================================================
vim.treesitter.start()

-- ============================================================
-- Buf lint
-- ============================================================
-- Buf lint を :make で叩けるようにする（Quickfixに入る）
-- Trouble を入れているなら qflist を Trouble で開けます
vim.opt_local.makeprg = "buf\\ lint"
vim.opt_local.errorformat = "%f:%l:%c:%m"

