local M = {
  style = "rounded",
  border = {
    { "╭", "SoulFloatBorder" },
    { "─", "SoulFloatBorder" },
    { "╮", "SoulFloatBorder" },
    { "│", "SoulFloatBorder" },
    { "╯", "SoulFloatBorder" },
    { "─", "SoulFloatBorder" },
    { "╰", "SoulFloatBorder" },
    { "│", "SoulFloatBorder" },
  },
  winhighlight = table.concat({
    "Normal:NormalFloat",
    "FloatBorder:SoulFloatBorder",
    "FloatTitle:SoulFloatTitle",
  }, ","),
  telescope_borderchars = {
    "─",
    "│",
    "─",
    "│",
    "╭",
    "╮",
    "╯",
    "╰",
  },
}

function M.apply(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  vim.wo[win].winhighlight = M.winhighlight
end

return M
