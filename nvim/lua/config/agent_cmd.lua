--- Sidekick agent: всегда запускаем через ~/.local/bin/nvim-agent (создаёт install.sh).
local M = {}

function M.resolve()
  local bin = vim.fn.expand("~/.local/bin/nvim-agent")
  if vim.fn.executable(bin) == 1 then
    return { bin }
  end
  if vim.fn.executable("nvim-agent") == 1 then
    return { "nvim-agent" }
  end
  return { "nvim-agent" }
end

return M