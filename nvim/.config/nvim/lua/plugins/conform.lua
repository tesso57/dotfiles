return {
  {
    "stevearc/conform.nvim",
    opts = {
      format_on_save = {
        timeout_ms = 2000,
        lsp_format = "fallback",
      },

      formatters_by_ft = {
        go = { "goimports" },

        proto = { "buf", "clang-format", stop_after_first = true },

        -- biome-check: `biome check --write --unsafe`
        --   formatter + import 並び替え + lint 自動修正(未使用 import 削除など)
        javascript      = { "biome-check" },
        javascriptreact = { "biome-check" },
        typescript      = { "biome-check" },
        typescriptreact = { "biome-check" },
        json            = { "biome" },
        jsonc           = { "biome" },

        python = { "ruff_organize_imports", "ruff_format" },
      },

      -- conform の biome-check は default で --unsafe を付けない
      -- (--unsafe がないと noUnusedImports の自動修正が走らないため上書き)
      formatters = {
        ["biome-check"] = {
          args = { "check", "--write", "--unsafe", "--stdin-file-path", "$FILENAME" },
        },
      },
    },
  }
}
