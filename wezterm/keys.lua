local wezterm = require("wezterm")

local M = {}

function M.apply_to_config(config, workspaces)
	-- Leader key: Ctrl+Space, 2 second timeout
	config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 2000 }

	-- Alt+click drag to move window (no title bar needed)
	config.mouse_bindings = {
		{
			event = { Drag = { streak = 1, button = "Left" } },
			mods = "ALT",
			action = wezterm.action.StartWindowDrag,
		},
	}

	-- Leader-driven key bindings
	config.keys = {
		-- Workspaces
		{ key = "Space", mods = "LEADER", action = workspaces.selector_action() },
		{ key = "c", mods = "LEADER", action = workspaces.create_action() },
		{ key = "m", mods = "LEADER", action = workspaces.profile_selector_action() },
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

		-- Splits (vim/tmux conventions: | = vertical, - = horizontal)
		{ key = "|", mods = "LEADER|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "-", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },

		-- Rename current tab
		{
			key = "e",
			mods = "LEADER",
			action = wezterm.action.PromptInputLine({
				description = "Enter new tab name",
				action = wezterm.action_callback(function(window, pane, line)
					if line then
						window:active_tab():set_title(line)
					end
				end),
			}),
		},

		-- Switch to tab by name (substring, case-insensitive)
		{
			key = "s",
			mods = "LEADER",
			action = wezterm.action.PromptInputLine({
				description = "Switch to tab matching name",
				action = wezterm.action_callback(function(window, pane, line)
					if not line then
						return
					end
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
			}),
		},
	}
end

return M