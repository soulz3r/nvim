local M = {
	"saghen/blink.cmp",
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

function M.config(_, opts)
	require("blink.cmp").setup(opts)

	local palette = require("soul.core.helpers.ui.colors").palette

	vim.api.nvim_set_hl(0, "Pmenu", { bg = "none" })
	vim.api.nvim_set_hl(0, "PmenuSel", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
	vim.api.nvim_set_hl(0, "PmenuSbar", { bg = "none" })
	vim.api.nvim_set_hl(0, "PmenuThumb", { bg = "none" })

	vim.api.nvim_set_hl(0, "BlinkCmpMenu", { bg = "none" })
	vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { bg = "none" })
	vim.api.nvim_set_hl(0, "BlinkCmpMenuSelection", {
		bg = palette.background_visual,
	})

	vim.api.nvim_set_hl(0, "BlinkCmpDoc", { bg = "none" })
	vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { bg = "none" })
	vim.api.nvim_set_hl(0, "BlinkCmpSignatureHelp", { bg = "none" })
	vim.api.nvim_set_hl(0, "BlinkCmpSignatureHelpBorder", { bg = "none" })
end

return M
