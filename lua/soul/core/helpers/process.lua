local M = {}

-- Wait for a child process without leaving timed-out or failed probes running.
-- A non-zero exit code (including 124) is a completed process, not a timeout.
function M.wait(child, timeout)
	if not child or type(child.wait) ~= "function" then
		return nil, "Invalid process handle."
	end

	local ok, result = pcall(function()
		return child:wait(timeout)
	end)

	if ok and result ~= nil then
		return result
	end

	local reason = ok and ("Process timed out after " .. tostring(timeout) .. " ms.") or tostring(result)

	pcall(function()
		child:kill(9)
	end)
	pcall(function()
		child:wait(1000)
	end)

	return nil, reason
end

return M
