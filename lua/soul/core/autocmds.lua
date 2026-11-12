local M = {}

local statusline_laststatus
local statusline_update_pending = false

local function update_float_statusline()
	statusline_update_pending = false

	local has_readonly_float = false

	for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
			local config = vim.api.nvim_win_get_config(win)

			if config.relative ~= "" then
				local buf = vim.api.nvim_win_get_buf(win)

				if vim.api.nvim_buf_is_valid(buf) then
					local is_minifiles = vim.bo[buf].filetype == "minifiles"
					local is_readonly = not vim.bo[buf].modifiable

					if is_minifiles or is_readonly then
						has_readonly_float = true
						break
					end
				end
			end
		end

		if has_readonly_float then
			break
		end
	end

	if has_readonly_float and statusline_laststatus == nil then
		statusline_laststatus = vim.o.laststatus
		vim.o.laststatus = 0
	elseif not has_readonly_float and statusline_laststatus ~= nil then
		vim.o.laststatus = statusline_laststatus
		statusline_laststatus = nil
	end
end

local function schedule_float_statusline_update()
	if statusline_update_pending then
		return
	end

	statusline_update_pending = true
	vim.schedule(update_float_statusline)
end

local group = vim.api.nvim_create_augroup("SoulCore", {
	clear = true,
})

vim.api.nvim_create_autocmd({
	"BufWinEnter",
	"BufWinLeave",
	"WinEnter",
	"WinClosed",
}, {
	group = group,
	callback = schedule_float_statusline_update,
})

vim.api.nvim_create_autocmd("OptionSet", {
	group = group,
	pattern = "modifiable",
	callback = schedule_float_statusline_update,
})

vim.api.nvim_create_autocmd("User", {
	group = group,
	pattern = { "MiniFilesExplorerOpen", "MiniFilesExplorerClose" },
	callback = schedule_float_statusline_update,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
	group = group,
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = {
		"netrw",
		"Jaq",
		"qf",
		"git",
		"help",
		"man",
		"lspinfo",
		"spectre_panel",
		"lir",
		"DressingSelect",
		"tsplayground",
		"mininotify-history",
	},
	callback = function(args)
		vim.bo[args.buf].buflisted = false

		vim.keymap.set("n", "q", function()
			pcall(vim.cmd, "close")
		end, {
			buffer = args.buf,
			silent = true,
			desc = "Close utility window",
		})
	end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
	group = group,
	callback = function(args)
		-- Only check ordinary file buffers; special/plugin buffers have no
		-- external file timestamp to refresh.
		if vim.bo[args.buf].buftype == "" then
			vim.cmd.checktime()
		end
	end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
	group = group,
	callback = function()
		vim.hl.on_yank({ higroup = "Visual", timeout = 40 })
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = { "gitcommit", "markdown", "NeogitCommitMessage" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.spell = false
	end,
})

return M
