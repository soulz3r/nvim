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
assert(vim.deep_equal(entry.args, { "--from-registry" }), "Current project did not load shared launch arguments")

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

-- A file with no marker or registered ancestor falls back to its own directory,
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

vim.fn.delete(temp_dir, "rf")
print("DAP path and project resolution tests passed.")
