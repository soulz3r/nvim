return {
  {
    'echasnovski/mini.files',
    version = false,
    config = function()
      require('mini.files').setup({
        windows = {
          max_width = 50,
          min_width = 20,
        },
        use_as_default_explorer = true,
      })

      vim.keymap.set("n", "<leader>e", function() require("mini.files").open() end,
        { desc = "Open mini.files file explorer" })
    end,
  }
}
