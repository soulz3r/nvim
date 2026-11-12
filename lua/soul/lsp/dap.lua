local M = {
	"mfussenegger/nvim-dap",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"rcarriga/nvim-dap-ui",
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
