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

	-- tiny-cmdline.nvim
	TinyCmdlineNormal = { fg = P.foreground, bg = "NONE" },
	TinyCmdlineBorder = { fg = P.border, bg = "NONE" },
	TinyCmdlineTitle = { fg = P.green, bg = "NONE", bold = true },
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

	WhichKeyNormal = { fg = P.foreground, bg = "NONE" },
	WhichKeyBorder = { fg = P.border, bg = "NONE" },
	WhichKeyTitle = { fg = P.green, bg = "NONE", bold = true },
	WhichKeyDesc = { fg = P.foreground },
	WhichKeyGroup = { fg = P.teal, bold = true },
	WhichKeySeparator = { fg = P.border },
	WhichKeyValue = { fg = P.muted },

	TelescopeNormal = { fg = P.foreground, bg = "NONE" },
	TelescopeBorder = { fg = P.border, bg = "NONE" },
	TelescopeTitle = { fg = P.green, bg = "NONE", bold = true },
	TelescopePromptNormal = { fg = P.foreground, bg = "NONE" },
	TelescopePromptBorder = { fg = P.border, bg = "NONE" },
	TelescopePromptTitle = { fg = P.green, bg = "NONE", bold = true },
	TelescopeResultsNormal = { fg = P.foreground, bg = "NONE" },
	TelescopeResultsBorder = { fg = P.border, bg = "NONE" },
	TelescopeResultsTitle = { fg = P.green, bg = "NONE", bold = true },
	TelescopePreviewNormal = { fg = P.foreground, bg = "NONE" },
	TelescopePreviewBorder = { fg = P.border, bg = "NONE" },
	TelescopePreviewTitle = { fg = P.green, bg = "NONE", bold = true },
	TelescopeSelection = { fg = P.green, bg = P.background_visual, bold = true },
	TelescopeSelectionCaret = { fg = P.green, bg = P.background_visual },
	TelescopeMatching = { fg = P.green, bold = true },

	BlinkCmpMenu = { fg = P.foreground, bg = "NONE" },
	BlinkCmpMenuBorder = { fg = P.border, bg = "NONE" },
	BlinkCmpMenuSelection = { fg = P.green, bg = P.background_visual, bold = true },
	BlinkCmpDoc = { fg = P.foreground, bg = "NONE" },
	BlinkCmpDocBorder = { fg = P.border, bg = "NONE" },
	BlinkCmpSignatureHelp = { fg = P.foreground, bg = "NONE" },
	BlinkCmpSignatureHelpBorder = { fg = P.border, bg = "NONE" },

	LspInfoBorder = { fg = P.border, bg = "NONE" },
	DiagnosticFloating = { fg = P.foreground, bg = "NONE" },
	DiagnosticFloatingError = { fg = P.red, bg = "NONE" },
	DiagnosticFloatingWarn = { fg = P.yellow, bg = "NONE" },
	DiagnosticFloatingInfo = { fg = P.teal, bg = "NONE" },
	DiagnosticFloatingHint = { fg = P.green, bg = "NONE" },

	MiniFilesBorder = { fg = P.border, bg = "NONE" },
	MiniFilesTitle = { fg = P.green, bg = "NONE", bold = true },
	MiniFilesDirectory = { fg = P.teal, bg = "NONE" },
	MiniFilesFile = { fg = P.foreground, bg = "NONE" },
	MiniFilesNormal = { bg = "NONE" },
	MiniFilesCursorLine = { bg = P.background_visual },
	MiniNotifyBorder = { fg = P.border, bg = "NONE" },
	MiniNotifyNormal = { fg = P.foreground, bg = "NONE" },
	MiniNotifyTitle = { fg = P.green, bg = "NONE", bold = true },
	MiniNotifyLspProgress = { fg = P.teal, bg = "NONE" },

	AlphaGreen = { fg = P.green },
	AlphaTeal = { fg = P.teal },
	AlphaYellow = { fg = P.yellow },
	AlphaRed = { fg = P.red },
	AlphaMuted = { fg = P.muted },
	AlphaBlue = { fg = P.teal },
	AlphaAqua = { fg = P.aqua },
	AlphaPurple = { fg = P.purple },
	AlphaOrange = { fg = P.orange },

	-- Alpha dashboard animation: topic, prose, and C syntax roles.
	AlphaTopicPointers = { fg = P.green, bold = true },
	AlphaTopicDereference = { fg = P.purple, bold = true },
	AlphaTopicMemory = { fg = P.teal, bold = true },
	AlphaTopicCompilation = { fg = P.orange, bold = true },
	AlphaTopicRepresentations = { fg = P.aqua, bold = true },
	AlphaMessage = { fg = P.muted },
	AlphaMessageKey = { fg = P.yellow, bold = true },
	AlphaCodeType = { fg = P.teal },
	AlphaCodeKeyword = { fg = P.purple },
	AlphaCodeIdentifier = { fg = P.foreground },
	AlphaCodeNumber = { fg = P.yellow },
	AlphaCodeOperator = { fg = P.orange },
	AlphaCodePunctuation = { fg = P.muted },
	AlphaCodeFile = { fg = P.green },
	AlphaCodeStage = { fg = P.aqua },
	AlphaCodeCursor = { fg = P.red, bold = true },
	AlphaCodeText = { fg = P.foreground },
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
