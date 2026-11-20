-- Языконезависимые команды.
-- 1) langmap (см. options.lua) покрывает встроенные команды vim: i, v, dd, ciw...
-- 2) Но langmap НЕ применяется к пользовательским маппингам (<leader>e, gd, ...),
--    поэтому для каждого такого маппинга автоматически создаём "двойник" с
--    русскими буквами, который просто перенаправляет на оригинал.
local M = {}

local en = "qwertyuiop[]asdfghjkl;'zxcvbnm,.`QWERTYUIOP{}ASDFGHJKL:\"ZXCVBNM<>~"
local ru = "йцукенгшщзхъфывапролджэячсмитьбюёЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮЁ"
local to_ru = {}
do
  local e, r = vim.fn.split(en, "\\zs"), vim.fn.split(ru, "\\zs")
  for i, ch in ipairs(e) do
    if ch:match("%a") then to_ru[ch] = r[i] end -- только буквы; пунктуацию не трогаем
  end
end

-- Заменяет буквы в lhs на русские, не трогая спец-клавиши вида <Space>, <C-p>, <CR>
local function twin(lhs)
  local out, i = {}, 1
  while i <= #lhs do
    local special = lhs:match("^<[%w%-_]+>", i)
    if special then
      out[#out + 1] = special
      i = i + #special
    else
      local ch = lhs:sub(i, i)
      out[#out + 1] = to_ru[ch] or ch
      i = i + 1
    end
  end
  return table.concat(out)
end

local modes = { "n", "x" } -- терминальный режим не трогаем: там печатается текст

local function add(buf)
  for _, mode in ipairs(modes) do
    local maps = buf and vim.api.nvim_buf_get_keymap(buf, mode) or vim.api.nvim_get_keymap(mode)
    for _, m in ipairs(maps) do
      local lhs = m.lhs
      -- не создаём двойники для самих двойников и для чужих служебных <Plug>
      if not lhs:find("<Plug>", 1, true) and not lhs:find("<SNR>", 1, true) then
        local t = twin(lhs)
        if t ~= lhs and #t > 0 and not m.desc_twin then
          local exists = vim.fn.maparg(t, mode, false, true)
          if vim.tbl_isempty(exists) or exists.lhs == nil then
            vim.keymap.set(mode, t, lhs, {
              remap = true, nowait = m.nowait == 1, silent = true, buffer = buf,
              desc = "ru: " .. (m.desc or lhs),
            })
          end
        end
      end
    end
  end
end

function M.setup()
  local function run() add(nil); add(0) end
  local group = vim.api.nvim_create_augroup("RuKeymapTwins", { clear = true })
  vim.api.nvim_create_autocmd("User", { group = group, pattern = { "VeryLazy", "LazyLoad" },
    callback = function() vim.schedule(function() add(nil) end) end })
  vim.api.nvim_create_autocmd({ "LspAttach", "BufEnter", "FileType" }, { group = group,
    callback = function(a) vim.schedule(function() if vim.api.nvim_buf_is_valid(a.buf) then add(a.buf) end end) end })
  run()
end

return M
