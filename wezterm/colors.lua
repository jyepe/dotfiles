local M = {}

function M.apply_to_config(config)
	-- SynthWave '84 Palette
	config.colors = {
		-- TokyoNight Storm Fallbacks
		foreground = "#c0caf5",
		background = "#24283b",

		cursor_bg = "#c0caf5",
		cursor_border = "#c0caf5",
		cursor_fg = "#24283b",

		selection_bg = "#364a82",
		selection_fg = "#c0caf5",

		scrollbar_thumb = "#292e42",
		split = "#1f2335",

		ansi = {
			"#1d202f", -- black
			"#f7768e", -- red
			"#9ece6a", -- green
			"#e0af68", -- yellow
			"#7aa2f7", -- blue
			"#bb9af7", -- magenta
			"#7dcfff", -- cyan
			"#a9b1d6", -- white
		},
		brights = {
			"#414868", -- bright black
			"#f7768e", -- bright red
			"#9ece6a", -- bright green
			"#e0af68", -- bright yellow
			"#7aa2f7", -- bright blue
			"#bb9af7", -- bright magenta
			"#7dcfff", -- bright cyan
			"#c0caf5", -- bright white
		},

		tab_bar = {
			background = "#1f2335",
			active_tab = {
				bg_color = "#394260",
				fg_color = "#c0caf5",
				intensity = "Bold",
				underline = "None",
				italic = false,
				strikethrough = false,
			},
			inactive_tab = {
				bg_color = "#292e42",
				fg_color = "#a9b1d6",
				intensity = "Normal",
				underline = "None",
				italic = false,
				strikethrough = false,
			},
			inactive_tab_hover = {
				bg_color = "#3b4261",
				fg_color = "#c0caf5",
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