local M = {
	"goolord/alpha-nvim",
	event = "VimEnter",
}

function M.config()
	local dashboard = require("alpha.themes.dashboard")
	local icons = require("soul.core.helpers.icons")
	local utils = require("alpha.utils")

	---------------------------------------------------------------------------
	-- Header
	---------------------------------------------------------------------------

	local header_data = require("soul.core.helpers.dashboard.header")
	local header = vim.deepcopy(header_data.lines)

	dashboard.section.header.val = header

	-- Alpha mutates the header while animating, so keep helper data immutable.
	local header_hl = vim.deepcopy(header_data.highlights)

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

	---------------------------------------------------------------------------
	-- Buttons
	---------------------------------------------------------------------------

	local button_data = require("soul.core.helpers.dashboard.buttons")

	local function create_button(item)
		local icon = icons[item.icon_group][item.icon]
		local button = dashboard.button(
			item.key,
			icon .. " " .. item.label,
			item.command
		)

		button.opts.hl_shortcut = "Include"
		button.opts.hl = {
			{
				item.highlight,
				0,
				#icon,
			},
		}

		return button
	end

	dashboard.section.buttons.val = vim.tbl_map(create_button, button_data.items)
	dashboard.section.buttons.opts.hl = "Include"

	---------------------------------------------------------------------------
	-- Footer
	---------------------------------------------------------------------------

	local footer_data = require("soul.core.helpers.dashboard.footer")

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

	local function set_footer(lines)
		for index, line in ipairs(lines) do
			dashboard.section.footer.val[index].val = line
		end

		pcall(vim.cmd.AlphaRedraw)
	end

	local footer = footer_data.new(set_footer)
	footer.update()

	---------------------------------------------------------------------------
	-- Layout
	---------------------------------------------------------------------------

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

	---------------------------------------------------------------------------
	-- Animation
	---------------------------------------------------------------------------

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
	-- Animation lifecycle
	---------------------------------------------------------------------------

	local animation = require("soul.core.helpers.dashboard.animation").new({
		interval = animation_data.speed,

		is_active = function()
			return vim.bo.filetype == "alpha"
		end,

		on_tick = function()
			animation_step = animation_step + 1

			if animation_step > #animation_data.steps then
				animation_step = 1
			end

			apply_animation_frame()
		end,

		redraw = function()
			pcall(vim.cmd.AlphaRedraw)
		end,
	})

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
			animation.start()
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		pattern = "AlphaReady",
		callback = animation.start,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		callback = function(args)
			if vim.bo[args.buf].filetype == "alpha" then
				footer.invalidate(vim.fn.getcwd())
				footer.update()
				pcall(vim.cmd.AlphaRedraw)
				animation.start()
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufLeave", {
		callback = function(args)
			if vim.bo[args.buf].filetype == "alpha" then
				animation.stop()
			end
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		pattern = "VeryLazy",
		callback = function()
			footer.update()
			pcall(vim.cmd.AlphaRedraw)
		end,
	})

	vim.api.nvim_create_autocmd("DirChanged", {
		callback = function()
			if vim.bo.filetype == "alpha" then
				footer.update()
				pcall(vim.cmd.AlphaRedraw)
			end
		end,
	})

	if vim.bo.filetype == "alpha" then
		animation.start()
	end
end

return M
