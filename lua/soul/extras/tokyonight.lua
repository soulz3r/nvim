local M = {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {},
}

function M.config()
  vim.cmd.colorscheme "tokyonight-moon"
end

return M
