local M = {
  "jinh0/eyeliner.nvim",
  event = "VeryLazy",
}

function M.config()
  require 'eyeliner'.setup {
    highlight_on_key = true,

    dim = true,

    max_length = 9999,

    disabled_filetypes = { "alpha" },

    disabled_buftypes = { "alpha" },

    default_keymaps = true,
  }
end

return M
