local M = {
  "LunarVim/breadcrumbs.nvim",
}

function M.config()
  local breadcrumbs = require("breadcrumbs")

  table.insert(breadcrumbs.winbar_filetype_exclude, "minifiles")

  breadcrumbs.setup()
end

return M

