local M = {
  "nvim-mini/mini.files",
  version = "*",
  dependencies = {
    "nvim-mini/mini.pick",
    "nvim-mini/mini.extra",
    "nvim-mini/mini.icons",
    "nvim-mini/mini.pairs",
  },
}

function M.config()
  local MiniFiles = require("mini.files")

  require("mini.icons").setup()
  require("mini.pairs").setup()

  local show_hidden = false

  local function filter_show()
    return true
  end

  local function filter_hide(entry)
    return not vim.startswith(entry.name, ".")
  end

  local function toggle_hidden()
    show_hidden = not show_hidden

    MiniFiles.refresh({
      content = {
        filter = show_hidden and filter_show or filter_hide,
      },
    })
  end

  MiniFiles.setup({
    mappings = {
      go_in = "<CR>",
      go_in_plus = "L",
      go_out = ",",
      go_out_plus = "H",
      synchronize = "s",
    },

    options = {
      use_as_default_explorer = false,
      permanent_delete = false,
    },

    windows = {
      preview = true,
      width_focus = 32,
      width_nofocus = 18,
      width_preview = 48,
    },

    content = {
      filter = filter_hide,
    },
  })

  local function set_cwd()
    local entry = MiniFiles.get_fs_entry()

    if not entry or not entry.path then
      return vim.notify("Cursor is not on a valid entry", vim.log.levels.WARN)
    end

    local path = entry.path
    local directory = vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path)

    vim.cmd.cd(vim.fn.fnameescape(directory))
    vim.notify("Working directory: " .. vim.fn.fnamemodify(directory, ":~"))
  end

  local function open_entry()
    local entry = MiniFiles.get_fs_entry()

    if not entry or not entry.path then
      return
    end

    vim.ui.open(entry.path)
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesBufferCreate",
    callback = function(args)
      local buf = args.data.buf_id

      vim.keymap.set("n", "g~", set_cwd, {
        buffer = buf,
        desc = "Set working directory",
      })

      vim.keymap.set("n", "H", toggle_hidden, {
        buffer = buf,
        desc = "Toggle hidden files",
      })

      vim.keymap.set("n", "gx", open_entry, {
        buffer = buf,
        desc = "Open with system application",
      })
    end,
  })

  function M.open(path)
    MiniFiles.open(path or vim.fn.getcwd())
  end

  vim.keymap.set("n", "<leader>e", M.open, {
    desc = "Open Mini.files",
  })

  local highlights = {
    MiniFilesBorder = { fg = "#859289", bg = "NONE" },
    MiniFilesTitle = { fg = "#A7C080", bg = "NONE", bold = true },
    MiniFilesDirectory = { fg = "#7FBBB3", bg = "NONE" },
    MiniFilesFile = { fg = "#D3C6AA", bg = "NONE" },
    MiniFilesNormal = { bg = "NONE" },
    MiniFilesCursorLine = { bg = "#343F44" },
  }

  for group, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

return M
