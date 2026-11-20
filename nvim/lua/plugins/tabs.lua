-- Верхняя панель с "вкладками" = открытые буферы (файлы), как в IDE
return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  keys = {
    { "H", "<cmd>BufferLineCyclePrev<cr>", desc = "Tab: предыдущая" },
    { "L", "<cmd>BufferLineCycleNext<cr>", desc = "Tab: следующая" },
    { "<leader>bh", "<cmd>BufferLineMovePrev<cr>", desc = "Tab: сдвинуть влево" },
    { "<leader>bl", "<cmd>BufferLineMoveNext<cr>", desc = "Tab: сдвинуть вправо" },
    { "<leader>bp", "<cmd>BufferLineTogglePin<cr>", desc = "Tab: закрепить" },
    { "<leader>bb", "<cmd>BufferLinePick<cr>", desc = "Tab: выбрать буквой" },
    { "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "Tab: закрыть остальные" },
    { "<leader>bd", function() require("config.bufutil").close() end, desc = "Tab: закрыть текущую" },
    { "<leader>1", "<cmd>BufferLineGoToBuffer 1<cr>", desc = "Tab 1" },
    { "<leader>2", "<cmd>BufferLineGoToBuffer 2<cr>", desc = "Tab 2" },
    { "<leader>3", "<cmd>BufferLineGoToBuffer 3<cr>", desc = "Tab 3" },
    { "<leader>4", "<cmd>BufferLineGoToBuffer 4<cr>", desc = "Tab 4" },
    { "<leader>5", "<cmd>BufferLineGoToBuffer 5<cr>", desc = "Tab 5" },
    { "<leader>6", "<cmd>BufferLineGoToBuffer 6<cr>", desc = "Tab 6" },
    { "<leader>7", "<cmd>BufferLineGoToBuffer 7<cr>", desc = "Tab 7" },
    { "<leader>8", "<cmd>BufferLineGoToBuffer 8<cr>", desc = "Tab 8" },
    { "<leader>9", "<cmd>BufferLineGoToBuffer -1<cr>", desc = "Tab: последняя" },
  },
  opts = {
    options = {
      mode = "buffers",
      numbers = "ordinal", -- номер вкладки = <leader>N
      diagnostics = "nvim_lsp",
      always_show_bufferline = true,
      separator_style = "slant",
      close_command = function(n) require("config.bufutil").close(n) end,
      right_mouse_command = function(n) require("config.bufutil").close(n) end,
      offsets = {
        { filetype = "NvimTree", text = "Files", highlight = "Directory", separator = true },
      },
    },
  },
}
