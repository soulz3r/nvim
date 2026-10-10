local M = {
  "nvim-treesitter/nvim-treesitter",

  -- The new nvim-treesitter does NOT support lazy-loading.
  lazy = false,

  -- Keep parsers updated whenever the plugin updates.
  build = ":TSUpdate",
}

function M.config()
  local treesitter = require("nvim-treesitter")

  -- Where parsers and queries are installed.
  treesitter.setup({
    install_dir = vim.fn.stdpath("data") .. "/site",
  })

  -- Languages I actually use.
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

  -- Enable Treesitter highlighting.
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

  -- Treesitter folding.
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
