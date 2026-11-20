return {
  -- Markdown preview в браузере с live-reload, синхронизацией скролла, поддержкой Mermaid/KaTeX
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    ft = { "markdown" },
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown: preview toggle" },
      { "<leader>ms", "<cmd>MarkdownPreview<cr>", desc = "Markdown: preview start" },
      { "<leader>mx", "<cmd>MarkdownPreviewStop<cr>", desc = "Markdown: preview stop" },
    },
    init = function()
      -- Настройки markdown-preview.nvim
      vim.g.mkdp_auto_start = 0           -- не запускать автоматически при открытии .md
      vim.g.mkdp_auto_close = 1           -- закрывать при выходе из буфера
      vim.g.mkdp_refresh_slow = 0         -- обновлять в реальном времени
      vim.g.mkdp_command_for_global = 0   -- только для markdown-файлов
      vim.g.mkdp_open_to_the_world = 0    -- не открывать доступ извне
      vim.g.mkdp_open_ip = ""             -- слушать localhost
      vim.g.mkdp_browser = ""             -- использовать браузер по умолчанию
      vim.g.mkdp_echo_preview_url = 1     -- показывать URL в командной строке
      vim.g.mkdp_browserfunc = ""         -- кастомная функция открытия (пусто = дефолт)
      vim.g.mkdp_preview_options = {
        mkit = {},                        -- markdown-it опции
        katex = {},                       -- KaTeX опции
        uml = {},                         -- PlantUML опции
        maid = {},                        -- Mermaid опции
        disable_sync_scroll = 0,          -- синхронизировать скролл
        sync_scroll_type = "middle",      -- тип синхронизации
        hide_yaml_meta = 1,               -- скрыть YAML frontmatter
        sequence_diagrams = {},           -- JS sequence diagrams
        flowchart_diagrams = {},          -- flowchart diagrams
        content_editable = false,         -- редактирование в превью
        disable_filename = 0,             -- показывать имя файла
        toc = {},                         -- таблица содержания
      }
      vim.g.mkdp_markdown_css = ""        -- кастомный CSS для markdown
      vim.g.mkdp_highlight_css = ""       -- кастомный CSS для подсветки кода
      vim.g.mkdp_port = ""                -- случайный порт
      vim.g.mkdp_page_title = "《${name}》" -- заголовок страницы
      vim.g.mkdp_filetypes = { "markdown" } -- типы файлов
      vim.g.mkdp_theme = "dark"           -- тема: "dark" | "light"
    end,
  },
}