-- Optional startup profiler. Run with:
-- CVIM_CONFIG=/path/to/cvim CVIM_PROFILE_OUTPUT=/tmp/cvim-profile.tsv
-- nvim --headless -u scripts/profile-init.lua -c
--   'lua vim.wait(500, function() return vim.g.cvim_profile_done end, 10)' -c 'qa!'
local config = vim.env.CVIM_CONFIG
if not config or config == "" then
	error("CVIM_CONFIG must point to the CVIM checkout")
end

local output = vim.env.CVIM_PROFILE_OUTPUT
if not output or output == "" then
	error("CVIM_PROFILE_OUTPUT must specify the profile output file")
end

vim.opt.rtp:prepend(config)

local started_at = vim.uv.hrtime()
local original_require = require
local stack = {}
local records = {}
local unpack_values = table.unpack or unpack

local function pack(...)
	return { n = select("#", ...), ... }
end

local function record_time(name, elapsed, child_ms)
	local record = records[name]
	if not record then
		record = { calls = 0, inclusive_ms = 0, exclusive_ms = 0 }
		records[name] = record
	end

	record.calls = record.calls + 1
	record.inclusive_ms = record.inclusive_ms + elapsed
	record.exclusive_ms = record.exclusive_ms + math.max(0, elapsed - child_ms)
end

local function measure(name, callback, ...)
	local parent = stack[#stack]
	local frame = { child_ms = 0 }
	stack[#stack + 1] = frame

	local started = vim.uv.hrtime()
	local result = pack(pcall(callback, ...))
	local elapsed = (vim.uv.hrtime() - started) / 1e6

	stack[#stack] = nil
	if parent then
		parent.child_ms = parent.child_ms + elapsed
	end

	record_time(name, elapsed, frame.child_ms)

	if not result[1] then
		error(result[2], 0)
	end

	return unpack_values(result, 2, result.n)
end

local function instrument_module(name, module)
	if type(module) ~= "table" then
		return module
	end

	-- Lazy plugin setup runs after its specification module is imported.
	if name:match("^soul%.plugins%.") and type(module.config) == "function" then
		local callback = module.config
		module.config = function(...)
			return measure(name .. ".config()", callback, ...)
		end
	end

	-- Dashboard rendering is performed by builder functions after require().
	if name:match("^soul%.core%.helpers%.dashboard%.") then
		for key, callback in pairs(module) do
			if type(callback) == "function" then
				module[key] = function(...)
					return measure(name .. "." .. key .. "()", callback, ...)
				end
			end
		end
	end

	return module
end

_G.require = function(name)
	if type(name) ~= "string" or package.loaded[name] ~= nil then
		return original_require(name)
	end

	local parent = stack[#stack]
	local frame = { child_ms = 0 }
	stack[#stack + 1] = frame

	local started = vim.uv.hrtime()
	local ok, result = pcall(original_require, name)
	local elapsed = (vim.uv.hrtime() - started) / 1e6

	stack[#stack] = nil
	if parent then
		parent.child_ms = parent.child_ms + elapsed
	end

	record_time(name, elapsed, frame.child_ms)

	if not ok then
		error(result, 0)
	end

	return instrument_module(name, result)
end

local ok, err = pcall(dofile, config .. "/init.lua")
if not ok then
	error(err)
end
if vim.g.cvim_config_loaded ~= true then
	error("CVIM init.lua did not finish loading")
end

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		vim.schedule(function()
			local rows = {}
			for name, record in pairs(records) do
				rows[#rows + 1] = {
					name = name,
					calls = record.calls,
					inclusive_ms = record.inclusive_ms,
					exclusive_ms = record.exclusive_ms,
				}
			end

			table.sort(rows, function(left, right)
				return left.exclusive_ms > right.exclusive_ms
			end)

			local lines = {
				"CVIM STARTUP MODULE PROFILE",
				("Elapsed through VimEnter: %.3f ms"):format((vim.uv.hrtime() - started_at) / 1e6),
				"Alpha dashboard ready: " .. tostring(vim.g.cvim_alpha_ready == true),
				"Includes first require() costs and measured setup/build callbacks.",
				"Exclusive time subtracts nested module loads and measured calls.",
				"",
				"exclusive_ms\tinclusive_ms\tcalls\toperation",
			}

			for _, row in ipairs(rows) do
				lines[#lines + 1] = ("%.3f\t%.3f\t%d\t%s"):format(
					row.exclusive_ms,
					row.inclusive_ms,
					row.calls,
					row.name
				)
			end

			vim.fn.writefile(lines, output)
			vim.g.cvim_profile_done = true
		end)
	end,
})
