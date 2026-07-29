  vim.cmd [[
  highlight NormalFloat guibg=NONE
  highlight FloatBorder guibg=NONE guifg=NONE
  highlight PmenuSel guibg=NONE
  highlight PmenuSbar guibg=NONE
  highlight PmenuThumb guibg=NONE
]]
vim.cmd.colorscheme("catppuccin")
vim.api.nvim_exec_autocmds('ColorScheme', { pattern = 'catppuccin', modeline = false })
vim.g.neovide_opacity = 0.75
