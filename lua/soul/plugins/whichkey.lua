local M = {
  "folke/which-key.nvim",
}

function M.config()
  local which_key = require("which-key")

  which_key.setup({
    spec = {
      { "<leader>f", group = "Telescope" },
      { "<leader>h", group = "Mark Harpoon" },
      { "<leader>l", group = "LSP" },
      { "<leader>L", group = "Lazy" },
      { "<leader>n", group = "Neovim" },
      { "<leader>q", group = "Quit" },
      { "<leader>w", group = "Save" },
    },

    icons = {
      mappings = false,
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
        operators = false,
        motions = false,
        text_objects = false,
        windows = false,
        nav = false,
        z = false,
        g = false,
      },
    },

    disable = {
      buftypes = {},
      filetypes = { "TelescopePrompt" },
    },
  })
end

return M
