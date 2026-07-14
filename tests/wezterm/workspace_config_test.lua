local wezterm = require("wezterm")
local repo = wezterm.home_dir .. "/dotfiles/"
local workspace_config = dofile(repo .. "wezterm/workspace_config.lua")
local fixtures = repo .. "tests/wezterm/fixtures/"

local function assert_equal(actual, expected, message)
	if actual ~= expected then
		error(string.format("%s: expected %q, got %q", message, expected, actual))
	end
end

local valid = workspace_config.load(fixtures .. "valid.lua")
assert_equal(#valid, 3, "valid list size")
assert_equal(valid[1].name, "home", "home is first")
assert_equal(valid[1].cwd, wezterm.home_dir, "home directory")
assert_equal(valid[2].name, "dotfiles", "first local name")
assert_equal(valid[2].cwd, "C:/projects/dotfiles", "first local cwd")
assert_equal(valid[3].name, "notes", "second local name")

local mixed = workspace_config.load(fixtures .. "mixed.lua")
assert_equal(#mixed, 3, "invalid entries are removed")
assert_equal(mixed[2].name, "dotfiles", "first duplicate wins")
assert_equal(mixed[2].cwd, "C:/projects/dotfiles", "duplicate does not replace cwd")
assert_equal(mixed[3].name, "notes", "valid entry after invalid entries survives")

local missing = workspace_config.load(fixtures .. "does-not-exist.lua")
assert_equal(#missing, 1, "missing file fallback size")
assert_equal(missing[1].name, "home", "missing file fallback name")

local broken = workspace_config.load(fixtures .. "runtime-error.lua")
assert_equal(#broken, 1, "runtime error fallback size")
assert_equal(broken[1].name, "home", "runtime error fallback name")

local wrong_type = workspace_config.validate("not a table")
assert_equal(#wrong_type, 1, "wrong root type fallback size")

wezterm.log_info("workspace_config tests passed")
return wezterm.config_builder()