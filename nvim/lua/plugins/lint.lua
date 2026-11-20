-- Линтинг идёт через eslint LSP (mason); форматирование через none-ls
return {
  {
    "nvimtools/none-ls.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "BufReadPre",
    config = function()
      local null_ls = require("null-ls")
      null_ls.setup({
        sources = { null_ls.builtins.formatting.prettier },
      })
      vim.keymap.set("n", "<leader>cf", function() vim.lsp.buf.format({ async = true }) end,
        { desc = "Format" })
    end,
  },
}
