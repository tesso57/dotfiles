return {
  -- LSPサーバー等のインストール管理
  { "mason-org/mason.nvim", opts = {} },

  -- mason と lspconfig の橋渡し（lazy.nvim 推奨構成）
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = { "gopls", "lua_ls", "marksman" },
      -- mason-lspconfig はデフォルトで「Masonで入れたサーバを自動enable」するので、
      -- ここでは明示的に enable したい -> OFF にしておく
      automatic_enable = false,
    },
  },

  -- LSP設定集
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- =========================
      -- capabilities（nvim-cmp連携）
      -- =========================
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok then
        capabilities = cmp_lsp.default_capabilities(capabilities)
      end

      -- 全LSP共通設定
      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      -- =========================
      -- Go: gopls
      -- =========================
      vim.lsp.config("gopls", {
        settings = {
          gopls = {
            ["formatting.local"] = "github.com/knowledge-work",
            gofumpt = true,
            staticcheck = true,
            analyses = { unusedparams = true },
          },
        },
      })
      vim.lsp.enable("gopls")

      -- =========================
      -- Markdown: marksman
      -- =========================
      vim.lsp.enable({
        "marksman"
      })

      -- =========================
      -- Lua: lua_ls
      -- =========================
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = {
              checkThirdParty = false,
              library = {
                vim.env.VIMRUNTIME .. "/lua",
                vim.fn.stdpath("config") .. "/lua",
              },
            },
            telemetry = { enable = false },
          },
        },
      })
      vim.lsp.enable("lua_ls")

      -- =========================
      -- Proto (Buf): buf lsp serve
      -- =========================
      -- Buf CLI が必要です: `buf` コマンドが見つからないと動きません。
      if vim.fn.executable("buf") == 1 then
        vim.lsp.config("buf_ls", {
          cmd = { "buf", "lsp", "serve" },
          filetypes = { "proto" },
          root_markers = { "buf.yaml", "buf.work.yaml", ".git" },
        })
        vim.lsp.enable("buf_ls")
      end

      -- =========================
      -- LspAttach: 共通キーマップ + format-on-save
      -- =========================
      local format_group = vim.api.nvim_create_augroup("LspFormatOnSave", { clear = true })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local bufnr = ev.buf
          local client = vim.lsp.get_client_by_id(ev.data.client_id)

          -- ---- 共通キーマップ（最低限）
          local opts = { buffer = bufnr }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, opts)

          -- ---- format-on-save（バッファごとに二重登録しないようクリア）
          vim.api.nvim_clear_autocmds({ group = format_group, buffer = bufnr })

          local ft = vim.bo[bufnr].filetype

          -- Go: organize imports -> format
          if ft == "go" and client and client.name == "gopls" then
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = format_group,
              buffer = bufnr,
              callback = function()
                -- imports 整理（失敗しても止めない）
                pcall(vim.lsp.buf.code_action, {
                  context = { only = { "source.organizeImports" } },
                  apply = true,
                })
                pcall(vim.lsp.buf.format, { bufnr = bufnr })
              end,
            })
          end

          -- Proto: Buf LSPが付いているときに format
          if ft == "proto" and client and client.name == "buf_ls" then
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = format_group,
              buffer = bufnr,
              callback = function()
                pcall(vim.lsp.buf.format, { bufnr = bufnr })
              end,
            })
          end

          -- Lua: 保存時formatは好み（必要ならONに）
          -- if ft == "lua" and client and client.name == "lua_ls" then
          --   vim.api.nvim_create_autocmd("BufWritePre", {
          --     group = format_group,
          --     buffer = bufnr,
          --     callback = function()
          --       pcall(vim.lsp.buf.format, { bufnr = bufnr })
          --     end,
          --   })
          -- end
        end,
      })
    end,
  }
}
