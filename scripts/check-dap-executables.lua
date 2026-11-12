local root = vim.fn.getcwd()
vim.opt.rtp:prepend(root)
package.path = table.concat({
	root .. "/lua/?.lua",
	root .. "/lua/?/init.lua",
	root .. "/?.lua",
	package.path,
}, ";")

assert(vim.fn.has("nvim-0.12") == 1, "Neovim 0.12 or newer is required")

local find_executables = require("soul.core.helpers.dap.executables").find
local platform = require("soul.core.platform")
local temp_dir = vim.fn.tempname()
assert(vim.fn.mkdir(temp_dir, "p") == 1, "Could not create executable discovery test directory")

local suffix = platform.is_windows and ".exe" or ".bin"
local created = {}

local function add_executable(relative_path)
	local path = temp_dir .. "/" .. relative_path .. suffix
	vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
	assert(vim.fn.writefile({ "test executable" }, path) == 0, "Could not create test executable: " .. path)
	if not platform.is_windows then
		assert(vim.fn.setfperm(path, "rwxr-xr-x") == 1, "Could not mark test executable: " .. path)
	end
	created[relative_path] = path
	return path
end

add_executable("root-app")
add_executable("bin/primary")
add_executable("bin/nested/secondary")
add_executable("bin/one/two/three/included")
add_executable("bin/one/two/three/four/excluded")
add_executable("bin/node_modules/dependency")
add_executable("bin/.git/ignored")
add_executable("build/Debug/debug")
add_executable("build/Release/release")
add_executable("Debug/direct")
add_executable("Release/direct")
add_executable("other/not-scanned")

local found = find_executables(temp_dir)
local indices = {}

for index, path in ipairs(found) do
	indices[vim.fn.fnamemodify(path, ":t")] = index
end

local function basename(relative_path)
	return vim.fn.fnamemodify(created[relative_path], ":t")
end

for _, relative_path in ipairs({
	"root-app",
	"bin/primary",
	"bin/nested/secondary",
	"bin/one/two/three/included",
	"build/Debug/debug",
	"build/Release/release",
	"Debug/direct",
	"Release/direct",
}) do
	assert(indices[basename(relative_path)], "Executable discovery missed " .. relative_path)
end

for _, relative_path in ipairs({
	"bin/one/two/three/four/excluded",
	"bin/node_modules/dependency",
	"bin/.git/ignored",
	"other/not-scanned",
}) do
	assert(not indices[basename(relative_path)], "Executable discovery entered an excluded path: " .. relative_path)
end

assert(
	indices[basename("bin/primary")] < indices[basename("build/Debug/debug")],
	"Executables in bin/ must rank ahead of build/ executables"
)
assert(
	indices[basename("build/Debug/debug")] < indices[basename("Debug/direct")],
	"Executables in build/ must rank ahead of other root output directories"
)

local empty_dir = temp_dir .. "/empty"
assert(vim.fn.mkdir(empty_dir, "p") == 1, "Could not create empty executable discovery directory")
assert(#find_executables(empty_dir) == 0, "A project without executables must return an empty result")

if not platform.is_windows then
	local non_executable = temp_dir .. "/not-executable"
	assert(vim.fn.writefile({ "not executable" }, non_executable) == 0, "Could not create permission test file")
	assert(vim.fn.setfperm(non_executable, "rw-r--r--") == 1, "Could not remove executable permission")
	assert(
		not vim.tbl_contains(find_executables(temp_dir), vim.fn.fnamemodify(non_executable, ":p")),
		"Executable discovery must ignore files without execute permission"
	)
end

vim.fn.delete(temp_dir, "rf")
print("DAP executable discovery tests passed.")
