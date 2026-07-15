local wezterm = require("wezterm")
local mux = wezterm.mux
local act = wezterm.action
local workspace_config = dofile(wezterm.home_dir .. "/dotfiles/wezterm/workspace_config.lua")

local M = {}
local local_path = wezterm.home_dir .. "/.config/wezterm/workspaces.local.lua"
local profiles = workspace_config.load_profiles(local_path)
local selected_profile = profiles[1].name

local function definitions()
	return workspace_config.profile_definitions(profiles, selected_profile)
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

local function profile_selector_action(window, pane)
	local choices = {}
	for _, profile in ipairs(profiles) do
		table.insert(choices, { id = profile.name, label = profile.name })
	end

	window:perform_action(
		act.InputSelector({
			title = "Choose workspace profile",
			description = "Enter = use profile  Esc = keep current profile",
			choices = choices,
			action = wezterm.action_callback(function(inner_window, inner_pane, id)
				if not id then
					return
				end
				selected_profile = id
				inner_window:toast_notification(
					"WezTerm workspace profile",
					"Using profile: " .. selected_profile,
					nil,
					2500
				)
			end),
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
				title = "Choose workspace (" .. selected_profile .. ")",
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

local function file_url_to_path(file_url)
	if file_url == nil then
		return nil
	end
	local ok, path = pcall(function()
		return file_url.file_path
	end)
	if ok and path then
		return path
	end
	if type(file_url) ~= "string" then
		return nil
	end
	local path = file_url:gsub("^file:///", "")
	return path:gsub("\\", "/")
end

function M.create_action()
	return act.PromptInputLine({
		description = wezterm.format({
			{ Attribute = { Intensity = "Bold" } },
			{ Foreground = { AnsiColor = "Fuchsia" } },
			{ Text = "Enter name for new workspace: " },
		}),
		action = wezterm.action_callback(function(window, pane, line)
			if not line or line == "" then
				return
			end

			local cwd = file_url_to_path(pane:get_current_working_dir())
			if not cwd or cwd == "" then
				window:toast_notification("WezTerm workspace", "Cannot determine current directory", nil, 3000)
				return
			end

			local exists = existing_workspaces()[line]
			window:perform_action(
				act.SwitchToWorkspace({
					name = line,
					spawn = exists and nil or {
						label = "Workspace: " .. line,
						cwd = cwd,
					},
				}),
				pane
			)
		end),
	})
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
		local tab, pane, mux_window = mux.spawn_window(spawn)
		profile_selector_action(mux_window:gui_window(), pane)
	end)
end

function M.profile_selector_action()
	return wezterm.action_callback(profile_selector_action)
end

return M
