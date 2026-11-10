# Keymap reference

The leader key is Space. This is a compact reference for the most-used mappings; WhichKey provides descriptions for many additional mappings.

## Navigation and editing

| Mapping | Action |
|---|---|
| `Ctrl-h/j/k/l` | Move between windows |
| `Alt-Tab` | Switch to the alternate buffer |
| `,,` | Exit insert/visual mode; clear search highlighting in normal mode |
| `n` / `N` | Next / previous search result, centered |
| `Alt-j` / `Alt-k` | Move line or selection down / up |
| `<leader>ww` | Save |
| `<leader>wa` | Force save |
| `<leader>qq` | Quit |
| `<leader>qa` | Quit without saving |
| `<leader>ne` | Restart Neovim |
| `<leader>ni` | Open the config's `init.lua` |
| `<leader>nm` | Show messages |
| `<leader>u` | Open Undotree |

## Files and search

| Mapping | Action |
|---|---|
| `<leader>e` | Open Mini Files |
| `g~` inside Mini Files | Set working directory to the selected file's directory or selected directory |
| `g.` inside Mini Files | Toggle hidden files |
| `gx` inside Mini Files | Open selected entry with the system application |
| `<leader>ss` | Save a named project session |
| `<leader>sr` | Restore a session |
| `<leader>sd` | Delete a session |
| `<leader>ff` | Find files |
| `<leader>ft` | Live grep |
| `<leader>fb` | Buffers |
| `<leader>fo` | Recent files |
| `<leader>fp` | Open Telescope Projects |
| `<leader>fC` | Colorscheme picker |
| `<leader>fr` | Resume last Telescope picker |
| `<leader>fgb` | Git branches |
| `<leader>fgc` | Git commits |
| `<leader>fgs` | Git status |
| `<leader>fgS` | Git stash |
| `<leader>fgf` | Git-tracked files |
| `<leader>fgB` | Git buffer commits |
| `<leader>fs` | Treesitter symbols |
| `<leader>fx` | Diagnostics |
| `<leader>fch` | Command history |
| `<leader>fcc` | Commands |
| `<leader>fy` | Registers |
| `<leader>fm` | Marks |

## Git signs

| Mapping | Action |
|---|---|
| `<leader>gj` / `<leader>gk` | Next / previous hunk |
| `<leader>gp` | Preview hunk |
| `<leader>gs` | Stage hunk |
| `<leader>gu` | Undo stage hunk |
| `<leader>gr` | Reset hunk |
| `<leader>gR` | Reset buffer |
| `<leader>gl` | Blame line |
| `<leader>gd` | Diff against HEAD |
| `ih` in operator/visual mode | Select the current Git hunk |

## LSP

These mappings are buffer-local and appear when an LSP client attaches.

| Mapping | Action |
|---|---|
| `<leader>ld` | Definition |
| `<leader>lD` | Declaration |
| `<leader>li` | Implementation |
| `<leader>lt` | Type definition |
| `<leader>lr` | References |
| `<leader>lh` | Hover documentation |
| `<leader>ls` | Signature help |
| `<leader>la` | Code action |
| `<leader>lR` | Rename |
| `<leader>lf` | Format with clangd or Stylua |
| On save | Automatically format C/C++ with clangd and Lua with Stylua |
| `<leader>lj` / `<leader>lk` | Next / previous diagnostic |
| `<leader>lo` | Show diagnostics |
| `<leader>lq` | Diagnostic location list |
| `<leader>lH` | Toggle inlay hints |
| `<leader>lI` | LSP health |
| `<leader>lC` | Restart LSP |

## C and C++ (clangd)

| Mapping | Action |
|---|---|
| `gS` | Switch between source and header |
| `gI` | Show Clangd symbol information |

## Editing

Mini.ai provides additional built-in text objects for arguments, function calls, tags, quotes, and balanced brackets. Mini.surround provides `sa`, `sd`, and `sr` actions for adding, deleting, and replacing surrounding pairs.

## Debugging

| Mapping | Action |
|---|---|
| `<F5>` or `<leader>dc` | Start / continue with arguments |
| `<leader>dp` | Select saved project |
| `<leader>de` | Set executable |
| `<leader>dr` | Restart session |
| `<leader>dk` | Terminate session |
| `<leader>dl` | Run last configuration |
| `<F9>` or `<leader>dx` | Toggle breakpoint |
| `<leader>dB` | Conditional breakpoint |
| `<leader>dL` | Logpoint |
| `<leader>dX` | Clear all breakpoints |
| `<F10>` or `<leader>ds` | Step over |
| `<F11>` or `<leader>di` | Step into |
| `<F12>` or `<leader>do` | Step out |
| `<leader>dh` | Evaluate expression |
| `<leader>dR` | Open / focus REPL |
| `<leader>d/` | Search REPL lines |
| `<leader>du` | Toggle DAP UI |
| `<leader>dw` | Add watch |
| `<leader>dt` | Float a DAP UI element |

## Terminal and build

Inside the Telescope Projects picker (`<leader>fp`):

| Mapping | Action |
|---|---|
| `Enter` | Change working directory to the selected project |
| `Ctrl-r` | Run the selected project |
| `Ctrl-b` | Build the selected project |
| `Ctrl-f` | Find files in the selected project |
| `Ctrl-g` | Live grep in the selected project |

| Mapping | Action |
|---|---|
| `Ctrl-\` | Toggle the default terminal |
| `Alt-1` | Horizontal terminal |
| `Alt-2` | Vertical terminal |
| `Alt-3` | Floating terminal |
| `Ctrl-;` | Leave terminal mode |
| `<leader>rr` | Run the current project |
| `<leader>rb` | Build the current project |
| `<leader>rf` | Run the current file independently |
