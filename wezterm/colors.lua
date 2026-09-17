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