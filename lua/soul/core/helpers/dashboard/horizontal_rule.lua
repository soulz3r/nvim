local M = {}

function M.build(width)
	width = math.max(0, math.floor(width))
	return string.rep("─", width)
end

return M
