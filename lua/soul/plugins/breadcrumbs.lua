local M = {
  "LunarVim/breadcrumbs.nvim",
}

function M.config()
  local breadcrumbs = require("breadcrumbs")

  table.insert(breadcrumbs.winbar_filetype_exclude, "minifiles")

  vim.api.nvim_set_hl(0, "WinBar", {
    bg = "#272e33",
  })

  breadcrumbs.setup({})
end

return M
