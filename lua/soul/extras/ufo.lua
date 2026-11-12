local M = {
	"kevinhwang91/nvim-ufo",
	dependencies = {
		"kevinhwang91/promise-async",
		"luukvbaal/statuscol.nvim",
	},
}

function M.config()
	local builtin = require("statuscol.builtin")

	require("statuscol").setup({
		setopt = true,
		relculright = true,
		segments = {
			{ text = { builtin.foldfunc, " " }, click = "v:lua.ScFa", hl = "Comment" },
			{ text = { "%s" }, click = "v:lua.ScSa" },
			{ text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
		},
	})

	vim.o.foldcolumn = "1"
	vim.o.foldlevel = 99
	vim.o.foldlevelstart = 99
	vim.o.foldenable = true
	vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

	local handler = function(virtText, lnum, endLnum, width, truncate)
		local newVirtText = {}
		local suffix = (" 󰡏 %d "):format(endLnum - lnum)
		local sufWidth = vim.fn.strdisplaywidth(suffix)

		if sufWidth > width then
			suffix = truncate(suffix, width)
			sufWidth = vim.fn.strdisplaywidth(suffix)
		end

		local targetWidth = math.max(0, width - sufWidth)
		local curWidth = 0

		for _, chunk in ipairs(virtText) do
			local chunkText = chunk[1]
			local chunkWidth = vim.fn.strdisplaywidth(chunkText)

			if targetWidth > curWidth + chunkWidth then
				table.insert(newVirtText, chunk)
			else
				local remaining = math.max(0, targetWidth - curWidth)
				chunkText = remaining > 0 and truncate(chunkText, remaining) or ""
				local hlGroup = chunk[2]

				if chunkText ~= "" then
					table.insert(newVirtText, { chunkText, hlGroup })
				end

				chunkWidth = vim.fn.strdisplaywidth(chunkText)

				if curWidth + chunkWidth < targetWidth then
					suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
				end
				break
			end

			curWidth = curWidth + chunkWidth
		end

		table.insert(newVirtText, { suffix, "MoreMsg" })
		return newVirtText
	end

	require("ufo").setup({
		fold_virt_text_handler = handler,
		close_fold_kinds = {},
		provider_selector = function()
			return { "treesitter", "indent" }
		end,
		preview = {
			win_config = {
				border = { "", "─", "", "", "", "─", "", "" },
				winhighlight = "Normal:Folded",
				winblend = 0,
			},
			mappings = {
				scrollU = "<C-k>",
				scrollD = "<C-j>",
				jumpTop = "[",
				jumpBot = "]",
			},
		},
	})

	vim.keymap.set("n", "zR", require("ufo").openAllFolds, { desc = "Open all folds" })
	vim.keymap.set("n", "zM", require("ufo").closeAllFolds, { desc = "Close all folds" })
	vim.keymap.set("n", "zr", require("ufo").openFoldsExceptKinds, { desc = "Open folds except kinds" })
	vim.keymap.set("n", "zm", require("ufo").closeFoldsWith, { desc = "Close folds with" })

	vim.keymap.set("n", "K", function()
		local winid = require("ufo").peekFoldedLinesUnderCursor()
		if not winid then
			vim.lsp.buf.hover()
		end
	end, { desc = "Peek fold or show LSP hover" })
end

return M
