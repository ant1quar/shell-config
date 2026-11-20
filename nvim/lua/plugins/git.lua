return {
  -- Magit-подобный интерфейс: статус, stage, коммит, push/pull, ветки, stash, log — прямо в nvim
  {
    "NeogitOrg/neogit",
    dependencies = { "nvim-lua/plenary.nvim", "sindrets/diffview.nvim" },
    cmd = "Neogit",
    keys = {
      { "<leader>gg", "<cmd>Neogit<cr>", desc = "Git: status/commit (Neogit)" },
      { "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Git: commit" },
      { "<leader>gl", "<cmd>Neogit log<cr>", desc = "Git: log" },
      { "<leader>gP", "<cmd>Neogit push<cr>", desc = "Git: push" },
    },
    opts = {
      integrations = { diffview = true, telescope = true },
      graph_style = "unicode",
    },
  },
  -- История и диффы
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Git: diff рабочего дерева" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Git: история файла" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Git: история репозитория" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Git: закрыть diffview" },
    },
    opts = {},
  },
}
