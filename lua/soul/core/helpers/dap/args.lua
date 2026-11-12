local M = {}

function M.format(args)
	local formatted = {}

	for _, arg in ipairs(args or {}) do
		if arg == "" then
			table.insert(formatted, '""')
		elseif arg:find("%s") or arg:find('"', 1, true) or arg:find("'", 1, true) or arg:find("\\", 1, true) then
			local escaped = arg:gsub("\\", "\\\\"):gsub('"', '\\"')
			table.insert(formatted, '"' .. escaped .. '"')
		else
			table.insert(formatted, arg)
		end
	end

	return table.concat(formatted, " ")
end

function M.parse(input, is_windows)
	if type(input) ~= "string" then
		return nil, "Program arguments must be a string."
	end

	local args = {}
	local current = {}
	local quote = nil
	local escaped = false
	local token_started = false

	for i = 1, #input do
		local char = input:sub(i, i)

		if escaped then
			table.insert(current, char)
			escaped = false
			token_started = true
		elseif char == "\\" and quote ~= "'" then
			local next_char = input:sub(i + 1, i + 1)

			if not is_windows or next_char == '"' or next_char == "\\" or next_char:match("%s") then
				escaped = true
			else
				table.insert(current, char)
			end

			token_started = true
		elseif quote then
			if char == quote then
				quote = nil
			else
				table.insert(current, char)
			end
			token_started = true
		elseif char == '"' or char == "'" then
			quote = char
			token_started = true
		elseif char:match("%s") then
			if token_started then
				table.insert(args, table.concat(current))
				current = {}
				token_started = false
			end
		else
			table.insert(current, char)
			token_started = true
		end
	end

	if escaped then
		table.insert(current, "\\")
	end

	if quote then
		return nil, "Unclosed quote in program arguments."
	end

	if token_started then
		table.insert(args, table.concat(current))
	end

	return args
end

return M
