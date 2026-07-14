local wezterm = require("wezterm")
local mux = wezterm.mux

local M = {}

function M.setup()
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
end

return M