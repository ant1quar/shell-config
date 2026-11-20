return {
  "nvim-tree/nvim-tree.lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "File tree" },
    { "<leader>E", "<cmd>NvimTreeFindFile<cr>", desc = "Reveal current file in tree" },
  },
  init = function()
    -- отключить встроенный netrw
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  end,
  opts = {
    view = { width = 35 },
    renderer = { group_empty = true },
    filters = { dotfiles = false },
    git = { ignore = false },
    update_focused_file = { enable = true },
  },
}
