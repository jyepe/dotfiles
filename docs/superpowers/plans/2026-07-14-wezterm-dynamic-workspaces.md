# Dynamic WezTerm Workspaces Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build machine-local, lazily created WezTerm workspaces with a searchable launcher and a styled top bar that always shows the active workspace and its tabs.

**Architecture:** Keep workspace definitions in `~/.config/wezterm/workspaces.local.lua` and shared behavior in the dotfiles repository. Separate pure definition loading/validation from GUI workspace actions so validation can be exercised through a dedicated WezTerm test configuration. Render the workspace once with left status and render each tab through `format-tab-title`.

**Tech Stack:** WezTerm Lua configuration API, WezTerm 20240203-110809-5046fc22, PowerShell 7, Windows 10, Nerd Font glyphs, Git Bash for verification commands.

## Global Constraints

- The installed WezTerm version is `20240203-110809-5046fc22`; do not use newer-only `tab_bar_style` edge fields.
- `Ctrl+Space` remains the leader and `Leader+w` remains close-current-tab.
- `Alt+number` remains reserved for GlazeWM.
- Startup creates only `home`, rooted at `wezterm.home_dir`.
- Machine-local definitions live at `wezterm.home_dir .. "/.config/wezterm/workspaces.local.lua"` and are never committed.
- Missing, invalid, or empty local definitions fall back safely to `home`.
- Configured workspaces are created only when selected.
- The top tab bar is always visible, including with one tab.
- The default program remains `{ "pwsh" }`; never pass an empty `args` table during startup.
- Do not alter the existing unrelated modified `nvim` submodule.

---

## File Structure

- Create `wezterm/workspace_config.lua`: load and validate the machine-local list without GUI side effects.
- Replace `wezterm/workspaces.lua`: register startup and expose the dynamic workspace launcher action.
- Create `wezterm/tab_bar.lua`: render left workspace status and formatted tab labels.
- Modify `wezterm/keys.lua`: bind `Leader+Space` to the action supplied by `workspaces.lua` while preserving current bindings.
- Modify `wezterm/appearance.lua`: move the bar to the top, keep it visible, and suppress built-in index/close/new-tab decorations.
- Modify `wezterm/colors.lua`: retain the TokyoNight palette and add command-palette colors used by the launcher.
- Modify `wezterm/.wezterm.lua`: load modules in dependency order and register both workspace and tab-bar event handlers.
- Create `wezterm/workspaces.local.example.lua`: tracked example for per-machine definitions.
- Create `tests/wezterm/workspace_config_test.lua`: assertions run by WezTerm's configuration loader.
- Create `tests/wezterm/fixtures/*.lua`: valid and invalid definition fixtures.
- Modify `README.md`: document setup, local path, fallback, and bindings.

---

### Task 1: Workspace Definition Loader and Validation

**Files:**
- Create: `wezterm/workspace_config.lua`
- Create: `wezterm/workspaces.local.example.lua`
- Create: `tests/wezterm/workspace_config_test.lua`
- Create: `tests/wezterm/fixtures/valid.lua`
- Create: `tests/wezterm/fixtures/mixed.lua`
- Create: `tests/wezterm/fixtures/runtime-error.lua`

**Interfaces:**
- Produces: `workspace_config.load(path) -> ordered array of { name: string, cwd: string }`.
- Produces: `workspace_config.validate(raw) -> ordered array of valid definitions`.
- The returned list always begins with `{ name = "home", cwd = wezterm.home_dir }`.
- Later tasks consume the returned list without revalidating it.

- [ ] **Step 1: Create fixtures that cover valid, malformed, duplicate, and reserved entries**

Create `tests/wezterm/fixtures/valid.lua`:

```lua
return {
	{ name = "dotfiles", cwd = "C:/projects/dotfiles" },
	{ name = "notes", cwd = "D:/notes" },
}
```

Create `tests/wezterm/fixtures/mixed.lua`:

```lua
return {
	{ name = "dotfiles", cwd = "C:/projects/dotfiles" },
	{ name = "", cwd = "C:/empty-name" },
	{ name = "missing-cwd" },
	"not-a-table",
	{ name = "dotfiles", cwd = "C:/duplicate" },
	{ name = "home", cwd = "C:/reserved" },
	{ name = "notes", cwd = "D:/notes" },
}
```

Create `tests/wezterm/fixtures/runtime-error.lua`:

```lua
error("fixture failure")
```

- [ ] **Step 2: Write the failing WezTerm-hosted loader test**

Create `tests/wezterm/workspace_config_test.lua`:

```lua
local wezterm = require("wezterm")
local repo = wezterm.home_dir .. "/dotfiles/"
local workspace_config = dofile(repo .. "wezterm/workspace_config.lua")
local fixtures = repo .. "tests/wezterm/fixtures/"

local function assert_equal(actual, expected, message)
	if actual ~= expected then
		error(string.format("%s: expected %q, got %q", message, expected, actual))
	end
end

local valid = workspace_config.load(fixtures .. "valid.lua")
assert_equal(#valid, 3, "valid list size")
assert_equal(valid[1].name, "home", "home is first")
assert_equal(valid[1].cwd, wezterm.home_dir, "home directory")
assert_equal(valid[2].name, "dotfiles", "first local name")
assert_equal(valid[2].cwd, "C:/projects/dotfiles", "first local cwd")
assert_equal(valid[3].name, "notes", "second local name")

local mixed = workspace_config.load(fixtures .. "mixed.lua")
assert_equal(#mixed, 3, "invalid entries are removed")
assert_equal(mixed[2].name, "dotfiles", "first duplicate wins")
assert_equal(mixed[2].cwd, "C:/projects/dotfiles", "duplicate does not replace cwd")
assert_equal(mixed[3].name, "notes", "valid entry after invalid entries survives")

local missing = workspace_config.load(fixtures .. "does-not-exist.lua")
assert_equal(#missing, 1, "missing file fallback size")
assert_equal(missing[1].name, "home", "missing file fallback name")

local broken = workspace_config.load(fixtures .. "runtime-error.lua")
assert_equal(#broken, 1, "runtime error fallback size")
assert_equal(broken[1].name, "home", "runtime error fallback name")

local wrong_type = workspace_config.validate("not a table")
assert_equal(#wrong_type, 1, "wrong root type fallback size")

wezterm.log_info("workspace_config tests passed")
return wezterm.config_builder()
```

- [ ] **Step 3: Run the test to verify it fails because the module is absent**

Run:

```bash
"/c/Program Files/WezTerm/wezterm.exe" --config-file tests/wezterm/workspace_config_test.lua ls-fonts
```

Expected: non-zero exit with an error that `wezterm/workspace_config.lua` cannot be opened.

- [ ] **Step 4: Implement the loader and validator**

Create `wezterm/workspace_config.lua`:

```lua
local wezterm = require("wezterm")

local M = {}

local function home_definition()
	return { name = "home", cwd = wezterm.home_dir }
end

function M.validate(raw)
	local definitions = { home_definition() }
	local seen = { home = true }

	if type(raw) ~= "table" then
		wezterm.log_warn("workspace definitions must return a table; using home only")
		return definitions
	end

	for index, entry in ipairs(raw) do
		if type(entry) ~= "table" then
			wezterm.log_warn(string.format("skipping workspace entry %d: expected a table", index))
		elseif type(entry.name) ~= "string" or entry.name == "" then
			wezterm.log_warn(string.format("skipping workspace entry %d: name must be a non-empty string", index))
		elseif type(entry.cwd) ~= "string" or entry.cwd == "" then
			wezterm.log_warn(string.format("skipping workspace entry %d (%s): cwd must be a non-empty string", index, entry.name))
		elseif seen[entry.name] then
			wezterm.log_warn(string.format("skipping workspace entry %d: duplicate or reserved name %q", index, entry.name))
		else
			seen[entry.name] = true
			table.insert(definitions, { name = entry.name, cwd = entry.cwd })
		end
	end

	return definitions
end

function M.load(path)
	local matches = wezterm.glob(path)
	if #matches == 0 then
		return { home_definition() }
	end

	local ok, raw = pcall(dofile, path)
	if not ok then
		wezterm.log_error(string.format("failed to load workspace definitions from %s: %s", path, raw))
		return { home_definition() }
	end

	return M.validate(raw)
end

return M
```

- [ ] **Step 5: Add the tracked local-file example**

Create `wezterm/workspaces.local.example.lua`:

```lua
return {
	{ name = "dotfiles", cwd = "C:/Users/your-name/dotfiles" },
	{ name = "notes", cwd = "D:/Notes" },
}
```

- [ ] **Step 6: Run the loader tests and configuration parser**

Run:

```bash
"/c/Program Files/WezTerm/wezterm.exe" --config-file tests/wezterm/workspace_config_test.lua ls-fonts 2>&1 | tee /tmp/workspace-config-test.log
grep -F "workspace_config tests passed" /tmp/workspace-config-test.log
```

Expected: both commands exit 0; output includes warnings for rejected fixture entries and `workspace_config tests passed`.

- [ ] **Step 7: Commit the loader slice**

```bash
git add wezterm/workspace_config.lua wezterm/workspaces.local.example.lua tests/wezterm
git commit -m "feat(wezterm): load machine-local workspaces"
```

---

### Task 2: Lazy Workspace Launcher and Startup

**Files:**
- Replace: `wezterm/workspaces.lua`
- Modify: `wezterm/keys.lua:1-85`
- Modify: `wezterm/.wezterm.lua:13-27`

**Interfaces:**
- Consumes: `workspace_config.load(path)` from Task 1.
- Produces: `workspaces.setup()` for startup event registration.
- Produces: `workspaces.selector_action()` returning a WezTerm callback action for `Leader+Space`.
- `keys.apply_to_config(config, workspaces)` consumes the workspace module.

- [ ] **Step 1: Capture the pre-change key map and prove the workspace binding is absent**

Run:

```bash
"/c/Program Files/WezTerm/wezterm.exe" show-keys --lua > /tmp/wezterm-keys-before.lua
if grep -F 'key = "Space"' /tmp/wezterm-keys-before.lua | grep -F 'LEADER'; then exit 1; fi
```

Expected: exit 0 because no `Leader+Space` binding exists yet.

- [ ] **Step 2: Replace the workspace module with lazy selection behavior**

Replace `wezterm/workspaces.lua` with:

```lua
local wezterm = require("wezterm")
local mux = wezterm.mux
local act = wezterm.action
local workspace_config = dofile(wezterm.home_dir .. "/dotfiles/wezterm/workspace_config.lua")

local M = {}
local local_path = wezterm.home_dir .. "/.config/wezterm/workspaces.local.lua"

local function definitions()
	return workspace_config.load(local_path)
end

local function directory_exists(path)
	return #wezterm.glob(path) > 0
end

local function existing_workspaces()
	local result = {}
	for _, name in ipairs(mux.get_workspace_names()) do
		result[name] = true
	end
	return result
end

local function switch_to(window, pane, definition)
	if window:active_workspace() == definition.name then
		return
	end

	local exists = existing_workspaces()[definition.name]
	if not exists and not directory_exists(definition.cwd) then
		window:toast_notification(
			"WezTerm workspace",
			string.format("Cannot open %s: directory does not exist\n%s", definition.name, definition.cwd),
			nil,
			4000
		)
		return
	end

	window:perform_action(
		act.SwitchToWorkspace({
			name = definition.name,
			spawn = exists and nil or {
				label = "Workspace: " .. definition.name,
				cwd = definition.cwd,
			},
		}),
		pane
	)
end

function M.selector_action()
	return wezterm.action_callback(function(window, pane)
		local loaded = definitions()
		local by_name = {}
		local choices = {}

		for _, definition in ipairs(loaded) do
			by_name[definition.name] = definition
			table.insert(choices, {
				id = definition.name,
				label = string.format("%-16s  %s", definition.name, definition.cwd),
			})
		end

		window:perform_action(
			act.InputSelector({
				title = "Choose workspace",
				description = "Enter = switch  Esc = cancel",
				fuzzy = true,
				fuzzy_description = "Workspace: ",
				choices = choices,
				action = wezterm.action_callback(function(inner_window, inner_pane, id)
					if id and by_name[id] then
						switch_to(inner_window, inner_pane, by_name[id])
					end
				end),
			}),
			pane
		)
	end)
end

function M.setup()
	wezterm.on("gui-startup", function(cmd)
		local spawn = {
			workspace = "home",
			cwd = wezterm.home_dir,
		}
		if cmd and cmd.args and #cmd.args > 0 then
			spawn.args = cmd.args
		end
		mux.spawn_window(spawn)
	end)
end

return M
```

- [ ] **Step 3: Pass the workspace module into the key module and add `Leader+Space`**

In `wezterm/keys.lua`, change the function signature:

```lua
function M.apply_to_config(config, workspaces)
```

Add this as the first entry in `config.keys`:

```lua
		-- Workspaces
		{ key = "Space", mods = "LEADER", action = workspaces.selector_action() },
```

Keep every existing tab, split, pane, rename, search, zoom, and reload binding unchanged.

- [ ] **Step 4: Change module application order in the root config**

In `wezterm/.wezterm.lua`, keep the current module loads but replace:

```lua
keys.apply_to_config(config)
```

with:

```lua
keys.apply_to_config(config, workspaces)
```

Keep `workspaces.setup()` after all `apply_to_config` calls.

- [ ] **Step 5: Parse the configuration and inspect key assignments**

Run:

```bash
"/c/Program Files/WezTerm/wezterm.exe" ls-fonts
"/c/Program Files/WezTerm/wezterm.exe" show-keys --lua > /tmp/wezterm-keys-after.lua
grep -n -A2 -B2 'key = "Space"' /tmp/wezterm-keys-after.lua
grep -n -A2 -B2 'key = "w"' /tmp/wezterm-keys-after.lua
```

Expected: all commands exit 0; output shows `Leader+Space` and preserves `Leader+w`.

- [ ] **Step 6: Perform a startup smoke test without the local file**

First confirm whether the local file exists:

```bash
LOCAL_WORKSPACES="$HOME/.config/wezterm/workspaces.local.lua"
test ! -e "$LOCAL_WORKSPACES" || printf 'Local file exists; leave it untouched: %s\n' "$LOCAL_WORKSPACES"
```

Launch a bounded smoke process:

```bash
"/c/Program Files/WezTerm/wezterm.exe" start --always-new-process -- pwsh -NoLogo -NoProfile -Command 'exit 0'
```

Expected: command exits 0 and no Lua error dialog appears. Do not rename, overwrite, or delete an existing machine-local file for this test.

- [ ] **Step 7: Commit the launcher slice**

```bash
git add wezterm/.wezterm.lua wezterm/keys.lua wezterm/workspaces.lua
git commit -m "feat(wezterm): add lazy workspace launcher"
```

---

### Task 3: Styled Workspace and Tab Bar

**Files:**
- Create: `wezterm/tab_bar.lua`
- Modify: `wezterm/appearance.lua:3-10`
- Modify: `wezterm/colors.lua:3-51`
- Modify: `wezterm/.wezterm.lua:13-28`

**Interfaces:**
- Produces: `tab_bar.setup()` registering exactly one `format-tab-title` handler and one `update-status` handler.
- Uses `window:active_workspace()` to render the singular workspace segment through `window:set_left_status()`.
- Uses the event's `tab`, `hover`, and `max_width` values to render each tab.

- [ ] **Step 1: Change the static appearance settings**

In `wezterm/appearance.lua`, replace the tab-bar block with:

```lua
	-- Top tab bar: always visible so the active workspace is always visible.
	config.enable_tab_bar = true
	config.use_fancy_tab_bar = false
	config.tab_bar_at_bottom = false
	config.hide_tab_bar_if_only_one_tab = false
	config.show_new_tab_button_in_tab_bar = false
	config.show_close_tab_button_in_tabs = false
	config.show_tab_index_in_tab_bar = false
	config.tab_max_width = 32
```

Leave window, Acrylic, padding, size, scrollback, and shell settings unchanged.

- [ ] **Step 2: Extend the TokyoNight palette for the launcher**

At the start of `config.colors` in `wezterm/colors.lua`, keep the cursor colors and add:

```lua
		command_palette_bg_color = "#1f2335",
		command_palette_fg_color = "#c0caf5",
```

Keep the existing tab-bar colors unchanged; the event formatter in the next step uses the same palette constants.

- [ ] **Step 3: Implement the top-bar event module**

Create `wezterm/tab_bar.lua`:

```lua
local wezterm = require("wezterm")

local M = {}

local colors = {
	bar = "#1f2335",
	workspace_bg = "#7aa2f7",
	workspace_fg = "#1f2335",
	active_bg = "#394260",
	active_fg = "#c0caf5",
	inactive_bg = "#1f2335",
	inactive_fg = "#565f89",
	hover_bg = "#292e42",
	hover_fg = "#a9b1d6",
}

local separator = wezterm.nerdfonts.pl_right_hard_divider
local workspace_icon = wezterm.nerdfonts.md_folder_multiple

local function title_for(tab)
	if tab.tab_title and #tab.tab_title > 0 then
		return tab.tab_title
	end
	return tab.active_pane.title
end

local function format_workspace(window)
	local name = window:active_workspace()
	return wezterm.format({
		{ Background = { Color = colors.workspace_bg } },
		{ Foreground = { Color = colors.workspace_fg } },
		{ Attribute = { Intensity = "Bold" } },
		{ Text = " " .. workspace_icon .. " " .. name .. " " },
		{ Background = { Color = colors.bar } },
		{ Foreground = { Color = colors.workspace_bg } },
		{ Text = separator },
	})
end

local function format_tab(tab, hover, max_width)
	local background = colors.inactive_bg
	local foreground = colors.inactive_fg
	if tab.is_active then
		background = colors.active_bg
		foreground = colors.active_fg
	elseif hover then
		background = colors.hover_bg
		foreground = colors.hover_fg
	end

	local prefix = string.format(" %d ", tab.tab_index + 1)
	local title = wezterm.truncate_right(title_for(tab), math.max(1, max_width - #prefix - 2))

	return {
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Attribute = { Intensity = tab.is_active and "Bold" or "Normal" } },
		{ Text = prefix .. title .. " " },
		{ Background = { Color = colors.bar } },
		{ Foreground = { Color = background } },
		{ Text = separator },
	}
end

function M.setup()
	wezterm.on("update-status", function(window)
		window:set_left_status(format_workspace(window))
	end)

	wezterm.on("format-tab-title", function(tab, _, _, _, hover, max_width)
		return format_tab(tab, hover, max_width)
	end)
end

return M
```

- [ ] **Step 4: Load and register the top-bar module**

In `wezterm/.wezterm.lua`, add beside the other module loads:

```lua
local tab_bar = load_module("tab_bar")
```

Under event registration, keep workspace setup and add:

```lua
workspaces.setup()
tab_bar.setup()
```

- [ ] **Step 5: Verify syntax, supported fields, and Nerd Font glyphs**

Run:

```bash
"/c/Program Files/WezTerm/wezterm.exe" ls-fonts
"/c/Program Files/WezTerm/wezterm.exe" ls-fonts --text '󰉋 home  1 pwsh'
```

Expected: both commands exit 0; the glyph report resolves the folder and separator glyphs to `CaskaydiaCove Nerd Font`, with no invalid `TabBarStyle` field error.

- [ ] **Step 6: Run a real GUI smoke test and inspect the top bar**

Run:

```bash
"/c/Program Files/WezTerm/wezterm.exe" start --always-new-process
```

Verify manually in the spawned window:

- top bar is visible with one tab;
- the left segment reads `home` with a folder icon;
- tab 1 is styled as active;
- `Leader+t` adds a styled inactive/active tab transition;
- `Leader+e` manual rename appears in the tab;
- hovering an inactive tab changes its colors;
- `Leader+w` still closes the current tab.

Close only the smoke-test window after verification.

- [ ] **Step 7: Commit the styled bar slice**

```bash
git add wezterm/.wezterm.lua wezterm/appearance.lua wezterm/colors.lua wezterm/tab_bar.lua
git commit -m "feat(wezterm): style workspace and tab bar"
```

---

### Task 4: Per-Machine Setup Documentation and End-to-End Verification

**Files:**
- Modify: `README.md:5-91`

**Interfaces:**
- Consumes all prior tasks.
- Produces documented setup and a verified user flow; no new Lua interface.

- [ ] **Step 1: Update the repository layout and add a workspace setup section**

Add these entries under `dotfiles/wezterm` in the repository layout:

```text
  wezterm/                   # Shared modular WezTerm configuration
    .wezterm.lua             # Root configuration loader
    workspaces.lua           # Workspace startup and picker behavior
    workspace_config.lua     # Local definition loading and validation
    workspaces.local.example.lua
    tab_bar.lua              # Workspace status and tab styling
```

Add this section after the bootstrap instructions:

```markdown
### Configure machine-local WezTerm workspaces

Workspaces are optional and machine-specific. WezTerm always starts with a
`home` workspace rooted at your user directory.

To add workspaces on a PC, create:

`~/.config/wezterm/workspaces.local.lua`

Use `wezterm/workspaces.local.example.lua` as the template:

```lua
return {
  { name = "dotfiles", cwd = "C:/Users/your-name/dotfiles" },
  { name = "notes", cwd = "D:/Notes" },
}
```

Use forward slashes in Windows paths. The local file is outside this repository,
so each PC can use different names and directories. After editing it, press
`Ctrl+Space`, then `r` to reload the configuration.

Workspace and tab shortcuts:

- `Ctrl+Space`, then `Space`: search and switch workspaces
- `Ctrl+Space`, then `t`: new tab in the active workspace
- `Ctrl+Space`, then `w`: close current tab
- `Ctrl+Space`, then `1` through `8`: jump to a tab
- `Ctrl+Space`, then `Tab` / `Shift+Tab`: next / previous tab

Configured workspaces are created only when selected. Selecting one whose
directory does not exist leaves the current workspace active and shows a
notification.
```

- [ ] **Step 2: Create this PC's local workspace file only if the user wants machine-specific entries now**

If no entries were supplied during execution, do not invent them and do not create the local file. Confirm fallback behavior instead:

```bash
test -e "$HOME/.config/wezterm/workspaces.local.lua" \
  && printf 'Using existing local workspace file\n' \
  || printf 'No local workspace file; home fallback is active\n'
```

Expected: either message is acceptable. Never overwrite an existing file.

- [ ] **Step 3: Run automated final checks**

```bash
"/c/Program Files/WezTerm/wezterm.exe" --config-file tests/wezterm/workspace_config_test.lua ls-fonts 2>&1 | tee /tmp/workspace-config-final.log
grep -F "workspace_config tests passed" /tmp/workspace-config-final.log
"/c/Program Files/WezTerm/wezterm.exe" ls-fonts
"/c/Program Files/WezTerm/wezterm.exe" show-keys --lua > /tmp/wezterm-keys-final.lua
grep -n -A2 -B2 'key = "Space"' /tmp/wezterm-keys-final.lua
grep -n -A2 -B2 'key = "w"' /tmp/wezterm-keys-final.lua
git diff --check
```

Expected: every command exits 0; loader success marker is present; both workspace and close-tab bindings appear; no whitespace errors are reported.

- [ ] **Step 4: Exercise the end-to-end GUI flow**

Launch a fresh window:

```bash
"/c/Program Files/WezTerm/wezterm.exe" start --always-new-process
```

Verify:

1. Startup creates only `home` at the user home directory.
2. The top bar always shows the workspace segment and all tabs.
3. `Leader+Space` opens the fuzzy workspace selector.
4. Selecting the current `home` workspace creates nothing.
5. If a valid local entry exists, first selection creates it in its configured directory.
6. Switching away and back reuses the same workspace and tabs.
7. If a nonexistent-directory entry exists, selection shows a toast and keeps the current workspace active.
8. Tab creation, close, index jumps, next/previous, rename, tab search, splits, pane close, zoom, and reload still work.

Close only the verification window when finished.

- [ ] **Step 5: Review repository scope and commit documentation**

```bash
git status --short
git diff -- README.md
```

Confirm the unrelated `nvim` submodule remains untouched by this work, then commit:

```bash
git add README.md
git commit -m "docs: explain machine-local wezterm workspaces"
```

- [ ] **Step 6: Report final evidence**

Record in the completion response:

- exact automated commands run and their exit status;
- whether the local file existed or the `home` fallback was tested;
- GUI behaviors personally verified;
- any manual per-PC setup still required;
- final `git status --short`, explicitly distinguishing the pre-existing `nvim` change.
