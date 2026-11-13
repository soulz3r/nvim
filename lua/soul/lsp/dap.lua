local M = {
	"mfussenegger/nvim-dap",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"rcarriga/nvim-dap-ui",
	},
	keys = {
		{ "<leader>dc", desc = "DAP: Start / continue" },
		{ "<leader>dr", desc = "DAP: Restart session" },
		{ "<leader>dk", desc = "DAP: Terminate session" },
		{ "<leader>dl", desc = "DAP: Run last configuration" },
		{ "<leader>dp", desc = "DAP: Select saved project" },
		{ "<leader>de", desc = "DAP: Set executable" },
		{ "<leader>dx", desc = "DAP: Toggle breakpoint" },
		{ "<leader>dB", desc = "DAP: Conditional breakpoint" },
		{ "<leader>dL", desc = "DAP: Logpoint" },
		{ "<leader>dX", desc = "DAP: Clear breakpoints" },
		{ "<leader>dK", desc = "DAP: List breakpoints" },
		{ "<leader>ds", desc = "DAP: Step over" },
		{ "<leader>di", desc = "DAP: Step into" },
		{ "<leader>do", desc = "DAP: Step out" },
		{ "<leader>dS", desc = "DAP: Step back" },
		{ "<leader>dP", desc = "DAP: Pause" },
		{ "<leader>dG", desc = "DAP: Run to cursor" },
		{ "<leader>dJ", desc = "DAP: Go to current line" },
		{ "<leader>dU", desc = "DAP: Older stack frame" },
		{ "<leader>dD", desc = "DAP: Newer stack frame" },
		{ "<leader>dF", desc = "DAP: Focus frame" },
		{ "<leader>dh", mode = { "n", "v" }, desc = "DAP: Evaluate expression" },
		{ "<leader>dR", desc = "DAP: Open / focus REPL" },
		{ "<leader>d/", desc = "DAP: Search REPL" },
		{ "<leader>dw", desc = "DAP: Add watch" },
		{ "<leader>du", desc = "DAP UI: Toggle" },
		{ "<leader>dt", desc = "DAP UI: Float element" },
		{ "<leader>d?", desc = "DAP: Show log" },
		{ "<F5>", desc = "DAP: Start / continue" },
		{ "<F9>", desc = "DAP: Toggle breakpoint" },
		{ "<F10>", desc = "DAP: Step over" },
		{ "<F11>", desc = "DAP: Step into" },
		{ "<F12>", desc = "DAP: Step out" },
	},
}

M.config = function()
	local dap = require("dap")
	local dapui = require("dapui")
	local dap_widgets = require("dap.ui.widgets")
	local paths = require("soul.core.helpers.paths")
	local platform = require("soul.core.platform")

	local projects = require("soul.core.helpers.dap.project").setup()
	local launch = require("soul.core.helpers.dap.launch").setup(
		dap,
		projects,
		require("soul.core.helpers.dap.args"),
		platform,
		paths
	)

	require("soul.core.helpers.dap.ui").setup(dap, dapui)
	require("soul.core.helpers.dap.keymaps").setup(dap, dapui, dap_widgets, launch, projects)
end

return M
