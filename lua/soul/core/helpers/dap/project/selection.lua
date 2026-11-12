local M = {}

local fn = vim.fn

function M.setup(store, resolver, path)
	local function select_project()
		local current_key = path.key(resolver.resolve())
		local projects = store.list()
		local entries = {}

		for key, entry in pairs(projects) do
			if type(entry) == "table" and entry.root then
				entries[#entries + 1] = {
					key = key,
					root = entry.root,
					executable = entry.executable or "",
				}
			end
		end

		table.sort(entries, function(a, b)
			return a.root:lower() < b.root:lower()
		end)

		if #entries == 0 then
			vim.notify("No saved DAP projects were found.", vim.log.levels.WARN)
			return
		end

		local choices = {}
		for _, entry in ipairs(entries) do
			choices[#choices + 1] = entry.root .. (entry.key == current_key and " [active]" or "")
		end

		vim.ui.select(choices, {
			prompt = "Select saved DAP project",
		}, function(_, index)
			if not index then
				return
			end

			local entry = entries[index]
			if fn.isdirectory(entry.root) ~= 1 then
				vim.notify("Project directory does not exist:\n" .. entry.root, vim.log.levels.ERROR)
				return
			end

			resolver.select(entry.root)

			local touched, saved = store.touch(entry.root)
			if not touched or saved ~= true then
				vim.notify(
					"Changed project directory, but could not update its last-opened metadata.",
					vim.log.levels.WARN
				)
			end

			vim.notify(
				"Selected project:\n"
					.. entry.root
					.. "\nExecutable: "
					.. (entry.executable ~= "" and entry.executable or "Not configured"),
				vim.log.levels.INFO,
				{ title = "DAP" }
			)
		end)
	end

	local function select_executable()
		local entry, root = store.current(resolver.resolve())
		if not entry or not root then
			vim.notify("Could not resolve the current project's root.", vim.log.levels.ERROR)
			return
		end

		vim.ui.input({
			prompt = "Full executable path: ",
			default = entry.executable or "",
			completion = "file",
		}, function(input)
			if not input or input == "" then
				return
			end

			input = input:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
			local executable = path.normalize(input)
			if not path.is_executable(executable) then
				vim.notify("Executable not found:\n" .. tostring(executable), vim.log.levels.ERROR)
				return
			end

			if not store.save_executable(root, executable) then
				return
			end
			vim.notify("Executable saved for:\n" .. root .. "\n" .. executable, vim.log.levels.INFO, { title = "DAP" })
		end)
	end

	return {
		select_project = select_project,
		select_executable = select_executable,
	}
end

return M
