local M = {}

local icons = require("soul.icons")

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)
capabilities.textDocument.completion.completionItem.snippetSupport = true

M.capabilities = capabilities

local function lsp_keymaps(bufnr)
	local map = function(lhs, rhs, desc, mode)
		vim.keymap.set(mode or "n", lhs, rhs, {
			buffer = bufnr,
			silent = true,
			desc = desc,
		})
	end

	map("gD", vim.lsp.buf.declaration, "Declaration")
	map("gd", vim.lsp.buf.definition, "Definition")
	map("K", vim.lsp.buf.hover, "Hover")
	map("gI", vim.lsp.buf.implementation, "Implementation")
	map("gr", vim.lsp.buf.references, "References")
	map("gl", vim.diagnostic.open_float, "Line diagnostics")
end

function M.on_attach(client, bufnr)
	lsp_keymaps(bufnr)

	if client:supports_method("textDocument/inlayHint") then
		vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
	end
end

function M.toggle_inlay_hints()
	local bufnr = vim.api.nvim_get_current_buf()
	local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })

	vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
end

local function setup_which_key()
	local wk = require("which-key")

	wk.add({
		{ "<leader>l", group = "LSP" },
		{ "<leader>la", vim.lsp.buf.code_action, desc = "Code action" },
		{
			"<leader>lf",
			function()
				vim.lsp.buf.format({
					async = true,
					filter = function(client)
						return client.name ~= "typescript-tools"
					end,
				})
			end,
			desc = "Format",
		},
		{
			"<leader>lh",
			M.toggle_inlay_hints,
			desc = "Toggle inlay hints",
		},
		{
			"<leader>li",
			"<cmd>checkhealth vim.lsp<cr>",
			desc = "LSP info",
		},
		{
			"<leader>lj",
			function()
				vim.diagnostic.jump({ count = 1 })
			end,
			desc = "Next diagnostic",
		},
		{
			"<leader>lk",
			function()
				vim.diagnostic.jump({ count = -1 })
			end,
			desc = "Previous diagnostic",
		},
		{
			"<leader>ll",
			vim.lsp.codelens.run,
			desc = "Run CodeLens",
		},
		{
			"<leader>lq",
			vim.diagnostic.setloclist,
			desc = "Diagnostic location list",
		},
		{
			"<leader>lr",
			vim.lsp.buf.rename,
			desc = "Rename",
		},
		{
			"<leader>la",
			vim.lsp.buf.code_action,
			desc = "Code action",
			mode = "v",
		},
	})
end

local function setup_diagnostics()
	local diagnostic_signs = {
		{ name = "DiagnosticSignError", text = icons.diagnostics.Error },
		{ name = "DiagnosticSignWarn", text = icons.diagnostics.Warning },
		{ name = "DiagnosticSignHint", text = icons.diagnostics.Hint },
		{ name = "DiagnosticSignInfo", text = icons.diagnostics.Information },
	}

	vim.diagnostic.config({
		signs = {
			text = {
				[vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
				[vim.diagnostic.severity.WARN] = icons.diagnostics.Warning,
				[vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
				[vim.diagnostic.severity.INFO] = icons.diagnostics.Information,
			},
		},
		virtual_text = false,
		update_in_insert = false,
		underline = true,
		severity_sort = true,
		float = {
			focusable = true,
			style = "minimal",
			border = "rounded",
			source = "if_many",
			header = "",
			prefix = "",
		},
	})

	-- Compatibility with configurations that still use legacy sign names.
	for _, sign in ipairs(diagnostic_signs) do
		vim.fn.sign_define(sign.name, {
			text = sign.text,
			texthl = sign.name,
			numhl = sign.name,
		})
	end
end

local servers = {
	"lua_ls",
	"cssls",
	"html",
	"ts_ls",
	"eslint",
	"pyright",
	"bashls",
	"jsonls",
	"yamlls",
	"clangd",
}

local function setup_servers()
	for _, server in ipairs(servers) do
		local opts = {
			on_attach = M.on_attach,
			capabilities = M.capabilities,
		}

		local ok, settings = pcall(require, "soul.lspsettings." .. server)
		if ok then
			opts = vim.tbl_deep_extend("force", settings, opts)
		end

		vim.lsp.config(server, opts)
	end

	vim.lsp.enable(servers)
end

function M.setup()
	setup_diagnostics()
	setup_which_key()
	setup_servers()
end

return M
