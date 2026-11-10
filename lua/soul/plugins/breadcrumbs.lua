local M = {
  "LunarVim/breadcrumbs.nvim",
}

function M.config()
  local breadcrumbs = require("breadcrumbs")

  table.insert(breadcrumbs.winbar_filetype_exclude, "minifiles")

  breadcrumbs.setup()

  local group = vim.api.nvim_create_augroup("SoulBreadcrumbsCenter", {
    clear = true,
  })

  local function center_winbar()
    local win = vim.api.nvim_get_current_win()

    if not vim.api.nvim_win_is_valid(win) then
      return
    end

    local winbar = vim.api.nvim_get_option_value("winbar", {
      win = win,
    })

    if winbar == "" then
      return
    end

    local visible = winbar
      :gsub("%%#.-#", "")
      :gsub("%%\\*", "")
      :gsub("%%%%", "%%")

    local width = vim.api.nvim_win_get_width(win)
    local content_width = vim.fn.strdisplaywidth(visible)
    local padding = math.max(0, math.floor((width - content_width) / 2))

    vim.api.nvim_set_option_value("winbar", string.rep(" ", padding) .. winbar, {
      win = win,
    })
  end

  vim.api.nvim_create_autocmd({
    "CursorHoldI",
    "CursorHold",
    "BufReadPost",
    "BufFilePost",
    "InsertEnter",
    "BufWritePost",
    "TabClosed",
    "TabEnter",
    "VimResized",
    "WinResized",
  }, {
    group = group,
    callback = function()
      vim.schedule(center_winbar)
    end,
  })
end

return M
