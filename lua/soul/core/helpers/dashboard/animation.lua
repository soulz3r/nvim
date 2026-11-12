local M = {}

-- Generic timer-driven animation lifecycle.
-- The consumer owns frame data and decides what each tick does.
function M.new(opts)
	assert(type(opts) == "table", "animation options must be a table")
	assert(type(opts.on_tick) == "function", "animation requires on_tick")
	assert(type(opts.is_active) == "function", "animation requires is_active")

	local interval = math.max(1, math.floor(tonumber(opts.interval) or 150))
	local running = false
	local generation = 0

	local function stop()
		running = false
		generation = generation + 1
	end

	local function tick(token)
		if not running or token ~= generation then
			return
		end

		local active_ok, active = pcall(opts.is_active)
		if not active_ok or not active then
			stop()
			if not active_ok then
				pcall(vim.notify, "Animation activity check failed: " .. tostring(active), vim.log.levels.WARN, {
					title = "Dashboard",
				})
			end
			return
		end

		local tick_ok, tick_error = pcall(opts.on_tick)
		if not tick_ok then
			stop()
			pcall(vim.notify, "Animation stopped: " .. tostring(tick_error), vim.log.levels.WARN, {
				title = "Dashboard",
			})
			return
		end

		if opts.redraw then
			local redraw_ok, redraw_error = pcall(opts.redraw)
			if not redraw_ok then
				stop()
				pcall(vim.notify, "Animation redraw failed: " .. tostring(redraw_error), vim.log.levels.WARN, {
					title = "Dashboard",
				})
				return
			end
		end

		vim.defer_fn(function()
			tick(token)
		end, interval)
	end

	local function start()
		if running then
			return
		end

		running = true
		generation = generation + 1

		local token = generation
		vim.defer_fn(function()
			tick(token)
		end, interval)
	end

	return {
		start = start,
		stop = stop,
		is_running = function()
			return running
		end,
	}
end

return M
