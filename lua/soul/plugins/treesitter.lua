local M = {
  "nvim-treesitter/nvim-treesitter",
  lazy = false,
  build = ":TSUpdate",
}

function M.config()
  local treesitter = require("nvim-treesitter")

  local filetypes = {
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
  }

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
    pattern = filetypes,
    callback = function(args)
      local ok = pcall(vim.treesitter.start, args.buf)

      if ok then
        local win = vim.api.nvim_get_current_win()
        vim.wo[win].foldmethod = "expr"
        vim.wo[win].foldexpr = "v:lua.vim.treesitter.foldexpr()"
      end
    end,
  })
end

return M
