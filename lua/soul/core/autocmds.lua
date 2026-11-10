vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  callback = function()
    vim.opt_local.formatoptions:remove({ "c", "r", "o" })
  end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function(args)
    local buf = args.buf

    if vim.bo[buf].buftype ~= "nofile"
      or not vim.bo[buf].readonly
      or vim.bo[buf].modifiable
    then
      return
    end

    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      local config = vim.api.nvim_win_get_config(win)

      if config.relative ~= "" then
        vim.bo[buf].filetype = "project-output"
        return
      end
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "netrw",
    "Jaq",
    "qf",
    "git",
    "help",
    "man",
    "lspinfo",
    "oil",
    "spectre_panel",
    "lir",
    "DressingSelect",
    "tsplayground",
    "mininotify-history",
  },
  callback = function(args)
    vim.bo[args.buf].buflisted = false

    vim.keymap.set("n", "q", function()
      pcall(vim.cmd, "close")
    end, {
      buffer = args.buf,
      silent = true,
      desc = "Close utility window",
    })
  end,
})

vim.api.nvim_create_autocmd("CmdWinEnter", {
  callback = function()
    vim.cmd("quit")
  end,
})

vim.api.nvim_create_autocmd({ "VimResized" }, {
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  pattern = { "!vim" },
  callback = function()
    vim.cmd("checktime")
  end,
})

vim.api.nvim_create_autocmd({ "TextYankPost" }, {
  callback = function()
    vim.hl.on_yank({ higroup = "Visual", timeout = 40 })
  end,
})

vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "gitcommit", "markdown", "NeogitCommitMessage" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = false
  end,
})
