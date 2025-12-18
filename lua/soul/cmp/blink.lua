return {
  'saghen/blink.cmp',
  dependencies = { 'rafamadriz/friendly-snippets' },
  version = '1.*',

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = { preset = 'default' },
    completion = {
      ghost_text = { enabled = false },
      menu = { border = "rounded" },
      documentation = {
        auto_show = true,
        window = { border = "rounded" },
      },
      accept = {
        auto_brackets = { enabled = true },
      },
    },
    appearance = {
      nerd_font_variant = 'nerd',
    },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },

  opts_extend = { "sources.default" },

  config = function(_, opts)
    require("blink.cmp").setup(opts)

    -- Transparent backgrounds
    vim.api.nvim_set_hl(0, "Pmenu", { bg = "none" })
    vim.api.nvim_set_hl(0, "PmenuSel", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
    vim.api.nvim_set_hl(0, "PmenuSbar", { bg = "none" })
    vim.api.nvim_set_hl(0, "PmenuThumb", { bg = "none" })

    -- BlinkCmp-specific
    vim.api.nvim_set_hl(0, "BlinkCmpMenu", { bg = "none" })
    vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { bg = "none" })
    vim.api.nvim_set_hl(0, "BlinkCmpDoc", { bg = "none" })
    vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { bg = "none" })
    vim.api.nvim_set_hl(0, "BlinkCmpSignatureHelp", { bg = "none" })
    vim.api.nvim_set_hl(0, "BlinkCmpSignatureHelpBorder", { bg = "none" })
  end,
}

