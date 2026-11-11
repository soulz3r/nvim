local M = {
	cmd = {
		"stylua",
		"--lsp",
	},

	filetypes = {
		"lua",
		"luau",
	},

	root_markers = {
		".stylua.toml",
		"stylua.toml",
		".git",
	},

	workspace_required = false,
}
return M
