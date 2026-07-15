# WezTerm Workspace Profiles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans (recommended) to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prompt for a workspace profile at WezTerm startup and load persistent, machine-local workspace definitions for the selected profile.

**Architecture:** The local Lua file returns a table keyed by profile name, with each value an ordered list of `{ name, cwd }` entries. The workspace module validates profile data, prompts once after startup, stores the selected profile in memory, and uses only that profile for the workspace selector. No runtime file writes are performed.

**Tech Stack:** WezTerm Lua configuration API, `PromptInputSelector`, `SwitchToWorkspace`, machine-local Lua definitions.

## Global Constraints

- The local file remains `C:/Users/yepej/.config/wezterm/workspaces.local.lua` and is never committed.
- The local file must support independent `home` and `work` profiles with different paths.
- WezTerm must prompt for a profile at startup rather than infer one from the computer name.
- The existing `home` workspace remains a safe fallback if the local file is missing, invalid, or the prompt is cancelled.
- `Leader+Space` remains the workspace selector.
- `Leader+c` creates/selects a workspace using the current pane directory and prompts for its workspace name.
- `Leader+w` remains close-current-tab.
- No direct file writes from WezTerm Lua are required or added.
- The unrelated dirty `nvim` submodule must remain untouched.

---

### Task 1: Profile-aware local definition loader

**Files:**
- Modify: `wezterm/workspace_config.lua`
- Modify: `wezterm/workspaces.local.example.lua`
- Modify: `tests/wezterm/workspace_config_test.lua`
- Create: `tests/wezterm/fixtures/profiles.lua`

**Interfaces:**
- `workspace_config.load_profiles(path) -> ordered table of { name = string, definitions = ordered array }`.
- `workspace_config.profile_definitions(profiles, name) -> ordered array of validated definitions`, always beginning with `home`.
- Legacy flat lists remain accepted as the `default` profile for compatibility.

- [ ] Add fixtures returning `home` and `work` profile tables, including malformed entries.
- [ ] Add assertions for profile order, profile validation, missing profile fallback, and reserved `home` handling.
- [ ] Implement profile loading without GUI side effects.
- [ ] Preserve the existing `load(path)` behavior by treating a flat list as the `default` profile.
- [ ] Run `wezterm --config-file tests/wezterm/workspace_config_test.lua ls-fonts` and require the existing success marker.

---

### Task 2: Startup profile prompt and profile-scoped workspace actions

**Files:**
- Modify: `wezterm/workspaces.lua`
- Modify: `wezterm/keys.lua`

**Interfaces:**
- `workspaces.setup()` spawns the safe `home` workspace and prompts once for a profile after a GUI window is available.
- `workspaces.selector_action()` reads the selected profile.
- `workspaces.create_action()` remains the name-prompting current-directory creator.

- [ ] Add an in-memory selected-profile state initialized to `default` or the first valid profile.
- [ ] Register a startup/GUI-attached callback that presents `PromptInputSelector` with profile names and selects the requested profile.
- [ ] Ensure cancelling the prompt keeps the safe `home` profile active.
- [ ] Make the workspace selector consume only the selected profile’s definitions.
- [ ] Keep the existing `Leader+Space`, `Leader+c`, and `Leader+w` key behavior.
- [ ] Parse the full config and inspect the resolved key output using the nightly WezTerm command syntax.

---

### Task 3: Documentation and focused verification

**Files:**
- Modify: `README.md`

**Interfaces:**
- Document the profile-file shape, startup prompt, fallback behavior, reload behavior, and shortcuts.

- [ ] Replace the flat-list example with `home` and `work` profile examples.
- [ ] Explain that profiles persist on disk but selection is made at each startup.
- [ ] Run a focused ad-hoc verifier from an OS-generated `hermes-verify-*` temporary path.
- [ ] Verify config parsing, loader success, profile fixture success, key preservation, and `git diff --check`.
- [ ] Remove the temporary verifier when possible and report if cleanup is blocked.
