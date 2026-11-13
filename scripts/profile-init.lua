-- Optional startup profiler. Run with:
-- CVIM_CONFIG=/path/to/cvim CVIM_PROFILE_OUTPUT=/tmp/cvim-profile.tsv
-- nvim --headless -u scripts/profile-init.lua
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

local function instrument_config(name, spec)
	if type(spec) ~= "table" then
		return
	end

	-- Plugin modules may expose metatables that throw on unknown fields.
	-- Inspect the raw plugin spec so profiling does not trigger those lookups.
	local callback = rawget(spec, "config")
	if type(callback) ~= "function" then
		return
	end

	spec.config = function(...)
		return measure(name .. ".config()", callback, ...)
	end
end

local function instrument_method(module, key, label)
	local callback = rawget(module, key)
	if type(callback) ~= "function" then
		return
	end

	module[key] = function(...)
		return measure(label, callback, ...)
	end
end

local function instrument_lazy_module(name, module)
	if name == "lazy.core.config" then
		instrument_method(module, "setup", "lazy.phase.config_setup()")
	elseif name == "lazy.core.plugin" then
		local spec = rawget(module, "Spec")
		if type(spec) == "table" then
			instrument_method(spec, "new", "lazy.phase.spec_new()")
			instrument_method(spec, "parse", "lazy.phase.spec_parse()")

			local function instrument_plugin_specs(plugin_spec)
				if type(plugin_spec) ~= "table" then
					return
				end
				if plugin_spec[1] or plugin_spec.dir or plugin_spec.url then
					local plugin_name = plugin_spec.name or plugin_spec[1] or plugin_spec.url or "unnamed"
					instrument_config("plugin[" .. tostring(plugin_name) .. "]", plugin_spec)
					return
				end
				for _, child in ipairs(plugin_spec) do
					instrument_plugin_specs(child)
				end
			end

			local normalize = rawget(spec, "normalize")
			if type(normalize) == "function" then
				spec.normalize = function(self, plugin_spec, ...)
					instrument_plugin_specs(plugin_spec)
					return measure("lazy.phase.spec_normalize()", normalize, self, plugin_spec, ...)
				end
			end

			instrument_method(spec, "import", "lazy.phase.spec_import()")
		end
		instrument_method(module, "update_state", "lazy.phase.plugin_state()")
		instrument_method(module, "load", "lazy.phase.plugin_load()")
	elseif name == "lazy.core.loader" then
		instrument_method(module, "setup", "lazy.phase.loader_setup()")
		instrument_method(module, "startup", "lazy.phase.loader_startup()")
		instrument_method(module, "install_missing", "lazy.phase.install_missing()")
		instrument_method(module, "config", "lazy.phase.plugin_config_dispatch()")
	elseif name == "lazy.core.handler" or name == "lazy.core.handler.init" then
		instrument_method(module, "init", "lazy.phase.handler_init()")
		instrument_method(module, "setup", "lazy.phase.handler_setup()")
	end
end

local function instrument_module(name, module)
	if type(module) ~= "table" then
		return module
	end

	-- Lazy accepts both single plugin specs and lists of plugin specs.
	-- Measure either form, including the LSP and Mini spec arrays.
	if name:match("^soul%.plugins%.") then
		instrument_config(name, module)
		for index, spec in ipairs(module) do
			instrument_config(name .. "[" .. index .. "]", spec)
		end
	end

	-- Instrument Lazy's internal setup phases without touching the installed
	-- Lazy.nvim source or changing production startup behavior.
	if name:match("^lazy%.core%.") then
		instrument_lazy_module(name, module)
	end

	-- Separate Lazy's module load from its setup work. The setup call is
	-- otherwise included in soul.lazy's exclusive time.
	if name == "lazy" then
		local setup = rawget(module, "setup")
		if type(setup) == "function" then
			module.setup = function(...)
				return measure("lazy.setup()", setup, ...)
			end
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

-- Lazy loads imported plugin-spec files with loadfile(), not require().
-- Time the execution of each CVIM spec file so the aggregate import cost can
-- be attributed to its actual source module.
local original_loadfile = loadfile
_G.loadfile = function(path, ...)
	local chunk, err = original_loadfile(path, ...)
	if not chunk or type(path) ~= "string" then
		return chunk, err
	end

	local normalized = path:gsub("\\", "/")
	local marker = "/lua/soul/plugins/"
	local marker_start = normalized:find(marker, 1, true)
	if not marker_start then
		return chunk, err
	end

	local relative = normalized:sub(marker_start + #marker)
	return function(...)
		return measure("specfile." .. relative, chunk, ...)
	end
end

-- These lookups are cheap in isolation on many systems, but can become
-- expensive with large PATH environments (notably Windows/WSL). Measure each
-- function without changing the production configuration or its call sites.
for _, name in ipairs({ "exepath", "executable", "expand", "stdpath" }) do
	local original = vim.fn[name]
	vim.fn[name] = function(...)
		return measure("vim.fn." .. name .. "()", original, ...)
	end
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

local function write_report()
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
		("CVIM init to Alpha ready: %.3f ms"):format(tonumber(vim.g.cvim_alpha_ready_ms) or -1),
		"Includes first require() costs and measured setup/build callbacks.",
		"Exclusive time subtracts nested module loads and measured calls.",
		"",
		"exclusive_ms\tinclusive_ms\tcalls\toperation",
	}

	for _, row in ipairs(rows) do
		lines[#lines + 1] = ("%.3f\t%.3f\t%d\t%s"):format(row.exclusive_ms, row.inclusive_ms, row.calls, row.name)
	end

	vim.fn.writefile(lines, output)
	vim.g.cvim_profile_done = true
	vim.cmd("qa!")
end

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		vim.schedule(write_report)
	end,
})
