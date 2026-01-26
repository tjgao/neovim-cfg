# AGENTS

## Purpose & Context
- This repository hosts a personal Neovim configuration rooted in `~/.config/nvim`, bootstrapped by `lazy.nvim` and tailored for daily development.
- The setup prioritizes fast startup, rich AI assistance via `opencode.nvim`, and a curated UI stack (Snacks, Lualine, Kanso theme, Diffview, etc.).
- All configuration modules live under `lua/`, with `init.lua` only orchestrating high-level requires for settings, lazy, and user modules.
- Plugin pinning is handled by `lazy-lock.json`; keep it in sync when adding or upgrading plugins.
- There are no Cursor rule files or GitHub Copilot instruction documents in this repo; if you add any, surface their guidance here as well.
- Agentic contributors should preserve ergonomic keymaps, diagnostics defaults, and existing UX choices unless explicitly asked to change them.
- Treat this config as the source of truth for development workflows on this machine—changes should be conservative and well-tested in Neovim.

## Repository Layout
- `init.lua` – entry point requiring options, lazy, keymaps, commands, and user-specific modules.
- `lua/lazy-nvim.lua` – bootstraps `lazy.nvim`, sets `mapleader`, and wires plugin specs from `lua/plugins`.
- `lua/settings/` – editor options (`options.lua`), global commands/autocmds (`commands.lua`), keymaps (`keymaps.lua`), and shared icon helpers.
- `lua/plugins/` – one file per plugin or feature group (LSP, Treesitter, opencode, Snacks, Gitsigns, Diffview, Telescope alternatives, etc.).
- `lua/users/` – bespoke modules such as `buf_close`, `skip`, `ts_breadcrumb`, and `dedoc` that encapsulate personal workflows.
- `lua/shared/utils.lua` – shared helper functions (keymap wrapper, visual selection getter, git hash parsing, title casing).
- Root-level helper scripts (`test.lua`, `test2.lua`, etc.) are sandboxes; avoid relying on them for automation unless instructed.
- `lazy-lock.json` pins plugin commits; regenerate via `:Lazy lock` after vetted upgrades.
- `.stylua.toml` and `.luarc.json` define formatting and LuaLS diagnostics preferences.

## Bootstrap & Environment
- Neovim nightly or ≥0.9 is assumed; ensure `nvim` is on PATH and supports LuaJIT + `vim.uv` APIs.
- Fonts: GUI configs assume `UbuntuMono Nerd Font Regular:h16`; adjust only if UX requirements change.
- Dependencies: `git`, `curl`, `node`, `python` (for tree-sitter grammars), and `rg` (for Telescope/LiveGrep) should be available.
- `lazy.nvim` auto-installs into `~/.local/share/nvim/lazy/lazy.nvim` if missing; no manual steps required beyond internet access.
- `opencode` CLI must exist on PATH; the Neovim plugin auto-detects running servers or spawns providers (terminal/snacks/tmux/kitty/wezterm).
- `tmux` is optional but recommended since many keymaps integrate with `vim-tmux-navigator` and terminal providers.
- Keep `$XDG_DATA_HOME` consistent (default `~/.local/share`) so Lazy and Treesitter assets resolve predictably.
- For remote agents, run commands from repo root `/home/tiejun/.config/nvim` unless told otherwise.

## Build / Install Commands
- Install or sync plugins headlessly: `nvim --headless "+Lazy! sync" +qa` (rerun after editing plugin specs or `lazy-lock.json`).
- Update plugins interactively: launch Neovim, run `:Lazy update`, review diffs, then `:Lazy lock` to pin.
- Rebuild Treesitter parsers: `nvim --headless "+TSUpdate" +qa` to ensure highlight modules stay current.
- Validate health: `nvim --headless "+checkhealth" +qa` (or `:checkhealth opencode` for focused diagnostics).
- Refresh LSP Mason tools: `nvim --headless "+MasonInstall clangd lua-language-server" +qa` as needed.
- If Snacks terminal provider is enabled, ensure `:Snacks terminal` launches without errors before relying on opencode auto-start.
- Use `:DiffviewOpen` and `:Lazy log` within Neovim to inspect plugin changes; avoid editing generated plugin metadata manually.

## Lint & Format
- Lua formatting is enforced by Stylua (see `.stylua.toml`); run `stylua lua` for the whole tree or `stylua lua/plugins/opencode.lua` for a single file.
- Stylua settings: 4-space indent, column width 120, Unix line endings, double quotes preferred, simple statements never collapsed.
- Keep `sort_requires.enabled = false` unless the user opts in; preserve require order when it conveys initialization semantics.
- LuaLS reads `.luarc.json`; declare globals via `---@diagnostic disable` or type annotations rather than editing `.luarc` unless necessary.
- For plugin files that expect `---@module` annotations, mirror upstream style for best completion support (e.g., opencode opts tables).
- No dedicated Lua linters are configured; prefer `stylua` + LuaLS diagnostics surfaced within Neovim.

## Testing & Single-Test Workflows
- There is no automated test suite; rely on targeted Neovim runs to validate changes.
- Quick sanity check: `nvim --headless -c "luafile %" -c "qa" lua/some/module.lua` to ensure a single module loads without runtime errors.
- Validate keymaps or commands by launching Neovim normally and exercising affected mappings (e.g., `<C-a>` for opencode ask, `<leader>tt` for Treesj).
- For plugin setups that affect diagnostics or UI, run `nvim --headless -c "lua require('plugins.<name>')" +qa` with `pcall` wrappers if needed.
- When modifying Treesitter configs, test a representative buffer: `nvim --headless +'e test.lua' +"TSHighlightCapturesUnderCursor" +qa`.
- Use `:messages` and `:Snacks notifier history` to ensure no startup warnings were introduced.
- Document manual test steps in PR descriptions so future agents can reproduce them.

## Plugin Management
- Each plugin spec resides in `lua/plugins/<name>.lua`; follow Lazy’s return-table convention (opts/keys/config fields).
- Defer expensive setup until inside `config = function()` blocks to avoid slowing Neovim startup.
- Use `dependencies` arrays to express plugin relationships (e.g., `opencode.nvim` depends on `folke/snacks.nvim`).
- Keep keymaps close to plugin configs when they are feature-specific; general-purpose mappings live in `settings/keymaps.lua`.
- Respect `vim.g.opencode_opts` global usage—opencode.nvim reads it during module load.
- Update `lazy-lock.json` whenever plugin commits change; avoid manual edits to that file.
- For experimental plugins, prefer disabling via Lazy opts instead of deleting files so history stays informative.

## Coding Style: Lua
- Use 4-space indentation consistently; avoid tabs.
- Prefer descriptive table keys and trailing commas; match existing alignment for readability.
- Modules should `return` either a config table (for Lazy) or a function table (for shared utilities).
- Group `require` statements at the top; no implicit globals besides `vim` (already whitelisted in `.luarc.json`).
- Document complex tables with EmmyLua annotations (`---@class`, `---@type`) to keep LuaLS happy.
- Keep comments factual and minimal—only where behavior is non-obvious or references upstream quirks.
- Avoid anonymous globals; attach helpers to module tables (e.g., `local M = {}` / `return M`).
- When wrapping commands, prefer `vim.api.nvim_create_user_command` or `vim.keymap.set` with descriptive `desc` fields.

## Coding Style: Neovim UX
- Maintain the dark theme baseline (`kanso-ink`) unless a change is explicitly requested.
- Respect existing keybinding philosophy: `<leader>` is space, heavy use of `<C-*>` for navigation, `<leader>q*` for quickfix helpers.
- Diagnostics defaults disable virtual text and underline; keep that consistent unless the user opts in.
- `vim.opt` assignments are centralized—prefer editing `settings/options.lua` over scattered overrides.
- Autocmd groups should be named (e.g., `kickstart-highlight-yank`, `last_location`) and created with `{ clear = true }` to avoid duplicates.
- Window/UI tweaks (WinSeparator colors, fillchars) belong in `settings/commands.lua`; don’t hardcode them elsewhere.

## Types, Docs, Diagnostics
- Use `---@type` before complex tables (such as `vim.g.opencode_opts`) to advertise schemas to LuaLS.
- When referencing plugin-specific types (e.g., `opencode.Opts`), ensure the defining plugin exports the annotation or add a local stub as done in `lua/plugins/opencode.lua`.
- Disable diagnostics locally with `---@diagnostic disable-next-line` instead of editing `.luarc.json`.
- Keep user-facing docstrings synchronized with actual behavior—especially for custom commands like `:Spell` or `:Df`.
- Document expectations for provider tables (`opencode.provider.*`) when wiring new options.

## Shared Utilities & Patterns
- `shared/utils.lua` defines `keymap`, `get_visual_selection`, and git helpers; reuse them instead of duplicating logic.
- `keymap(mode, lhs, rhs, desc)` automatically sets `{ noremap = true, silent = true }` and attaches descriptions; pass strings or tables per current pattern.
- Use `get_visual_selection` when piping selections to external tools or prompts to avoid yank-register side effects.
- Git hash utilities (`valid_commit_hash`, `get_commit_from_line`) rely on `vim.system`; ensure asynchronous expectations are met when reusing.

## User Modules & Commands
- `users/buf_close.lua`, `users/skip.lua`, `users/ts_breadcrumb.lua`, and `users/dedoc.lua` encapsulate personalized automations; keep their APIs stable.
- `settings/commands.lua` defines user commands like `:Spell` and `:Df`; extend this file when adding more custom commands.
- Quickfix autocmd logic distinguishes between loclist and qf windows; preserve that behavior when tweaking keymaps.
- Maintain highlight groups (e.g., `WinSeparator`) in the same module to keep UI tweaks centralized.

## Colors, UI, Status
- Theme defaults to `kanso-ink`; any alternative should be configured via `settings/commands.lua` to ensure consistent startup behavior.
- Global statusline is enabled (`set laststatus=3`), and window separators are styled; confirm changes keep backgrounds transparent (`guibg=none`).
- Snacks Notifier history is accessible via `<leader>sn`; new notification-heavy features should integrate with Snacks where possible.
- Diffview is preferred for git diffs; `:Df` command wraps `DiffviewOpen`, and `<leader>dd/df` manage views.

## External Integrations
- `vim-tmux-navigator` is tied to `<C-h/j/k/l>`; avoid conflicting keymaps and respect `vim.g.tmux_navigator_disable_when_zoomed = 1`.
- `Gitsigns` commands (`]h`, `[h`, `<leader>rh`) are pre-bound; new git helpers should harmonize with these mappings.
- `opencode.nvim` exposes keymaps: `<C-a>` or `@this` ask, `<C-x>` selection menu, `<C-.>` toggles pane, `go/goo` operator-pending functions.
- `quicker.nvim` handles quickfix/loclist toggles; reuse its API instead of reimplementing floats.
- `toggleterm`, `Harpoon`, `Diffview`, `Treesj`, `Flash`, `Mini.files`, and `Which-Key` already have configs; extend via their respective plugin files.

## Troubleshooting & Debugging
- Use `debug.log` in repo root for historical context; append findings instead of truncating unless size becomes an issue.
- If `:Lazy sync` fails, inspect `~/.local/share/nvim/lazy/lazy.nvim/log.json` or run `LAZY_LOG=trace nvim` for verbose output.
- For opencode issues, confirm the CLI server is running (`opencode serve --port 0`) and Neovim can reach it (`require('opencode.cli.server').get_port()`).
- `:Snacks profiler` (if enabled) can help trace slow startups; keep instrumentation off in committed code unless debugging.
- When diagnosing UI glitches, toggle highlights via `:hi WinSeparator?` and ensure autocmds aren’t redefined multiple times.
- Document any new debugging steps you discover by updating this section so future agents inherit the knowledge.

## Key Keymaps & Usage
- `<C-a>` / `<A-a>` prompt opencode with contextual placeholders; keep them conflict-free and documented.
- `<C-x>` opens the opencode action switcher, exposing prompts, commands, and provider controls.
- `<C-.>` toggles the opencode provider pane (Snacks terminal by default); avoid remapping this chord.
- `<leader>qq` / `<leader>ql` toggle quickfix vs loclist via `quicker.nvim`; rely on those before creating new lists.
- `<F1>` toggles `nvim-tree`; keep file explorers consistent with this binding.
- `<leader>tt` toggles Treesj structured editing; test structural changes against this workflow.

## Provider Guidance
- Provider options live under `vim.g.opencode_opts.provider`; keep them declarative to support Snacks, terminal, kitty, wezterm, or tmux launches.
- Ensure integrated providers run `opencode` with `--port <port>`; the plugin auto-appends this flag when `port` is set.
- Use `vim.o.autoread = true` (already set) to keep buffers in sync with opencode reload events.
- `opencode.cli.client` handles HTTP + SSE traffic via `curl`; prefer extending it over spawning new curl jobs elsewhere.
- The `select` UI fetches available agents and commands; when adding new opencode commands, ensure they surface through `/command`.
- Keep provider toggles accessible through the select picker; add new actions there to stay discoverable.

## Git & Workflow Expectations
- You may be in a dirty git worktree; never reset or clean unrelated changes without explicit approval.
- Avoid force pushes or history rewrites; prefer new commits over amendments unless the user explicitly requests otherwise.
- Do not edit `lazy-lock.json` manually; let Lazy update it and review the diff before committing.
- When adding files, default to ASCII; introduce Unicode only when already used and justified.
- Use apply_patch for focused edits; reserve bulk rewrites for well-justified refactors.
- Run `git status -sb` before and after work to keep track of unrelated changes.
- Document any manual steps (e.g., font installs, tmux tweaks) in `debug.log` or this file so agents stay in sync.

## Documentation Updates
- Keep this `AGENTS.md` in sync with tooling or workflow changes; aim for ~150 lines so future updates stay focused.
- If Cursor or Copilot instruction files are added later, summarize their directives here and link to their paths.
- Reference new custom commands, keymaps, or scripts in the relevant sections above to reduce onboarding friction.
