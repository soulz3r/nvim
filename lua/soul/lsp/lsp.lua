local M = {}

function M.capabilities()
	local capabilities = vim.lsp.protocol.make_client_capabilities()

	local ok, cmp = pcall(require, "cmp_nvim_lsp")

	if ok then
		capabilities = cmp.default_capabilities(capabilities)
	end

	return capabilities
end

function M.on_attach(client, bufnr)
	if client.name == "lua_ls" then
		client.server_capabilities.documentFormattingProvider = false
	end

	if vim.lsp.inlay_hint and client:supports_method("textDocument/inlayHint") then
		vim.lsp.inlay_hint.enable(false, {
			bufnr = bufnr,
		})
	end
end

function M.setup_keymaps(bufnr)
	local map = function(key, func, desc)
		vim.keymap.set("n", key, func, {
			buffer = bufnr,
			desc = desc,
			silent = true,
		})
	end

	-- Navigation
	map("<leader>ld", vim.lsp.buf.definition, "Definition")
	map("<leader>lD", vim.lsp.buf.declaration, "Declaration")
	map("<leader>li", vim.lsp.buf.implementation, "Implementation")
	map("<leader>lt", vim.lsp.buf.type_definition, "Type Definition")
	map("<leader>lr", vim.lsp.buf.references, "References")

	-- Documentation
	map("<leader>lh", vim.lsp.buf.hover, "Hover Documentation")
	map("<leader>ls", vim.lsp.buf.signature_help, "Signature Help")

	-- Actions
	map("<leader>la", vim.lsp.buf.code_action, "Code Action")
	map("<leader>ln", vim.lsp.buf.rename, "Rename")

	-- Formatting
	map("<leader>lf", function()
		vim.lsp.buf.format({
			filter = function(client)
				return client.name == "clangd" or client.name == "stylua"
			end,
		})
	end, "Format")

	-- Diagnostics
	map("<leader>lj", function()
		vim.diagnostic.jump({
			count = 1,
		})
	end, "Next Diagnostic")

	map("<leader>lk", function()
		vim.diagnostic.jump({
			count = -1,
		})
	end, "Previous Diagnostic")

	map("<leader>lo", vim.diagnostic.open_float, "Show Diagnostics")

	map("<leader>lq", vim.diagnostic.setloclist, "Diagnostic List")

	-- Workspace
	map("<leader>lw", vim.lsp.buf.workspace_symbol, "Workspace Symbols")
	map("<leader>lS", vim.lsp.buf.document_symbol, "Document Symbols")

	-- LSP utilities
	map("<leader>lI", "<cmd>checkhealth vim.lsp<CR>", "LSP Info")

	map("<leader>lH", function()
		if vim.lsp.inlay_hint then
			local enabled = vim.lsp.inlay_hint.is_enabled({
				bufnr = bufnr,
			})

			vim.lsp.inlay_hint.enable(not enabled, {
				bufnr = bufnr,
			})
		end
	end, "Toggle Inlay Hints")

	map("<leader>lC", "<cmd>LspRestart<CR>", "Restart LSP")
end

return {

	{
		"neovim/nvim-lspconfig",

		event = {
			"BufReadPre",
			"BufNewFile",
		},

		config = function()
			-- Capabilities
			vim.lsp.config("*", {
				capabilities = M.capabilities(),
			})

			-- Attach event (Neovim 0.12 recommended)
			vim.api.nvim_create_autocmd("LspAttach", {

				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)

					if not client then
						return
					end

					M.on_attach(client, args.buf)
					M.setup_keymaps(args.buf)
				end,
			})

			-- StyLua
			vim.lsp.config("stylua", {

				cmd = {
					"stylua",
					"--lsp",
				},

				filetypes = {
					"lua",
					"luau",
				},

				root_markers = {
					".stylua.toml",
					"stylua.toml",
					".git",
				},

				workspace_required = false,
			})

			-- Enable servers
			vim.lsp.enable({
				"lua_ls",
				"stylua",
				"clangd",
				"bashls",
			})

			-- Diagnostics
			vim.diagnostic.config({

				virtual_text = true,
				virtual_lines = false,

				signs = true,
				underline = true,

				update_in_insert = false,
				severity_sort = true,

				float = {
					border = "rounded",
					source = true,
				},
			})
		end,
	},
}
