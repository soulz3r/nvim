local M = {
  "stevearc/dressing.nvim",
  event = "VeryLazy",
}

function M.config()
  require("dressing").setup {
    input = {
      enabled = true,

      default_prompt = "Input:",

      title_pos = "left",

      insert_only = true,

      start_in_insert = true,

      -- anchor = "SW",
      border = "rounded",
      relative = "cursor",

      prefer_width = 40,
      width = nil,
      -- min_width = {20, 0.2} means "the greater of 20 columns or 20% of total"
      max_width = { 140, 0.9 },
      min_width = { 20, 0.2 },

      buf_options = {},
      win_options = {
        winblend = 10,
        wrap = false,
        list = true,
        listchars = "precedes:…,extends:…",
        sidescrolloff = 0,
      },
    },
    select = {
      enabled = true,

      backend = { "nui", "telescope", "fzf_lua", "fzf", "builtin" },

      trim_prompt = true,

      nui = {
        position = "50%",
        size = nil,
        relative = "editor",
        border = {
          style = "rounded",
        },
        buf_options = {
          swapfile = false,
          filetype = "DressingSelect",
        },
        win_options = {
          winblend = 10,
        },
        max_width = 80,
        max_height = 40,
        min_width = 40,
        min_height = 10,
      },

      builtin = {
        -- anchor = "NW",
        border = "rounded",
        relative = "editor",

        buf_options = {},
        win_options = {
          winblend = 10,
          cursorline = true,
          cursorlineopt = "both",
        },

        -- max_width = {140, 0.8} means "the lesser of 140 columns or 80% of total"
        width = nil,
        max_width = { 140, 0.8 },
        min_width = { 40, 0.2 },
        height = nil,
        max_height = 0.9,
        min_height = { 10, 0.2 },

        mappings = {
          ["<Esc>"] = "Close",
          ["<C-c>"] = "Close",
          ["<CR>"] = "Confirm",
        },
      },
    },
  }
end

return M
