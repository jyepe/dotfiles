local wezterm = require("wezterm")

local M = {}

local colors = {
	bar = "#1f2335",
	workspace_bg = "#7aa2f7",
	workspace_fg = "#1f2335",
	active_bg = "#394260",
	active_fg = "#c0caf5",
	inactive_bg = "#292e42",
	inactive_fg = "#a9b1d6",
	hover_bg = "#3b4261",
	hover_fg = "#c0caf5",
}

-- Nerd Font rounded caps
local cap_left = wezterm.nerdfonts.ple_left_half_circle_thick
local cap_right = wezterm.nerdfonts.ple_right_half_circle_thick
local workspace_icon = wezterm.nerdfonts.md_folder_multiple

local function title_for(tab)
	if tab.tab_title and #tab.tab_title > 0 then
		return tab.tab_title
	end
	return tab.active_pane.title
end

-- Square workspace block at the far left of the tab bar
local function format_workspace(window)
	local name = window:active_workspace()
	return wezterm.format({
		{ Background = { Color = colors.workspace_bg } },
		{ Foreground = { Color = colors.workspace_fg } },
		{ Attribute = { Intensity = "Bold" } },
		{ Text = "  " .. workspace_icon .. "  " .. name .. "  " },
		{ Background = { Color = colors.bar } },
		{ Text = " " },
	})
end

-- Pill-shaped tab:  body  with the tab color showing through the caps
local function format_tab(tab, hover, max_width)
	local background = colors.inactive_bg
	local foreground = colors.inactive_fg
	if tab.is_active then
		background = colors.active_bg
		foreground = colors.active_fg
	elseif hover then
		background = colors.hover_bg
		foreground = colors.hover_fg
	end

	local prefix = string.format("%d ", tab.tab_index + 1)
	local title = wezterm.truncate_right(title_for(tab), math.max(1, max_width - #prefix - 4))

	return {
		-- left rounded cap
		{ Background = { Color = colors.bar } },
		{ Foreground = { Color = background } },
		{ Text = cap_left },
		-- pill body
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Attribute = { Intensity = tab.is_active and "Bold" or "Normal" } },
		{ Text = "  " .. prefix .. title .. "  " },
		-- right rounded cap
		{ Background = { Color = colors.bar } },
		{ Foreground = { Color = background } },
		{ Attribute = { Intensity = "Normal" } },
		{ Text = cap_right },
		-- gap between pills
		{ Background = { Color = colors.bar } },
		{ Foreground = { Color = colors.bar } },
		{ Text = " " },
	}
end

function M.setup()
	wezterm.on("update-status", function(window)
		window:set_left_status(format_workspace(window))
	end)

	wezterm.on("format-tab-title", function(tab, _, _, _, hover, max_width)
		return format_tab(tab, hover, max_width)
	end)
end

return M
