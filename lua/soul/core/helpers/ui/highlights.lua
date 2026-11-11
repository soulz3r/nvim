local M = {}

local palette = require("soul.core.helpers.ui.colors").palette

local groups = {
  SoulSectionTitle = { link = "Title" },
  SoulMuted = { fg = palette.muted },
  SoulSuccess = { link = "DiagnosticOk" },
  SoulBuildSeparator = { link = "SoulSectionTitle", bold = true },
  SoulExecutionSeparator = { link = "SoulSuccess", bold = true },
  SoulWarning = { link = "DiagnosticWarn" },
  SoulError = { link = "DiagnosticError" },
}

function M.apply()
  for name, value in pairs(groups) do
    vim.api.nvim_set_hl(0, name, value)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("SoulUIHighlights", { clear = true })

  M.apply()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = M.apply,
  })
end

return M
