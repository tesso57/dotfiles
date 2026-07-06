return {
  -- LSPサーバー等のインストール管理
  { "mason-org/mason.nvim", opts = {} },

  -- Mason 経由でLSP以外のツール(formatter等)も自動インストール
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = { "ruff" },
      auto_update = false,
      run_on_start = true,
    },
  },

  -- mason と lspconfig の橋渡し（lazy.nvim 推奨構成）
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = { "lua_ls", "marksman", "vtsls", "biome", "pyright" },
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
      vim.lsp.config("gopls", require("config.gopls_router").server())
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
      -- TypeScript / JavaScript: vtsls
      -- =========================
      vim.lsp.config("vtsls", {
        settings = {
          typescript = {
            inlayHints = {
              parameterNames = { enabled = "literals" },
              parameterTypes = { enabled = true },
              variableTypes = { enabled = false },
              propertyDeclarationTypes = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              enumMemberValues = { enabled = true },
            },
          },
          javascript = {
            inlayHints = {
              parameterNames = { enabled = "literals" },
              parameterTypes = { enabled = true },
              variableTypes = { enabled = false },
              propertyDeclarationTypes = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              enumMemberValues = { enabled = true },
            },
          },
          vtsls = {
            autoUseWorkspaceTsdk = true,
          },
        },
        on_init = function(client)
          -- format は conform→biome に一本化するため LSP 側を無効化
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end,
      })
      vim.lsp.enable("vtsls")

      -- =========================
      -- Biome (JS/TS lint via LSP)
      -- =========================
      vim.lsp.config("biome", {
        on_init = function(client)
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end,
      })
      vim.lsp.enable("biome")

      -- =========================
      -- Python: pyright
      -- =========================
      vim.lsp.config("pyright", {
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "basic",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "openFilesOnly",
            },
          },
        },
      })
      vim.lsp.enable("pyright")

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

          -- TS/JS/JSX/TSX: import 整理 + format は conform 側 (biome-check) に一本化
          -- vtsls 側では inlay hint を有効化、トグルキーを設定する
          local ts_fts = { typescript = true, typescriptreact = true, javascript = true, javascriptreact = true }
          if ts_fts[ft] and client and client.name == "vtsls" then
            -- inlay hint を有効化
            if vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable then
              pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })
            end

            -- <leader>ih: inlay hint トグル
            vim.keymap.set("n", "<leader>ih", function()
              if not (vim.lsp.inlay_hint and vim.lsp.inlay_hint.is_enabled) then
                return
              end
              local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
              vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
            end, { buffer = bufnr, desc = "Toggle inlay hints" })
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
