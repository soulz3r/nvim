local M = {
  "nvim-treesitter/nvim-treesitter",

  lazy = false,

  build = ":TSUpdate",
}

function M.config()
  local treesitter = require("nvim-treesitter")

  treesitter.setup({
    install_dir = vim.fn.stdpath("data") .. "/site",
  })

  treesitter.install({
    "c",
    "cpp",
    "lua",
    "vim",
    "vimdoc",
    "bash",
    "json",
    "yaml",
    "markdown",
    "markdown_inline",
    "python",
    "rust",
    "toml",
    "javascript",
    "typescript",
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = {
      "c",
      "cpp",
      "lua",
      "vim",
      "bash",
      "json",
      "yaml",
      "markdown",
      "python",
      "rust",
      "toml",
      "javascript",
      "typescript",
    },

    callback = function()
      vim.treesitter.start()
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = {
      "c",
      "cpp",
      "lua",
      "vim",
      "bash",
      "json",
      "yaml",
      "markdown",
      "python",
      "rust",
      "toml",
      "javascript",
      "typescript",
    },

    callback = function()
      vim.wo.foldmethod = "expr"
      vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end,
  })
end

return M
