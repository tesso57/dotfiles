return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = true },
      dashboard = { enabled = true },
      explorer = { enabled = true },
      indent = { enabled = true },
      input = { enabled = true },

      -- Noice + nvim-notify を入れているなら、まずは off 推奨（vim.notify の取り合いを避ける）
      -- notifier = {
      --   enabled = true,
      --   timeout = 3000,
      -- },
      --
      picker = {
        enabled = true,
        ui_select = true
      },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      styles = {
        notification = {
          -- wo = { wrap = true } -- Wrap notifications
        }
      }
    },


    keys = {
      -- よく使うピッカー & エクスプローラー
      { "<leader><space>", function() Snacks.picker.smart() end, desc = "ファイルを賢く検索" },
      { "<leader>,", function() Snacks.picker.buffers() end, desc = "バッファ一覧" },
      { "<leader>/", function() Snacks.picker.grep() end, desc = "文字列検索（Grep）" },
      { "<leader>:", function() Snacks.picker.command_history() end, desc = "コマンド履歴" },
      { "<leader>n", function() Snacks.picker.notifications() end, desc = "通知履歴" },
      { "<leader>e", function() Snacks.explorer() end, desc = "ファイルエクスプローラー" },

      -- 検索（Find）
      { "<leader>fb", function() Snacks.picker.buffers() end, desc = "バッファ一覧" },
      { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "設定ファイルを検索" },
      { "<leader>ff", function() Snacks.picker.files() end, desc = "ファイル検索" },
      { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Git管理下のファイル検索" },
      { "<leader>fp", function() Snacks.picker.projects() end, desc = "プロジェクト" },
      { "<leader>fr", function() Snacks.picker.recent() end, desc = "最近使ったもの" },

      -- Git
      { "<leader>gb", function() Snacks.picker.git_branches() end, desc = "Gitブランチ" },
      { "<leader>gl", function() Snacks.picker.git_log() end, desc = "Gitログ" },
      { "<leader>gL", function() Snacks.picker.git_log_line() end, desc = "Gitログ（現在行）" },
      { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Gitステータス" },
      { "<leader>gS", function() Snacks.picker.git_stash() end, desc = "Gitスタッシュ" },
      { "<leader>gd", function() Snacks.picker.git_diff() end, desc = "Git差分（hunk）" },
      { "<leader>gf", function() Snacks.picker.git_log_file() end, desc = "Gitログ（ファイル）" },

      -- GitHub（gh）
      { "<leader>gi", function() Snacks.picker.gh_issue() end, desc = "GitHub Issues（オープン）" },
      { "<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end, desc = "GitHub Issues（全て）" },
      { "<leader>gp", function() Snacks.picker.gh_pr() end, desc = "GitHub PR（オープン）" },
      { "<leader>gP", function() Snacks.picker.gh_pr({ state = "all" }) end, desc = "GitHub PR（全て）" },

      -- 文字列検索（Grep）
      { "<leader>sb", function() Snacks.picker.lines() end, desc = "バッファ内の行" },
      { "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "開いているバッファを検索" },
      { "<leader>sg", function() Snacks.picker.grep() end, desc = "文字列検索（Grep）" },
      { "<leader>sw", function() Snacks.picker.grep_word() end, desc = "選択範囲または単語を検索", mode = { "n", "x" } },

      -- 検索/参照（Search）
      { '<leader>s"', function() Snacks.picker.registers() end, desc = "レジスタ" },
      { '<leader>s/', function() Snacks.picker.search_history() end, desc = "検索履歴" },
      { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmd一覧" },
      { "<leader>sb", function() Snacks.picker.lines() end, desc = "バッファ内の行" },
      { "<leader>sc", function() Snacks.picker.command_history() end, desc = "コマンド履歴" },
      { "<leader>sC", function() Snacks.picker.commands() end, desc = "コマンド一覧" },
      { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "診断" },
      { "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "バッファ診断" },
      { "<leader>sh", function() Snacks.picker.help() end, desc = "ヘルプ" },
      { "<leader>sH", function() Snacks.picker.highlights() end, desc = "ハイライト一覧" },
      { "<leader>si", function() Snacks.picker.icons() end, desc = "アイコン" },
      { "<leader>sj", function() Snacks.picker.jumps() end, desc = "ジャンプリスト" },
      { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "キーマップ一覧" },
      { "<leader>sl", function() Snacks.picker.loclist() end, desc = "ロケーションリスト" },
      { "<leader>sm", function() Snacks.picker.marks() end, desc = "マーク" },
      { "<leader>sM", function() Snacks.picker.man() end, desc = "manページ" },
      { "<leader>sp", function() Snacks.picker.lazy() end, desc = "プラグイン定義を検索" },
      { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfixリスト" },
      { "<leader>sR", function() Snacks.picker.resume() end, desc = "再開" },
      { "<leader>su", function() Snacks.picker.undo() end, desc = "Undo履歴" },
      { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "カラースキーム" },

      -- LSP
      { "gd", function() Snacks.picker.lsp_definitions() end, desc = "定義へ移動" },
      { "gD", function() Snacks.picker.lsp_declarations() end, desc = "宣言へ移動" },
      { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "参照" },
      { "gI", function() Snacks.picker.lsp_implementations() end, desc = "実装へ移動" },
      { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "型定義へ移動" },
      { "gai", function() Snacks.picker.lsp_incoming_calls() end, desc = "呼び出し元（Incoming）" },
      { "gao", function() Snacks.picker.lsp_outgoing_calls() end, desc = "呼び出し先（Outgoing）" },
      { "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "シンボル" },
      { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "ワークスペースシンボル" },

      -- その他
      { "<leader>z",  function() Snacks.zen() end, desc = "Zenモード切替" },
      { "<leader>Z",  function() Snacks.zen.zoom() end, desc = "ズーム切替" },
      { "<leader>.",  function() Snacks.scratch() end, desc = "スクラッチバッファ切替" },
      { "<leader>S",  function() Snacks.scratch.select() end, desc = "スクラッチバッファ選択" },

      { "<leader>bd", function() Snacks.bufdelete() end, desc = "バッファ削除" },
      { "<leader>cR", function() Snacks.rename.rename_file() end, desc = "ファイル名変更" },
      { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Gitをブラウザで開く", mode = { "n", "v" } },
      { "<leader>gg", function() Snacks.lazygit() end, desc = "LazyGit" },
      { "<leader>un", function() Snacks.notifier.hide() end, desc = "通知を全て消す" },
      { "<c-/>",      function() Snacks.terminal() end, desc = "ターミナル切替" },
      { "<c-_>",      function() Snacks.terminal() end, desc = "which_key_ignore" },
      { "]]",         function() Snacks.words.jump(vim.v.count1) end, desc = "次の参照", mode = { "n", "t" } },
      { "[[",         function() Snacks.words.jump(-vim.v.count1) end, desc = "前の参照", mode = { "n", "t" } },

      {
        "<leader>N",
        desc = "Neovimニュース",
        function()
          Snacks.win({
            file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
            width = 0.6,
            height = 0.6,
            wo = {
              spell = false,
              wrap = false,
              signcolumn = "yes",
              statuscolumn = " ",
              conceallevel = 3,
            },
          })
        end,
      },
    },

    init = function()
       vim.api.nvim_create_autocmd("User", {
         pattern = "VeryLazy",
         callback = function()
           -- Setup some globals for debugging (lazy-loaded)
           _G.dd = function(...)
             Snacks.debug.inspect(...)
           end
           _G.bt = function()
             Snacks.debug.backtrace()
           end

           -- Override print to use snacks for `:=` command
           if vim.fn.has("nvim-0.11") == 1 then
             vim._print = function(_, ...)
               dd(...)
             end
           else
             vim.print = _G.dd
           end

           -- Create some toggle mappings
           Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
           Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
           Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
           Snacks.toggle.diagnostics():map("<leader>ud")
           Snacks.toggle.line_number():map("<leader>ul")
           Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
           Snacks.toggle.treesitter():map("<leader>uT")
           Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
           Snacks.toggle.inlay_hints():map("<leader>uh")
           Snacks.toggle.indent():map("<leader>ug")
           Snacks.toggle.dim():map("<leader>uD")
         end,
       })
    end,
  }
}
