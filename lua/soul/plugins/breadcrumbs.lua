local M = {
  "LunarVim/breadcrumbs.nvim",
  dependencies = {
    "neovim/nvim-lspconfig",
    "SmiteshP/nvim-navic",
  },
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

    local current = vim.api.nvim_get_option_value("winbar", { win = win })
    if current == "" then
      centered[win] = nil
      return
    end

    local state = centered[win]
    local base = state and current == state.value and state.base or current
    local value = "%=" .. base .. "%="

    centered[win] = {
      base = base,
      value = value,
    }

    vim.api.nvim_set_option_value("winbar", value, { win = win })
  end

  local function center_current_win()
    center_winbar(vim.api.nvim_get_current_win())
  end

  local function center_all_windows()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      center_winbar(win)
    end
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
    callback = function(args)
      if args.event == "WinResized" or args.event == "VimResized" then
        vim.schedule(center_all_windows)
      else
        vim.schedule(center_current_win)
      end
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
