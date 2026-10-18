local M = {
  "folke/which-key.nvim",
}

function M.config()
  local which_key = require("which-key")
  local icons = require("soul.icons")

  which_key.setup({
    preset = "modern",

    spec = {
      {
        "<leader>f",
        group = "Telescope",
        icon = icons.which_key.Telescope,
      },
      {
        "<leader>e",
        group = "Explorer",
        icon = icons.which_key.Explorer,
      },

      {
        "<leader>h",
        group = "Mark Harpoon",
        icon = icons.which_key.Mark,
      },

      {
        "<leader>l",
        group = "Code",
        icon = icons.which_key.Code,
      },

      {
        "<leader>L",
        group = "Plugins",
        icon = icons.which_key.Plugins,
      },

      {
        "<leader>n",
        group = "Neovim",
        icon = icons.which_key.Neovim,
      },

      {
        "<leader>q",
        group = "Exit",
        icon = icons.which_key.Exit,
      },

      {
        "<leader>w",
        group = "Save",
        icon = icons.which_key.Save,
      },

      {
        "<leader>ff",
        desc = "Find Files",
        icon = icons.ui.Telescope,
      },

      {
        "<leader>ft",
        desc = "Live Grep",
        icon = icons.ui.FindText,
      },

      {
        "<leader>fb",
        desc = "Buffers",
        icon = icons.ui.Files,
      },

      {
        "<leader>fC",
        desc = "Colorscheme",
        icon = icons.ui.Pencil,
      },

      {
        "<leader>fh",
        desc = "Help Tags",
        icon = icons.ui.Note,
      },

      {
        "<leader>fr",
        desc = "Resume",
        icon = icons.ui.Forward,
      },

      {
        "<leader>fo",
        desc = "Old Files",
        icon = icons.ui.History,
      },

      {
        "<leader>fm",
        desc = "Marks",
        icon = icons.ui.BookMark,
      },

      {
        "<leader>fy",
        desc = "Registers",
        icon = icons.ui.Files,
      },

      {
        "<leader>flr",
        desc = "References",
        icon = icons.kind.Reference,
      },

      {
        "<leader>fld",
        desc = "Definition",
        icon = icons.kind.Function,
      },

      {
        "<leader>flD",
        desc = "Declaration",
        icon = icons.kind.Function,
      },

      {
        "<leader>fli",
        desc = "Implementation",
        icon = icons.kind.Interface,
      },

      {
        "<leader>flt",
        desc = "Type Definition",
        icon = icons.kind.TypeParameter,
      },

      {
        "<leader>wa",
        desc = "Save All",
        icon = icons.ui.Files,
      },

      {
        "<leader>qq",
        desc = "Quit",
        icon = icons.ui.Close,
      },

      {
        "<leader>qa",
        desc = "Quit All",
        icon = icons.ui.BoldClose,
      },
    },

    icons = {
      mappings = true,

      keys = {
        Up = icons.ui.BoldArrowUp,
        Down = icons.ui.BoldArrowDown,
        Left = icons.ui.BoldArrowLeft,
        Right = icons.ui.BoldArrowRight,

        C = "󰘴 ",
        M = "󰘵 ",
        D = "󰘳 ",
        S = "󰘶 ",

        CR = "󰌑 ",
        Esc = "󱊷 ",
        BS = "󰁮 ",
        Space = "󱁐 ",
        Tab = icons.ui.Tab,

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

      breadcrumb = icons.ui.DoubleChevronRight,
      separator = icons.ui.ChevronRight,
      group = icons.ui.Plus,
      ellipsis = icons.ui.Ellipsis,

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

