local M = {
	"mfussenegger/nvim-dap",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"rcarriga/nvim-dap-ui",
	},
	keys = {
		{ "<leader>dc", function() require("soul.core.helpers.dap.keymaps").run("<leader>dc") end, desc = "DAP: Start / continue" },
		{ "<leader>dr", function() require("soul.core.helpers.dap.keymaps").run("<leader>dr") end, desc = "DAP: Restart session" },
		{ "<leader>dk", function() require("soul.core.helpers.dap.keymaps").run("<leader>dk") end, desc = "DAP: Terminate session" },
		{ "<leader>dl", function() require("soul.core.helpers.dap.keymaps").run("<leader>dl") end, desc = "DAP: Run last configuration" },
		{ "<leader>dp", function() require("soul.core.helpers.dap.keymaps").run("<leader>dp") end, desc = "DAP: Select saved project" },
		{ "<leader>de", function() require("soul.core.helpers.dap.keymaps").run("<leader>de") end, desc = "DAP: Set executable" },
		{ "<leader>dx", function() require("soul.core.helpers.dap.keymaps").run("<leader>dx") end, desc = "DAP: Toggle breakpoint" },
		{ "<leader>dB", function() require("soul.core.helpers.dap.keymaps").run("<leader>dB") end, desc = "DAP: Conditional breakpoint" },
		{ "<leader>dL", function() require("soul.core.helpers.dap.keymaps").run("<leader>dL") end, desc = "DAP: Logpoint" },
		{ "<leader>dX", function() require("soul.core.helpers.dap.keymaps").run("<leader>dX") end, desc = "DAP: Clear breakpoints" },
		{ "<leader>dK", function() require("soul.core.helpers.dap.keymaps").run("<leader>dK") end, desc = "DAP: List breakpoints" },
		{ "<leader>ds", function() require("soul.core.helpers.dap.keymaps").run("<leader>ds") end, desc = "DAP: Step over" },
		{ "<leader>di", function() require("soul.core.helpers.dap.keymaps").run("<leader>di") end, desc = "DAP: Step into" },
		{ "<leader>do", function() require("soul.core.helpers.dap.keymaps").run("<leader>do") end, desc = "DAP: Step out" },
		{ "<leader>dS", function() require("soul.core.helpers.dap.keymaps").run("<leader>dS") end, desc = "DAP: Step back" },
		{ "<leader>dP", function() require("soul.core.helpers.dap.keymaps").run("<leader>dP") end, desc = "DAP: Pause" },
		{ "<leader>dG", function() require("soul.core.helpers.dap.keymaps").run("<leader>dG") end, desc = "DAP: Run to cursor" },
		{ "<leader>dJ", function() require("soul.core.helpers.dap.keymaps").run("<leader>dJ") end, desc = "DAP: Go to current line" },
		{ "<leader>dU", function() require("soul.core.helpers.dap.keymaps").run("<leader>dU") end, desc = "DAP: Older stack frame" },
		{ "<leader>dD", function() require("soul.core.helpers.dap.keymaps").run("<leader>dD") end, desc = "DAP: Newer stack frame" },
		{ "<leader>dF", function() require("soul.core.helpers.dap.keymaps").run("<leader>dF") end, desc = "DAP: Focus frame" },
		{ "<leader>dh", function() require("soul.core.helpers.dap.keymaps").run("<leader>dh") end, mode = { "n", "v" }, desc = "DAP: Evaluate expression" },
		{ "<leader>dR", function() require("soul.core.helpers.dap.keymaps").run("<leader>dR") end, desc = "DAP: Open / focus REPL" },
		{ "<leader>d/", function() require("soul.core.helpers.dap.keymaps").run("<leader>d/") end, desc = "DAP: Search REPL" },
		{ "<leader>dw", function() require("soul.core.helpers.dap.keymaps").run("<leader>dw") end, desc = "DAP: Add watch" },
		{ "<leader>du", function() require("soul.core.helpers.dap.keymaps").run("<leader>du") end, desc = "DAP UI: Toggle" },
		{ "<leader>dt", function() require("soul.core.helpers.dap.keymaps").run("<leader>dt") end, desc = "DAP UI: Float element" },
		{ "<leader>d?", function() require("soul.core.helpers.dap.keymaps").run("<leader>d?") end, desc = "DAP: Show log" },
		{ "<F5>", function() require("soul.core.helpers.dap.keymaps").run("<F5>") end, desc = "DAP: Start / continue" },
		{ "<F9>", function() require("soul.core.helpers.dap.keymaps").run("<F9>") end, desc = "DAP: Toggle breakpoint" },
		{ "<F10>", function() require("soul.core.helpers.dap.keymaps").run("<F10>") end, desc = "DAP: Step over" },
		{ "<F11>", function() require("soul.core.helpers.dap.keymaps").run("<F11>") end, desc = "DAP: Step into" },
		{ "<F12>", function() require("soul.core.helpers.dap.keymaps").run("<F12>") end, desc = "DAP: Step out" },
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
