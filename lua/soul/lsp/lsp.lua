local M = {}

-- Called when language server attaches to buffer
function M.on_attach(client, bufnr)
  -- Your keymap setup here, e.g., lsp_keymaps(bufnr) if defined
  if client and client:supports_method("textDocument/inlayHint") then
    vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
  end
end

-- Return capabilities extended with snippet support
function M.common_capabilities()
  local orig_capabilities = vim.lsp.protocol.make_client_capabilities()

  local cmp_status_ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")

  if cmp_status_ok then
    orig_capabilities = cmp_lsp.default_capabilities(orig_capabilities)
  end

  orig_capabilities.textDocument.completion.completionItem.snippetSupport = true

  return orig_capabilities
end

-- Toggle inlay hints manually
function M.toggle_inlay_hints()
  local bufnr = vim.api.nvim_get_current_buf()
  local is_enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })

  vim.lsp.inlay_hint.enable(not is_enabled, { bufnr = bufnr })
end

local plugins = {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },

    dependencies = {
      "folke/neodev.nvim",
    },

    config = function()
      -- ============================================================
      -- LSP server configuration
      -- ============================================================

      -- Shared capabilities
      local capabilities = M.common_capabilities()

      -- Configure language servers using the native Neovim LSP API
      vim.lsp.config("lua_ls", {
        capabilities = capabilities,
      })

      vim.lsp.config("clangd", {
        capabilities = capabilities,
      })

      vim.lsp.config("bashls", {
        capabilities = capabilities,
      })

      -- Enable language servers
      vim.lsp.enable("lua_ls")
      vim.lsp.enable("clangd")
      vim.lsp.enable("bashls")


      -- ============================================================
      -- Diagnostics
      -- ============================================================

      vim.diagnostic.config({
        virtual_lines = false,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,

        float = {
          focusable = true,
          style = "minimal",
          border = "rounded",
          source = "always",
        },
      })


      -- ============================================================
      -- LSP Attach
      -- ============================================================

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)

          if client and client:supports_method("textDocument/completion") then
            vim.keymap.set("i", "<C-Space>", function()
              -- Hook your completion plugin here
            end, {
              buffer = ev.buf,
            })
          end

          M.on_attach(client, ev.buf)
        end,
      })


      -- ============================================================
      -- Which-Key LSP mappings
      -- ============================================================

      local wk = require("which-key")

      wk.add({
        { "<leader>l", group = "LSP" },

        { "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<cr>", desc = "Code Action" },

        { "<leader>lb", "<C-o>", desc = "Go Back" },

        { "<leader>ld", "<cmd>lua vim.lsp.buf.definition()<cr>", desc = "Definition" },

        { "<leader>lD", "<cmd>lua vim.lsp.buf.declaration()<cr>", desc = "Declaration" },

        { "<leader>lf", "<cmd>lua vim.lsp.buf.format({ async = true })<cr>", desc = "Format" },

        { "<leader>lh", function()
            M.toggle_inlay_hints()
          end, desc = "Toggle Hints" },

        { "<leader>lI", "<cmd>LspInfo<cr>", desc = "LSP Info" },

        { "<leader>lj", "<cmd>lua vim.diagnostic.goto_next()<cr>", desc = "Next Diagnostic" },

        { "<leader>lk", "<cmd>lua vim.diagnostic.goto_prev()<cr>", desc = "Previous Diagnostic" },

        { "<leader>ll", "<cmd>lua vim.lsp.codelens.run()<cr>", desc = "CodeLens Action" },

        { "<leader>lm", "<cmd>lua vim.lsp.buf.implementation()<cr>", desc = "Implementation" },

        { "<leader>lo", "<cmd>lua vim.lsp.buf.hover()<cr>", desc = "Hover Documentation" },

        { "<leader>lq", "<cmd>lua vim.diagnostic.setloclist()<cr>", desc = "Quickfix" },

        { "<leader>lr", "<cmd>lua vim.lsp.buf.rename()<cr>", desc = "Rename" },

        { "<leader>lR", "<cmd>lua vim.lsp.buf.references()<cr>", desc = "References" },

        { "<leader>li", "<cmd>lua vim.lsp.buf.implementation()<cr>", desc = "Implementation" },

        { "<leader>lt", "<cmd>lua vim.lsp.buf.type_definition()<cr>", desc = "Type Definition" },

        { "<leader>lw", "<cmd>lua vim.lsp.buf.workspace_symbol()<cr>", desc = "Workspace Symbols" },
      })


      -- ============================================================
      -- Completion options
      -- ============================================================

      -- Uncomment if you want to set completeopt here:
      -- vim.opt.completeopt = { "menu", "menuone", "noselect" }
    end,
  },
}

-- ============================================================
-- Optional Telescope code action mapping
-- ============================================================

-- vim.keymap.set("n", "<leader>la", function()
--   require("telescope").extensions["ui-select"].code_actions()
-- end, { desc = "LSP Code Actions" })


return plugins
