local keymap = vim.keymap.set

function OPTS(description)
  return {
    noremap = true,
    silent = true,
    desc = description or nil
  }
end

keymap("n", "<Space>", "", OPTS())
vim.g.mapleader = " "
vim.g.maplocalleader = " "

keymap("n", "<C-i>", "<C-i>", OPTS())

-- Better window navigation
keymap("n", "<m-h>", "<C-w>h", OPTS())
keymap("n", "<m-j>", "<C-w>j", OPTS())
keymap("n", "<m-k>", "<C-w>k", OPTS())
keymap("n", "<m-l>", "<C-w>l", OPTS())
keymap("n", "<m-tab>", "<c-6>", OPTS())

keymap("n", "n", "nzz", OPTS())
keymap("n", "N", "Nzz", OPTS())
keymap("n", "*", "*zz", OPTS())
keymap("n", "#", "#zz", OPTS())
keymap("n", "g*", "g*zz", OPTS())
keymap("n", "g#", "g#zz", OPTS())

-- Stay in indent mode
keymap("v", "<", "<gv", OPTS())
keymap("v", ">", ">gv", OPTS())

keymap("x", "p", [["_dP]])

vim.cmd [[:amenu 10.100 mousemenu.Goto\ Definition <cmd>lua vim.lsp.buf.definition()<CR>]]
vim.cmd [[:amenu 10.110 mousemenu.References <cmd>lua vim.lsp.buf.references()<CR>]]
-- vim.cmd [[:amenu 10.120 mousemenu.-sep- *]]

vim.keymap.set("n", "<RightMouse>", "<cmd>:popup mousemenu<CR>")
vim.keymap.set("n", "<Tab>", "<cmd>:popup mousemenu<CR>")

-- more good
keymap({ "n", "o", "x" }, "<s-h>", "^", OPTS())
keymap({ "n", "o", "x" }, "<s-l>", "g_", OPTS())

-- tailwind bearable to work with
keymap({ "n", "x" }, "j", "gj", OPTS())
keymap({ "n", "x" }, "k", "gk", OPTS())
keymap("n", "<leader>uw", ":lua vim.wo.wrap = not vim.wo.wrap<CR>", OPTS())
keymap("n", "<leader>uh", ":nohl<CR>", OPTS("NOHL"))


keymap("n", "<leader>s", ":w<CR>", OPTS())
keymap({ "i", "x" }, ",,", "<ESC>", OPTS())

vim.api.nvim_set_keymap("t", "<C-;>", "<C-\\><C-n>", OPTS())
vim.api.nvim_set_keymap('n', '<leader>e', ':terminal yazi<CR>', OPTS("See the whole project structure"))
