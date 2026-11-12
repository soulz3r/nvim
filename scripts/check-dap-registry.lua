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
			args = { "--legacy", "sample file.c" },
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

-- Legacy standalone DAP files are imported and retained as backups.
vim.fn.writefile({ payload }, source)
local migrated, backup = registry_migration.migrate_file(source, registry, normalize)
assert(migrated, "Valid legacy DAP registry should migrate")
assert(backup == source .. ".migrated", "First migration should use the stable backup suffix")
assert(vim.fn.filereadable(source) == 0, "Successful migration should move the original DAP file")
assert(vim.fn.filereadable(backup) == 1, "Successful migration must preserve a backup")
assert(#updates == 1 and updates[1].root == project_root, "Migration did not update the expected project")
assert(updates[1].fields.dap_enabled == true, "Migration must enable DAP for the project")
assert(updates[1].fields.executable == executable, "Migration lost the configured executable")
assert(
	vim.deep_equal(updates[1].fields.args, { "--legacy", "sample file.c" }),
	"Migration lost the configured launch arguments"
)
assert(notifications[#notifications].title == "DAP Registry", "Successful migration should report the backup location")

-- Existing backups must never be overwritten.
vim.fn.writefile({ payload }, source)
vim.fn.writefile({ "keep this backup" }, source .. ".migrated")
local migrated_again, second_backup = registry_migration.migrate_file(source, registry, normalize)
assert(migrated_again, "Migration should succeed when the default backup already exists")
assert(second_backup ~= source .. ".migrated", "Migration must choose a unique backup name")
assert(vim.fn.readfile(source .. ".migrated")[1] == "keep this backup", "Existing migration backup was overwritten")
assert(vim.fn.filereadable(second_backup) == 1, "Timestamped migration backup was not created")

-- Import only DAP metadata from the former YAP registry, without modifying YAP's file.
local yap_source = temp_dir .. "/yap/projects.json"
local migration_marker = temp_dir .. "/state/soul/dap/yap-registry-imported"
local yap_payload = vim.json.encode({
	[project_root] = {
		root = project_root,
		name = "sample-project",
		dap_enabled = true,
		debug_executable = executable,
		last_executable = executable,
		dap_args = { "--from-yap", "sample file.c", 42 },
	},
	[temp_dir .. "/ordinary-project"] = {
		root = temp_dir .. "/ordinary-project",
		name = "ordinary-project",
		last_opened = 123,
	},
	[temp_dir .. "/runner-only-project"] = {
		root = temp_dir .. "/runner-only-project",
		name = "runner-only-project",
		last_executable = temp_dir .. "/runner-only-project/bin/app.exe",
		last_args = { "--run-only" },
		last_run = 456,
	},
})
vim.fn.mkdir(vim.fn.fnamemodify(yap_source, ":h"), "p")
vim.fn.writefile({ yap_payload }, yap_source)
local before_import = #updates
local imported = registry_migration.import_yap_file(yap_source, registry, normalize, migration_marker)
assert(imported, "Legacy YAP DAP metadata should import")
assert(#updates == before_import + 1, "YAP import must ignore projects without DAP metadata")
assert(
	updates[#updates].root ~= temp_dir .. "/runner-only-project",
	"YAP runner-only metadata must not be imported as DAP state"
)
assert(updates[#updates].root == project_root, "YAP import selected the wrong project")
assert(updates[#updates].fields.executable == executable, "YAP import lost the debug executable")
assert(
	vim.deep_equal(updates[#updates].fields.args, { "--from-yap", "sample file.c" }),
	"YAP import must retain string launch arguments and ignore unsupported values"
)
assert(vim.fn.filereadable(yap_source) == 1, "YAP's project registry must remain untouched")
assert(vim.fn.filereadable(migration_marker) == 1, "YAP import must write a one-time migration marker")

-- The marker prevents stale YAP metadata from overwriting future DAP settings.
vim.fn.writefile({
	vim.json.encode({
		[temp_dir .. "/new-project"] = {
			root = temp_dir .. "/new-project",
			dap_enabled = true,
		},
	}),
}, yap_source)
local after_first_import = #updates
assert(
	registry_migration.import_yap_file(yap_source, registry, normalize, migration_marker),
	"Repeated YAP import should be a harmless no-op"
)
assert(#updates == after_first_import, "YAP metadata must only be imported once")

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
