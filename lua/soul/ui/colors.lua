local M = {}

M.palette = {
  background = "#272e33",
  background_dim = "#2D353B",
  background_visual = "#343F44",
  foreground = "#D3C6AA",
  border = "#859289",
  muted = "#859289",
  muted_inactive = "#7A8478",
  green = "#A7C080",
  teal = "#7FBBB3",
  aqua = "#83C092",
  yellow = "#DBBC7F",
  red = "#E67E80",
  purple = "#D699B6",
  orange = "#E69875",
}

local P = M.palette

local highlights = {
  -- Floating windows stay transparent; their borders remain visible.
  NormalFloat = { fg = P.foreground, bg = "NONE" },
  FloatBorder = { fg = P.border, bg = "NONE" },
  FloatTitle = { fg = P.green, bg = "NONE", bold = true },
  FloatFooter = { fg = P.muted, bg = "NONE" },
  SoulFloatBorder = { fg = P.border, bg = "NONE" },
  SoulFloatTitle = { fg = P.green, bg = "NONE", bold = true },
  SoulFloatNormal = { fg = P.foreground, bg = "NONE" },

  WinSeparator = { fg = P.border },
  WinBar = { fg = P.muted, bg = "NONE" },
  WinBarNC = { fg = P.muted_inactive, bg = "NONE" },
  NavicText = { fg = P.foreground, bg = "NONE" },
  NavicSeparator = { fg = P.border, bg = "NONE" },
  CursorLine = { bg = P.background_visual },
  Visual = { bg = "#3D484D" },

  Pmenu = { fg = P.foreground, bg = P.background_dim },
  PmenuSel = { fg = P.green, bg = "NONE", bold = true },
  PmenuSbar = { bg = "NONE" },
  PmenuThumb = { bg = "NONE" },

  WhichKeyNormal = { fg = P.foreground, bg = P.background },
  WhichKeyBorder = { fg = P.border, bg = P.background },
  WhichKeyTitle = { fg = P.green, bg = P.background, bold = true },
  WhichKeyDesc = { fg = P.foreground },
  WhichKeyGroup = { fg = P.teal, bold = true },
  WhichKeySeparator = { fg = P.border },
  WhichKeyValue = { fg = P.muted },

  TelescopeNormal = { fg = P.foreground, bg = P.background },
  TelescopeBorder = { fg = P.border, bg = P.background },
  TelescopeTitle = { fg = P.green, bg = P.background, bold = true },
  TelescopePromptNormal = { fg = P.foreground, bg = P.background_dim },
  TelescopePromptBorder = { fg = P.border, bg = P.background_dim },
  TelescopePromptTitle = { fg = P.green, bg = P.background_dim, bold = true },
  TelescopeResultsNormal = { fg = P.foreground, bg = P.background },
  TelescopeResultsBorder = { fg = P.border, bg = P.background },
  TelescopeResultsTitle = { fg = P.green, bg = P.background, bold = true },
  TelescopePreviewNormal = { fg = P.foreground, bg = P.background },
  TelescopePreviewBorder = { fg = P.border, bg = P.background },
  TelescopePreviewTitle = { fg = P.green, bg = P.background, bold = true },
  TelescopeSelection = { fg = P.green, bg = P.background_visual, bold = true },
  TelescopeSelectionCaret = { fg = P.green, bg = P.background_visual },
  TelescopeMatching = { fg = P.green, bold = true },

  BlinkCmpMenu = { fg = P.foreground, bg = P.background },
  BlinkCmpMenuBorder = { fg = P.border, bg = P.background },
  BlinkCmpMenuSelection = { fg = P.green, bg = P.background_visual, bold = true },
  BlinkCmpDoc = { fg = P.foreground, bg = P.background },
  BlinkCmpDocBorder = { fg = P.border, bg = P.background },
  BlinkCmpSignatureHelp = { fg = P.foreground, bg = P.background },
  BlinkCmpSignatureHelpBorder = { fg = P.border, bg = P.background },

  LspInfoBorder = { fg = P.border, bg = P.background },
  DiagnosticFloating = { fg = P.foreground, bg = P.background },
  DiagnosticFloatingError = { fg = P.red, bg = P.background },
  DiagnosticFloatingWarn = { fg = P.yellow, bg = P.background },
  DiagnosticFloatingInfo = { fg = P.teal, bg = P.background },
  DiagnosticFloatingHint = { fg = P.green, bg = P.background },

  MiniFilesBorder = { fg = P.border, bg = "NONE" },
  MiniFilesTitle = { fg = P.green, bg = "NONE", bold = true },
  MiniFilesDirectory = { fg = P.teal, bg = "NONE" },
  MiniFilesFile = { fg = P.foreground, bg = "NONE" },
  MiniFilesNormal = { bg = "NONE" },
  MiniFilesCursorLine = { bg = P.background_visual },
  MiniNotifyBorder = { fg = P.border, bg = P.background },
  MiniNotifyNormal = { fg = P.foreground, bg = P.background },
  MiniNotifyTitle = { fg = P.green, bg = P.background, bold = true },
  MiniNotifyLspProgress = { fg = P.teal, bg = P.background },

  AlphaGreen = { fg = P.green },
  AlphaTeal = { fg = P.teal },
  AlphaYellow = { fg = P.yellow },
  AlphaRed = { fg = P.red },
  AlphaMuted = { fg = P.muted },
  AlphaBlue = { fg = P.teal },
  AlphaAqua = { fg = P.aqua },
  AlphaPurple = { fg = P.purple },
  AlphaOrange = { fg = P.orange },
}

function M.apply()
  for group, options in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, options)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("SoulColors", { clear = true })

  M.apply()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = M.apply,
  })
end

return M
