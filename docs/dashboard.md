# Dashboard

CVIM uses Alpha as its startup dashboard. The layout and animation are implemented in the configuration rather than being a static collection of ASCII text.

## Layout

The dashboard contains:

- An animated C-shaped logo rendered from a precomputed surface.
- A VIM wordmark beside the C, with intermittent randomized glitch effects.
- The tagline, **C, with a better editor.**, and a horizontal rule sized to the tagline.
- Quick-action buttons for files, projects, search, configuration, plugins, health checks, and quitting.
- A footer showing the Neovim version, loaded plugin count, startup time, working directory, and Git branch when available.
- An optional animated C tutorial below the logo.

The wordmark glitch effects are intentionally intermittent. Events vary in type and duration, and affect localized fragments so the wordmark remains recognizable. The C logo rotates independently of the wordmark effects.

## Dashboard buttons

The button definitions live in `lua/soul/core/helpers/dashboard/buttons.lua`. Each entry supplies its shortcut, icon registry key, label, command, and highlight group. Icon glyphs come from the shared registry in `lua/soul/core/helpers/icons.lua`.

Keep icon keys separate from display labels. Labels include their own leading space for consistent text spacing. When adding or changing a button, verify that its icon group and icon name exist in the shared registry.

The dashboard shortcuts are listed in [keymaps.md](keymaps.md).

## Animated C tutorial

The tutorial is controlled by `code_examples` in `lua/soul/plugins/alpha.lua`:

```lua
code_examples = false,
```

Set it to `true` to show the tutorial beneath the logo. It is disabled by default.

Tutorial scene data and timing live in `lua/soul/core/helpers/dashboard/header.lua`. The current sequence contains 19 short C topics, from a first program and compilation through pointers, dynamic memory, file I/O, and bitwise operations.

The timeline builder in `alpha/sections.lua` types each heading, code line, and explanation progressively. The caret moves toward the selected token as its code line is typed, and remains anchored while optional closing lines appear. Code tokens and explanation vocabulary use semantic highlight groups rather than applying color to an entire completed line.

When adding a scene:

1. Give it a heading, code lines, an explanation, and a `cursor_token`.
2. Make sure the cursor token occurs in the configured source line. The timeline builder asserts this when it creates the scene.
3. Keep the snippet valid and the explanation accurate.
4. Check that its topic highlight exists in the dashboard highlight definitions.
5. Review the caret position and line centering in a real Alpha window.

## Implementation map

| File | Responsibility |
|---|---|
| `lua/soul/plugins/alpha.lua` | Alpha setup, tutorial toggle, and shared animation clock |
| `lua/soul/core/helpers/dashboard/logo.lua` | C renderer, VIM wordmark, glitch effects, and logo frame state |
| `lua/soul/core/helpers/dashboard/header.lua` | C tutorial scenes and timing |
| `lua/soul/core/helpers/dashboard/alpha/sections.lua` | Layout, button creation, tutorial timeline, and syntax highlighting |
| `lua/soul/core/helpers/dashboard/animation.lua` | Timer start/stop lifecycle and guarded redraws |
| `lua/soul/core/helpers/dashboard/alpha/autocmds.lua` | Starts and stops animation as the Alpha buffer is entered or left |
| `lua/soul/core/helpers/dashboard/buttons.lua` | Dashboard button data |
| `lua/soul/core/helpers/dashboard/footer.lua` | Startup and current-project context |
| `lua/soul/core/helpers/dashboard/horizontal_rule.lua` | Shared width-based horizontal rule |

The animation lifecycle stops when the dashboard buffer is left and restarts when it is entered again. The timer checks that Alpha is still active before updating, and stops with a notification if an animation callback or redraw fails.

## Maintenance notes

- Keep the C renderer and wordmark glitch state in `logo.lua`; do not move animation state into the plugin specification.
- Keep tutorial scene content in `header.lua` and timeline/rendering behavior in `sections.lua`.
- Keep the shared animation timer independent of logo and tutorial implementation details.
- Keep dashboard icon definitions in the shared icon registry. Do not add leading spaces to icon lookup keys.
- Preserve the fixed-width tutorial frame padding. It prevents Alpha from shifting the dashboard as partial lines are typed.
- Use the shared horizontal-rule helper when adding a rule whose width depends on displayed text.
- Source inspection and headless checks do not replace visual testing in a real Neovim window. Review alignment, glyph width, highlight timing, caret placement, animation pacing, and terminal font rendering after dashboard changes.
