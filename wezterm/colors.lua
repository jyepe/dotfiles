local M = {}

function M.apply_to_config(config)
	-- TokyoNight Storm
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
end

return M