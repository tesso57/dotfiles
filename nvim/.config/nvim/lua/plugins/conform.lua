return {
  {
    "stevearc/conform.nvim",
    opts = {
      format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
      },

      formatters_by_ft = {
        go = { "goimports" },

        proto = { "buf", "clang-format", stop_after_first = true },

        javascript      = { "biome" },
        javascriptreact = { "biome" },
        typescript      = { "biome" },
        typescriptreact = { "biome" },
        json            = { "biome" },
        jsonc           = { "biome" },
      },
    },
  }
}
