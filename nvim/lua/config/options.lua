local o = vim.opt
o.number = true
o.relativenumber = true
o.tabstop = 2
o.shiftwidth = 2
o.expandtab = true
o.wrap = false
o.mouse = "a"
o.mousemodel = "extend"
o.mousescroll = "ver:3,hor:2"
o.termguicolors = true
o.signcolumn = "yes"
o.ignorecase = true
o.smartcase = true
o.updatetime = 250
o.splitright = true
o.splitbelow = true
o.clipboard = "unnamedplus"
o.autoread = true
o.ttimeoutlen = 10

-- перечитывать файлы, изменённые снаружи (Claude Code)
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  command = "silent! checktime",
})

-- Языконезависимые команды: русская раскладка (ЙЦУКЕН) -> латиница в normal/visual.
-- <leader>у работает как <leader>e и т.д. На ввод текста в insert не влияет.
do
  local function chars(s) return vim.fn.split(s, "\\zs") end
  local ru = chars("йцукенгшщзхъфывапролджэячсмитьбюё" .. "ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮЁ")
  local en = chars("qwertyuiop[]asdfghjkl;'zxcvbnm,.`" .. "QWERTYUIOP{}ASDFGHJKL:\"ZXCVBNM<>~")
  local pairs_ = {}
  for i, r in ipairs(ru) do
    local e = en[i]
    if e == ";" or e == "," or e == "\\" or e == '"' then e = "\\" .. e end
    pairs_[#pairs_ + 1] = r .. ";" .. e
  end
  vim.o.langmap = table.concat(pairs_, ",")
end