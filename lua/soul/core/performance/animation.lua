-- Opt-in dashboard frame profiler. Disabled unless the environment variable
-- CVIM_ANIMATION_PROFILE=1 is set before Neovim starts.
local M = {
	enabled = vim.env.CVIM_ANIMATION_PROFILE == "1",
}

local SAMPLE_LIMIT = 4096
local records = {}

local function percentile(samples, fraction)
	local ordered = vim.deepcopy(samples)
	table.sort(ordered)
	local index = math.max(1, math.ceil(#ordered * fraction))
	return ordered[index]
end

function M.record(name, elapsed_ms)
	if not M.enabled then
		return
	end

	local record = records[name]
	if not record then
		record = {
			count = 0,
			total_ms = 0,
			min_ms = math.huge,
			max_ms = 0,
			samples = {},
			next_sample = 1,
		}
		records[name] = record
	end

	record.count = record.count + 1
	record.total_ms = record.total_ms + elapsed_ms
	record.min_ms = math.min(record.min_ms, elapsed_ms)
	record.max_ms = math.max(record.max_ms, elapsed_ms)

	if #record.samples < SAMPLE_LIMIT then
		record.samples[#record.samples + 1] = elapsed_ms
	else
		record.samples[record.next_sample] = elapsed_ms
		record.next_sample = record.next_sample % SAMPLE_LIMIT + 1
	end
end

function M.reset()
	records = {}
end

function M.report()
	if not M.enabled then
		return "Animation profiling is disabled. Set CVIM_ANIMATION_PROFILE=1 before starting Neovim."
	end

	local rows = {}
	for name, record in pairs(records) do
		local samples = record.samples
		rows[#rows + 1] = {
			name = name,
			count = record.count,
			average = record.total_ms / record.count,
			median = percentile(samples, 0.50),
			p95 = percentile(samples, 0.95),
			minimum = record.min_ms,
			maximum = record.max_ms,
		}
	end

	if #rows == 0 then
		return "No dashboard animation samples recorded yet."
	end

	table.sort(rows, function(left, right)
		return left.p95 > right.p95
	end)

	local lines = {
		"CVIM DASHBOARD FRAME PROFILE",
		"Times are milliseconds. P95 is the 95th-percentile sample.",
		"",
		("Total samples are counted; percentiles use the latest %d samples."):format(SAMPLE_LIMIT),
		"",
		("  %-22s %8s %9s %9s %9s %9s %9s"):format("operation", "samples", "average", "median", "p95", "min", "max"),
	}

	for _, row in ipairs(rows) do
		lines[#lines + 1] = ("  %-22s %8d %9.3f %9.3f %9.3f %9.3f %9.3f"):format(
			row.name,
			row.count,
			row.average,
			row.median,
			row.p95,
			row.minimum,
			row.maximum
		)
	end

	return table.concat(lines, "\n")
end

function M.setup()
	if not M.enabled then
		return
	end

	if vim.fn.exists(":CvimAnimationProfile") == 0 then
		vim.api.nvim_create_user_command("CvimAnimationProfile", function()
			vim.api.nvim_echo({ { M.report(), "Normal" } }, true, {})
		end, {
			desc = "Show dashboard animation frame timings",
		})
	end

	if vim.fn.exists(":CvimAnimationProfileReset") == 0 then
		vim.api.nvim_create_user_command("CvimAnimationProfileReset", function()
			M.reset()
			vim.notify("Dashboard animation profile reset", vim.log.levels.INFO, {
				title = "CVIM",
			})
		end, {
			desc = "Reset dashboard animation frame timings",
		})
	end
end

return M
