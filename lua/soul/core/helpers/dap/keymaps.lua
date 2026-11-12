local M = {}

function M.setup(dap, dapui, dap_widgets, launch, projects)
	local function map(mode, lhs, callback, desc)
		vim.keymap.set(mode, lhs, callback, {
			noremap = true,
			silent = true,
			desc = desc,
		})
	end

	local function call_dap(name, ...)
		local callback = dap[name]
		if type(callback) ~= "function" then
			vim.notify("nvim-dap does not provide dap." .. name, vim.log.levels.ERROR)
			return
		end
		return callback(...)
	end

	local repl = require("soul.core.helpers.dap.repl").setup(dap)

	-- Session and project
	map("n", "<leader>dc", launch.start_or_continue, "DAP: Start / continue with arguments")
	map("n", "<leader>dr", function()
		if not dap.session() then
			vim.notify("No active debug session to restart.", vim.log.levels.WARN)
			return
		end
		call_dap("restart")
	end, "DAP: Restart session")
	map("n", "<leader>dk", function()
		if not dap.session() then
			vim.notify("No active debug session to kill.", vim.log.levels.WARN)
			return
		end
		call_dap("terminate")
	end, "DAP: Kill session")
	map("n", "<leader>dl", function()
		call_dap("run_last")
	end, "DAP: Run last configuration")
	map("n", "<leader>dp", projects.select, "DAP: Select saved project")
	map("n", "<leader>de", projects.select_executable, "DAP: Set executable")

	-- Breakpoints
	map("n", "<leader>dx", function()
		call_dap("toggle_breakpoint")
	end, "DAP: Toggle breakpoint")
	map("n", "<leader>dB", function()
		vim.ui.input({ prompt = "Breakpoint condition: " }, function(condition)
			if condition ~= nil then
				call_dap("set_breakpoint", condition ~= "" and condition or nil)
			end
		end)
	end, "DAP: Conditional breakpoint")
	map("n", "<leader>dL", function()
		vim.ui.input({ prompt = "Log message: " }, function(message)
			if message and message ~= "" then
				call_dap("set_breakpoint", nil, nil, message)
			end
		end)
	end, "DAP: Logpoint")
	map("n", "<leader>dX", function()
		call_dap("clear_breakpoints")
	end, "DAP: Clear all breakpoints")
	map("n", "<leader>dK", function()
		call_dap("list_breakpoints")
	end, "DAP: List breakpoints")

	-- Stepping and stack navigation
	map("n", "<leader>ds", function()
		call_dap("step_over")
	end, "DAP: Step over")
	map("n", "<leader>di", function()
		call_dap("step_into")
	end, "DAP: Step into")
	map("n", "<leader>do", function()
		call_dap("step_out")
	end, "DAP: Step out")
	map("n", "<leader>dS", function()
		call_dap("step_back")
	end, "DAP: Step back")
	map("n", "<leader>dP", function()
		call_dap("pause")
	end, "DAP: Pause")
	map("n", "<leader>dG", function()
		call_dap("run_to_cursor")
	end, "DAP: Run to cursor")
	map("n", "<leader>dJ", function()
		call_dap("goto_")
	end, "DAP: Go to current line")
	map("n", "<leader>dU", function()
		call_dap("up")
	end, "DAP: Older stack frame")
	map("n", "<leader>dD", function()
		call_dap("down")
	end, "DAP: Newer stack frame")
	map("n", "<leader>dF", function()
		call_dap("focus_frame")
	end, "DAP: Focus frame")

	-- Evaluation and REPL
	map({ "n", "v" }, "<leader>dh", function()
		dap_widgets.hover()
	end, "DAP: Evaluate expression")
	map("n", "<leader>dR", repl.open_or_focus, "DAP: Open or focus REPL")
	map("n", "<leader>d/", repl.search, "DAP: Search REPL")
	map("n", "<leader>dw", function()
		local watches = dapui.elements.watches
		if watches and type(watches.add) == "function" then
			watches.add()
		else
			vim.notify("Watch expressions are unavailable.", vim.log.levels.WARN)
		end
	end, "DAP: Add watch")

	-- UI and diagnostics
	map("n", "<leader>du", function()
		dapui.toggle()
	end, "DAP UI: Toggle")
	map("n", "<leader>dt", function()
		vim.ui.select({
			"scopes",
			"stacks",
			"watches",
			"breakpoints",
			"repl",
			"console",
		}, {
			prompt = "Open floating DAP element",
		}, function(element)
			if element then
				dapui.float_element(element, {})
			end
		end)
	end, "DAP UI: Float element")
	map("n", "<leader>d?", function()
		call_dap("show_log")
	end, "DAP: Show log")

	-- Standard debugger function keys
	map("n", "<F5>", launch.start_or_continue, "DAP: Start / continue with arguments")
	map("n", "<F9>", function()
		call_dap("toggle_breakpoint")
	end, "DAP: Toggle breakpoint")
	map("n", "<F10>", function()
		call_dap("step_over")
	end, "DAP: Step over")
	map("n", "<F11>", function()
		call_dap("step_into")
	end, "DAP: Step into")
	map("n", "<F12>", function()
		call_dap("step_out")
	end, "DAP: Step out")
end

return M
