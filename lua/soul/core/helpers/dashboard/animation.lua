local Scope = require("soul.core.lifecycle.scope")
local FrameProfile = require("soul.core.performance.animation")

local M = {}

-- One-shot libuv timer: the next frame is scheduled only after the current
-- frame has completed, so slow redraws never accumulate queued timer ticks.
function M.new(opts)
	assert(type(opts) == "table", "animation options must be a table")
	assert(type(opts.on_tick) == "function", "animation requires on_tick")
	assert(type(opts.is_active) == "function", "animation requires is_active")

	local interval = math.max(1, math.floor(tonumber(opts.interval) or 150))
	local scope = Scope.new()
	local timer = scope:timer()
	local running = false
	local generation = 0

	local function stop()
		running = false
		generation = generation + 1

		if not scope:is_closed() then
			timer:stop()
		end
	end

	local function close()
		stop()
		scope:close()
	end

	local function fail(message)
		stop()
		pcall(vim.notify, message, vim.log.levels.WARN, {
			title = "Dashboard",
		})
	end

	local function schedule_tick(token)
		if not running or token ~= generation or scope:is_closed() then
			return
		end

		local ok, err = pcall(timer.start, timer, interval, 0, function()
			vim.schedule(function()
				if not running or token ~= generation or scope:is_closed() then
					return
				end

				local frame_started = FrameProfile.enabled and vim.uv.hrtime() or nil
				local activity_started = FrameProfile.enabled and vim.uv.hrtime() or nil
				local active_ok, active = pcall(opts.is_active)
				if activity_started then
					FrameProfile.record("animation.activity", (vim.uv.hrtime() - activity_started) / 1e6)
				end
				if not active_ok then
					return fail("Animation activity check failed: " .. tostring(active))
				end
				if not active then
					return stop()
				end

				local tick_started = FrameProfile.enabled and vim.uv.hrtime() or nil
				local tick_ok, tick_error = pcall(opts.on_tick)
				if tick_started then
					FrameProfile.record("animation.update", (vim.uv.hrtime() - tick_started) / 1e6)
				end
				if not tick_ok then
					return fail("Animation stopped: " .. tostring(tick_error))
				end

				if opts.redraw then
					local redraw_started = FrameProfile.enabled and vim.uv.hrtime() or nil
					local redraw_ok, redraw_error = pcall(opts.redraw)
					if redraw_started then
						FrameProfile.record("animation.redraw", (vim.uv.hrtime() - redraw_started) / 1e6)
					end
					if not redraw_ok then
						return fail("Animation redraw failed: " .. tostring(redraw_error))
					end
				end

				if frame_started then
					FrameProfile.record("animation.frame", (vim.uv.hrtime() - frame_started) / 1e6)
				end

				schedule_tick(token)
			end)
		end)

		if not ok then
			fail("Animation timer failed: " .. tostring(err))
		end
	end

	local function start()
		if running or scope:is_closed() then
			return
		end

		running = true
		generation = generation + 1
		schedule_tick(generation)
	end

	return {
		start = start,
		stop = stop,
		close = close,
		is_running = function()
			return running
		end,
	}
end

return M
