return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      -- ここを true にすると、カーソル行の blame を右端に出せます（好み）
      current_line_blame = false, -- Toggle: :Gitsigns toggle_current_line_blame

      -- README 推奨: バッファに attach したタイミングで buffer-local keymap を張る
      on_attach = function(bufnr)
        local gs = require("gitsigns")

        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        -- Hunk 移動（diffモードのときは元の ]c/[c を優先）
        map("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "次のhunkへ")

        map("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "前のhunkへ")

        -- ステージ/リセット（ノーマル/ビジュアル）
        map("n", "<leader>hs", gs.stage_hunk, "hunkをステージ")
        map("n", "<leader>hr", gs.reset_hunk, "hunkをリセット")

        map("v", "<leader>hs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "選択範囲hunkをステージ")

        map("v", "<leader>hr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "選択範囲hunkをリセット")

        map("n", "<leader>hS", gs.stage_buffer, "バッファ全体をステージ")
        map("n", "<leader>hR", gs.reset_buffer, "バッファ全体をリセット")

        -- プレビュー/Blame/Diff
        map("n", "<leader>hp", gs.preview_hunk, "hunkプレビュー（popup）")
        map("n", "<leader>hi", gs.preview_hunk_inline, "hunkプレビュー（inline）")
        map("n", "<leader>hb", function()
          gs.blame_line({ full = true })
        end, "この行のBlame（詳細）")
        map("n", "<leader>hd", gs.diffthis, "このバッファのDiff")
        map("n", "<leader>hD", function()
          gs.diffthis("~")
        end, "直前コミットとの差分")

        -- Quickfix/Loclist に差分を入れる
        -- trouble.nvim が入っていると setqflist/setloclist が Trouble を開きます
        map("n", "<leader>hq", gs.setqflist, "変更をQuickfixへ")
        map("n", "<leader>hQ", function() gs.setqflist("all") end, "変更をQuickfixへ（repo全体）")

        -- トグル
        map("n", "<leader>tb", gs.toggle_current_line_blame, "行Blameのトグル")
        map("n", "<leader>tw", gs.toggle_word_diff, "word diff のトグル")

        -- textobject: hunk（operator/visual）
        map({ "o", "x" }, "ih", gs.select_hunk, "hunkを選択")
      end,
    },
  },
}

