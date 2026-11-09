local M = {
    "sainnhe/everforest",
    lazy = false,
    priority = 1000,
}

function M.config()
    vim.g.everforest_background = "hard"
    vim.g.everforest_better_performance = 1

    vim.cmd.colorscheme("everforest")
end

return M
