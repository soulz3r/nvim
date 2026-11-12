local root = vim.fn.getcwd()
vim.opt.rtp:prepend(root)
package.path = table.concat({
	root .. "/lua/?.lua",
	root .. "/lua/?/init.lua",
	root .. "/?.lua",
	package.path,
}, ";")

assert(vim.fn.has("nvim-0.12") == 1, "Neovim 0.12 or newer is required")

local registry_migration = require("soul.core.helpers.dap.registry")
local temp_dir = vim.fn.tempname()
assert(vim.fn.mkdir(temp_dir, "p") == 1, "Could not create DAP migration test directory")

local source = temp_dir .. "/dap-projects.json"
local project_root = temp_dir .. "/sample-project"
local executable = temp_dir .. "/sample-project/bin/app.exe"
local payload = vim.json.encode({
	projects = {
		["sample-project"] = {
			root = project_root,
			executable = executable,
		},
	},
})

local original_notify = vim.notify
local notifications = {}
vim.notify = function(message, level, opts)
	notifications[#notifications + 1] = {
		message = tostring(message),
		level = level,
		title = opts and opts.title,
	}
end

local function normalize(path)
	if type(path) ~= "string" or path == "" then
		return nil
	end
	return path
end

local updates = {}
local registry = {
	update = function(path, fields)
		updates[#updates + 1] = {
			root = path,
			fields = vim.deepcopy(fields),
		}
		return true
	end,
}

vim.fn.writefile({ payload }, source)
local migrated, backup = registry_migration.migrate_file(source, registry, normalize)
assert(migrated, "Valid legacy DAP registry should migrate")
assert(backup == source .. ".migrated", "First migration should use the stable backup suffix")
assert(vim.fn.filereadable(source) == 0, "Successful migration should move the original file")
assert(vim.fn.filereadable(backup) == 1, "Successful migration must preserve a backup")
assert(#updates == 1 and updates[1].root == project_root, "Migration did not update the expected project")
assert(updates[1].fields.dap_enabled == true, "Migration must enable DAP for the project")
assert(updates[1].fields.debug_executable == executable, "Migration lost the configured executable")
assert(updates[1].fields.last_executable == executable, "Migration must preserve the last executable")
assert(
	notifications[#notifications].title == "DAP Registry",
	"Successful migration should report the backup location"
)

-- Existing backups must never be overwritten.
vim.fn.writefile({ payload }, source)
vim.fn.writefile({ "keep this backup" }, source .. ".migrated")
local migrated_again, second_backup = registry_migration.migrate_file(source, registry, normalize)
assert(migrated_again, "Migration should succeed when the default backup already exists")
assert(second_backup ~= source .. ".migrated", "Migration must choose a unique backup name")
assert(vim.fn.readfile(source .. ".migrated")[1] == "keep this backup", "Existing migration backup was overwritten")
assert(vim.fn.filereadable(second_backup) == 1, "Timestamped migration backup was not created")

-- Invalid JSON must leave the original file untouched.
vim.fn.writefile({ "{ invalid json" }, source)
local invalid_migration = registry_migration.migrate_file(source, registry, normalize)
assert(not invalid_migration, "Invalid legacy JSON must not be migrated")
assert(vim.fn.filereadable(source) == 1, "Invalid legacy JSON must remain available for recovery")
assert(notifications[#notifications].level == vim.log.levels.ERROR, "Invalid JSON should report an error")

-- A failed registry write must not move the source file.
vim.fn.writefile({ payload }, source)
local failing_registry = {
	update = function()
		return false
	end,
}
local failed_migration = registry_migration.migrate_file(source, failing_registry, normalize)
assert(not failed_migration, "A failed registry update must fail migration")
assert(vim.fn.filereadable(source) == 1, "A failed migration must preserve its source file")

-- A missing legacy file is a harmless no-op.
vim.fn.delete(source)
local missing_migration = registry_migration.migrate_file(source, registry, normalize)
assert(missing_migration, "A missing legacy registry should be treated as a no-op")

vim.notify = original_notify
vim.fn.delete(temp_dir, "rf")
print("DAP registry migration tests passed.")
