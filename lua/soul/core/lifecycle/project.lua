local M = {}

local function read_registry(path)
	if vim.fn.filereadable(path) ~= 1 then
		return nil
	end

	local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
	if not ok or type(data) ~= "table" then
		return nil
	end

	return data
end

function M.restore(path)
	local registry

	if path then
		registry = read_registry(path)
	else
		local state = vim.fn.stdpath("state")
		registry = read_registry(state .. "/yap/projects.json")
		if not registry then
			registry = read_registry(state .. "/soul/projects.json")
		end
	end

	if not registry then
		return false
	end

	local selected
	local selected_time = -1

	for _, entry in pairs(registry) do
		if type(entry) == "table" and type(entry.root) == "string" and entry.root ~= "" then
			local root = vim.fs.normalize(entry.root)
			local timestamp = tonumber(entry.last_opened or entry.updated_at) or 0

			if vim.fn.isdirectory(root) == 1 and timestamp > selected_time then
				selected = root
				selected_time = timestamp
			end
		end
	end

	if not selected then
		return false
	end

	local ok = pcall(vim.cmd.cd, vim.fn.fnameescape(selected))
	return ok
end

function M.setup()
	local group = vim.api.nvim_create_augroup("SoulProjectRestore", {
		clear = true,
	})

	vim.api.nvim_create_autocmd("VimEnter", {
		group = group,
		once = true,
		callback = function()
			-- Never override an explicit file or directory supplied by the user.
			if vim.fn.argc() ~= 0 then
				return
			end

			vim.schedule(M.restore)
		end,
	})
end

return M
