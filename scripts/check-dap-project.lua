local root = vim.fn.getcwd()
vim.opt.rtp:prepend(root)
package.path = table.concat({
	root .. "/lua/?.lua",
	root .. "/lua/?/init.lua",
	root .. "/?.lua",
	package.path,
}, ";")

assert(vim.fn.has("nvim-0.12") == 1, "Neovim 0.12 or newer is required")

local path = require("soul.core.helpers.dap.path")
local temp_dir = vim.fn.tempname()
assert(vim.fn.mkdir(temp_dir, "p") == 1, "Could not create DAP path test directory")

local outer_dir = temp_dir .. "/registered"
local inner_dir = outer_dir .. "/nested"
local source_dir = inner_dir .. "/src"
assert(vim.fn.mkdir(source_dir, "p") == 1, "Could not create nested project source directory")
local outer = path.normalize(outer_dir)
local inner = path.normalize(inner_dir)
source_dir = path.normalize(source_dir)
local source_file = source_dir .. "/main.c"
assert(vim.fn.writefile({ "int main(void) { return 0; }" }, source_file) == 0, "Could not create project source file")

assert(path.normalize(outer .. "/nested/..") == outer, "Path normalization must resolve parent components")
assert(path.normalize(outer .. "/") == outer, "Path normalization must remove trailing separators")
assert(path.is_within(source_file, inner), "A source file must be inside its project root")
assert(path.is_within(inner, inner), "A project root must contain itself")
assert(not path.is_within(outer .. "-sibling/file.c", outer), "Path containment must respect directory boundaries")
assert(path.is_executable(vim.v.progpath), "The current Neovim executable must be recognized")

-- The standalone DAP registry must persist independently of YAP.
local registry_file = temp_dir .. "/state/soul/dap/projects.json"
local disk_registry = require("soul.core.helpers.dap.project.registry").setup(path, registry_file)
assert(
	disk_registry.update(inner, {
		dap_enabled = true,
		executable = vim.v.progpath,
		args = { "--from-disk", "sample file.c" },
	}),
	"Standalone DAP registry should persist project metadata"
)
local reloaded_registry = require("soul.core.helpers.dap.project.registry").setup(path, registry_file)
local disk_entry = reloaded_registry.get(inner)
assert(type(disk_entry) == "table", "Standalone DAP registry should reload saved projects")
assert(
	disk_entry.executable == path.normalize(vim.v.progpath),
	"Standalone DAP registry lost the executable"
)
assert(
	vim.deep_equal(disk_entry.args, { "--from-disk", "sample file.c" }),
	"Standalone DAP registry lost launch arguments"
)

local registry_state = {
	[inner] = {
		root = inner,
		dap_enabled = true,
		dap_args = { "--from-registry" },
	},
}
local registry = {
	list = function()
		return {
			{ root = outer, dap_enabled = true },
			{ root = inner, dap_enabled = true, dap_args = { "--from-registry" } },
		}
	end,
	get = function(project_root)
		return registry_state[project_root]
	end,
	update = function(project_root, fields)
		local entry = registry_state[project_root] or { root = project_root }
		for key, value in pairs(fields) do
			entry[key] = vim.deepcopy(value)
		end
		registry_state[project_root] = entry
		return true
	end,
	touch = function()
		return true
	end,
}

local projects = require("soul.core.helpers.dap.project").setup(registry)
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(buf, source_file)
vim.api.nvim_set_current_buf(buf)

local resolved_project = projects.resolve_root()
assert(resolved_project == inner, "Expected " .. inner .. ", got " .. tostring(resolved_project))
local entry, resolved_root = projects.current()
assert(resolved_root == inner, "Current project returned the wrong registered root")
assert(vim.deep_equal(entry.args, { "--from-registry" }), "Current project did not load saved launch arguments")

-- Root markers must be resolved from the current file path, not Neovim's cwd.
local marker_root = temp_dir .. "/marker-project"
local marker_source = marker_root .. "/src"
assert(vim.fn.mkdir(marker_source, "p") == 1, "Could not create marker project source directory")
assert(vim.fn.mkdir(marker_root .. "/.git", "p") == 1, "Could not create marker project root")
local marker_file = marker_source .. "/main.c"
assert(
	vim.fn.writefile({ "int main(void) { return 0; }" }, marker_file) == 0,
	"Could not create marker project source file"
)
local marker_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(marker_buf, marker_file)
vim.api.nvim_set_current_buf(marker_buf)
assert(
	projects.resolve_root() == path.normalize(marker_root),
	"Project marker lookup must start from the current buffer path"
)

-- A file with no marker or DAP-registered ancestor falls back to its own directory,
-- not whichever unrelated directory Neovim happens to use as its cwd.
local fallback_dir = temp_dir .. "/unregistered/src"
assert(vim.fn.mkdir(fallback_dir, "p") == 1, "Could not create fallback source directory")
fallback_dir = path.normalize(fallback_dir)
local fallback_file = fallback_dir .. "/standalone.c"
assert(
	vim.fn.writefile({ "int main(void) { return 0; }" }, fallback_file) == 0,
	"Could not create fallback source file"
)
local fallback_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(fallback_buf, fallback_file)
vim.api.nvim_set_current_buf(fallback_buf)
assert(projects.resolve_root() == fallback_dir, "Unregistered files must fall back to their containing directory")

vim.api.nvim_set_current_buf(buf)

-- Project settings must be persisted through the independent DAP registry.
local saved_args = { "--input", "sample file.c", 42, "--verbose" }
assert(projects.save_args(inner, saved_args), "Project launch arguments should be saved")
assert(
	vim.deep_equal(registry_state[inner].args, { "--input", "sample file.c", "--verbose" }),
	"Launch arguments must retain strings and ignore unsupported values"
)

assert(projects.save_executable(inner, vim.v.progpath), "A valid executable should be saved")
assert(
	registry_state[inner].executable == path.normalize(vim.v.progpath),
	"The debug executable must be persisted in the DAP registry"
)
local saved_entry, saved_root = projects.current()
assert(saved_root == inner, "Saved settings must remain associated with the resolved project")
assert(
	vim.deep_equal(saved_entry.args, { "--input", "sample file.c", "--verbose" }),
	"Current project must expose the saved launch arguments"
)
assert(saved_entry.executable == path.normalize(vim.v.progpath), "Current project must expose the saved executable")

-- Cancelling project selection must leave the working directory unchanged.
local original_cwd = vim.fn.getcwd()
local original_select = vim.ui.select
local selection_callback
local selection_choices
vim.ui.select = function(items, opts, callback)
	selection_choices = items
	selection_callback = callback
end

projects.select()
assert(type(selection_callback) == "function", "Project selection must invoke the UI selector")
assert(#selection_choices == 2, "Project selection must list the saved projects")
selection_callback(nil, nil)
assert(vim.fn.getcwd() == original_cwd, "Cancelling project selection must not change the working directory")

-- Selecting a saved project activates it for the current buffer.
selection_callback = nil
projects.select()
local inner_index
for index, choice in ipairs(selection_choices) do
	if choice:find(inner, 1, true) == 1 then
		inner_index = index
		break
	end
end
assert(inner_index, "The saved nested project must appear in the selection list")
selection_callback(selection_choices[inner_index], inner_index)
assert(path.normalize(vim.fn.getcwd()) == inner, "Selecting a project must change the working directory")
assert(projects.resolve_root() == inner, "The selected project must become active for the current buffer")

-- A manually selected project is scoped to its buffer and must clear on BufEnter.
vim.api.nvim_set_current_buf(marker_buf)
assert(
	projects.resolve_root() == path.normalize(marker_root),
	"Entering another buffer must clear the previous manual project selection"
)
vim.ui.select = original_select
vim.api.nvim_set_current_dir(original_cwd)

vim.fn.delete(temp_dir, "rf")
print("DAP path and project resolution tests passed.")
