local M = {}

function M.capabilities()
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	local ok, blink = pcall(require, "blink.cmp")

	if ok then
		capabilities = blink.get_lsp_capabilities(capabilities)
	end

	return capabilities
end

function M.setup_format_on_save(client, bufnr)
	if client.name ~= "clangd" and client.name ~= "stylua" then
		return
	end

	if not client:supports_method("textDocument/formatting", bufnr) then
		return
	end

	if vim.b[bufnr].soul_format_on_save then
		return
	end

	vim.b[bufnr].soul_format_on_save = true

	local group = vim.api.nvim_create_augroup("soul_lsp_format", {
		clear = false,
	})

	vim.api.nvim_create_autocmd("BufWritePre", {
		group = group,
		buffer = bufnr,
		callback = function()
			local formatter = vim.bo[bufnr].filetype == "lua" and "stylua" or "clangd"

			vim.lsp.buf.format({
				bufnr = bufnr,
				async = false,
				timeout_ms = 3000,
				filter = function(active_client)
					return active_client.name == formatter
						and active_client:supports_method("textDocument/formatting", bufnr)
				end,
			})
		end,
	})
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
	local function map(key, func, desc)
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

	-- Refactoring
	map("<leader>la", vim.lsp.buf.code_action, "Code Action")
	map("<leader>lR", vim.lsp.buf.rename, "Rename")

	-- Formatting: only use an attached client that supports it
	map("<leader>lf", function()
		vim.lsp.buf.format({
			bufnr = bufnr,
			async = true,
			timeout_ms = 3000,
			filter = function(client)
				return client:supports_method("textDocument/formatting")
					and (client.name == "clangd" or client.name == "stylua")
			end,
		})
	end, "Format")

	-- Diagnostics
	map("<leader>lj", function()
		vim.diagnostic.jump({ count = 1, wrap = true })
	end, "Next Diagnostic")

	map("<leader>lk", function()
		vim.diagnostic.jump({ count = -1, wrap = true })
	end, "Previous Diagnostic")

	map("<leader>lo", function()
		vim.diagnostic.open_float(bufnr)
	end, "Show Diagnostics")

	map("<leader>lq", function()
		vim.diagnostic.setloclist({ bufnr = bufnr })
	end, "Diagnostic List")

	-- Symbols
	map("<leader>lw", vim.lsp.buf.workspace_symbol, "Workspace Symbols")
	map("<leader>lS", vim.lsp.buf.document_symbol, "Document Symbols")

	-- LSP utilities
	map("<leader>lI", "<cmd>checkhealth vim.lsp<CR>", "LSP Health")

	map("<leader>lH", function()
		local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
		vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
	end, "Toggle Inlay Hints")

	map("<leader>lC", "<cmd>lsp restart<CR>", "Restart LSP")
end
return {

	{
		"neovim/nvim-lspconfig",

		event = {
			"BufReadPre",
			"BufNewFile",
		},

		config = function()
			vim.lsp.config("*", {
				capabilities = M.capabilities(),
			})

			vim.api.nvim_create_autocmd("LspAttach", {

				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)

					if not client then
						return
					end

					M.on_attach(client, args.buf)
					M.setup_keymaps(args.buf)
					M.setup_format_on_save(client, args.buf)
				end,
			})

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

			vim.lsp.enable({
				"lua_ls",
				"stylua",
				"clangd",
				"bashls",
			})

			vim.diagnostic.config({

				virtual_text = false,
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
