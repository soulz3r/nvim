
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

				if vim.api.nvim_buf_is_valid(buf) and not vim.bo[buf].modifiable then
					has_readonly_float = true
					break
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

vim.api.nvim_create_autocmd({
	"BufWinEnter",
	"BufWinLeave",
	"WinEnter",
	"WinClosed",
}, {
	callback = schedule_float_statusline_update,
})

vim.api.nvim_create_autocmd("OptionSet", {
	pattern = "modifiable",
	callback = schedule_float_statusline_update,
})

vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  callback = function()
    vim.opt_local.formatoptions:remove({ "c", "r", "o" })
  end,
})



vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "netrw",
    "Jaq",
    "qf",
    "git",
    "help",
    "man",
    "lspinfo",
    "oil",
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

vim.api.nvim_create_autocmd("CmdWinEnter", {
  callback = function()
    vim.cmd("quit")
  end,
})

vim.api.nvim_create_autocmd({ "VimResized" }, {
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  pattern = { "!vim" },
  callback = function()
    vim.cmd("checktime")
  end,
})

vim.api.nvim_create_autocmd({ "TextYankPost" }, {
  callback = function()
    vim.hl.on_yank({ higroup = "Visual", timeout = 40 })
  end,
})

vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "gitcommit", "markdown", "NeogitCommitMessage" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = false
  end,
})
