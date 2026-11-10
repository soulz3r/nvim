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



        -- Which-key
        WhichKeyNormal = { fg = "#D3C6AA", bg = "#272e33" },
        WhichKeyBorder = { fg = "#859289", bg = "#272e33" },
        WhichKeyTitle = { fg = "#A7C080", bg = "#272e33", bold = true },
        WhichKeyDesc = { fg = "#D3C6AA" },
        WhichKeyGroup = { fg = "#7FBBB3", bold = true },
        WhichKeySeparator = { fg = "#859289" },
        WhichKeyValue = { fg = "#859289" },

        -- Telescope: prompt, results, preview, and all window borders
        TelescopeNormal = { fg = "#D3C6AA", bg = "#272e33" },
        TelescopeBorder = { fg = "#859289", bg = "#272e33" },
        TelescopeTitle = { fg = "#A7C080", bg = "#272e33", bold = true },
        TelescopePromptNormal = { fg = "#D3C6AA", bg = "#2D353B" },
        TelescopePromptBorder = { fg = "#859289", bg = "#2D353B" },
        TelescopePromptTitle = { fg = "#A7C080", bg = "#2D353B", bold = true },
        TelescopeResultsNormal = { fg = "#D3C6AA", bg = "#272e33" },
        TelescopeResultsBorder = { fg = "#859289", bg = "#272e33" },
        TelescopeResultsTitle = { fg = "#A7C080", bg = "#272e33", bold = true },
        TelescopePreviewNormal = { fg = "#D3C6AA", bg = "#272e33" },
        TelescopePreviewBorder = { fg = "#859289", bg = "#272e33" },
        TelescopePreviewTitle = { fg = "#A7C080", bg = "#272e33", bold = true },
        TelescopeSelection = { fg = "#A7C080", bg = "#343F44", bold = true },
        TelescopeSelectionCaret = { fg = "#A7C080", bg = "#343F44" },
        TelescopeMatching = { fg = "#A7C080", bold = true },

        -- Blink.cmp
        BlinkCmpMenu = { fg = "#D3C6AA", bg = "#272e33" },
        BlinkCmpMenuBorder = { fg = "#859289", bg = "#272e33" },
        BlinkCmpMenuSelection = { fg = "#A7C080", bg = "#343F44", bold = true },
        BlinkCmpDoc = { fg = "#D3C6AA", bg = "#272e33" },
        BlinkCmpDocBorder = { fg = "#859289", bg = "#272e33" },
        BlinkCmpSignatureHelp = { fg = "#D3C6AA", bg = "#272e33" },
        BlinkCmpSignatureHelpBorder = { fg = "#859289", bg = "#272e33" },

        -- Common LSP floating windows
        LspInfoBorder = { fg = "#859289", bg = "#272e33" },
        DiagnosticFloating = { fg = "#D3C6AA", bg = "#272e33" },
        DiagnosticFloatingError = { fg = "#E67E80", bg = "#272e33" },
        DiagnosticFloatingWarn = { fg = "#DBBC7F", bg = "#272e33" },
        DiagnosticFloatingInfo = { fg = "#7FBBB3", bg = "#272e33" },
        DiagnosticFloatingHint = { fg = "#A7C080", bg = "#272e33" },

        -- Mini.nvim components
        MiniFilesBorder = { fg = "#859289", bg = "NONE" },
        MiniFilesTitle = { fg = "#A7C080", bg = "NONE", bold = true },
        MiniFilesDirectory = { fg = "#7FBBB3", bg = "NONE" },
        MiniFilesFile = { fg = "#D3C6AA", bg = "NONE" },
        MiniFilesNormal = { bg = "NONE" },
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
