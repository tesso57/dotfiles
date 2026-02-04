-- ============================================================
-- vim.opt (設定値) の設定
-- ============================================================

-- -----------------------------
-- 表示 / UI
-- -----------------------------
vim.opt.encoding = "utf-8"    -- 文字エンコーディング
vim.opt.termguicolors = true  -- TrueColor を有効（対応端末で色が綺麗に）
vim.opt.number = true         -- 行番号を表示
vim.opt.relativenumber = true -- 相対行番号（移動が楽。不要なら false）
vim.opt.cursorline = true     -- カーソル行をハイライト
vim.opt.signcolumn = "yes"    -- サイン列を常に表示（ガタつき防止）
vim.opt.wrap = false          -- 長い行を折り返さない（好みで true）
vim.opt.scrolloff = 8         -- 上下に余白を残す
vim.opt.sidescrolloff = 8     -- 左右スクロールの余白
vim.opt.colorcolumn = "120"   -- 120文字目に縦線

-- -----------------------------
-- インデント / タブ
-- -----------------------------
vim.opt.expandtab = true   -- Tab をスペースに変換
vim.opt.shiftwidth = 2     -- 自動インデント幅（>> 等）
vim.opt.tabstop = 2        -- タブ幅の見た目
vim.opt.smartindent = true -- それっぽく自動インデント

-- -----------------------------
-- 検索
-- -----------------------------
vim.opt.ignorecase = true -- 大文字小文字を無視
vim.opt.smartcase = true  -- ただし大文字を含む検索は区別する
vim.opt.incsearch = true  -- 入力中に検索結果を反映
vim.opt.hlsearch = true   -- 検索結果をハイライト

-- -----------------------------
-- 編集体験
-- -----------------------------
vim.opt.mouse = "a"      -- マウス有効（分割のリサイズ等）
vim.opt.undofile = true  -- 永続Undo
vim.opt.swapfile = false -- swap を作らない（好み）
vim.opt.backup = false   -- backup ファイルを作らない
vim.opt.updatetime = 250 -- 反応速度
vim.opt.timeoutlen = 400 -- キーマップ待ち時間

-- OSクリップボード連携（環境によっては別途設定が必要なことあり）
vim.opt.clipboard = "unnamedplus"

-- 見えにくい文字を可視化
vim.opt.list = true

-- -----------------------------
-- status line
-- -----------------------------

-- -----------------------------
-- cmdline
-- -----------------------------
vim.opt.cmdheight = 0
