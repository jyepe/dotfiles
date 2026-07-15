local wezterm = require("wezterm")
local mux = wezterm.mux
local act = wezterm.action
local workspace_config = dofile(wezterm.home_dir .. "/dotfiles/wezterm/workspace_config.lua")

local M = {}
local local_path = wezterm.home_dir .. "/.config/wezterm/workspaces.local.lua"

local function definitions()
	return workspace_config.load(local_path)
end

local function directory_exists(path)
	return #wezterm.glob(path) > 0
end

local function existing_workspaces()
	local result = {}
	for _, name in ipairs(mux.get_workspace_names()) do
		result[name] = true
	end
	return result
end

local function switch_to(window, pane, definition)
	if window:active_workspace() == definition.name then
		return
	end

	local exists = existing_workspaces()[definition.name]
	if not exists and not directory_exists(definition.cwd) then
		window:toast_notification(
			"WezTerm workspace",
			string.format("Cannot open %s: directory does not exist\n%s", definition.name, definition.cwd),
			nil,
			4000
		)
		return
	end

	window:perform_action(
		act.SwitchToWorkspace({
			name = definition.name,
			spawn = exists and nil or {
				label = "Workspace: " .. definition.name,
				cwd = definition.cwd,
			},
		}),
		pane
	)
end

function M.selector_action()
	return wezterm.action_callback(function(window, pane)
		local loaded = definitions()
		local by_name = {}
		local choices = {}

		for _, definition in ipairs(loaded) do
			by_name[definition.name] = definition
			table.insert(choices, {
				id = definition.name,
				label = string.format("%-16s  %s", definition.name, definition.cwd),
			})
		end

		window:perform_action(
			act.InputSelector({
				title = "Choose workspace",
				description = "Enter = switch  Esc = cancel",
				fuzzy = true,
				fuzzy_description = "Workspace: ",
				choices = choices,
				action = wezterm.action_callback(function(inner_window, inner_pane, id)
					if id and by_name[id] then
						switch_to(inner_window, inner_pane, by_name[id])
					end
				end),
			}),
			pane
		)
	end)
end

function M.setup()
	wezterm.on("gui-startup", function(cmd)
		local spawn = {
			workspace = "home",
			cwd = wezterm.home_dir,
		}
		if cmd and cmd.args and #cmd.args > 0 then
			spawn.args = cmd.args
		end
		mux.spawn_window(spawn)
	end)
end

return M