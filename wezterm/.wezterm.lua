local wezterm = require("wezterm")

-- All modules live alongside this config file in the dotfiles repo.
-- WezTerm's Lua require() doesn't search the config directory, so
-- we load them explicitly via dofile with the known repo path.
local mod_dir = wezterm.home_dir .. "/dotfiles/wezterm/"
local function load_module(name)
	return dofile(mod_dir .. name .. ".lua")
end

local config = wezterm.config_builder()

-- Modules
local fonts = load_module("fonts")
local colors = load_module("colors")
local appearance = load_module("appearance")
local keys = load_module("keys")
local workspaces = load_module("workspaces")
local tab_bar = load_module("tab_bar")

-- Apply
fonts.apply_to_config(config)
colors.apply_to_config(config)
appearance.apply_to_config(config)
keys.apply_to_config(config, workspaces)

-- Register event handlers
workspaces.setup()
tab_bar.setup()

return config