local root = vim.fn.getcwd()
vim.opt.rtp:prepend(root)
package.path = table.concat({
	root .. "/lua/?.lua",
	root .. "/lua/?/init.lua",
	package.path,
}, ";")

require("soul.launch")

local native_dir = vim.env.FZF_NATIVE_DIR
assert(native_dir and native_dir ~= "", "FZF_NATIVE_DIR must point to a fresh telescope-fzf-native checkout")

local telescope_spec = require("soul.plugins.telescope")
local fzf_spec

for _, dependency in ipairs(telescope_spec.dependencies or {}) do
	if type(dependency) == "table" and dependency[1] == "nvim-telescope/telescope-fzf-native.nvim" then
		fzf_spec = dependency
		break
	end
end

assert(fzf_spec and type(fzf_spec.build) == "function", "Telescope fzf-native build callback is missing")
fzf_spec.build({ dir = native_dir })

local library = native_dir .. "/build/libfzf.dll"
assert(vim.uv.fs_stat(library), "Native build did not create " .. library)

local ffi = require("ffi")
local ok, handle = pcall(ffi.load, library)
assert(ok, "Windows could not load the built fzf DLL: " .. tostring(handle))

handle = nil
print("Telescope fzf-native DLL built and loaded successfully.")
