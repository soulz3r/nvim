return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",

    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },

    "nvim-telescope/telescope-ui-select.nvim",
  },

  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    -- Replace with your icons module if it exists
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
        path_display = { "smart" },
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
            ["<C-n>"] = actions.cycle_history_next,
            ["<C-p>"] = actions.cycle_history_prev,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
          },

          n = {
            ["<esc>"] = actions.close,
            ["j"] = actions.move_selection_next,
            ["k"] = actions.move_selection_previous,
            ["q"] = actions.close,
          },
        },
      },

      pickers = {
        live_grep = {
          theme = "dropdown",
        },

        grep_string = {
          theme = "dropdown",
        },

        find_files = {
          theme = "dropdown",
          previewer = false,
        },

        buffers = {
          theme = "dropdown",
          previewer = false,
          initial_mode = "normal",

          mappings = {
            i = {
              ["<C-d>"] = actions.delete_buffer,
            },

            n = {
              ["dd"] = actions.delete_buffer,
            },
          },
        },

        colorscheme = {
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

    -- Load extensions AFTER setup
    pcall(telescope.load_extension, "fzf")
    pcall(telescope.load_extension, "ui-select")

    local keymap = vim.keymap.set

    keymap("n", "<leader>fb", "<cmd>Telescope buffers previewer=false<CR>", OPTS("Buffers"))
    keymap("n", "<leader>fB", "<cmd>Telescope git_branches<CR>", OPTS("Git Branches"))
    keymap("n", "<leader>fc", "<cmd>Telescope colorscheme<CR>", OPTS("Colorscheme"))
    keymap("n", "<leader>ff", "<cmd>Telescope find_files<CR>", OPTS("Find Files"))
    keymap("n", "<leader>ft", "<cmd>Telescope live_grep<CR>", OPTS("Live Grep"))
    keymap("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", OPTS("Help"))
    keymap("n", "<leader>fl", "<cmd>Telescope resume<CR>", OPTS("Resume"))
    keymap("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", OPTS("Recent Files"))

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
  end,
}
