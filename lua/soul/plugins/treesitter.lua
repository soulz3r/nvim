local M = {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPost", "BufNewFile" },
  build = ":TSUpdate",
}

function M.config()
  require("nvim-treesitter.configs").setup {
    ensure_installed = { "lua", "gdscript", "godot_resource", "gdshader", "markdown", "markdown_inline", "bash", "python", "cpp" },
    highlight = { enable = true },
    indent = { enable = false },
  }
end

return M
