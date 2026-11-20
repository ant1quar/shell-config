return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local ts = require("nvim-treesitter")
    ts.setup()
    ts.install({ "lua", "vim", "vimdoc", "javascript", "typescript", "tsx",
      "html", "css", "json", "angular", "markdown", "markdown_inline" })
    vim.api.nvim_create_autocmd("FileType", {
      callback = function(a) pcall(vim.treesitter.start, a.buf) end,
    })
  end,
}
