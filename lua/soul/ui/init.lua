local M = {}

local hidden_statusline_windows = {}
local previous_laststatus

local floats = require("soul.ui.floats")

function M.setup()
  require("soul.ui.highlights").setup()
  require("soul.ui.colors").setup()
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

function M.centered(width, height, title, opts)
  opts = opts or {}
  local columns = vim.o.columns
  local lines = vim.o.lines
  width = math.max(1, math.min(width or math.floor(columns * 0.72), columns - 4))
  height = math.max(1, math.min(height or math.floor(lines * 0.62), lines - 4))

  return {
    relative = "editor",
    style = "minimal",
    border = opts.border or floats.border,
    title = title and (" " .. title .. " ") or nil,
    title_pos = opts.title_pos or "center",
    width = width,
    height = height,
    row = math.max(0, math.floor((lines - height) / 2) - 1),
    col = math.max(0, math.floor((columns - width) / 2)),
  }
end

function M.open_text(lines, title, opts)
  opts = opts or {}
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = opts.filetype or "text"
  vim.bo[buf].modifiable = false

  local width = opts.width or math.floor(vim.o.columns * 0.72)
  local height = opts.height or math.min(#lines + 2, math.floor(vim.o.lines * 0.62))
  local win = vim.api.nvim_open_win(buf, true, M.centered(width, height, title, opts))
  vim.wo[win].wrap = opts.wrap == true
  vim.wo[win].cursorline = true
  floats.apply(win)

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  vim.keymap.set("n", "q", close, { buffer = buf, silent = true, nowait = true, desc = "Close window" })
  vim.keymap.set("n", "<Esc>", close, { buffer = buf, silent = true, nowait = true, desc = "Close window" })
  return buf, win
end

M.setup()

return M
