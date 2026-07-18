local M = {}

function M.apply_to_config(config)
	-- Top tab bar: always visible so the active workspace is always visible.
	config.enable_tab_bar = true
	config.use_fancy_tab_bar = false
	config.tab_bar_at_bottom = false
	config.hide_tab_bar_if_only_one_tab = false
	config.show_new_tab_button_in_tab_bar = false
	config.show_tab_index_in_tab_bar = false
	config.tab_max_width = 32

	-- Window
	config.window_decorations = "RESIZE"
	config.window_background_opacity = 0.5
	config.win32_system_backdrop = "Acrylic"
	config.window_padding = { left = 8, right = 8, top = 8, bottom = 0 }

	-- Initial size
	config.initial_cols = 120
	config.initial_rows = 30

	-- Scrollback
	config.scrollback_lines = 10000

	-- Shell
	config.default_prog = { "pwsh" }
end

return M