return {
  'MeanderingProgrammer/render-markdown.nvim',
  after = { 'nvim-treesitter' },
  requires = { 'echasnovski/mini.nvim', opt = true },
  config = function()
    require('render-markdown').setup({})
  end,
}
