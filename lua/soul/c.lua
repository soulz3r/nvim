local M = {}

local root_markers = {
  ".git", "compile_commands.json", "compile_flags.txt",
  "CMakeLists.txt", "Makefile", "build.sh", "build.bat",
}

local function root()
  local file = vim.api.nvim_buf_get_name(0)
  local directory = file ~= "" and vim.fs.dirname(file) or vim.fn.getcwd()
  return vim.fs.root(directory, root_markers) or vim.fn.getcwd()
end

local function switch_header_source()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    return vim.notify("Current buffer has no file.", vim.log.levels.WARN)
  end

  local extension = vim.fn.fnamemodify(file, ":e"):lower()
  local candidates = ({
    c = { "h", "hpp" },
    h = { "c", "cpp" },
    cc = { "h", "hpp" },
    cpp = { "h", "hpp" },
    hpp = { "cpp", "cc" },
  })[extension]

  if not candidates then
    return vim.notify("No source/header counterpart for ." .. extension, vim.log.levels.INFO)
  end

  local base = vim.fn.fnamemodify(file, ":r")
  for _, candidate in ipairs(candidates) do
    local path = base .. "." .. candidate
    if vim.fn.filereadable(path) == 1 then
      vim.cmd.edit(vim.fn.fnameescape(path))
      return
    end
  end

  local project = root()
  local stem = vim.fn.fnamemodify(file, ":t:r")
  local found = vim.fn.globpath(project, "**/" .. stem .. ".{" .. table.concat(candidates, ",") .. "}", false, true)
  if #found == 1 then
    vim.cmd.edit(vim.fn.fnameescape(found[1]))
  elseif #found > 1 then
    vim.ui.select(found, {
      prompt = "Choose source/header",
      format_item = function(path) return vim.fn.fnamemodify(path, ":~:.") end,
    }, function(choice)
      if choice then vim.cmd.edit(vim.fn.fnameescape(choice)) end
    end)
  else
    vim.notify("No matching source/header file found.", vim.log.levels.INFO)
  end
end

local function insert_include()
  vim.ui.input({ prompt = "Header to include: " }, function(value)
    if not value or vim.trim(value) == "" then return end
    value = vim.trim(value):gsub("[<>\"\r\n]", "")
    local line = "#include <" .. value .. ">"
    vim.api.nvim_buf_set_lines(0, vim.api.nvim_win_get_cursor(0)[1] - 1, vim.api.nvim_win_get_cursor(0)[1] - 1, false, { line })
  end)
end

local function compile_metadata()
  local project = root()
  local lines = {
    "C / C++ PROJECT",
    string.rep("─", 48),
    "Root: " .. project,
    "",
  }

  for _, name in ipairs({ "compile_commands.json", "compile_flags.txt", ".clangd", "CMakeLists.txt", "Makefile" }) do
    local path = project .. "/" .. name
    lines[#lines + 1] = (vim.fn.filereadable(path) == 1 and "✓ " or "· ") .. name
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "Attached language servers:"
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    lines[#lines + 1] = "  None"
  else
    for _, client in ipairs(clients) do
      lines[#lines + 1] = "  " .. client.name
    end
  end

  local flags = project .. "/compile_flags.txt"
  if vim.fn.filereadable(flags) == 1 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Compile flags:"
    vim.list_extend(lines, vim.fn.readfile(flags))
  end

  require("soul.ui").open_text(lines, " C Project ", { width = math.floor(vim.o.columns * 0.68), height = math.min(#lines + 1, 24) })
end

function M.setup()
  local group = vim.api.nvim_create_augroup("SoulCTools", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { "c", "cpp" },
    callback = function(args)
      vim.keymap.set("n", "<leader>ch", switch_header_source, { buffer = args.buf, desc = "C: Switch source/header" })
      vim.keymap.set("n", "<leader>ci", insert_include, { buffer = args.buf, desc = "C: Insert include" })
      vim.keymap.set("n", "<leader>cp", compile_metadata, { buffer = args.buf, desc = "C: Project information" })
    end,
  })

  vim.api.nvim_create_user_command("CProjectInfo", compile_metadata, { desc = "Show C project metadata" })
  vim.api.nvim_create_user_command("CSwitchHeader", switch_header_source, { desc = "Switch C source/header" })
end

return M
