local M = {}

function M.new()
	local cleanups = {}
	local closed = false

	local scope = {}

	function scope:add(cleanup)
		assert(type(cleanup) == "function", "cleanup must be a function")

		if closed then
			pcall(cleanup)
			return cleanup
		end

		cleanups[#cleanups + 1] = cleanup
		return cleanup
	end

	function scope:timer()
		assert(not closed, "cannot create resources in a closed scope")

		local timer = vim.uv.new_timer()
		if not timer then
			error("could not create libuv timer")
		end

		self:add(function()
			if not timer:is_closing() then
				timer:stop()
				timer:close()
			end
		end)

		return timer
	end

	function scope:augroup(name)
		assert(not closed, "cannot create resources in a closed scope")

		local group = vim.api.nvim_create_augroup(name, {
			clear = true,
		})

		self:add(function()
			pcall(vim.api.nvim_del_augroup_by_id, group)
		end)

		return group
	end

	function scope:close()
		if closed then
			return
		end

		closed = true

		for index = #cleanups, 1, -1 do
			pcall(cleanups[index])
			cleanups[index] = nil
		end
	end

	function scope:is_closed()
		return closed
	end

	return scope
end

return M
