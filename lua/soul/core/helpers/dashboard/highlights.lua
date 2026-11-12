local M = {}

-- Returns a copied highlight-range table with selected characters highlighted.
-- Ranges use character offsets, not UTF-8 byte offsets.
function M.add_character_ranges(lines, ranges, characters, highlight)
	local result = vim.deepcopy(ranges)
	local lookup = {}

	for _, char in ipairs(characters) do
		lookup[char] = true
	end

	for line_number, line in ipairs(lines) do
		result[line_number] = result[line_number] or {}

		for index = 1, vim.fn.strchars(line) do
			local char = vim.fn.strcharpart(line, index - 1, 1)

			if lookup[char] then
				table.insert(result[line_number], {
					highlight,
					index - 1,
					index,
				})
			end
		end
	end

	return result
end

return M
