local M = {
	"goolord/alpha-nvim",
	event = "VimEnter",
}

function M.config()
	local dashboard = require("alpha.themes.dashboard")
	local icons = require("soul.core.helpers.icons")
	local utils = require("alpha.utils")

	local function button(sc, txt, keybind, keybind_opts)
		local b = dashboard.button(sc, txt, keybind, keybind_opts)
		b.opts.hl_shortcut = "Include"
		return b
	end

	local header_data = require("soul.core.helpers.dashboard.header")
	local header = header_data.lines

	dashboard.section.header.val = header

	local header_hl = header_data.highlights

	for line_number, line in ipairs(header) do
		for i = 1, vim.fn.strchars(line) do
			local char = vim.fn.strcharpart(line, i - 1, 1)

			if char == "╚" or char == "═" or char == "╝" or char == "╗" or char == "║" or char == "╔" then
				table.insert(header_hl[line_number], {
					"AlphaTeal",
					i - 1,
					i,
				})
			end
		end
	end

	dashboard.section.header.opts = {
		position = "center",
		hl = utils.charhl_to_bytehl(header_hl, header),
	}

	local button_icons = {
		files = icons.ui.Files,
		explorer = icons.ui.Folder,
		new_file = icons.ui.NewFile,
		project = icons.git.Repo,
		recent = icons.ui.History,
		text = icons.ui.Text,
		marks = icons.ui.BookMark,
		config = icons.ui.Gear,
		lazy = icons.which_key.Plugins,
		health = icons.ui.Bug,
		quit = icons.ui.SignOut,
	}

	dashboard.section.buttons.val = {
		button("f", button_icons.files .. " Find file", "<cmd>Telescope find_files<CR>"),

		button("e", button_icons.explorer .. " Open Explorer", "<cmd>lua require('mini.files').open(vim.fn.getcwd())<CR>"),

		button("n", button_icons.new_file .. " New file", "<cmd>ene | startinsert<CR>"),

		button("p", button_icons.project .. " Projects", "<cmd>lua require('yap').project_picker.open(require('yap').config)<CR>"),

		button("r", button_icons.recent .. " Recent files", "<cmd>Telescope oldfiles<CR>"),

		button("t", button_icons.text .. " Find text", "<cmd>Telescope live_grep<CR>"),

		button("m", button_icons.marks .. " Marks", "<cmd>Telescope marks<CR>"),

		button("c", button_icons.config .. " Config", "<cmd>edit " .. vim.fn.stdpath("config") .. "/init.lua<CR>"),

		button("l", button_icons.lazy .. "Lazy", "<cmd>Lazy<CR>"),

		button("h", button_icons.health .. " Health", "<cmd>checkhealth<CR>"),

		button("q", button_icons.quit .. " Quit", "<cmd>qa<CR>"),
	}

	dashboard.section.buttons.opts.hl = "Include"


	local button_icon_highlights = {
		{ button_icons.files, "AlphaBlue" },
		{ button_icons.explorer, "AlphaAqua" },
		{ button_icons.new_file, "AlphaGreen" },
		{ button_icons.project, "AlphaPurple" },
		{ button_icons.recent, "AlphaYellow" },
		{ button_icons.text, "AlphaOrange" },
		{ button_icons.marks, "AlphaRed" },
		{ button_icons.config, "AlphaTeal" },
		{ button_icons.lazy, "AlphaBlue" },
		{ button_icons.health, "AlphaRed" },
		{ button_icons.quit, "AlphaMuted" },
	}

	for index, btn in ipairs(dashboard.section.buttons.val) do
		local icon = button_icon_highlights[index][1]
		local highlight = button_icon_highlights[index][2]

		btn.opts.hl = {
			{
				highlight,
				0,
				#icon,
			},
		}
	end

	local git_branch_cache = {}
	local git_branch_pending = {}
	local update_footer

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
				git_branch_pending[cwd] = nil

				local branch
				if result and result.code == 0 then
					branch = vim.trim(result.stdout or "")
					if branch == "" then
						branch = nil
					end
				end

				-- false is cached too, so non-Git directories are not queried
				-- repeatedly every time Alpha redraws.
				git_branch_cache[cwd] = branch or false

				if update_footer then
					update_footer()
					if vim.bo.filetype == "alpha" then
						pcall(vim.cmd.AlphaRedraw)
					end
				end
			end)
		end)

		if ok then
			git_branch_pending[cwd] = process
		else
			git_branch_cache[cwd] = false
		end

		return nil
	end

	local function footer()
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

	dashboard.section.footer = {
		type = "group",

		val = {
			{
				type = "text",
				val = "",
			},

			{
				type = "text",
				val = "",
				opts = {
					position = "center",
				},
			},

			{
				type = "text",
				val = "",
				opts = {
					position = "center",
				},
			},

			{
				type = "text",
				val = "",
				opts = {
					position = "center",
				},
			},
		},

		opts = {
			spacing = 0,
		},
	}

	update_footer = function()
		local lines = footer()

		dashboard.section.footer.val[1].val = lines[1]
		dashboard.section.footer.val[2].val = lines[2]
		dashboard.section.footer.val[3].val = lines[3]
		dashboard.section.footer.val[4].val = lines[4]
	end

	update_footer()

	dashboard.opts.layout = {
		{ type = "padding", val = 1 },

		dashboard.section.header,

		{ type = "padding", val = 1 },

		dashboard.section.buttons,

		{ type = "padding", val = 1 },

		dashboard.section.footer,
	}

	dashboard.opts.opts = {
		noautocmd = true,
	}

	local animation_data = header_data.animation
	local animation_step = 1

	local function apply_animation_frame()
		local state = animation_data.steps[animation_step]

		local line = state[1]
		local frames = animation_data.fragments[state[2]]
		local frame = state[3]

		dashboard.section.header.val[line] = animation_data.lines[line][1]
			.. frames[frame]
			.. animation_data.lines[line][2]
	end

	apply_animation_frame()

	---------------------------------------------------------------------------
	-- Alpha setup
	---------------------------------------------------------------------------

	require("alpha").setup(dashboard.opts)

	---------------------------------------------------------------------------
	-- Animation
	---------------------------------------------------------------------------

	local animation_running = false
	local animation_generation = 0

	local function stop_animation()
		animation_running = false
		animation_generation = animation_generation + 1
	end

	local function animate(generation)
		if not animation_running or generation ~= animation_generation then
			return
		end

		if vim.bo.filetype ~= "alpha" then
			stop_animation()
			return
		end

		animation_step = animation_step + 1

		if animation_step > #animation_data.steps then
			animation_step = 1
		end

		apply_animation_frame()
		pcall(vim.cmd.AlphaRedraw)

		vim.defer_fn(function()
			animate(generation)
		end, animation_data.speed)
	end

	local function start_animation()
		if animation_running then
			return
		end

		animation_running = true
		animation_generation = animation_generation + 1

		local generation = animation_generation

		vim.defer_fn(function()
			animate(generation)
		end, animation_data.speed)
	end

	---------------------------------------------------------------------------
	-- Autocmds
	---------------------------------------------------------------------------

	vim.api.nvim_create_autocmd("FileType", {
		pattern = "alpha",
		callback = function()
			vim.opt_local.foldenable = false
			vim.opt_local.number = false
			vim.opt_local.relativenumber = false
			vim.opt_local.cursorline = false
			start_animation()
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		pattern = "AlphaReady",
		callback = start_animation,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		callback = function(args)
			if vim.bo[args.buf].filetype == "alpha" then
				git_branch_cache[vim.fn.getcwd()] = nil
				update_footer()
				pcall(vim.cmd.AlphaRedraw)
				start_animation()
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufLeave", {
		callback = function(args)
			if vim.bo[args.buf].filetype == "alpha" then
				stop_animation()
			end
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		pattern = "VeryLazy",
		callback = function()
			update_footer()
			pcall(vim.cmd.AlphaRedraw)
		end,
	})

	vim.api.nvim_create_autocmd("DirChanged", {
		callback = function()
			if vim.bo.filetype == "alpha" then
				update_footer()
				pcall(vim.cmd.AlphaRedraw)
			end
		end,
	})
	if vim.bo.filetype == "alpha" then
		start_animation()
	end
end

return M
