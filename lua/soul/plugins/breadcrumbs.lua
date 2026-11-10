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

  local centered = {}

  local function center_winbar(win)
    if not vim.api.nvim_win_is_valid(win) then
      return
    end

    local current = vim.api.nvim_get_option_value("winbar", {
      win = win,
    })

    if current == "" then
      centered[win] = nil
      return
    end

    local state = centered[win]
    local base = state and current == state.value and state.base or current

    local visible = base
      :gsub("%%#.-#", "")
      :gsub("%%%*", "")
      :gsub("%%%%", "%%")

    local width = vim.api.nvim_win_get_width(win)
    local content_width = vim.fn.strdisplaywidth(visible)
    local padding = math.max(0, math.floor((width - content_width) / 2))
    local value = string.rep(" ", padding) .. base

    centered[win] = {
      base = base,
      value = value,
    }

    vim.api.nvim_set_option_value("winbar", value, {
      win = win,
    })
  end

  local function center_current_win()
    center_winbar(vim.api.nvim_get_current_win())
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
    "WinEnter",
    "WinResized",
    "VimResized",
  }, {
    group = group,
    callback = function()
      vim.schedule(center_current_win)
    end,
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(args)
      centered[tonumber(args.match)] = nil
    end,
  })
end

return M
