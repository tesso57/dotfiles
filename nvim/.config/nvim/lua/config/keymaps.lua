-- ============================================================
-- plugin なしのキーマップ
-- ============================================================

-- Leader キー（Space）
vim.g.mapleader = " "

-- 保存 / 終了
vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "保存" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<cr>",  { desc = "終了" })

-- 検索ハイライト消し
vim.keymap.set("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "検索ハイライト解除" })

-- Insert モードで "jj" を押すと Esc（ノーマルモードへ戻る）
vim.keymap.set("i", "jj", "<Esc>", { desc = "jjでEsc" })

-- 折り返し行があるとき、j/k を見た目の行で動かす
vim.keymap.set("n", "j", "gj", { desc = "表示行で下へ" })
vim.keymap.set("n", "k", "gk", { desc = "表示行で上へ" })

-- ウィンドウ移動
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "左のウィンドウへ" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "下のウィンドウへ" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "上のウィンドウへ" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "右のウィンドウへ" })

-- ============================================================
-- 画面分割（split）
-- ============================================================

-- 水平分割 / 垂直分割
vim.keymap.set("n", "<leader>sh", "<cmd>split<cr>",  { desc = "水平分割" })
vim.keymap.set("n", "<leader>sv", "<cmd>vsplit<cr>", { desc = "垂直分割" })

-- 今の分割を閉じる
vim.keymap.set("n", "<leader>sc", "<cmd>close<cr>",  { desc = "この分割を閉じる" })

-- 分割を均等化
vim.keymap.set("n", "<leader>s=", "<C-w>=", { desc = "分割サイズを均等化" })

-- 分割サイズ調整（2ずつ）
vim.keymap.set("n", "<Up>",    "<cmd>resize +2<cr>",          { desc = "高さ+2" })
vim.keymap.set("n", "<Down>",  "<cmd>resize -2<cr>",          { desc = "高さ-2" })
vim.keymap.set("n", "<Left>",  "<cmd>vertical resize -2<cr>", { desc = "幅-2" })
vim.keymap.set("n", "<Right>", "<cmd>vertical resize +2<cr>", { desc = "幅+2" })
