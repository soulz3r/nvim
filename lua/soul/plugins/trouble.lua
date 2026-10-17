local M = {
  "folke/trouble.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
}

function M.config()
  require("trouble").setup({
    auto_close = true,
    auto_preview = true,
    focus = true,
    follow = false,
    indent_guides = true,
    max_items = 200,
    multiline = true,
    warn_no_results = false,
    open_no_results = false,

    win = {
      type = "float",
      relative = "editor",
      position = "center",
      size = {
        width = 0.75,
        height = 0.65,
      },
      border = "rounded",
      title = " Diagnostics ",
      title_pos = "center",
    },

    preview = {
      type = "float",
      relative = "editor",
      border = "rounded",
      title = " Preview ",
      title_pos = "center",
      size = {
        width = 0.35,
        height = 0.3,
      },
      zindex = 200,
    },

    icons = {
      indent = {
        middle = " ",
        last = " ",
        top = " ",
        ws = "│  ",
      },
    },

    modes = {
      diagnostics = {
        mode = "diagnostics",
      },

      diagnostics_buffer = {
        mode = "diagnostics",
        filter = {
          buf = 0,
        },
      },
    },
  })

  local map = vim.keymap.set

  map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", {
    desc = "Diagnostics (Workspace)",
  })

  map("n", "<leader>xX", "<cmd>Trouble diagnostics_buffer toggle<cr>", {
    desc = "Diagnostics (Buffer)",
  })

  map("n", "<leader>xs", "<cmd>Trouble symbols toggle<cr>", {
    desc = "Symbols",
  })

  map("n", "<leader>xl", "<cmd>Trouble lsp toggle<cr>", {
    desc = "LSP References",
  })

  map("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", {
    desc = "Location List",
  })

  map("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", {
    desc = "Quickfix List",
  })
end

return M

