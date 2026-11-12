local process_helper = require("soul.core.helpers.process")

local M = {}

function M.build(plugin)
	local fn = vim.fn
	local paths = require("soul.core.helpers.paths")
	local windows = require("soul.core.platform").is_windows
	local build_dir = plugin.dir .. "/build"
	local library = build_dir .. "/" .. (windows and "libfzf.dll" or "libfzf.so")

	local function clean_build()
		local result = fn.delete(build_dir, "rf")
		if result ~= 0 and vim.uv.fs_stat(build_dir) then
			return false, "Could not remove the previous native build directory. Restart Neovim before rebuilding."
		end
		return true
	end

	local function run(command)
		local ok, process = pcall(vim.system, command, {
			cwd = plugin.dir,
			text = true,
		})

		if not ok then
			return false, tostring(process)
		end

		local result, wait_error = process_helper.wait(process, 120000)
		if not result then
			return false, wait_error or "Build timed out after 120 seconds."
		end

		return result.code == 0, table.concat({
			result.stdout or "",
			result.stderr or "",
		}, "\n")
	end

	local errors = {}
	local clean_ok, clean_error = clean_build()
	if not clean_ok then
		error(clean_error)
	end

	-- Prefer CMake on Windows when available. Its MSVC build uses the
	-- static CRT, avoiding a separate Visual C++ runtime dependency.
	if windows then
		local cmake = fn.exepath("cmake")
		if cmake ~= "" then
			local configure_ok, configure_output = run({
				cmake,
				"-S",
				".",
				"-B",
				"build",
				"-DCMAKE_BUILD_TYPE=Release",
				"-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
				"-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded",
			})

			if configure_ok then
				local build_ok, build_output = run({
					cmake,
					"--build",
					"build",
					"--config",
					"Release",
				})

				if build_ok then
					local install_ok, install_output = run({
						cmake,
						"--install",
						"build",
						"--config",
						"Release",
						"--prefix",
						"build",
					})

					if install_ok and vim.uv.fs_stat(library) then
						return
					end
					table.insert(errors, "CMake install failed:\n" .. install_output)
				else
					table.insert(errors, "CMake build failed:\n" .. build_output)
				end
			else
				table.insert(errors, "CMake configure failed:\n" .. configure_output)
			end

			local cleaned, cleanup_error = clean_build()
			if not cleaned then
				error(
					table.concat(errors, "\n\n")
						.. "\n\n"
						.. cleanup_error
						.. "\nRefusing to continue with a potentially stale native build directory."
				)
			end
		end
	end

	local make = fn.exepath("make")
	if windows and make == "" then
		make = fn.exepath("mingw32-make")
	end

	if make ~= "" then
		local command = { make, "-C", plugin.dir }
		if windows then
			local compiler = paths.clang or fn.exepath("clang")
			if compiler and compiler ~= "" then
				command[#command + 1] = 'CC="' .. compiler .. '"'
			end
		end

		local make_ok, make_output = run(command)
		if make_ok and vim.uv.fs_stat(library) then
			return
		end
		table.insert(errors, "Make build failed:\n" .. make_output)
	else
		table.insert(errors, "GNU Make was not found.")
	end

	-- Last-resort Windows path for LLVM-only setups without Make/CMake.
	if windows then
		local cleaned, cleanup_error = clean_build()
		if not cleaned then
			table.insert(errors, cleanup_error)
		else
			fn.mkdir(build_dir, "p")

			local clang_cl = fn.exepath("clang-cl")
			if clang_cl ~= "" then
				local ok, output = run({
					clang_cl,
					"/nologo",
					"/O2",
					"/W4",
					"/MT",
					"/LD",
					"/std:c11",
					"src/fzf.c",
					"/Fe:build/libfzf.dll",
				})

				if ok and vim.uv.fs_stat(library) then
					return
				end
				table.insert(errors, "clang-cl build failed:\n" .. output)
			end

			local clang = paths.clang or fn.exepath("clang")
			if clang and clang ~= "" then
				local ok, output = run({
					clang,
					"-O3",
					"-Wall",
					"-fpic",
					"-std=gnu99",
					"-shared",
					"src/fzf.c",
					"-o",
					"build/libfzf.dll",
				})

				if ok and vim.uv.fs_stat(library) then
					return
				end
				table.insert(errors, "Clang build failed:\n" .. output)
			end
		end
	end

	error(
		"Could not build telescope-fzf-native.nvim.\n"
			.. table.concat(errors, "\n\n")
			.. "\nInstall a C compiler and Make, or CMake with Visual Studio Build Tools on Windows. "
			.. "Then run :Lazy build telescope-fzf-native.nvim."
	)
end

return M
