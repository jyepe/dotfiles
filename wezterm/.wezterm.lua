local wezterm = require("wezterm")
local mux = wezterm.mux
local config = wezterm.config_builder()

-- Fonts
config.font = wezterm.font("CaskaydiaCove Nerd Font")
config.font_size = 15
config.harfbuzz_features = { "calt=1", "liga=1" }
config.line_height = 1.1
config.bold_brightens_ansi_colors = true

-- TokyoNight Storm colors
-- config.color_scheme = 'tokyonight_storm'
config.colors = {
	cursor_bg = "white",
	cursor_border = "white",
	tab_bar = {
		background = "#1f2335",
		active_tab = {
			bg_color = "#394260",
			fg_color = "#c0caf5",
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},
		inactive_tab = {
			bg_color = "#1f2335",
			fg_color = "#565f89",
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},
		inactive_tab_hover = {
			bg_color = "#292e42",
			fg_color = "#a9b1d6",
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},
		new_tab = {
			bg_color = "#1f2335",
			fg_color = "#565f89",
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},
		new_tab_hover = {
			bg_color = "#292e42",
			fg_color = "#a9b1d6",
			intensity = "Normal",
			underline = "None",
			italic = false,
			strikethrough = false,
		},
	},
}

-- Appearance
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 32

config.window_decorations = "RESIZE"
config.window_background_opacity = 0.5
config.win32_system_backdrop = "Acrylic"
config.window_padding = { left = 8, right = 8, top = 8, bottom = 0 }

-- Window
config.initial_cols = 120
config.initial_rows = 30

-- Cursor
-- config.default_cursor_style = 'SteadyBar'
-- config.cursor_thickness = 2

-- Scrollback
config.scrollback_lines = 10000

-- Shell
config.default_prog = { "pwsh" }

-- Alt+click drag to move window (no title bar needed)
config.mouse_bindings = {
	{
		event = { Drag = { streak = 1, button = "Left" } },
		mods = "ALT",
		action = wezterm.action.StartWindowDrag,
	},
}

-- Leader key: Ctrl+Space, 1 second timeout
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 2000 }

-- Leader-driven key bindings
config.keys = {
	-- Tabs
	{ key = "t", mods = "LEADER", action = wezterm.action.SpawnTab("DefaultDomain") },
	{ key = "w", mods = "LEADER", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
	{ key = "Tab", mods = "LEADER", action = wezterm.action.ActivateTabRelative(1) },
	{ key = "Tab", mods = "LEADER|SHIFT", action = wezterm.action.ActivateTabRelative(-1) },
	{ key = "n", mods = "LEADER", action = wezterm.action.ActivateTabRelative(1) },
	{ key = "p", mods = "LEADER", action = wezterm.action.ActivateTabRelative(-1) },

	-- Direct tab jumps
	{ key = "1", mods = "LEADER", action = wezterm.action.ActivateTab(0) },
	{ key = "2", mods = "LEADER", action = wezterm.action.ActivateTab(1) },
	{ key = "3", mods = "LEADER", action = wezterm.action.ActivateTab(2) },
	{ key = "4", mods = "LEADER", action = wezterm.action.ActivateTab(3) },
	{ key = "5", mods = "LEADER", action = wezterm.action.ActivateTab(4) },
	{ key = "6", mods = "LEADER", action = wezterm.action.ActivateTab(5) },
	{ key = "7", mods = "LEADER", action = wezterm.action.ActivateTab(6) },
	{ key = "8", mods = "LEADER", action = wezterm.action.ActivateTab(7) },

	-- Useful extras
	{ key = "q", mods = "LEADER", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
	{ key = "r", mods = "LEADER", action = wezterm.action.ReloadConfiguration },
	{ key = "z", mods = "LEADER", action = wezterm.action.TogglePaneZoomState },
	-- Rename current tab
	{ key = "e", mods = "LEADER", action = wezterm.action.PromptInputLine {
		description = "Enter new tab name",
		action = wezterm.action_callback(function(window, pane, line)
			if line then window:active_tab():set_title(line) end
		end),
	}},
	-- Switch to tab by name (substring, case-insensitive)
	{ key = "s", mods = "LEADER", action = wezterm.action.PromptInputLine {
		description = "Switch to tab matching name",
		action = wezterm.action_callback(function(window, pane, line)
			if not line then return end
			local tabs = window:mux_window():tabs()
			local needle = line:lower()
			for _, tab in ipairs(tabs) do
				local title = tab:get_title() or ""
				if title:lower():find(needle, 1, true) then
					tab:activate()
					return
				end
			end
		end),
	}},
}

-- Workspaces: auto-create "code" and "shell" on startup
wezterm.on("gui-startup", function(cmd)
	mux.spawn_window({
		workspace = "code",
		cwd = wezterm.home_dir,
	})

	mux.spawn_window({
		workspace = "shell",
		cwd = wezterm.home_dir,
	})
end)

return config
