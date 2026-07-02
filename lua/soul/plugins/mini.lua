return {
  "nvim-mini/mini.files",
  version = "*",
  dependencies = {
    "nvim-mini/mini.pick",
    "nvim-mini/mini.surround",
    "nvim-mini/mini.extra",
    "nvim-mini/mini.icons",
    "nvim-mini/mini.pairs",
  },

  config = function()
    local MiniFiles = require("mini.files")

    require("mini.icons").setup()
    require("mini.pairs").setup()
    require("mini.surround").setup()

    MiniFiles.setup({
      mappings = {
        go_in = "<CR>",
        go_in_plus = "<CR>",
        go_out = ",",
        go_out_plus = ",",
      },
    })

    -- Change working directory to selected entry
    local set_cwd = function()
      local entry = MiniFiles.get_fs_entry()

      if not entry or not entry.path then
        return vim.notify("Cursor is not on a valid entry")
      end

      local path = entry.path

      if vim.fn.isdirectory(path) == 1 then
        vim.cmd.cd(path)
      else
        vim.cmd.cd(vim.fs.dirname(path))
      end

      vim.notify("cwd → " .. vim.fn.getcwd())
    end

    -- Keymap inside mini.files buffer
    vim.api.nvim_create_autocmd("User", {
      pattern = "MiniFilesBufferCreate",
      callback = function(args)
        vim.keymap.set("n", "g~", set_cwd, {
          buffer = args.data.buf_id,
          desc = "Set current working directory",
        })
      end,
    })

    -- Open mini.files in current file directory
    local function open_mini_files()
      vim.opt.showtabline = 0
      vim.opt.laststatus = 0

      local path = vim.api.nvim_buf_get_name(0)

      if path == "" then
        path = vim.fn.getcwd()
      end

      MiniFiles.open(vim.fs.dirname(path))

      vim.api.nvim_create_autocmd("WinClosed", {
        once = true,
        callback = function()
          vim.opt.laststatus = 3
          vim.opt.showtabline = 2
        end,
      })
    end

    vim.keymap.set("n", "<leader>e", open_mini_files, {
      desc = "Open mini.files",
    })
  end,
}
