local M = {}

local fn = vim.fn

local root_markers = {
	".git",
	".clangd",
	".clang-tidy",
	".clang-format",
	"CMakeLists.txt",
	"Makefile",
	"makefile",
	"build.ninja",
	"compile_commands.json",
	"compile_flags.txt",
	"meson.build",
	"Cargo.toml",
	"build.sh",
	"build.bat",
	"build_all.sh",
	"build_all.bat",
}

function M.setup(path, find_registered_ancestor)
	local selected_project

	local function resolve_root()
		if selected_project then
			if selected_project.buf == vim.api.nvim_get_current_buf() then
				return selected_project.root
			end
			selected_project = nil
		end

		local name = vim.api.nvim_buf_get_name(0)
		if name ~= "" then
			local file = path.normalize(name)
			local detected = vim.fs.root(file, root_markers)
			if detected then
				return path.normalize(detected)
			end

			local registered = find_registered_ancestor(file)
			if registered then
				return path.normalize(registered)
			end

			return path.normalize(fn.fnamemodify(file, ":h"))
		end

		local cwd = path.normalize(fn.getcwd())
		local detected = vim.fs.root(cwd, root_markers)
		if detected then
			return path.normalize(detected)
		end
		return find_registered_ancestor(cwd) or cwd
	end

	local function select(root)
		vim.api.nvim_set_current_dir(root)
		selected_project = {
			root = root,
			buf = vim.api.nvim_get_current_buf(),
		}
	end

	vim.api.nvim_create_autocmd("BufEnter", {
		group = vim.api.nvim_create_augroup("SoulDapProjectSelection", { clear = true }),
		callback = function(args)
			if selected_project and args.buf ~= selected_project.buf then
				selected_project = nil
			end
		end,
	})

	return {
		resolve = resolve_root,
		select = select,
	}
end

return M
