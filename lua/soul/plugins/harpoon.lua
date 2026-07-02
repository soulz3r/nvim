return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local harpoon = require('harpoon')
    harpoon:setup()
  end,
  keys = function()
    return {
      -- Open Harpoon (marked files)
      {
        '<leader>hh',
        function()
          local harpoon = require('harpoon')
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = 'Harpoon Quick Menu'
      },

      -- Add file to Harpoon
      { '<leader>ha', function() 
        local harpoon = require('harpoon')
        harpoon:list():add() 
      end, desc = 'Add File to Harpoon' },

      -- Open/Mark your quicknotes file
      {
        '<leader>ni',
        function()
          local path = vim.fn.expand('$HOME/.config/nvim/init.lua')
          vim.cmd('edit ' .. path)
          local harpoon = require('harpoon')
          harpoon:list():add() -- Auto-mark it
        end,
        desc = 'Open neovim init file'
      },

      -- Jump to file 1-10
      { '<leader>hq', function() require('harpoon'):list():select(1) end, OPTS("Open file 1")},
      { '<leader>hw', function() require('harpoon'):list():select(2) end , OPTS("Open file 2")},
      { '<leader>he', function() require('harpoon'):list():select(3) end , OPTS("Open file 3")},
      { '<leader>hr', function() require('harpoon'):list():select(4) end , OPTS("Open file 4")},
      { '<leader>ht', function() require('harpoon'):list():select(5) end , OPTS("Open file 5")},
      { '<leader>hy', function() require('harpoon'):list():select(6) end , OPTS("Open file 6")},
      { '<leader>hu', function() require('harpoon'):list():select(7) end , OPTS("Open file 7")},
      { '<leader>hi', function() require('harpoon'):list():select(8) end , OPTS("Open file 8")},
      { '<leader>ho', function() require('harpoon'):list():select(9) end , OPTS("Open file 9")},
      { '<leader>hp', function() require('harpoon'):list():select(10) end , OPTS("Open file 10")},
    }
  end,
}
