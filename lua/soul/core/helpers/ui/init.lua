local M = {}


function M.setup()
  require("soul.core.helpers.ui.highlights").setup()
  require("soul.core.helpers.ui.colors").setup()
end

function M.hide_statusline(win)
  if not vim.api.nvim_win_is_valid(win) or hidden_statusline_windows[win] then
    return
  end

  if next(hidden_statusline_windows) == nil then
    previous_laststatus = vim.o.laststatus
    vim.o.laststatus = 0
  end

  hidden_statusline_windows[win] = true
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      hidden_statusline_windows[win] = nil
      if next(hidden_statusline_windows) == nil and previous_laststatus ~= nil then
        vim.o.laststatus = previous_laststatus
        previous_laststatus = nil
      end
    end,
  })
end

M.setup()

return M
