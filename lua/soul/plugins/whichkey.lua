local M = {
	"folke/which-key.nvim",
}

function M.config()
	local which_key = require("which-key")
	local icons = require("soul.core.helpers.icons")
	local ui = icons.ui
	local kind = icons.kind
	local diagnostics = icons.diagnostics
	local git = icons.git

	local spec = {
		-- Top-level groups
		{ "<leader>c", group = "Change / Add", icon = ui.Plus },
		{ "<leader>d", group = "Debug", icon = diagnostics.Debug },
		{ "<leader>f", group = "Find", icon = ui.Telescope },
		{ "<leader>fg", group = "Git pickers", icon = git.Repo },
		{ "<leader>fl", group = "LSP pickers", icon = icons.which_key.Code },
		{ "<leader>g", group = "Git", icon = git.Branch },
		{ "<leader>l", group = "Code / LSP", icon = icons.which_key.Code },
		{ "<leader>L", group = "Plugins", icon = icons.which_key.Plugins },
		{ "<leader>n", group = "Neovim", icon = icons.which_key.Neovim },
		{ "<leader>p", group = "Projects", icon = ui.Folder },
		{ "<leader>s", group = "Sessions", icon = ui.History },

		-- File, editor, and Neovim actions
		{ "<leader>w", desc = "Save file", icon = icons.which_key.Save },
		{ "<leader>q", desc = "Quit window", icon = ui.Close },
		{ "<leader>cd", desc = "Set cwd to file directory", icon = ui.FolderOpen },
		{ "<leader>e", desc = "Open file explorer", icon = ui.Folder },
		{ "<leader>u", desc = "Undotree", icon = ui.History },
		{ "<leader>x", desc = "Make file executable", icon = ui.Check },
		{ "<leader>X", desc = "Compile and run C file", icon = icons.misc.Terminal },
		{ "<leader>ne", desc = "Restart Neovim", icon = ui.Refresh },
		{ "<leader>ni", desc = "Open Neovim config", icon = ui.Gear },
		{ "<leader>nm", desc = "Show messages", icon = ui.Note },

		-- Telescope
		{ "<leader>ff", desc = "Find files", icon = ui.FindFile },
		{ "<leader>ft", desc = "Live grep", icon = ui.FindText },
		{ "<leader>fb", desc = "Buffers", icon = ui.Files },
		{ "<leader>fC", desc = "Colorscheme", icon = ui.Pencil },
		{ "<leader>fh", desc = "Help tags", icon = ui.Note },
		{ "<leader>fr", desc = "Resume picker", icon = ui.Forward },
		{ "<leader>fo", desc = "Recent files", icon = ui.History },
		{ "<leader>fm", desc = "Marks", icon = ui.BookMark },
		{ "<leader>fy", desc = "Registers", icon = ui.Files },
		{ "<leader>fs", desc = "Document symbols", icon = kind.Struct },
		{ "<leader>fx", desc = "Diagnostics", icon = diagnostics.Warning },
		{ "<leader>fch", desc = "Command history", icon = ui.History },
		{ "<leader>fcc", desc = "Commands", icon = ui.List },
		{ "<leader>fgb", desc = "Git branches", icon = git.Branch },
		{ "<leader>fgc", desc = "Git commits", icon = git.Octoface },
		{ "<leader>fgs", desc = "Git status", icon = git.Repo },
		{ "<leader>fgS", desc = "Git stash", icon = git.FileStaged },
		{ "<leader>fgf", desc = "Git-tracked files", icon = git.File },
		{ "<leader>fgB", desc = "Git buffer commits", icon = git.Diff },
		{ "<leader>flr", desc = "LSP references", icon = kind.Reference },
		{ "<leader>fld", desc = "LSP definitions", icon = kind.Function },
		{ "<leader>flD", desc = "LSP declarations", icon = kind.Function },
		{ "<leader>fli", desc = "LSP implementations", icon = kind.Interface },
		{ "<leader>flt", desc = "LSP type definitions", icon = kind.TypeParameter },

		-- Git signs
		{ "<leader>gj", desc = "Next hunk", icon = ui.ChevronShortDown },
		{ "<leader>gk", desc = "Previous hunk", icon = ui.ChevronShortUp },
		{ "<leader>gp", desc = "Preview hunk", icon = ui.Search },
		{ "<leader>gs", desc = "Stage hunk", icon = git.FileStaged },
		{ "<leader>gu", desc = "Undo stage hunk", icon = ui.Refresh },
		{ "<leader>gr", desc = "Reset hunk", icon = git.FileUnstaged },
		{ "<leader>gR", desc = "Reset buffer", icon = git.FileDeleted },
		{ "<leader>gl", desc = "Blame line", icon = git.Branch },
		{ "<leader>gd", desc = "Diff against HEAD", icon = git.Diff },

		-- Buffer-local LSP actions (available after an LSP attaches)
		{ "<leader>ld", desc = "Go to definition", icon = kind.Function },
		{ "<leader>lD", desc = "Go to declaration", icon = kind.Function },
		{ "<leader>li", desc = "Go to implementation", icon = kind.Interface },
		{ "<leader>lt", desc = "Go to type definition", icon = kind.TypeParameter },
		{ "<leader>lr", desc = "Find references", icon = kind.Reference },
		{ "<leader>lh", desc = "Hover documentation", icon = ui.Note },
		{ "<leader>ls", desc = "Signature help", icon = kind.Method },
		{ "<leader>la", desc = "Code action", icon = ui.Lightbulb },
		{ "<leader>lR", desc = "Rename symbol", icon = ui.Pencil },
		{ "<leader>lf", desc = "Format buffer", icon = ui.Check },
		{ "<leader>lj", desc = "Next diagnostic", icon = diagnostics.Warning },
		{ "<leader>lk", desc = "Previous diagnostic", icon = diagnostics.Warning },
		{ "<leader>lo", desc = "Show diagnostics", icon = diagnostics.Information },
		{ "<leader>lq", desc = "Diagnostic location list", icon = ui.List },
		{ "<leader>lw", desc = "Workspace symbols", icon = kind.Module },
		{ "<leader>lS", desc = "Document symbols", icon = kind.Struct },
		{ "<leader>lH", desc = "Toggle inlay hints", icon = ui.Lightbulb },
		{ "<leader>lI", desc = "LSP health", icon = ui.Gear },
		{ "<leader>lC", desc = "Restart LSP", icon = ui.Refresh },

		-- YAP project runner
		{ "<leader>pp", desc = "Project switcher", icon = ui.Folder },
		{ "<leader>pr", desc = "Build and run project", icon = icons.misc.Terminal },
		{ "<leader>pb", desc = "Build project", icon = ui.Gear },
		{ "<leader>pc", desc = "Clean project", icon = ui.Close },
		{ "<leader>pB", desc = "Clean and rebuild", icon = ui.Refresh },
		{ "<leader>pS", desc = "Select build script", icon = ui.List },
		{ "<leader>pe", desc = "Select executable and run", icon = ui.Forward },
		{ "<leader>ps", desc = "Stop project process", icon = ui.BoldClose },
		{ "<leader>pR", desc = "Rerun last project", icon = ui.Refresh },
		{ "<leader>ch", desc = "C: Switch source / header", icon = ui.Files },
		{ "<leader>ci", desc = "C: Insert include", icon = ui.Plus },
		{ "<leader>cp", desc = "C: Project information", icon = ui.Note },

		-- Sessions
		{ "<leader>ss", desc = "Save project session", icon = ui.CloudUpload },
		{ "<leader>sr", desc = "Restore project session", icon = ui.CloudDownload },
		{ "<leader>sd", desc = "Delete project session", icon = ui.Close },

		-- Debugger
		{ "<leader>dc", desc = "Start / continue", icon = ui.Forward },
		{ "<leader>dp", desc = "Select saved project", icon = ui.Folder },
		{ "<leader>de", desc = "Set executable", icon = ui.File },
		{ "<leader>dr", desc = "Restart session", icon = ui.Refresh },
		{ "<leader>dk", desc = "Terminate session", icon = ui.BoldClose },
		{ "<leader>dl", desc = "Run last configuration", icon = ui.History },
		{ "<leader>dx", desc = "Toggle breakpoint", icon = diagnostics.Debug },
		{ "<leader>dB", desc = "Conditional breakpoint", icon = diagnostics.Warning },
		{ "<leader>dL", desc = "Logpoint", icon = ui.Note },
		{ "<leader>dX", desc = "Clear all breakpoints", icon = ui.Close },
		{ "<leader>dK", desc = "List breakpoints", icon = ui.List },
		{ "<leader>ds", desc = "Step over", icon = ui.ArrowCircleRight },
		{ "<leader>di", desc = "Step into", icon = ui.ArrowCircleDown },
		{ "<leader>do", desc = "Step out", icon = ui.ArrowCircleUp },
		{ "<leader>dS", desc = "Step back", icon = ui.ArrowCircleLeft },
		{ "<leader>dP", desc = "Pause", icon = ui.BoldClose },
		{ "<leader>dG", desc = "Run to cursor", icon = ui.Target },
		{ "<leader>dJ", desc = "Go to current line", icon = ui.Target },
		{ "<leader>dU", desc = "Older stack frame", icon = ui.ChevronShortUp },
		{ "<leader>dD", desc = "Newer stack frame", icon = ui.ChevronShortDown },
		{ "<leader>dF", desc = "Focus frame", icon = ui.Search },
		{ "<leader>dh", desc = "Evaluate expression", icon = ui.Lightbulb },
		{ "<leader>dR", desc = "Open / focus REPL", icon = icons.misc.Terminal },
		{ "<leader>d/", desc = "Search REPL", icon = ui.FindText },
		{ "<leader>du", desc = "Toggle DAP UI", icon = ui.Stacks },
		{ "<leader>dw", desc = "Add watch", icon = ui.Watches },
		{ "<leader>dt", desc = "Float DAP element", icon = ui.FolderOpen },
		{ "<leader>d?", desc = "Show DAP log", icon = ui.Note },

		-- Non-leader shortcuts
		{ "gd", desc = "Go to definition", icon = kind.Function },
		{ "<F5>", desc = "Start / continue debugging", icon = ui.Forward },
		{ "<F9>", desc = "Toggle breakpoint", icon = diagnostics.Debug },
		{ "<F10>", desc = "Step over", icon = ui.ArrowCircleRight },
		{ "<F11>", desc = "Step into", icon = ui.ArrowCircleDown },
		{ "<F12>", desc = "Step out", icon = ui.ArrowCircleUp },
		{ "<M-1>", desc = "Horizontal terminal", icon = icons.misc.Terminal },
		{ "<M-2>", desc = "Vertical terminal", icon = icons.misc.Terminal },
		{ "<M-3>", desc = "Floating terminal", icon = icons.misc.Terminal },
	}

	which_key.setup({
		preset = "modern",
		spec = spec,

		icons = {
			mappings = true,
			keys = {
				Up = ui.BoldArrowUp,
				Down = ui.BoldArrowDown,
				Left = ui.BoldArrowLeft,
				Right = ui.BoldArrowRight,
				C = "󰘴 ",
				M = "󰘵 ",
				D = "󰘳 ",
				S = "󰘶 ",
				CR = "󰌑 ",
				Esc = "󱊷 ",
				BS = "󰁮 ",
				Space = "󱁐 ",
				Tab = ui.Tab,
				F1 = "󱊫 ",
				F2 = "󱊬 ",
				F3 = "󱊭 ",
				F4 = "󱊮 ",
				F5 = "󱊯 ",
				F6 = "󱊰 ",
				F7 = "󱊱 ",
				F8 = "󱊲 ",
				F9 = "󱊳 ",
				F10 = "󱊴 ",
				F11 = "󱊵 ",
				F12 = "󱊶 ",
			},
			breadcrumb = ui.DoubleChevronRight,
			separator = ui.ChevronRight,
			group = ui.Plus,
			ellipsis = ui.Ellipsis,
			colors = false,
		},

		win = {
			padding = { 2, 2, 2, 2 },
			border = "rounded",
		},

		show_help = false,
		show_keys = false,

		plugins = {
			marks = true,
			registers = true,
			spelling = {
				enabled = true,
				suggestions = 20,
			},
			presets = {
				operators = true,
				motions = true,
				text_objects = true,
				windows = true,
				nav = true,
				z = true,
				g = true,
			},
		},

		disable = {
			buftypes = {},
			filetypes = {
				"TelescopePrompt",
			},
		},
	})
end

return M
