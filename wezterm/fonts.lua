local wezterm = require("wezterm")

local M = {}

function M.apply_to_config(config)
	config.font = wezterm.font("CaskaydiaCove Nerd Font")
	config.font_size = 15
	config.harfbuzz_features = { "calt=1", "liga=1" }
	config.line_height = 1.1
	config.bold_brightens_ansi_colors = true
end

return M