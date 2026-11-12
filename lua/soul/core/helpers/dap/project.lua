local M = {}

function M.setup(project_registry)
	local path = require("soul.core.helpers.dap.path")
	local store = require("soul.core.helpers.dap.project.store").setup(path, project_registry)
	local resolver = require("soul.core.helpers.dap.project.resolver").setup(path, store.find_registered_ancestor)
	local selection = require("soul.core.helpers.dap.project.selection").setup(store, resolver, path)

	local function current()
		local root = resolver.resolve()
		if not root then
			return nil, nil
		end
		return store.current(root)
	end

	return {
		current = current,
		resolve_root = resolver.resolve,
		select = selection.select_project,
		select_executable = selection.select_executable,
		save_executable = store.save_executable,
		save_args = store.save_args,
		find_executables = require("soul.core.helpers.dap.executables").find,
		is_executable = path.is_executable,
	}
end

return M
