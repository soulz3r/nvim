LAZY_PLUGIN_GET = {}

function GET(module)
	table.insert(LAZY_PLUGIN_GET, require(module))
end
