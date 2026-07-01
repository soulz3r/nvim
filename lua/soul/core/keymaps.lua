keymap = vim.keymap.set

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
vim.cmd [[:amenu 10.120 mousemenu.-sep- *]]

vim.keymap.set("n", "<RightMouse>", "<cmd>:popup mousemenu<CR>")
vim.keymap.set("n", "<Tab>", "<cmd>:popup mousemenu<CR>")

-- more good
keymap({ "n", "o", "x" }, "<s-h>", "^", OPTS())
keymap({ "n", "o", "x" }, "<s-l>", "g_", OPTS())

-- tailwind bearable to work with
keymap({ "n", "x" }, "j", "gj", OPTS())
keymap({ "n", "x" }, "k", "gk", OPTS())


keymap("n", "<leader>s", ":w<CR>", OPTS())
keymap("n", "<leader>w", ":w!<CR>", OPTS())
keymap("n", "<leader>q", ":q<CR>", OPTS())
keymap("n", "<leader>Q", ":q!<CR>", OPTS())
keymap({ "i", "x" }, ",,", "<ESC>", OPTS())
keymap({ "n" }, ",,", "<CMD>nohl<CR>", OPTS())

vim.api.nvim_set_keymap("t", "<C-;>", "<C-\\><C-n>", OPTS())

-- some nut jobs keymaps
vim.keymap.set("x", "p", [["_dP]], { desc = "Paste over selection without losing yanked text" })
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "moves lines down in visual selection" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "moves lines up in visual selection" })

vim.keymap.set("v", "<", "<gv", { desc = "Unindent and keep selection" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent and keep selection" })


vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines without moving cursor" })

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "move down in buffer with cursor centered" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "move up in buffer with cursor centered" })

vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines without moving cursor" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result cursor centered" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result cursor centered" })

vim.keymap.set("n", "<leader>c", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word cursor is on globally" })
vim.keymap.set("n", "<leader>X", "<cmd>!chmod +x %<CR>", { silent = true, desc = "makes file executable" })

vim.keymap.set("n", "<leader>re", "<cmd>restart<cr>", { desc = "Restart config :restart)" })

-- native undotree
vim.keymap.set("n", "<leader>u", function()
    vim.cmd.packadd("nvim.undotree")
    require("undotree").open()
end, { desc = "Toggle Builtin Undotree" })

vim.keymap.set("n","<leader>nm", "<cmd>messages<cr>", OPTS("Open logs messages"))
