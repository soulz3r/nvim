# Keymap reference

The leader key is Space. This is a compact reference for the most-used mappings; WhichKey provides descriptions for many additional mappings.

## Dashboard

The Alpha dashboard exposes these single-key actions when it is open:

| Key | Action |
|---|---|
| `f` | Find files |
| `e` | Open Mini Files in the current working directory |
| `n` | Create a new empty buffer and enter Insert mode |
| `p` | Open the YAP project picker |
| `r` | Find recent files |
| `t` | Search text with live grep |
| `m` | Browse marks |
| `c` | Open the configuration's `init.lua` |
| `l` | Open Lazy.nvim |
| `h` | Run `:checkhealth` |
| `q` | Quit Neovim |

See [dashboard.md](dashboard.md) for the animated header, optional C tutorial, and dashboard configuration.

## Navigation and editing

| Mapping | Action |
|---|---|
| `Ctrl-h/j/k/l` | Move between windows |
| `Alt-Tab` | Switch to the alternate buffer |
| `,,` | Exit insert/visual mode; clear search highlighting in normal mode |
| `n` / `N` | Next / previous search result, centered |
| `Alt-j` / `Alt-k` | In Normal mode, move the current line down / up. In Visual mode, move the selected line range down / up and keep it selected |
| `<leader>w` | Save current file; inside Mini Files, synchronize pending filesystem changes with confirmation |
| `<leader>q` | Quit the current window; Neovim prompts if the buffer has unsaved changes |
| `<leader>ne` | Restart Neovim |
| `<leader>ni` | Open the config's `init.lua` |
| `<leader>nm` | Show all messages in a floating window |
| `<leader>u` | Open Undotree |

Use `V` to select whole lines, then press `Alt-j` or `Alt-k` to move the selected block one line down or up. The mapping uses the Visual selection marks and restores the selection after moving, so Visual mode remains active for repeated moves. Characterwise Visual selections that span multiple lines are also moved as whole lines.

## Files and search

| Mapping | Action |
|---|---|
| `<leader>e` | Open Mini Files |
| `g~` inside Mini Files | Set working directory to the selected file's directory or selected directory |
| `g.` inside Mini Files | Toggle hidden files |
| `gx` inside Mini Files | Open selected entry with the system application |
| `<leader>w` inside Mini Files | Synchronize filesystem changes; Mini Files asks for confirmation |
| `<leader>ss` | Save a named project session |
| `<leader>sr` | Restore a session |
| `<leader>sd` | Delete a session |
| `<leader>ff` | Find files |
| `<leader>ft` | Live grep |
| `<leader>fb` | Buffers |
| `<leader>fo` | Recent files |
| `<leader>pp` | Open the YAP Telescope project picker |
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
| `<leader>lw` | Workspace symbols |
| `<leader>lS` | Document symbols |
| `<leader>lH` | Toggle inlay hints |
| `<leader>lI` | LSP health |
| `<leader>lC` | Restart LSP |

## C and C++ (clangd)

YAP adds these buffer-local helpers in C/C++ buffers:

| Mapping / Command | Action |
|---|---|
| `<leader>ch` | Switch between matching source and header files |
| `<leader>ci` | Insert an include directive |
| `<leader>cp` | Show C/C++ project and compile metadata |
| `:CSwitchHeader` | Switch between matching source and header files |
| `:CProjectInfo` | Show C/C++ project and compile metadata |

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
| `<leader>dK` | List breakpoints |
| `<F10>` or `<leader>ds` | Step over |
| `<F11>` or `<leader>di` | Step into |
| `<F12>` or `<leader>do` | Step out |
| `<leader>dS` | Step back |
| `<leader>dP` | Pause |
| `<leader>dG` | Run to cursor |
| `<leader>dJ` | Go to current line |
| `<leader>dU` / `<leader>dD` | Older / newer stack frame |
| `<leader>dF` | Focus frame |
| `<leader>dh` | Evaluate expression |
| `<leader>dR` | Open / focus REPL |
| `<leader>d/` | Search REPL lines |
| `<leader>du` | Toggle DAP UI |
| `<leader>dw` | Add watch |
| `<leader>dt` | Float a DAP UI element |
| `<leader>d?` | Show DAP log |

## Terminal and build

| Mapping | Action |
|---|---|
| `<leader>X` | Compile and run the current C file in an interactive floating terminal |
| `<leader>x` | Add executable permission on POSIX systems; explain the Windows limitation on Windows |
| `Ctrl-\\` | Toggle the default terminal |
| `Alt-1` | Horizontal terminal |
| `Alt-2` | Vertical terminal |
| `Alt-3` | Floating terminal |
| `Ctrl-;` | Leave terminal mode |

### Project runner

| Mapping | Action |
|---|---|
| `<leader>pp` | Open the YAP Telescope project picker |
| `<leader>pr` | Build and run the current C project |
| `<leader>pb` | Build the current C project only |
| `<leader>pc` | Clean the current C project |
| `<leader>pB` | Clean and rebuild the current C project |
| `<leader>pS` | Select a build script, then build |
| `<leader>pe` | Select an executable, enter arguments, and run without building |
| `<leader>ps` | Stop the active project process |
| `<leader>pR` | Rerun the most recently used saved project's executable and arguments |

Inside the YAP Telescope project picker, these YAP-specific actions are available:

| Mapping | Action |
|---|---|
| `Ctrl-g` | Build and run the selected project |
| `Ctrl-y` | Build the selected project |
| `Ctrl-e` | Choose an executable and run it |
| `Ctrl-a` | Open the selected project's action menu |
| `gR` / `gB` / `gE` | Run / build / choose executable in Normal mode |
| `gC` / `gX` / `gS` | Clean / rebuild / choose build script in Normal mode |
| `gA` | Open the project action menu in Normal mode |

The runner output window also supports `Ctrl-c` to stop the active process and `<leader>pq` to send parsed compiler diagnostics to quickfix.
