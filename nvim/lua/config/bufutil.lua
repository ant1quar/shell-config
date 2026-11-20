local M = {}

-- Закрыть буфер, не ломая раскладку окон: окна, где он показан, переключаются на другой буфер
function M.close(buf)
  buf = (buf and buf > 0) and buf or vim.api.nvim_get_current_buf()
  if vim.bo[buf].modified then
    local ok = vim.fn.confirm("Буфер изменён. Закрыть без сохранения?", "&Да\n&Нет", 2)
    if ok ~= 1 then return end
  end
  local listed = vim.tbl_filter(function(b)
    return b ~= buf and vim.bo[b].buflisted and vim.api.nvim_buf_is_loaded(b) or (b ~= buf and vim.bo[b].buflisted)
  end, vim.api.nvim_list_bufs())
  local target = listed[#listed]
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.api.nvim_win_call(win, function()
      local alt = vim.fn.bufnr("#")
      if alt > 0 and alt ~= buf and vim.bo[alt].buflisted then vim.cmd("buffer " .. alt)
      elseif target then vim.cmd("buffer " .. target)
      else vim.cmd("enew") end
    end)
  end
  if vim.api.nvim_buf_is_valid(buf) then vim.cmd("bdelete! " .. buf) end
end

return M
