local M = {
  "goolord/alpha-nvim",
  event = "VimEnter",
}

function M.config()
  local dashboard = require("alpha.themes.dashboard")
  local icons = require("soul.icons")
  local utils = require("alpha.utils")

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

  vim.api.nvim_set_hl(0, "AlphaMuted", {
    fg = "#859289",
  })

  vim.api.nvim_set_hl(0, "AlphaBlue", {
    fg = "#7FBBB3",
  })

  vim.api.nvim_set_hl(0, "AlphaAqua", {
    fg = "#83C092",
  })

  vim.api.nvim_set_hl(0, "AlphaPurple", {
    fg = "#D699B6",
  })

  vim.api.nvim_set_hl(0, "AlphaOrange", {
    fg = "#E69875",
  })

  local function button(sc, txt, keybind, keybind_opts)
    local b = dashboard.button(sc, txt, keybind, keybind_opts)
    b.opts.hl_shortcut = "Include"
    return b
  end

    local header = {
    "███████╗ ██████╗ ██╗   ██╗██╗灵魂",
    "██╔════╝██╔═══██╗██║   ██║██║士兵",
    "███████╗██║no ██║██║   ██║██║国王",
    "╚════██║██║me ██║██║   ██║██║没了",
    "███████║╚██████╔╝╚██████╔╝███████╗",
    "╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝",
  }

  dashboard.section.header.val = header

  local header_hl = {
    {
      { "AlphaGreen", 0, 29 },
      { "AlphaYellow", 29, 31 },
    },

    {
      { "AlphaGreen", 0, 20 },
      { "AlphaRed", 20, 22 },
      { "AlphaGreen", 22, 29 },
      { "AlphaYellow", 29, 31 },
    },

    {
      { "AlphaGreen", 0, 11 },
      { "AlphaYellow", 11, 13 },
      { "AlphaGreen", 13, 20 },
      { "AlphaRed", 20, 22 },
      { "AlphaGreen", 22, 29 },
      { "AlphaYellow", 29, 31 },
    },

    {
      { "AlphaGreen", 0, 11 },
      { "AlphaYellow", 11, 13 },
      { "AlphaGreen", 13, 20 },
      { "AlphaRed", 20, 22 },
      { "AlphaGreen", 22, 29 },
      { "AlphaYellow", 29, 31 },
    },

    {
      { "AlphaGreen", 0, 34 },
    },

    {
      { "AlphaGreen", 0, 34 },
    },
  }

  for line_number, line in ipairs(header) do
    for i = 1, vim.fn.strchars(line) do
      local char = vim.fn.strcharpart(line, i - 1, 1)

      if char == "╚"
        or char == "═"
        or char == "╝"
        or char == "╗"
        or char == "║"
        or char == "╔"
      then
        table.insert(header_hl[line_number], {
          "AlphaTeal",
          i - 1,
          i,
        })
      end
    end
  end

  dashboard.section.header.opts = {
    position = "center",
    hl = utils.charhl_to_bytehl(header_hl, header),
  }

  local button_icons = {
    files = icons.ui.Files,
    explorer = icons.ui.Folder,
    new_file = icons.ui.NewFile,
    project = icons.git.Repo,
    recent = icons.ui.History,
    text = icons.ui.Text,
    marks = icons.ui.BookMark,
    config = icons.ui.Gear,
    lazy = icons.which_key.Plugins,
    health = icons.ui.Bug,
    quit = icons.ui.SignOut,
  }

  dashboard.section.buttons.val = {
    button(
      "f",
      button_icons.files .. " Find file",
      "<cmd>Telescope find_files<CR>"
    ),

    button(
      "e",
      button_icons.explorer .. " Open Explorer",
      "<cmd>lua open_mini_files()<CR>"
    ),

    button(
      "n",
      button_icons.new_file .. " New file",
      "<cmd>ene | startinsert<CR>"
    ),

    button(
      "p",
      button_icons.project .. "Find project",
      "<cmd>Telescope projects<CR>"
    ),

    button(
      "r",
      button_icons.recent .. " Recent files",
      "<cmd>Telescope oldfiles<CR>"
    ),

    button(
      "t",
      button_icons.text .. " Find text",
      "<cmd>Telescope live_grep<CR>"
    ),

    button(
      "m",
      button_icons.marks .. " Marks",
      "<cmd>Telescope marks<CR>"
    ),

    button(
      "c",
      button_icons.config .. " Config",
      "<cmd>edit " .. vim.fn.stdpath("config") .. "/init.lua<CR>"
    ),

    button(
      "l",
      button_icons.lazy .. "Lazy",
      "<cmd>Lazy<CR>"
    ),

    button(
      "h",
      button_icons.health .. " Health",
      "<cmd>checkhealth<CR>"
    ),

    button(
      "q",
      button_icons.quit .. " Quit",
      "<cmd>qa<CR>"
    ),
  }

  dashboard.section.buttons.opts.hl = "Include"

  local button_icon_highlights = {
    { button_icons.files, "AlphaBlue" },
    { button_icons.explorer, "AlphaAqua" },
    { button_icons.new_file, "AlphaGreen" },
    { button_icons.project, "AlphaPurple" },
    { button_icons.recent, "AlphaYellow" },
    { button_icons.text, "AlphaOrange" },
    { button_icons.marks, "AlphaRed" },
    { button_icons.config, "AlphaTeal" },
    { button_icons.lazy, "AlphaBlue" },
    { button_icons.health, "AlphaRed" },
    { button_icons.quit, "AlphaMuted" },
  }

  for index, btn in ipairs(dashboard.section.buttons.val) do
    local icon = button_icon_highlights[index][1]
    local highlight = button_icon_highlights[index][2]

    btn.opts.hl = {
      {
        highlight,
        0,
        #icon,
      },
    }
  end

  local function get_git_branch()
    local git_dir = vim.fn.finddir(".git", ".;")

    if git_dir == "" then
      return nil
    end

    local branch = vim.fn.system(
      "git -C " .. vim.fn.shellescape(vim.fn.getcwd())
      .. " branch --show-current 2>/dev/null"
    )

    branch = vim.trim(branch)

    if branch == "" then
      return nil
    end

    return branch
  end

  local function footer()
    local stats = require("lazy").stats()

    local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
    local nvim = vim.version()

    local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
    local branch = get_git_branch()

    local line1 =
      " Neovim "
      .. nvim.major
      .. "."
      .. nvim.minor
      .. "."
      .. nvim.patch

    local line2 =
      "󰒲 "
      .. stats.count
      .. " plugins"
      .. "  •  "
      .. ms
      .. "ms"

    local line3 = "󰉋 " .. cwd

    if branch then
      line3 = line3 .. "  •  󰘬 " .. branch
    end

    return {
      "",
      line1,
      line2,
      line3,
    }
  end

  dashboard.section.footer = {
    type = "group",

    val = {
      {
        type = "text",
        val = "",
      },

      {
        type = "text",
        val = "",
        opts = {
          position = "center",
        },
      },

      {
        type = "text",
        val = "",
        opts = {
          position = "center",
        },
      },

      {
        type = "text",
        val = "",
        opts = {
          position = "center",
        },
      },
    },

    opts = {
      spacing = 0,
    },
  }

  local function update_footer()
    local lines = footer()

    dashboard.section.footer.val[1].val = lines[1]
    dashboard.section.footer.val[2].val = lines[2]
    dashboard.section.footer.val[3].val = lines[3]
    dashboard.section.footer.val[4].val = lines[4]
  end

  update_footer()

  dashboard.opts.layout = {
    { type = "padding", val = 2 },

    dashboard.section.header,

    { type = "padding", val = 2 },

    dashboard.section.buttons,

    { type = "padding", val = 2 },

    dashboard.section.footer,

    { type = "padding", val = 0 },
  }

  dashboard.opts.opts = {
    noautocmd = true,
  }

  local daad_frames = {
    "d ",
    "da",
    "da",
    "d ",
    "  ",
  }

  local emme_frames = {
    "e ",
    "em",
    "em",
    "e ",
    "  ",
  }

  local onno_frames = {
    "o ",
    "on",
    "on",
    "o ",
    "  ",
  }

  local animation_speed = 150
  local animation_step = 1

  local animation_lines = {
    [2] = {
      "██╔════╝██╔═══██╗██║",
      " ██║██║士兵",
    },

    [3] = {
      "███████╗██║no ██║██║",
      " ██║██║国王",
    },

    [4] = {
      "╚════██║██║me ██║██║",
      " ██║██║没了",
    },
  }

  local animation = {
    -- DA
    { 2, daad_frames, 1 },
    { 2, daad_frames, 2 },
    { 2, daad_frames, 3 },

    -- EM
    { 3, emme_frames, 1 },
    { 3, emme_frames, 2 },
    { 3, emme_frames, 3 },

    -- ON
    { 4, onno_frames, 1 },
    { 4, onno_frames, 2 },
    { 4, onno_frames, 3 },

    -- Erase ON
    { 4, onno_frames, 4 },
    { 4, onno_frames, 5 },

    -- Erase EM
    { 3, emme_frames, 4 },
    { 3, emme_frames, 5 },

    -- Erase DA
    { 2, daad_frames, 4 },
    { 2, daad_frames, 5 },
  }

  local function apply_animation_frame()
    local state = animation[animation_step]

    local line = state[1]
    local frames = state[2]
    local frame = state[3]

    dashboard.section.header.val[line] =
      animation_lines[line][1]
      .. frames[frame]
      .. animation_lines[line][2]
  end

  apply_animation_frame()

  ---------------------------------------------------------------------------
  -- Alpha setup
  ---------------------------------------------------------------------------

  require("alpha").setup(dashboard.opts)

  ---------------------------------------------------------------------------
  -- Animation
  ---------------------------------------------------------------------------

  local function animate()
    if vim.bo.filetype ~= "alpha" then
      vim.defer_fn(animate, animation_speed)
      return
    end

    animation_step = animation_step + 1

    if animation_step > #animation then
      animation_step = 1
    end

    apply_animation_frame()

    pcall(vim.cmd.AlphaRedraw)

    vim.defer_fn(animate, animation_speed)
  end

  vim.defer_fn(animate, animation_speed)

  ---------------------------------------------------------------------------
  -- Autocmds
  ---------------------------------------------------------------------------

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "alpha",
    callback = function()
      vim.opt_local.foldenable = false
      vim.opt_local.number = false
      vim.opt_local.relativenumber = false
      vim.opt_local.cursorline = false
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
      update_footer()
      pcall(vim.cmd.AlphaRedraw)
    end,
  })

  vim.api.nvim_create_autocmd("DirChanged", {
    callback = function()
      if vim.bo.filetype == "alpha" then
        update_footer()
        pcall(vim.cmd.AlphaRedraw)
      end
    end,
  })
end

return M
