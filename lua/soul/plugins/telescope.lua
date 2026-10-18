local M = {
  "nvim-telescope/telescope.nvim",

  dependencies = {
    "nvim-lua/plenary.nvim",

    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },

    "nvim-telescope/telescope-ui-select.nvim",
  },
}

function M.config()

  local telescope = require("telescope")
  local actions = require("telescope.actions")
  local actions_layout = require("telescope.actions.layout")

  local ok, icons = pcall(require, "soul.icons")

  if not ok then
    icons = {
      ui = {
        Telescope = "",
        Forward = "",
      },
    }
  end

  telescope.setup({
    defaults = {
      winblend = 0,

      prompt_prefix = icons.ui.Telescope .. " ",
      selection_caret = icons.ui.Forward .. " ",
      entry_prefix = " ",

      initial_mode = "insert",
      selection_strategy = "reset",
      sorting_strategy = "descending",
      scroll_strategy = "cycle",

      path_display = { "tail" },
      color_devicons = true,

      vimgrep_arguments = {
        "rg",
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case",
        "--hidden",
        "--glob=!.git/",
      },

      mappings = {
        i = {
          ["<C-n>"] = actions.move_selection_next,
          ["<C-p>"] = actions.move_selection_previous,

          ["<C-j>"] = actions.move_selection_next,
          ["<C-k>"] = actions.move_selection_previous,

          ["<C-a>"] = actions.select_all,
          ["<C-x>"] = actions.drop_all,

          ["<C-Up>"] = actions.cycle_history_prev,
          ["<C-Down>"] = actions.cycle_history_next,

          ["<C-space>"] = actions_layout.toggle_preview,
          ["<C-f>"] = actions.to_fuzzy_refine,
        },

        n = {
          ["<C-space>"] = actions_layout.toggle_preview,
          ["<C-n>"] = actions.move_selection_next,
          ["<C-p>"] = actions.move_selection_previous,
          ["<C-f>"] = actions.to_fuzzy_refine,
          ["<C-a>"] = actions.select_all,
          ["<C-x>"] = actions.drop_all,

          ["dd"] = actions.delete_buffer,

          ["<esc>"] = actions.close,
          ["q"] = actions.close,

          ["j"] = actions.move_selection_next,
          ["k"] = actions.move_selection_previous,

          ["gg"] = actions.move_to_top,
          ["G"] = actions.move_to_bottom,
        },
      },
    },

    pickers = {
      find_files = {
        theme = "dropdown",
        previewer = false,
      },

      live_grep = {
        theme = "dropdown",
      },

      grep_string = {
        theme = "dropdown",
      },

      buffers = {
        theme = "dropdown",
        previewer = false,
        initial_mode = "insert",
        path_display = { "tail" },

        mappings = {
          i = {
            ["<C-n>"] = actions.move_selection_next,
            ["<C-p>"] = actions.move_selection_previous,
            ["<C-d>"] = actions.delete_buffer,
          },

          n = {
            ["dd"] = actions.delete_buffer,
          },
        },
      },

      oldfiles = {
        theme = "dropdown",
        previewer = false,
      },

      marks = {
        theme = "dropdown",
        previewer = true,

        mappings = {
          n = {
            ["dd"] = actions.delete_mark,
          },
        },
      },

      registers = {
        theme = "dropdown",
        previewer = true,

        mappings = {
          n = {
            ["dd"] = function(prompt_bufnr)
              local action_state = require("telescope.actions.state")
              local picker = action_state.get_current_picker(prompt_bufnr)
              local selection = action_state.get_selected_entry()

              if not selection then
                return
              end

              picker:delete_selection(function()
                vim.fn.setreg(selection.value, "")
                return true
              end)
            end,
          },
        },
      },

      help_tags = {
        theme = "dropdown",
      },

      git_branches = {
        theme = "dropdown",
      },

      colorscheme = {
        theme = "dropdown",
        enable_preview = true,
      },

      lsp_references = {
        theme = "dropdown",
        initial_mode = "normal",
      },

      lsp_definitions = {
        theme = "dropdown",
        initial_mode = "normal",
      },

      lsp_declarations = {
        theme = "dropdown",
        initial_mode = "normal",
      },

      lsp_implementations = {
        theme = "dropdown",
        initial_mode = "normal",
      },
    },

    extensions = {
      fzf = {
        fuzzy = true,
        override_generic_sorter = true,
        override_file_sorter = true,
        case_mode = "smart_case",
      },

      ["ui-select"] = require("telescope.themes").get_dropdown({}),
    },
  })

  pcall(telescope.load_extension, "fzf")
  pcall(telescope.load_extension, "ui-select")

  local keymap = vim.keymap.set

  keymap(
    "n",
    "<leader>fb",
    "<cmd>Telescope buffers previewer=false<CR>",
    OPTS("Buffers")
  )

  keymap(
    "n",
    "<leader>fC",
    "<cmd>Telescope colorscheme<CR>",
    OPTS("Colorscheme")
  )

  keymap(
    "n",
    "<leader>ff",
    "<cmd>Telescope find_files<CR>",
    OPTS("Find Files")
  )

  keymap(
    "n",
    "<leader>ft",
    "<cmd>Telescope live_grep<CR>",
    OPTS("Live Grep")
  )

  keymap(
    "n",
    "<leader>fh",
    "<cmd>Telescope help_tags<CR>",
    OPTS("Help")
  )

  keymap(
    "n",
    "<leader>fr",
    "<cmd>Telescope resume<CR>",
    OPTS("Resume")
  )

  keymap(
    "n",
    "<leader>fo",
    "<cmd>Telescope oldfiles<CR>",
    OPTS("Recent Files")
  )

  keymap(
    "n",
    "<leader>flr",
    "<cmd>Telescope lsp_references<CR>",
    OPTS("LSP References")
  )

  keymap(
    "n",
    "<leader>fld",
    "<cmd>Telescope lsp_definitions<CR>",
    OPTS("LSP Definitions")
  )

  keymap(
    "n",
    "<leader>flD",
    "<cmd>Telescope lsp_declarations<CR>",
    OPTS("LSP Declarations")
  )

  keymap(
    "n",
    "<leader>fli",
    "<cmd>Telescope lsp_implementations<CR>",
    OPTS("LSP Implementations")
  )

  keymap(
    "n",
    "<leader>flt",
    "<cmd>Telescope lsp_type_definitions<CR>",
    OPTS("LSP Type Definitions")
  )

  keymap(
    "n",
    "<leader>fgb",
    "<cmd>Telescope git_branches<CR>",
    OPTS("Git Branches")
  )

  keymap(
    "n",
    "<leader>fgc",
    "<cmd>Telescope git_commits<CR>",
    OPTS("Git Commits")
  )

  keymap(
    "n",
    "<leader>fgs",
    "<cmd>Telescope git_status<CR>",
    OPTS("Git Status")
  )

  keymap(
    "n",
    "<leader>fgS",
    "<cmd>Telescope git_stash<CR>",
    OPTS("Git Stash")
  )

  keymap(
    "n",
    "<leader>fgf",
    "<cmd>Telescope git_files<CR>",
    OPTS("Git Files")
  )

  keymap(
    "n",
    "<leader>fgB",
    "<cmd>Telescope git_bcommits<CR>",
    OPTS("Git Buffer Commits")
  )

  keymap(
    "n",
    "<leader>fs",
    "<cmd>Telescope treesitter<CR>",
    OPTS("Treesitter Symbols")
  )

  keymap(
    "n",
    "<leader>fx",
    "<cmd>Telescope diagnostics<CR>",
    OPTS("Diagnostics")
  )

  keymap(
    "n",
    "<leader>fch",
    "<cmd>Telescope command_history<CR>",
    OPTS("Command History")
  )

  keymap(
    "n",
    "<leader>fcc",
    "<cmd>Telescope commands<CR>",
    OPTS("Commands")
  )

  keymap(
    "n",
    "<leader>fy",
    "<cmd>Telescope registers<CR>",
    OPTS("Registers")
  )

  keymap(
    "n",
    "<leader>fm",
    "<cmd>Telescope marks<CR>",
    OPTS("Marks")
  )

  pcall(function()
    keymap(
      "n",
      "<leader>fp",
      "<cmd>lua require('telescope').extensions.projects.projects()<CR>",
      OPTS("Projects")
    )
  end)

  local highlights = {
    "TelescopeNormal",
    "TelescopeBorder",
    "TelescopePromptNormal",
    "TelescopePromptBorder",
    "TelescopePreviewNormal",
    "TelescopePreviewBorder",
    "TelescopeResultsNormal",
    "TelescopeResultsBorder",
  }

  for _, hl in ipairs(highlights) do
    vim.api.nvim_set_hl(0, hl, { bg = "none" })
  end
end

return M
