local M = {
	"rachartier/tiny-cmdline.nvim",
	event = "VeryLazy",
	cond = vim.fn.has("nvim-0.12") == 1,
}

function M.config()
	vim.o.cmdheight = 0

	-- Enable Neovim's new UI2 system.
	local ui2 = require("vim._core.ui2")
	ui2.enable({
		msg = {
			targets = "cmd",
		},
	})

	-- Let UI2 deliver messages to MiniNotify instead of rendering them itself.
	local function notify_message(kind, content)
		local levels = {
			emsg = vim.log.levels.ERROR,
			echoerr = vim.log.levels.ERROR,
			rpc_error = vim.log.levels.ERROR,
			shell_err = vim.log.levels.WARN,
			wmsg = vim.log.levels.WARN,
		}

		local level = levels[kind] or vim.log.levels.INFO
		if level ~= vim.log.levels.ERROR and level ~= vim.log.levels.WARN then
			return
		end

		local message = table.concat(vim.tbl_map(function(chunk)
			return type(chunk) == "table" and tostring(chunk[2] or "") or tostring(chunk)
		end, content or ""))
		message = vim.trim(message)

		if message == "" then
			return
		end

		if message:find("W10", 1, true)
			or message:find("Changing a readonly file", 1, true)
		then
			message = "This buffer is read-only. Changes are disabled."
			level = vim.log.levels.WARN
		end

		vim.schedule(function()
			vim.notify(message, level, {
				title = level == vim.log.levels.ERROR and "NEOVIM ERROR" or "WARNING",
			})
		end)
	end

	-- UI2 owns the msg_show event callback. Wrapping that exact handler avoids
	-- competing vim.ui_attach subscribers and prevents UI2's own message float.
	ui2.msg.msg_show = function(kind, content)
		notify_message(kind, content)
	end

	local tiny_cmdline = require("tiny-cmdline")

	tiny_cmdline.setup({
		on_reposition = tiny_cmdline.adapters.blink,
		width = {
			value = "60%",
			min = 40,
			max = 100,
		},
		-- Keep search at the bottom (or remove this if you want search centered too)
		native_types = {},
	})
end

return M
