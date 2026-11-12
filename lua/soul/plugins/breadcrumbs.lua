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
  table.insert(breadcrumbs.winbar_filetype_exclude, "project-output")

  breadcrumbs.setup()

  local group = vim.api.nvim_create_augroup("SoulBreadcrumbsCenter", {
    clear = true,
  })

  local state_key = "soul_breadcrumbs_centered"

  local function center_winbar(win)
    if not vim.api.nvim_win_is_valid(win) then
      return
    end

    local current = vim.api.nvim_get_option_value("winbar", { win = win })
    local ok, state = pcall(vim.api.nvim_win_get_var, win, state_key)

    if current == "" then
      pcall(vim.api.nvim_win_del_var, win, state_key)
      return
    end

    if not ok then
      state = nil
    end

    local base = state and current == state.value and state.base or current
    local value = "%=" .. base .. "%="

    pcall(vim.api.nvim_win_set_var, win, state_key, {
      base = base,
      value = value,
    })
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

end

return M
