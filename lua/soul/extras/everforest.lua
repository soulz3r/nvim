local M = {
    "sainnhe/everforest",
    lazy = false,
    priority = 1000,
}

function M.config()
    vim.g.everforest_background = "hard"
    vim.g.everforest_better_performance = 1

    vim.cmd.colorscheme("everforest")

    local highlights = {
        -- Global floating-window appearance
        NormalFloat = { fg = "#D3C6AA", bg = "#272e33" },
        FloatBorder = { fg = "#859289", bg = "#272e33" },
        FloatTitle = { fg = "#A7C080", bg = "#272e33", bold = true },
        FloatFooter = { fg = "#859289", bg = "#272e33" },

        -- Separators and current-line emphasis
        WinSeparator = { fg = "#859289" },
        CursorLine = { bg = "#343F44" },
        Visual = { bg = "#3D484D" },

        -- Completion-menu styling
        Pmenu = { fg = "#D3C6AA", bg = "#2D353B" },
        PmenuSel = { fg = "#A7C080", bg = "#343F44", bold = true },
        PmenuSbar = { bg = "#343F44" },
        PmenuThumb = { bg = "#859289" },

        -- Mini.nvim components
        MiniFilesBorder = { fg = "#859289", bg = "#272e33" },
        MiniFilesTitle = { fg = "#A7C080", bg = "#272e33", bold = true },
        MiniFilesDirectory = { fg = "#7FBBB3", bg = "#272e33" },
        MiniFilesFile = { fg = "#D3C6AA", bg = "#272e33" },
        MiniFilesNormal = { fg = "#D3C6AA", bg = "#272e33" },
        MiniFilesCursorLine = { bg = "#343F44" },

        MiniNotifyBorder = { fg = "#859289", bg = "#272e33" },
        MiniNotifyNormal = { fg = "#D3C6AA", bg = "#272e33" },
        MiniNotifyTitle = { fg = "#A7C080", bg = "#272e33", bold = true },
        MiniNotifyLspProgress = { fg = "#7FBBB3", bg = "#272e33" },
    }

    for group, opts in pairs(highlights) do
        vim.api.nvim_set_hl(0, group, opts)
    end
end

return M
