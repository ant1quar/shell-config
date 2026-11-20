local agent_cmd = require("config.agent_cmd")

return {
  "folke/sidekick.nvim",
  event = "VeryLazy",
  opts = {
    nes = { enabled = false }, -- NES требует Copilot; включить при необходимости
    cli = {
      mux = { enabled = true, backend = "tmux", create = "split", split = { vertical = true, size = 0.3 } },
      tools = { agent = { cmd = agent_cmd.resolve() } },
    },
  },
  keys = {
    { "<leader>aa", function() require("sidekick.cli").toggle({ name = "agent", focus = true }) end,
      desc = "Agent: toggle", mode = { "n", "t" } },
    { "<leader>as", function() require("sidekick.cli").select() end, desc = "Select CLI agent" },
    { "<leader>at", function() require("sidekick.cli").send({ msg = "{this}" }) end,
      mode = { "n", "x" }, desc = "Send this" },
    { "<leader>af", function() require("sidekick.cli").send({ msg = "{file}" }) end, desc = "Send file" },
    { "<leader>av", function() require("sidekick.cli").send({ msg = "{selection}" }) end,
      mode = "x", desc = "Send selection" },
    { "<leader>ad", function() require("sidekick.cli").send({ msg = "{diagnostics}" }) end,
      desc = "Send diagnostics" },
    { "<leader>ap", function() require("sidekick.cli").prompt() end,
      mode = { "n", "x" }, desc = "Prompt picker" },
  },
}
