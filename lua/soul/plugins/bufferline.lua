local M = {
  'akinsho/bufferline.nvim', version = "*", dependencies = 'nvim-tree/nvim-web-devicons',
  event = "VeryLazy",
}

function M.config()
  require("bufferline").setup { }
end

return M
