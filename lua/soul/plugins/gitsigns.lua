local M = {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPost", "BufNewFile" },
	cmd = "Gitsigns",
	keys = {
		{
			"ih",
			function()
				require("gitsigns").select_hunk()
			end,
			mode = { "o", "x" },
			desc = "Select Git hunk",
		},
		{
			"<leader>gj",
			"<cmd>lua require('gitsigns').next_hunk({ navigation_message = false })<CR>",
			desc = "Next Hunk",
		},
		{
			"<leader>gk",
			"<cmd>lua require('gitsigns').prev_hunk({ navigation_message = false })<CR>",
			desc = "Prev Hunk",
		},
		{ "<leader>gp", "<cmd>lua require('gitsigns').preview_hunk()<CR>", desc = "Preview Hunk" },
		{ "<leader>gr", "<cmd>lua require('gitsigns').reset_hunk()<CR>", desc = "Reset Hunk" },
		{ "<leader>gl", "<cmd>lua require('gitsigns').blame_line()<CR>", desc = "Blame" },
		{ "<leader>gR", "<cmd>lua require('gitsigns').reset_buffer()<CR>", desc = "Reset Buffer" },
		{ "<leader>gs", "<cmd>lua require('gitsigns').stage_hunk()<CR>", desc = "Stage Hunk" },
		{ "<leader>gu", "<cmd>lua require('gitsigns').undo_stage_hunk()<CR>", desc = "Undo Stage Hunk" },
		{ "<leader>gd", "<cmd>Gitsigns diffthis HEAD<CR>", desc = "Git Diff" },
	},
}

function M.config()
	local icons = require("soul.core.helpers.icons")

	require("gitsigns").setup({
		signs = {
			add = {
				text = icons.ui.BoldLineMiddle,
			},
			change = {
				text = icons.ui.BoldLineDashedMiddle,
			},
			delete = {
				text = icons.ui.TriangleShortArrowRight,
			},
			topdelete = {
				text = icons.ui.TriangleShortArrowRight,
			},
			changedelete = {
				text = icons.ui.BoldLineMiddle,
			},
		},
		watch_gitdir = {
			interval = 1000,
			follow_files = true,
		},
		attach_to_untracked = true,
		current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
		update_debounce = 200,
		max_file_length = 40000,
		preview_config = {
			border = "rounded",
			style = "minimal",
			relative = "cursor",
			row = 0,
			col = 1,
		},
	})
end

return M
