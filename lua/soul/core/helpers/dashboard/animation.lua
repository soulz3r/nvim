local M = {}

-- Generic timer-driven animation lifecycle.
-- The consumer owns frame data and decides what each tick does.
function M.new(opts)
	assert(type(opts) == "table", "animation options must be a table")
	assert(type(opts.on_tick) == "function", "animation requires on_tick")
	assert(type(opts.is_active) == "function", "animation requires is_active")

	local interval = opts.interval or 150
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

		if not opts.is_active() then
			stop()
			return
		end

		opts.on_tick()

		if opts.redraw then
			opts.redraw()
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
