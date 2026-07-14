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

function M.load(path)
	local matches = wezterm.glob(path)
	if #matches == 0 then
		return { home_definition() }
	end

	local ok, raw = pcall(dofile, path)
	if not ok then
		wezterm.log_error(string.format("failed to load workspace definitions from %s: %s", path, raw))
		return { home_definition() }
	end

	return M.validate(raw)
end

return M