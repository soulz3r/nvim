# Plugin inventory

This file records why each plugin is part of the configuration. It is an architectural guide, not a second lockfile; exact revisions remain in `lazy-lock.json`.

## Editor foundation

| Plugin | Purpose |
|---|---|
| `lazy.nvim` | Plugin specification loading, lazy-loading, and synchronization |
| `nvim-treesitter` | Syntax trees, highlighting, and parser-backed editor features |
| `nvim-lspconfig` | Server definitions used with Neovim's native LSP client |
| `blink.cmp` | Completion UI and LSP completion capabilities |
| `friendly-snippets` | Reusable completion snippets |

## Navigation and project workflow

| Plugin | Purpose |
|---|---|
| `telescope.nvim` | File, text, buffer, LSP, Git, and command pickers |
| `telescope-fzf-native.nvim` | Native fuzzy sorting for Telescope |
| `telescope-ui-select.nvim` | Telescope presentation for Neovim selection UIs |
| `telescope-project.nvim` | Project selection used by YAP |
| `yap.nvim` | Project build/run actions, project metadata, C helpers, and runner UI |
| `undotree` | Visualize buffer undo history |
| `gitsigns.nvim` | Git hunk indicators and buffer-level Git actions |

## Editing and buffer utilities

| Plugin | Purpose |
|---|---|
| `mini.ai` | Extend text objects |
| `mini.files` | File browsing, preview, and file operations |
| `mini.icons` | Icons used by Mini Files and other UI integrations |
| `mini.pairs` | Automatic paired-character insertion |
| `mini.surround` | Add, delete, and replace surrounding text |
| `mini.sessions` | Session persistence |
| `mini.notify` | Notification display and LSP progress presentation |
| `eyeliner.nvim` | Faster character targeting for motions |
| `todo-comments.nvim` | Highlight and search TODO-style comments |
| `nvim-ufo` | Fold management |
| `promise-async` | Async dependency used by folding integrations |

## UI and presentation

| Plugin | Purpose |
|---|---|
| `alpha-nvim` | Startup dashboard |
| `everforest` | Main colorscheme |
| `nvim-web-devicons` | Filetype icons |
| `lualine.nvim` | Statusline |
| `breadcrumbs.nvim` | Symbol breadcrumbs in the winbar |
| `nvim-navic` | LSP document-symbol context for breadcrumbs |
| `statuscol.nvim` | Status column and diagnostic/sign display |
| `render-markdown.nvim` | Markdown rendering in buffers |
| `nvim-colorizer.lua` | Inline color previews |
| `toggleterm.nvim` | Persistent terminal windows |
| `which-key.nvim` | Discoverable keymap hints |
| `tiny-cmdline.nvim` | Optional experimental UI2 command-line presentation |

## Debugging

| Plugin | Purpose |
|---|---|
| `nvim-dap` | Debug Adapter Protocol client |
| `nvim-dap-ui` | Debug session panels and controls |
| `nvim-nio` | Async dependency used by nvim-dap-ui |

## Maintenance rules

- Prefer Neovim's built-in features when they cover the requirement cleanly.
- Keep plugin setup in its owning specification and reusable configuration in the corresponding helper.
- Add a row here when adding a plugin, and remove it when removing one.
- Explain non-obvious dependencies in `docs/architecture.md`; this inventory is not a substitute for dependency declarations.
- Keep `lazy-lock.json` synchronized with plugin specification changes.
