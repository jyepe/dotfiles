local wezterm = require("wezterm")

local M = {}

local function home_definition()
	return { name = "home", cwd = wezterm.home_dir }
end

function M.validate(raw)
	local definitions = { home_definition() }
	local seen = { home = true }

	if type(raw) ~= "table" then
		wezterm.log_warn("workspace definitions must return a table; using home only")
		return definitions
	end

	for index, entry in ipairs(raw) do
		if type(entry) ~= "table" then
			wezterm.log_warn(string.format("skipping workspace entry %d: expected a table", index))
		elseif type(entry.name) ~= "string" or entry.name == "" then
			wezterm.log_warn(string.format("skipping workspace entry %d: name must be a non-empty string", index))
		elseif type(entry.cwd) ~= "string" or entry.cwd == "" then
			wezterm.log_warn(string.format("skipping workspace entry %d (%s): cwd must be a non-empty string", index, entry.name))
		elseif seen[entry.name] then
			wezterm.log_warn(string.format("skipping workspace entry %d: duplicate or reserved name %q", index, entry.name))
		else
			seen[entry.name] = true
			table.insert(definitions, { name = entry.name, cwd = entry.cwd })
		end
	end

	return definitions
end

local function load_raw(path)
	local matches = wezterm.glob(path)
	if #matches == 0 then
		return nil
	end

	local ok, raw = pcall(dofile, path)
	if not ok then
		wezterm.log_error(string.format("failed to load workspace definitions from %s: %s", path, raw))
		return nil
	end
	return raw
end

function M.load(path)
	return M.validate(load_raw(path))
end

function M.load_profiles(path)
	local raw = load_raw(path)
	if raw == nil then
		return { { name = "default", definitions = { home_definition() } } }
	end

	-- Preserve compatibility with the original flat-list format.
	if #raw > 0 then
		return { { name = "default", definitions = M.validate(raw) } }
	end

	local names = {}
	for name, value in pairs(raw) do
		if type(name) == "string" and type(value) == "table" then
			table.insert(names, name)
		end
	end
	table.sort(names)

	local profiles = {}
	for _, name in ipairs(names) do
		table.insert(profiles, {
			name = name,
			definitions = M.validate(raw[name]),
		})
	end

	if #profiles == 0 then
		return { { name = "default", definitions = { home_definition() } } }
	end
	return profiles
end

function M.profile_definitions(profiles, name)
	for _, profile in ipairs(profiles or {}) do
		if profile.name == name then
			return profile.definitions
		end
	end
	return { home_definition() }
end

return M
