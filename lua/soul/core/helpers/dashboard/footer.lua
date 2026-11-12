local M = {}

-- Creates footer data without depending on Alpha or its dashboard sections.
function M.new(on_update)
	local api = {}
	local git_branch_cache = {}
	local git_branch_pending = {}

	local function get_git_branch(cwd)
		local cached = git_branch_cache[cwd]
		if cached ~= nil then
			return cached or nil
		end

		if git_branch_pending[cwd] then
			return nil
		end

		local ok, process = pcall(vim.system, {
			"git",
			"-C",
			cwd,
			"branch",
			"--show-current",
		}, {
			text = true,
		}, function(result)
			vim.schedule(function()
				-- Ignore a callback from a process that already hit its timeout.
				if git_branch_pending[cwd] ~= process then
					return
				end

				git_branch_pending[cwd] = nil

				local branch
				if result and result.code == 0 then
					branch = vim.trim(result.stdout or "")
					if branch == "" then
						branch = nil
					end
				end

				-- Cache false as well, avoiding repeated Git calls outside repositories.
				git_branch_cache[cwd] = branch or false

				if on_update then
					on_update(api.get_lines())
				end
			end)
		end)

		if ok then
			git_branch_pending[cwd] = process

			vim.defer_fn(function()
				if git_branch_pending[cwd] ~= process then
					return
				end

				git_branch_pending[cwd] = nil
				git_branch_cache[cwd] = false
				pcall(function()
					process:kill(9)
				end)

				if on_update then
					on_update(api.get_lines())
				end
			end, 1500)
		else
			git_branch_cache[cwd] = false
		end

		return nil
	end

	function api.get_lines()
		local stats = require("lazy").stats()
		local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
		local nvim = vim.version()

		local current_dir = vim.fn.getcwd()
		local cwd = vim.fn.fnamemodify(current_dir, ":~")
		local branch = get_git_branch(current_dir)

		local line1 = " Neovim " .. nvim.major .. "." .. nvim.minor .. "." .. nvim.patch
		local line2 = "󰒲 " .. stats.count .. " plugins" .. "  •  " .. ms .. "ms"
		local line3 = "󰉋 " .. cwd

		if branch then
			line3 = line3 .. "  •  󰘬 " .. branch
		end

		return {
			"",
			line1,
			line2,
			line3,
		}
	end

	function api.update()
		local lines = api.get_lines()
		if on_update then
			on_update(lines)
		end
	end

	function api.invalidate(cwd)
		if cwd then
			git_branch_cache[cwd] = nil
		else
			git_branch_cache = {}
		end
	end

	return api
end

return M
