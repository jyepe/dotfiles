# SynthWave '84 Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update WezTerm and Herdr configuration files in dotfiles to use the SynthWave '84 theme palette, configure Mica backdrop with less blur, and streamline WezTerm window settings.

**Architecture:** Update `wezterm/colors.lua` with custom SynthWave '84 16-color ANSI palette and cursor/selection settings, adjust `wezterm/appearance.lua` (disable tab bar, Mica backdrop, padding = 6), and configure `herdr/config.toml` with custom theme overrides.

**Tech Stack:** Lua (WezTerm configuration), TOML (Herdr configuration).

## Global Constraints

- Palette tokens:
  - Background: `#262335`
  - Deep dark background (sidebar/bar): `#1a1528`
  - Elevated active row: `#34294f`
  - Selection: `#463568`
  - Neon Magenta (accent/cursor): `#ff7edb`
  - Electric Cyan: `#36f9f6`
  - Neon Mint (green): `#72f1b8`
  - Electric Gold (yellow): `#fede5d`
  - Neon Crimson (red): `#fe4450`
  - Text: `#f0eff1`
  - Muted text: `#848bbd`
- WezTerm backdrop: `win32_system_backdrop = "Mica"`, `window_background_opacity = 0.85`.
- WezTerm native tab bar disabled (`enable_tab_bar = false`), padding `6`.
- WezTerm configuration must parse without error via `wezterm ls-fonts`.

---

### Task 1: Update WezTerm Colors and Palette

**Files:**
- Modify: `wezterm/colors.lua`

**Interfaces:**
- Consumes: WezTerm Config Builder object
- Produces: `M.apply_to_config(config)` setting `config.colors` with full SynthWave '84 palette

- [ ] **Step 1: Write SynthWave '84 palette to `wezterm/colors.lua`**

Update `wezterm/colors.lua` with the following content:

```lua
local M = {}

function M.apply_to_config(config)
	-- SynthWave '84 Palette
	config.colors = {
		foreground = "#f0eff1",
		background = "#262335",

		cursor_bg = "#ff7edb",
		cursor_border = "#ff7edb",
		cursor_fg = "#262335",

		selection_bg = "#463568",
		selection_fg = "#f0eff1",

		scrollbar_thumb = "#34294f",
		split = "#34294f",

		ansi = {
			"#1a1528", -- black
			"#fe4450", -- red
			"#72f1b8", -- green
			"#fede5d", -- yellow
			"#36f9f6", -- blue / cyan
			"#ff7edb", -- magenta
			"#36f9f6", -- cyan
			"#f0eff1", -- white
		},
		brights = {
			"#614d85", -- bright black
			"#fe4450", -- bright red
			"#72f1b8", -- bright green
			"#fede5d", -- bright yellow
			"#36f9f6", -- bright blue
			"#ff7edb", -- bright magenta
			"#36f9f6", -- bright cyan
			"#ffffff", -- bright white
		},

		tab_bar = {
			background = "#1a1528",
			active_tab = {
				bg_color = "#34294f",
				fg_color = "#36f9f6",
				intensity = "Bold",
				underline = "None",
				italic = false,
				strikethrough = false,
			},
			inactive_tab = {
				bg_color = "#241b2f",
				fg_color = "#848bbd",
				intensity = "Normal",
				underline = "None",
				italic = false,
				strikethrough = false,
			},
			inactive_tab_hover = {
				bg_color = "#463568",
				fg_color = "#36f9f6",
				intensity = "Normal",
				underline = "None",
				italic = false,
				strikethrough = false,
			},
			new_tab = {
				bg_color = "#1a1528",
				fg_color = "#614d85",
				intensity = "Normal",
				underline = "None",
				italic = false,
				strikethrough = false,
			},
			new_tab_hover = {
				bg_color = "#241b2f",
				fg_color = "#848bbd",
				intensity = "Normal",
				underline = "None",
				italic = false,
				strikethrough = false,
			},
		},
	}
end

return M
```

- [ ] **Step 2: Verify WezTerm loads configuration**

Run: `wezterm ls-fonts`
Expected: Exit code 0, no errors on stderr.

- [ ] **Step 3: Commit changes**

```bash
git add wezterm/colors.lua
git commit -m "style(wezterm): update color palette to SynthWave '84"
```

---

### Task 2: Streamline WezTerm Appearance & Backdrop

**Files:**
- Modify: `wezterm/appearance.lua`

**Interfaces:**
- Consumes: WezTerm Config Builder object
- Produces: `M.apply_to_config(config)` configuring window appearance, padding, Mica backdrop, and disabling the native tab bar.

- [ ] **Step 1: Update `wezterm/appearance.lua`**

Update `wezterm/appearance.lua` with the following content:

```lua
local M = {}

function M.apply_to_config(config)
	-- Disable native tab bar: Herdr manages spaces, tabs, and panes
	config.enable_tab_bar = false
	config.use_fancy_tab_bar = false
	config.tab_bar_at_bottom = false
	config.hide_tab_bar_if_only_one_tab = false
	config.show_new_tab_button_in_tab_bar = false
	config.show_tab_index_in_tab_bar = false
	config.tab_max_width = 32

	-- Window & Backdrop (Mica with crisp opacity)
	config.window_decorations = "RESIZE"
	config.window_background_opacity = 0.85
	config.win32_system_backdrop = "Mica"
	config.window_padding = { left = 6, right = 6, top = 6, bottom = 6 }

	-- Initial size
	config.initial_cols = 120
	config.initial_rows = 30

	-- Scrollback
	config.scrollback_lines = 10000

	-- Shell
	config.default_prog = { "pwsh" }
end

return M
```

- [ ] **Step 2: Verify WezTerm loads configuration**

Run: `wezterm ls-fonts`
Expected: Exit code 0, no errors on stderr.

- [ ] **Step 3: Commit changes**

```bash
git add wezterm/appearance.lua
git commit -m "style(wezterm): streamline appearance with Mica backdrop and disabled tab bar"
```

---

### Task 3: Update Herdr Theme Configuration

**Files:**
- Modify: `herdr/config.toml`

**Interfaces:**
- Consumes: Herdr configuration file
- Produces: `[theme]` and `[theme.custom]` blocks configured for SynthWave '84

- [ ] **Step 1: Update `herdr/config.toml`**

Update `herdr/config.toml` with the following content:

```toml
onboarding = false

[theme]
name = "vesper"
auto_switch = false

[theme.custom]
sidebar_bg = "#1a1528"
active_row_bg = "#34294f"
selection_bg = "#463568"
panel_bg = "reset"
accent = "#ff7edb"
cyan = "#36f9f6"
green = "#72f1b8"
red = "#fe4450"
yellow = "#fede5d"
text = "#f0eff1"

[terminal]
default_shell = "pwsh"
shell_mode = "non_login"
```

- [ ] **Step 2: Validate configuration**

Run: `python3 -c "import tomllib; tomllib.loads(open('herdr/config.toml', 'rb').read().decode('utf-8')); print('TOML Valid')"`
Expected: `TOML Valid`

- [ ] **Step 3: Commit changes**

```bash
git add herdr/config.toml
git commit -m "style(herdr): configure SynthWave '84 theme overrides"
```

---

### Task 4: End-to-End Verification

**Files:**
- Test all modified files: `wezterm/colors.lua`, `wezterm/appearance.lua`, `herdr/config.toml`

- [ ] **Step 1: Run WezTerm syntax check and workspace tests**

Run: `wezterm ls-fonts`
Expected: Exit code 0.

Run: `wezterm --config-file tests/wezterm/workspace_config_test.lua ls-fonts`
Expected: `workspace_config tests passed`, Exit code 0.

- [ ] **Step 2: Verify git status is clean**

Run: `git status`
Expected: Working tree clean.
