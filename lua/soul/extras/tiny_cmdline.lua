-- UI2 is experimental and lives under Neovim's private namespace.
-- Keep this integration optional; the native command line is the fallback.
local function get_ui2()
	if vim.fn.has("nvim-0.12") ~= 1 then
		return nil
	end

	local ok, ui2 = pcall(require, "vim._core.ui2")
	if not ok or type(ui2) ~= "table" or type(ui2.enable) ~= "function" then
		return nil
	end

	return ui2
end

local M = {
	"rachartier/tiny-cmdline.nvim",
	event = "VeryLazy",
	dependencies = { "saghen/blink.cmp" },
	cond = function()
		return get_ui2() ~= nil
	end,
}

function M.config()
	local ui2 = get_ui2()
	if not ui2 then
		vim.o.cmdheight = 1
		return
	end

	local original_msg_show
	local ok, err = pcall(function()
		vim.o.cmdheight = 0

		ui2.enable({
			msg = {
				targets = "cmd",
			},
		})

		if type(ui2.msg) ~= "table" then
			error("Neovim UI2 message handlers are unavailable")
		end

		-- UI2's message handler is private API. Keep the override local to this
		-- optional module so the rest of the configuration never depends on it.
		local function notify_message(kind, content)
			local levels = {
				emsg = vim.log.levels.ERROR,
				lua_error = vim.log.levels.ERROR,
				echoerr = vim.log.levels.ERROR,
				rpc_error = vim.log.levels.ERROR,
				shell_err = vim.log.levels.WARN,
				wmsg = vim.log.levels.WARN,
			}

			local level = levels[kind] or vim.log.levels.INFO
			if level ~= vim.log.levels.ERROR and level ~= vim.log.levels.WARN then
				return
			end

			local message
			if type(content) == "table" then
				message = table.concat(vim.tbl_map(function(chunk)
					return type(chunk) == "table" and tostring(chunk[2] or "") or tostring(chunk)
				end, content))
			else
				message = tostring(content or "")
			end
			message = vim.trim(message)

			if message == "" then
				return
			end

			if message:find("W10", 1, true) or message:find("Changing a readonly file", 1, true) then
				message = "This buffer is read-only. Changes are disabled."
				level = vim.log.levels.WARN
			end

			vim.schedule(function()
				vim.notify(message, level, {
					title = level == vim.log.levels.ERROR and "NEOVIM ERROR" or "WARNING",
				})
			end)
		end

		original_msg_show = ui2.msg.msg_show
		ui2.msg.msg_show = notify_message

		local tiny_cmdline = require("tiny-cmdline")
		tiny_cmdline.setup({
			on_reposition = tiny_cmdline.adapters.blink,
			width = {
				value = "60%",
				min = 40,
				max = 100,
			},
			native_types = {},
		})
	end)

	if not ok then
		if type(ui2.msg) == "table" then
			ui2.msg.msg_show = original_msg_show
		end
		vim.o.cmdheight = 1
		vim.notify(
			"tiny-cmdline/UI2 is unavailable; using Neovim's native command line.\n" .. tostring(err),
			vim.log.levels.WARN
		)
	end
end

return M
