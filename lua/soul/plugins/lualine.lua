local M = {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
}

function M.config()
  require("lualine").setup({
    options = {
      icons_enabled = true,
      theme = "auto",

      component_separators = {
        left = "│",
        right = "│",
      },

      section_separators = {
        left = "",
        right = "",
      },

      disabled_filetypes = {
        statusline = {},
        winbar = {},
      },

      ignore_focus = {},
      always_divide_middle = true,
      always_show_tabline = false,
      globalstatus = false,

      refresh = {
        statusline = 1000,
        tabline = 1000,
        winbar = 1000,
        refresh_time = 100,

        events = {
          "WinEnter",
          "BufEnter",
          "BufWritePost",
          "SessionLoadPost",
          "FileChangedShellPost",
          "VimResized",
          "Filetype",
          "CursorMoved",
          "CursorMovedI",
          "ModeChanged",
        },
      },
    },

    sections = {
      lualine_a = {
        {
          "mode",
          fmt = function(str)
            local modes = {
              NORMAL = "N",
              INSERT = "I",
              VISUAL = "V",
              ["V-LINE"] = "VL",
              ["V-BLOCK"] = "VB",
              REPLACE = "R",
              COMMAND = "C",
              TERMINAL = "T",
            }

            return modes[str] or str
          end,
        },
      },

      lualine_b = {'branch'},

      lualine_c = {'diagnostics'},

      lualine_x = {'location'},

      lualine_y = {},

      lualine_z = {
        {
          "progress",
          fmt = function(str)
            local position = {
              Top = "T",
              Bot = "B",
            }

            return position[str] or str
          end,
        },
      },

    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {
        "filename",
      },
      lualine_x = {
        "location",
      },
      lualine_y = {},
      lualine_z = {},
    },

    tabline = {},
    winbar = {},
    inactive_winbar = {},
    extensions = {},
  })
end

return M
