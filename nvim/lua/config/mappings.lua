local map = vim.keymap.set
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
map("n", "<leader>fs", "<cmd>Telescope grep_string<cr>", { desc = "Word under cursor" })
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Buffers" })
map("n", "<C-p>", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
map("n", "<C-g>", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Terminal normal mode" })

-- Навигация между окнами без Ctrl-w (iTerm перехватывает его); работает и из терминала (Claude)
for _, k in ipairs({ "h", "j", "k", "l" }) do
  map({ "n", "t" }, "<C-" .. k .. ">", function()
    if vim.fn.mode() == "t" then vim.cmd("stopinsert") end
    vim.cmd("wincmd " .. k)
  end, { desc = "Go to window " .. k })
end

-- При входе в терминальное окно сразу печатать в нём
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  pattern = "term://*",
  command = "startinsert",
})

-- Мануал по хоткеям в попапе: <leader>h
-- Внутри: / — поиск, s — нечёткий поиск (Telescope), ]] / [[ — по заголовкам, q / Esc — закрыть
local function open_manual()
  local path = vim.fn.stdpath("config") .. "/manual.md"
  if vim.fn.filereadable(path) == 0 then
    vim.notify("Не найден " .. path, vim.log.levels.ERROR)
    return
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.fn.readfile(path))
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local w = math.floor(vim.o.columns * 0.8)
  local h = math.floor(vim.o.lines * 0.85)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = w,
    height = h,
    col = math.floor((vim.o.columns - w) / 2),
    row = math.floor((vim.o.lines - h) / 2 - 1),
    style = "minimal",
    border = "rounded",
    title = " Мануал  (/ поиск · s fuzzy · ]] [[ разделы · q выход) ",
    title_pos = "center",
  })
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].cursorline = true
  vim.wo[win].conceallevel = 2

  local o = { buffer = buf, nowait = true }
  local close = function() if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end end
  map("n", "q", close, o)
  map("n", "<Esc>", function()
    if vim.v.hlsearch == 1 then vim.cmd.nohlsearch() else close() end
  end, o)
  map("n", "s", function() require("telescope.builtin").current_buffer_fuzzy_find() end, o)
  map("n", "]]", function() vim.fn.search("^#", "W") end, o)
  map("n", "[[", function() vim.fn.search("^#", "bW") end, o)
end
map("n", "<leader>h", open_manual, { desc = "Manual (hotkeys)" })

-- Сплиты (без Ctrl-w, который перехватывает iTerm)
map("n", "<leader>sv", "<cmd>vsplit<cr>", { desc = "Split: вертикальный (рядом)" })
map("n", "<leader>sh", "<cmd>split<cr>", { desc = "Split: горизонтальный (друг под другом)" })
map("n", "<leader>sx", "<cmd>close<cr>", { desc = "Split: закрыть окно" })
map("n", "<leader>so", "<cmd>only<cr>", { desc = "Split: оставить только это окно" })
map("n", "<leader>se", "<C-w>=", { desc = "Split: выровнять размеры" })
map("n", "<leader>sm", "<C-w>|<C-w>_", { desc = "Split: максимизировать" })
-- Изменение размера: Alt-стрелки не используем (iTerm), берём <leader>s + [ ] - =
map("n", "<leader>s]", "<cmd>vertical resize +5<cr>", { desc = "Split: шире" })
map("n", "<leader>s[", "<cmd>vertical resize -5<cr>", { desc = "Split: уже" })
map("n", "<leader>s=", "<cmd>resize +3<cr>", { desc = "Split: выше" })
map("n", "<leader>s-", "<cmd>resize -3<cr>", { desc = "Split: ниже" })
