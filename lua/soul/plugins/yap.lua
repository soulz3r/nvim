local M = {
	"soulz3r/yap.nvim",
	branch = "main",
	event = { "BufReadPre", "BufNewFile" },
	cmd = { "CProjectInfo", "CSwitchHeader" },
	keys = {
		{ "<leader>pp", function() require("soul.core.helpers.yap.keymaps").run("<leader>pp") end, desc = "Open YAP project picker" },
		{ "<leader>pr", function() require("soul.core.helpers.yap.keymaps").run("<leader>pr") end, desc = "Build and run current project" },
		{ "<leader>pb", function() require("soul.core.helpers.yap.keymaps").run("<leader>pb") end, desc = "Build current project" },
		{ "<leader>pc", function() require("soul.core.helpers.yap.keymaps").run("<leader>pc") end, desc = "Clean current project" },
		{ "<leader>pB", function() require("soul.core.helpers.yap.keymaps").run("<leader>pB") end, desc = "Clean and rebuild current project" },
		{ "<leader>pS", function() require("soul.core.helpers.yap.keymaps").run("<leader>pS") end, desc = "Select project build script" },
		{ "<leader>pe", function() require("soul.core.helpers.yap.keymaps").run("<leader>pe") end, desc = "Select project executable" },
		{ "<leader>ps", function() require("soul.core.helpers.yap.keymaps").run("<leader>ps") end, desc = "Stop project process" },
		{ "<leader>pR", function() require("soul.core.helpers.yap.keymaps").run("<leader>pR") end, desc = "Rerun last project executable" },
	},
	dependencies = {
		"nvim-telescope/telescope.nvim",
		"nvim-telescope/telescope-project.nvim",
	},
}

function M.config()
	local palette = require("soul.core.helpers.ui.colors").palette
	local existing_vim_enter = {}

	for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = "VimEnter" })) do
		if autocmd.id then
			existing_vim_enter[autocmd.id] = true
		end
	end

	local ok, err = pcall(function()
		require("yap").setup({
			projects_dir = require("soul.core.helpers.paths").projects,
			telescope = true,
			keymaps = false,
			highlights = {
				normal = { fg = palette.foreground, bg = "NONE" },
				border = { fg = palette.border, bg = "NONE" },
				title = { fg = palette.green, bg = "NONE", bold = true },
				section_title = { fg = palette.green, bold = true },
				muted = { fg = palette.muted },
				success = { fg = palette.green },
				warning = { fg = palette.yellow },
				error = { fg = palette.red },
			},
		})
		require("soul.core.helpers.yap.keymaps").setup()
	end)

	-- Core owns project restoration. Remove YAP's own VimEnter callback so a
	-- lazy-loaded YAP instance cannot leave a callback that can never run.
	for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = "VimEnter" })) do
		if autocmd.id and not existing_vim_enter[autocmd.id] then
			pcall(vim.api.nvim_del_autocmd, autocmd.id)
		end
	end

	if not ok then
		error(err)
	end
end

return M
