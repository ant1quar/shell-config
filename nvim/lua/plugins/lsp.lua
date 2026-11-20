return {
  { "mason-org/mason.nvim", opts = {} },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig", "hrsh7th/cmp-nvim-lsp" },
    config = function()
      vim.lsp.config("*", {
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
      })
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "ts_ls", "angularls", "eslint" },
        automatic_enable = true,
      })
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(a)
          local m = function(k, f, d) vim.keymap.set("n", k, f, { buffer = a.buf, desc = d }) end
          m("gd", vim.lsp.buf.definition, "Definition")
          m("gr", vim.lsp.buf.references, "References")
          m("K", vim.lsp.buf.hover, "Hover")
          m("<leader>rn", vim.lsp.buf.rename, "Rename")
          m("<leader>ca", vim.lsp.buf.code_action, "Code action")
          m("<leader>d", vim.diagnostic.open_float, "Diagnostics")
        end,
      })
    end,
  },
}
