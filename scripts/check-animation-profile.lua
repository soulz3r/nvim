local root = vim.fn.getcwd()
vim.opt.rtp:prepend(root)
package.path = table.concat({
	root .. "/lua/?.lua",
	root .. "/lua/?/init.lua",
	root .. "/?.lua",
	package.path,
}, ";")

vim.env.CVIM_ANIMATION_PROFILE = "1"

local profile = require("soul.core.performance.animation")
assert(profile.enabled, "animation profiling did not enable from its environment flag")

profile.setup()
assert(vim.fn.exists(":CvimAnimationProfile") == 2, "animation profile command was not registered")
assert(
	vim.fn.exists(":CvimAnimationProfileReset") == 2,
	"animation profile reset command was not registered"
)

for sample = 1, 20 do
	profile.record("test.frame", sample)
end

local report = profile.report()
assert(report:find("CVIM DASHBOARD FRAME PROFILE", 1, true), "profile report header is missing")
assert(report:find("test.frame", 1, true), "profile report omitted the recorded operation")
assert(report:find("20", 1, true), "profile report omitted the sample count")
assert(report:find("19.000", 1, true), "profile report did not calculate the 95th percentile")
assert(report:find("20.000", 1, true), "profile report did not calculate the maximum")

profile.reset()
assert(
	profile.report():find("No dashboard animation samples", 1, true),
	"reset did not clear animation samples"
)

print("Dashboard animation profiler checks passed.")
