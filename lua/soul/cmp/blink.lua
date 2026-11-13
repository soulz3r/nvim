local M = {
	"saghen/blink.cmp",
	event = { "InsertEnter", "CmdlineEnter" },
	dependencies = { "rafamadriz/friendly-snippets" },
	version = "1.*",

	---@module 'blink.cmp'
	opts = {
		keymap = {
			preset = "default",
			["<C-b>"] = { "scroll_documentation_up", "fallback" },
			["<C-f>"] = { "scroll_documentation_down", "fallback" },
		},
		completion = {
			ghost_text = { enabled = false },
			menu = { border = "rounded" },
			documentation = {
				auto_show = true,
				window = { border = "rounded" },
			},
			accept = {
				auto_brackets = { enabled = true },
			},
			trigger = {
				show_on_keyword = true,
				show_on_trigger_character = true,
			},
		},
		appearance = {
			nerd_font_variant = "nerd",
		},
		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
		},
		cmdline = {
			completion = {
				menu = { auto_show = true },
			},
			sources = { "cmdline", "buffer" },
		},
		signature = {
			enabled = true,
			window = {
				border = "rounded",
				show_documentation = true,
			},
		},
		fuzzy = { implementation = "prefer_rust_with_warning" },
	},

	opts_extend = { "sources.default" },
}

local function set_bg(group, bg)
	local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
	highlight.bg = bg
	vim.api.nvim_set_hl(0, group, highlight)
end

function M.config(_, opts)
	require("blink.cmp").setup(opts)

	local palette = require("soul.core.helpers.ui.colors").palette

	set_bg("Pmenu", "none")
	set_bg("PmenuSel", "none")
	set_bg("NormalFloat", "none")
	set_bg("PmenuSbar", "none")
	set_bg("PmenuThumb", "none")

	set_bg("BlinkCmpMenu", "none")
	set_bg("BlinkCmpMenuBorder", "none")
	set_bg("BlinkCmpMenuSelection", palette.background_visual)

	set_bg("BlinkCmpDoc", "none")
	set_bg("BlinkCmpDocBorder", "none")
	set_bg("BlinkCmpSignatureHelp", "none")
	set_bg("BlinkCmpSignatureHelpBorder", "none")
end

return M
