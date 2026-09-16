local M = {
  "goolord/alpha-nvim",
  event = "VimEnter",
}

function M.config()
  local dashboard = require "alpha.themes.dashboard"
  local icons = require "soul.icons"
  local utils = require "alpha.utils"

  -- Everforest colors
  vim.api.nvim_set_hl(0, "AlphaGreen", {
    fg = "#A7C080",
  })

  vim.api.nvim_set_hl(0, "AlphaTeal", {
    fg = "#7FBBB3",
  })

  vim.api.nvim_set_hl(0, "AlphaYellow", {
    fg = "#DBBC7F",
  })

  vim.api.nvim_set_hl(0, "AlphaRed", {
    fg = "#E67E80",
  })

  local function button(sc, txt, keybind, keybind_opts)
    local b = dashboard.button(sc, txt, keybind, keybind_opts)
    b.opts.hl_shortcut = "Include"
    return b
  end

  -- Exact PowerShell header
  local header = {
    "███████╗ ██████╗ ██╗   ██╗██╗灵魂",
    "██╔════╝██╔═══██╗██║da ██║██║士兵",
    "███████╗██║no ██║██║em ██║██║国王",
    "╚════██║██║me ██║██║on ██║██║没了",
    "███████║╚██████╔╝╚██████╔╝███████╗",
    "╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝",
  }

  dashboard.section.header.val = header

  -- Highlight ranges are defined using CHARACTER positions.
  -- alpha.utils.charhl_to_bytehl() converts them correctly
  -- for UTF-8 characters such as 灵魂 / 士兵 / 国王 / 没了.
  local header_hl = {
    -- ███████╗ ██████╗ ██╗   ██╗██╗灵魂
    {
      { "AlphaGreen", 0, 29 },
      { "AlphaYellow", 29, 31 },
    },

    -- ██╔════╝██╔═══██╗██║da ██║██║士兵
    {
      { "AlphaGreen", 0, 20 },
      { "AlphaRed", 20, 22 },
      { "AlphaGreen", 22, 29 },
      { "AlphaYellow", 29, 31 },
    },

    -- ███████╗██║no ██║██║em ██║██║国王
    {
      { "AlphaGreen", 0, 11 },
      { "AlphaYellow", 11, 13 },
      { "AlphaGreen", 13, 20 },
      { "AlphaRed", 20, 22 },
      { "AlphaGreen", 22, 29 },
      { "AlphaYellow", 29, 31 },
    },

    -- ╚════██║██║me ██║██║on ██║██║没了
    {
      { "AlphaGreen", 0, 11 },
      { "AlphaYellow", 11, 13 },
      { "AlphaGreen", 13, 20 },
      { "AlphaRed", 20, 22 },
      { "AlphaGreen", 22, 29 },
      { "AlphaYellow", 29, 31 },
    },

    -- ███████║╚██████╔╝╚██████╔╝███████╗
    {
      { "AlphaGreen", 0, 34 },
    },

    -- ╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝
    {
      { "AlphaGreen", 0, 34 },
    },
  }

  dashboard.section.header.opts = {
    position = "center",
    hl = utils.charhl_to_bytehl(header_hl, header),
  }

  dashboard.section.buttons.val = {
    button("f", icons.ui.Files .. " Find file", ":Telescope find_files <CR>"),
    button("e", icons.ui.Folder .. " Open Explorer", ":lua open_mini_files()<CR>"),
    button("n", icons.ui.NewFile .. " New file", ":ene <BAR> startinsert <CR>"),
    button("p", icons.git.Repo .. " Find project", ":lua require('telescope').extensions.projects.projects()<CR>"),
    button("r", icons.ui.History .. " Recent files", ":Telescope oldfiles <CR>"),
    button("t", icons.ui.Text .. " Find text", ":Telescope live_grep <CR>"),
    button("c", icons.ui.Gear .. " Config", ":e " .. vim.fn.stdpath("config") .. "/init.lua<CR>"),
    button("q", icons.ui.SignOut .. " Quit", ":qa<CR>"),
  }

  local function footer()
    return "soulz3r"
  end

  dashboard.section.footer.val = footer()

  dashboard.section.buttons.opts.hl = "Include"
  dashboard.section.footer.opts.hl = "Type"

  dashboard.opts.opts.noautocmd = true
  require("alpha").setup(dashboard.opts)

  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyVimStarted",
    callback = function()
      local stats = require("lazy").stats()
      local ms = math.floor(stats.startuptime * 100 + 0.5) / 100

      dashboard.section.footer.val =
        "Loaded " .. stats.count .. " plugins in " .. ms .. "ms"

      pcall(vim.cmd.AlphaRedraw)
    end,
  })

  vim.api.nvim_create_autocmd({ "User" }, {
    pattern = { "AlphaReady" },
    callback = function()
      vim.cmd [[
        set laststatus=0 | autocmd BufUnload <buffer> set laststatus=0
        set showtabline=0 | autocmd BufUnload <buffer> set showtabline=2
      ]]
    end,
  })
end

return M
