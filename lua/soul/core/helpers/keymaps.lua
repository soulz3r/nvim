local M = {}

function M.opts(description)
	return {
		noremap = true,
		silent = true,
		desc = description,
	}
end

return M
