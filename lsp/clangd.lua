---@brief
---
--- https://clangd.llvm.org/installation.html
---
--- Clangd configuration for Neovim 0.12+

local function switch_source_header(bufnr, client)
	local method = "textDocument/switchSourceHeader"

	if not client:supports_method(method, bufnr) then
		vim.notify("Clangd does not support source/header switching", vim.log.levels.WARN)
		return
	end

	local params = vim.lsp.util.make_text_document_params(bufnr)

	client:request(method, params, function(err, uri)
		if err then
			vim.notify(tostring(err), vim.log.levels.ERROR)
			return
		end

		if not uri then
			vim.notify("Corresponding file could not be determined")
			return
		end

		vim.cmd.edit(vim.uri_to_fname(uri))
	end, bufnr)
end

local function symbol_info(bufnr, client)
	local method = "textDocument/symbolInfo"

	if not client:supports_method(method, bufnr) then
		vim.notify("Clangd symbol info is unavailable", vim.log.levels.WARN)
		return
	end

	local win = vim.api.nvim_get_current_win()
	local params = vim.lsp.util.make_position_params(win, client.offset_encoding)

	client:request(method, params, function(err, result)
		if err or not result or not result[1] then
			return
		end

		local symbol = result[1]
		local name = "name: " .. (symbol.name or "")
		local container = "container: " .. (symbol.containerName or "")

		vim.lsp.util.open_floating_preview({ name, container }, "", {
			height = 2,
			width = math.max(#name, #container),
			focusable = false,
			focus = false,
			border = "single",
			title = " Symbol Info ",
		})
	end, bufnr)
end

---@class ClangdInitializeResult: lsp.InitializeResult
---@field offsetEncoding? string

---@type vim.lsp.Config
local M = {
	cmd = {
		"clangd",
		"--background-index",
		"--clang-tidy",
	},

	filetypes = {
		"c",
		"cpp",
		"objc",
		"objcpp",
		"cuda",
	},

	root_markers = {
		".clangd",
		".clang-tidy",
		".clang-format",
		"compile_commands.json",
		"compile_flags.txt",
		"configure.ac",
		".git",
	},

	get_language_id = function(_, filetype)
		local language_ids = {
			objc = "objective-c",
			objcpp = "objective-cpp",
			cuda = "cuda-cpp",
		}

		return language_ids[filetype] or filetype
	end,

	capabilities = {
		textDocument = {
			completion = {
				editsNearCursor = true,
			},
		},
		offsetEncoding = { "utf-8", "utf-16" },
	},

	---@param client vim.lsp.Client
	---@param init_result ClangdInitializeResult
	on_init = function(client, init_result)
		if init_result.offsetEncoding then
			client.offset_encoding = init_result.offsetEncoding
		end
	end,

	on_attach = function(client, bufnr)
		vim.keymap.set("n", "gS", function()
			switch_source_header(bufnr, client)
		end, {
			buffer = bufnr,
			desc = "Switch source/header",
		})

		vim.keymap.set("n", "gI", function()
			symbol_info(bufnr, client)
		end, {
			buffer = bufnr,
			desc = "Show symbol info",
		})

		vim.api.nvim_buf_create_user_command(bufnr, "LspClangdSwitchSourceHeader", function()
			switch_source_header(bufnr, client)
		end, { desc = "Switch between source/header" })

		vim.api.nvim_buf_create_user_command(bufnr, "LspClangdShowSymbolInfo", function()
			symbol_info(bufnr, client)
		end, { desc = "Show Clangd symbol info" })
	end,
}

return M
