keymap = vim.keymap.set

function OPTS(description)
  return {
    noremap = true,
    silent = true,
    desc = description or nil,
  }
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

keymap("n", "<Space>", "", OPTS())
keymap("n", "<C-i>", "<C-i>", OPTS())

keymap("n", "<m-h>", "<C-w>h", OPTS())
keymap("n", "<m-j>", "<C-w>j", OPTS())
keymap("n", "<m-k>", "<C-w>k", OPTS())
keymap("n", "<m-l>", "<C-w>l", OPTS())
keymap("n", "<m-tab>", "<c-6>", OPTS())

keymap("n", "<ma>", "<mA>", OPTS())

keymap("n", "n", "nzz", OPTS())
keymap("n", "N", "Nzz", OPTS())
keymap("n", "*", "*zz", OPTS())
keymap("n", "#", "#zz", OPTS())
keymap("n", "g*", "g*zz", OPTS())
keymap("n", "g#", "g#zz", OPTS())

keymap({ "n", "o", "x" }, "<s-h>", "^", OPTS())
keymap({ "n", "o", "x" }, "<s-l>", "g_", OPTS())

keymap("x", "p", [["_dP]])
keymap("v", "p", [["_dP]], { desc = "Paste over selection without losing yanked text" })
keymap({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })

keymap("n", "J", "mzJ`z", { desc = "Join lines without moving cursor" })

keymap("n", "<C-d>", "<C-d>zz", { desc = "move down in buffer with cursor centered" })
keymap("n", "<C-u>", "<C-u>zz", { desc = "move up in buffer with cursor centered" })

keymap("n", "n", "nzzzv", { desc = "Next search result cursor centered" })
keymap("n", "N", "Nzzzv", { desc = "Previous search result cursor centered" })

keymap({ "n", "x" }, "j", "gj", OPTS())
keymap({ "n", "x" }, "k", "gk", OPTS())

keymap("n", "<leader>ww", ":w<CR>", OPTS("Save"))
keymap("n", "<leader>wa", ":w!<CR>", OPTS("Save force"))
keymap("n", "<leader>qq", ":q<CR>", OPTS("Quit"))
keymap("n", "<leader>qa", ":q!<CR>", OPTS("Quit without saving"))

keymap("n", "<leader>nm", ":messages<CR>", OPTS("Open Neovim debug messages"))

keymap({ "i", "x" }, ",,", "<ESC>", OPTS())
keymap("n", ",,", "<CMD>nohl<CR>", OPTS("Remove highlight"))

vim.api.nvim_set_keymap("t", "<C-;>", "<C-\\><C-n>", OPTS())

vim.cmd([[
  :amenu 10.100 mousemenu.Goto\ Definition <cmd>lua vim.lsp.buf.definition()<CR>
  :amenu 10.110 mousemenu.References <cmd>lua vim.lsp.buf.references()<CR>
  :amenu 10.120 mousemenu.-sep- *
]])

vim.keymap.set("n", "<RightMouse>", "<cmd>:popup mousemenu<CR>")
vim.keymap.set("n", "<Tab>", "<cmd>:popup mousemenu<CR>")

vim.keymap.set(
  "n",
  "<leader>c",
  [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Replace word cursor is on globally" }
)

vim.keymap.set(
  "n",
  "<leader>X",
  "<cmd>!chmod +x %<CR>",
  { silent = true, desc = "makes file executable" }
)

vim.keymap.set("n", "<leader>ne", "<cmd>restart<cr>", { desc = "Restart config :restart)" })

vim.keymap.set("n", "<leader>nm", "<cmd>messages<cr>", OPTS("Open logs messages"))

vim.keymap.set("n", "<leader>u", function()
  vim.cmd.packadd("nvim.undotree")
  require("undotree").open()
end, { desc = "Builtin Undotree" })
vim.keymap.set("n", "gd", vim.lsp.buf.definition, {
    desc = "Go to definition",
})
