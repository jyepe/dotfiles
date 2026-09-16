# SynthWave '84 Theme Specification for WezTerm and Herdr

**Date:** 2026-09-16  
**Status:** Approved by user  
**Topic:** Theme overhaul to SynthWave '84 aesthetic and streamlining WezTerm for Herdr integration.

---

## 1. Overview

Update the configuration files for both **WezTerm** and **Herdr** in the dotfiles repository to adopt a cohesive **SynthWave '84** retro-futuristic neon aesthetic (inspired by Robb Owen's SynthWave '84 VS Code theme). Streamline WezTerm by disabling its native tab and workspace bars so Herdr acts as the primary multiplexer and workspace interface.

---

## 2. Color Palette Reference

| Token | Hex Value | Role / Usage |
|---|---|---|
| **Background (Canvas)** | `#262335` | Terminal & editor background |
| **Deep Dark Background** | `#1a1528` | Sidebar, chrome background |
| **Elevated Dark (Active/Selection)** | `#34294f` | Active row background |
| **Selection Highlight** | `#463568` | Text and row selection background |
| **Neon Magenta / Pink (Accent)** | `#ff7edb` | Primary branding, cursor, active borders |
| **Electric Cyan** | `#36f9f6` | Secondary accents, indicators, active highlights |
| **Neon Mint / Green** | `#72f1b8` | Success, idle agent state |
| **Electric Gold / Yellow** | `#fede5d` | Warning, working state |
| **Neon Crimson / Red** | `#fe4450` | Error, blocked agent state, danger |
| **Text Foreground** | `#f0eff1` | Primary bright text |
| **Muted Text** | `#848bbd` | Secondary / dimmed text |

---

## 3. WezTerm Configuration Changes

### 3.1. `wezterm/colors.lua`
- Define full SynthWave '84 color palette:
  - `cursor_bg = "#ff7edb"`, `cursor_border = "#ff7edb"`, `cursor_fg = "#262335"`
  - `selection_bg = "#463568"`, `selection_fg = "#f0eff1"`
  - `background = "#262335"`, `foreground = "#f0eff1"`
  - 16 ANSI colors:
    - Normal: Black (`#1a1528`), Red (`#fe4450`), Green (`#72f1b8`), Yellow (`#fede5d`), Blue (`#36f9f6`), Magenta (`#ff7edb`), Cyan (`#36f9f6`), White (`#f0eff1`)
    - Bright: Black (`#614d85`), Red (`#fe4450`), Green (`#72f1b8`), Yellow (`#fede5d`), Blue (`#36f9f6`), Magenta (`#ff7edb`), Cyan (`#36f9f6`), White (`#ffffff`)
- Keep tab bar color definitions in `colors.lua` configured with the palette as fallback, even though tab bar is disabled.

### 3.2. `wezterm/appearance.lua`
- Disable native tab bar: `config.enable_tab_bar = false`
- Window decorations: `config.window_decorations = "RESIZE"`
- Window padding: `config.window_padding = { left = 6, right = 6, top = 6, bottom = 6 }`
- Window opacity & backdrop: `config.window_background_opacity = 0.85`, `config.win32_system_backdrop = "Mica"` (cleaner, less blurry modern material replacing frosted Acrylic)

### 3.3. `wezterm/keys.lua`
- Add mouse binding for dragging the titlebar-less window:
  ```lua
  config.mouse_bindings = {
    {
      event = { Drag = { streak = 1, button = "Left" } },
      mods = "ALT",
      action = wezterm.action.StartWindowDrag,
    },
  }
  ```

---

## 4. Herdr Configuration Changes

### 4.1. `herdr/config.toml`
- Configure `[theme]` and `[theme.custom]`:
  ```toml
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
  ```
- Ensure `ui` settings (e.g., borders and gaps) complement the frameless WezTerm setup.

---

## 5. Verification & Testing

1. Validate WezTerm syntax & font loading with `wezterm ls-fonts` (exit code 0).
2. Validate Herdr config with `herdr config` or `herdr status`.
3. Verify that `wezterm` loads clean without runtime Lua errors.
