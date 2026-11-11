local M = {}

function M.capabilities()
	local capabilities = vim.lsp.protocol.make_client_capabilities()
	local ok, blink = pcall(require, "blink.cmp")

	if ok then
		capabilities = blink.get_lsp_capabilities(capabilities)
	end

	return capabilities
end

local clangd_filetypes = {
	c = true,
	cpp = true,
	objc = true,
	objcpp = true,
	cuda = true,
}

local function formatter_for(bufnr)
	local filetype = vim.bo[bufnr].filetype
	if filetype == "lua" then
		return "stylua"
	end
	if clangd_filetypes[filetype] then
		return "clangd"
	end
	return nil
end

function M.format_buffer(bufnr)
	local formatter = formatter_for(bufnr)
	if not formatter then
		return false, "No formatter is configured for this filetype."
	end

	local has_formatter = false
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = formatter })) do
		if client:supports_method("textDocument/formatting", bufnr) then
			has_formatter = true
			break
		end
	end

	if not has_formatter then
		return false, ("No attached %s formatter supports this buffer."):format(formatter)
	end

	local ok, err = pcall(vim.lsp.buf.format, {
		bufnr = bufnr,
		async = true,
		timeout_ms = 3000,
		filter = function(active_client)
			return active_client.name == formatter
				and active_client:supports_method("textDocument/formatting", bufnr)
		end,
	})

	if not ok then
		return false, tostring(err)
	end
	return true
end

function M.setup_format_on_save(client, bufnr)
	local formatter = formatter_for(bufnr)
	if client.name ~= formatter then
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
	local navic_ok, navic = pcall(require, "nvim-navic")

	if navic_ok and client.server_capabilities.documentSymbolProvider and not navic.is_available(bufnr) then
		navic.attach(client, bufnr)
	end

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
		local ok, err = M.format_buffer(bufnr)
		if not ok then
			vim.notify("Formatting failed: " .. tostring(err), vim.log.levels.WARN)
		end
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

		dependencies = {
			"SmiteshP/nvim-navic",
			"saghen/blink.cmp",
		},

		event = {
			"BufReadPre",
			"BufNewFile",
		},

		config = function()
			require("nvim-navic").setup({
				lsp = {
					auto_attach = false,
				},
				highlight = true,
				separator = " ",
				safe_output = true,
			})

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

			-- Enable each server independently so one removed or broken config
			-- cannot prevent every other language server from starting.
			for _, server in ipairs({ "lua_ls", "stylua", "clangd", "bashls", "fish_lsp" }) do
				local ok, err = pcall(vim.lsp.enable, server)
				if not ok then
					vim.notify(
						("Could not enable LSP '%s': %s"):format(server, tostring(err)),
						vim.log.levels.WARN
					)
				end
			end

			M.setup_stylua_on_save()

			vim.diagnostic.config({

				virtual_text = false,
				virtual_lines = false,

				signs = true,
				underline = true,

				update_in_insert = false,
				severity_sort = true,

				float = {
					border = require("soul.core.helpers.ui.floats").border,
					source = true,
				},
			})
		end,
	},
}
