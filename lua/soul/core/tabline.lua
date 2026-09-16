vim.opt.laststatus = 0
vim.opt.showtabline = 2

local function lsp_diagnostics()
  local diag = vim.diagnostic.count(0)
  local parts = {}
  if diag[vim.diagnostic.severity.ERROR] then
    parts[#parts + 1] = "E:" .. diag[vim.diagnostic.severity.ERROR]
  end
  if diag[vim.diagnostic.severity.WARN] then
    parts[#parts + 1] = "W:" .. diag[vim.diagnostic.severity.WARN]
  end
  if diag[vim.diagnostic.severity.INFO] then
    parts[#parts + 1] = "I:" .. diag[vim.diagnostic.severity.INFO]
  end
  if diag[vim.diagnostic.severity.HINT] then
    parts[#parts + 1] = "H:" .. diag[vim.diagnostic.severity.HINT]
  end
  return #parts > 0 and " " .. table.concat(parts, " ") or ""
end

vim.o.tabline = '%= %{ expand("%:t") }' .. lsp_diagnostics() .. ' %V %='

vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
  callback = function()
    vim.o.tabline = '%= %{ expand("%:t") }' .. lsp_diagnostics() .. ' %V %='
  end,
})
