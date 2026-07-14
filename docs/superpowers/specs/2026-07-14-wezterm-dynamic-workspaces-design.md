# Dynamic WezTerm Workspaces Design

## Goal

Add a portable workspace workflow to the existing modular WezTerm configuration. Each PC can define different workspace names and starting directories without committing machine-specific paths. The active workspace name and all of its tabs remain visible in a styled top bar, and common navigation requires few keystrokes.

## Scope

This change covers:

- machine-local workspace definitions;
- safe `home` fallback behavior;
- lazy workspace creation and switching;
- a searchable workspace launcher;
- workspace-aware top-bar formatting;
- styled active and inactive tabs;
- keybindings that preserve the existing tab workflow and avoid GlazeWM's `Alt+number` bindings;
- validation and runtime error handling.

It does not add automatic project discovery, hostname-specific tracked configurations, in-terminal persistence of new workspace definitions, session restoration, or changes to GlazeWM.

## Architecture

The existing modular configuration remains in place:

- `wezterm/workspaces.lua` owns workspace definition loading, validation, startup, lazy creation, switching, and picker integration.
- `wezterm/keys.lua` owns workspace and tab keybindings.
- `wezterm/appearance.lua` owns top-bar placement and visibility.
- `wezterm/colors.lua` owns workspace and tab colors.
- A tab-formatting event handler owns the visible workspace segment and styled tab labels. It may live in a focused module if keeping it in `appearance.lua` would mix configuration values with event behavior.

Shared behavior stays tracked in the dotfiles repository. Machine-specific workspace definitions live outside the repository at `wezterm.home_dir .. "/.config/wezterm/workspaces.local.lua"`. The repository documents that path and includes a tracked `wezterm/workspaces.local.example.lua` file that users can copy there.

The local file returns an ordered list of entries:

```lua
return {
  { name = "dotfiles", cwd = "C:/Users/yepej/dotfiles" },
  { name = "notes", cwd = "D:/Notes" },
}
```

Ordering controls the order shown in the workspace launcher. Names are unique identifiers and visible labels. Paths are machine-local and may use forward slashes for reliable Lua string handling on Windows.

## Startup and Fallback Behavior

Every launch creates one workspace named `home`, rooted at `wezterm.home_dir`. Configured machine-local workspaces are not created during startup.

If the local workspace file is missing, empty, invalid, or contains no valid entries, WezTerm still starts normally with only `home` available. The fallback must not depend on hostname detection or shared machine-specific defaults.

The startup handler must preserve the current PowerShell default program. It must guard a nil `cmd` value and must not pass an empty `args` table to `mux.spawn_window`, because doing so suppresses `default_prog` on the installed WezTerm version.

## Workspace Loading and Validation

The loader validates each local entry before making it available:

- `name` must be a non-empty string.
- `cwd` must be a non-empty string.
- Duplicate names keep the first valid entry; later duplicates are skipped.
- Malformed entries are skipped without preventing valid entries from loading.
- The reserved name `home` cannot be overridden by the local file.

Missing or syntactically invalid local files fall back to `home`. Invalid configuration should be logged with enough context to identify the file or rejected entry, but it must not make WezTerm unusable.

Directory existence is checked when a configured workspace is selected. If the directory is unavailable, no workspace is created and WezTerm shows a brief toast naming the workspace and invalid path.

## Workspace Selection Flow

`Ctrl+Space` remains the leader key. `Leader+Space` opens WezTerm's searchable workspace launcher.

The launcher contains the always-available `home` entry plus all valid entries from the machine-local file. Selection behaves as follows:

1. If the selected workspace is already active, nothing is created.
2. If it exists but is not active, WezTerm switches to it.
3. If it does not exist, WezTerm creates its first window and tab in the configured directory, then activates it.
4. Selecting `home` switches back to the startup workspace rather than creating duplicate home workspaces.

Workspace definitions are re-read when the WezTerm configuration reloads. The user adds or changes entries by editing the local Lua file and pressing `Leader+r`.

## Keybindings

The design preserves the existing leader-driven tab workflow and avoids `Alt+number`, which belongs to GlazeWM:

| Binding | Action |
|---|---|
| `Ctrl+Space`, then `Space` | Open searchable workspace launcher |
| `Leader+t` | Create a tab in the active workspace |
| `Leader+w` | Close the current tab with confirmation |
| `Leader+1` through `Leader+8` | Activate a tab by index in the active workspace |
| `Leader+Tab` / `Leader+Shift+Tab` | Next / previous tab |
| `Leader+n` / `Leader+p` | Next / previous tab aliases |
| `Leader+e` | Rename the current tab |
| `Leader+s` | Search tabs by name in the active workspace |
| `Leader+|` / `Leader+-` | Split the current pane |
| `Leader+q` | Close the current pane |
| `Leader+z` | Toggle pane zoom |
| `Leader+r` | Reload configuration and local workspace definitions |

No existing binding needs to be displaced. `Leader+w` continues to close tabs.

## Top Bar and Tab Styling

The existing tab bar moves from the bottom to the top and remains visible even when a workspace has only one tab. The new-tab button and per-tab close buttons remain hidden.

The bar starts with a distinct workspace segment, followed by all tabs in the active workspace:

```text
 󰉋 home    1 pwsh    2 editor    3 server 
```

The presentation follows the existing clean TokyoNight aesthetic:

- The workspace segment uses a stronger blue accent background and bright foreground.
- The active tab uses a slate-blue background and bright TokyoNight text.
- Inactive tabs blend into the dark bar with muted blue-gray text.
- Hovered inactive tabs gain a subtle background and brighter text.
- Labels use compact horizontal padding, tab index, and title.
- Long titles are truncated to the configured maximum width.
- Manual tab titles remain authoritative when present.
- No close glyphs or new-tab button add visual noise.

Nerd Font powerline separators will be emitted as formatted text because the configured CaskaydiaCove Nerd Font supports them and this does not depend on the unsupported `tab_bar_style` edge fields. If a glyph fails to render on a PC, replacing the separator constants with plain characters preserves the layout. The design favors this stable formatted segment over unsupported rounded-tab fields.

The workspace segment must be generated from the active workspace rather than embedded into each tab title. This keeps the workspace identity singular and prevents repetitive labels.

## Data Flow

1. WezTerm loads the shared modular configuration.
2. The workspace module attempts to load and validate the machine-local definitions.
3. Startup creates only `home` at `wezterm.home_dir`.
4. The formatting handler reads the active workspace name and current tab metadata to render the top bar.
5. `Leader+Space` builds the launcher from `home` plus validated local definitions.
6. Selection resolves an existing workspace or lazily creates it with its configured `cwd`.
7. A configuration reload re-runs module loading so local changes become available.

## Error Handling

- Missing local file: silently expose only `home`.
- Invalid local Lua syntax or runtime error: log the failure and expose only `home`.
- Malformed entry: skip it and log its list position.
- Duplicate name: keep the first valid entry and warn about the duplicate.
- Reserved `home` name: skip it and warn that the name is reserved.
- Missing directory at selection time: remain in the current workspace and show a toast with the workspace name and path.
- Current workspace selected: perform no action.
- Unsupported `tab_bar_style` edge fields: do not use them; render separators through the supported tab-formatting event instead.

## Testing and Verification

Verification must cover configuration parsing and event-driven runtime behavior:

1. Run `wezterm ls-fonts` to parse the full modular configuration.
2. Start WezTerm without a local workspace file and confirm `home` opens at `wezterm.home_dir` using PowerShell.
3. Load a temporary local file with multiple valid workspaces and confirm they appear in launcher order.
4. Confirm no configured workspace is created before selection.
5. Select an unopened workspace and confirm its first tab starts in the configured directory.
6. Switch away and back, confirming the existing workspace is reused.
7. Test malformed, duplicate, reserved-name, and nonexistent-directory entries.
8. Confirm `Leader+Space` opens the launcher and `Leader+w` still closes a tab.
9. Confirm the top bar is visible with one tab and shows the active workspace at the left.
10. Confirm active, inactive, hover, truncation, and manually renamed tab states render correctly.
11. Exercise tab creation, direct tab jumps, next/previous navigation, tab search, splits, pane close, zoom, and reload.
12. Perform a real startup smoke test because `gui-startup` and formatting event failures are not fully exercised by `wezterm ls-fonts`.

## Documentation

The repository will include an example local workspace file and concise setup instructions. The example is tracked; the actual machine-local file is outside the repository and therefore cannot leak PC-specific paths through Git.

Each PC can independently copy the example, define its own ordered workspace list, and reload WezTerm. With no setup, the configuration remains functional through the `home` fallback.
