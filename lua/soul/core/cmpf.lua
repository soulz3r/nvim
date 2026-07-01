local cmpf_dir = "~/Notes/Projects/cmpf"

vim.keymap.set("n", "<leader>nn", function()
  vim.cmd("lcd ~/Notes/Projects/cmpf/")

  local cmd = table.concat({
    "cd " .. cmpf_dir,
    "cmake -S . -B build -DCMAKE_INSTALL_PREFIX=$HOME/.local",
    "cmake --build build",
    "cmake --install build"
  }, " && ")

  local result = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    print("Build failed ❌")
    print(result)
    return
  end

  print("cmpf rebuilt + installed ✅")
end)
