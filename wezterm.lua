local wezterm = require("wezterm") --[[@as Wezterm]] --- this type cast invokes the LSP module for Wezterm

---------
-- SYSTEM
---------

-- Update the plugins
wezterm.plugin.update_all()

-- Install plugins
local smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
local modal = wezterm.plugin.require("https://github.com/MLFlexer/modal.wezterm")
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

---@type { setup: fun(opts: table)}
local dev = wezterm.plugin.require("https://github.com/chrisgve/dev.wezterm")

-- This will hold the configuration.
Config = wezterm.config_builder()

local constants = require("utils.constants")

-- Selecting the color scheme
Config.color_scheme = "Catppuccin Mocha"
local scheme = wezterm.color.get_builtin_schemes()[Config.color_scheme]

Config.default_workspace = constants.DEFAULT_WORKSPACE

-- Remove confirmation when closing wezterm
Config.window_close_confirmation = "NeverPrompt"

-- Change the environment path
Config.set_environment_variables = {
	PATH = os.getenv("PATH") .. ":/usr/local/bin",
}

Config.enable_kitty_graphics = true

Config.scrollback_lines = constants.SCROLLBACK_LINES

-- Configure resurrect (plugin will be required automatically in the event_listeners)
-- local resurrect = wezterm.plugin.require("https://github.com/chrisgve/resurrect.wezterm")
-- opts = {
-- 	fetch_branch = true,
-- 	keywords = { "https", "github", "chrisgve", "resurrect", "wezterm", "dev" },
-- }
-- local resurrect = dev.require("https://github.com/MLFlexer/resurrect.wezterm", opts)
resurrect.state_manager.set_max_nlines(constants.SCROLLBACK_LINES)
resurrect.state_manager.change_state_save_dir(constants.STATE .. "/wezterm/resurrect/")
resurrect.state_manager.periodic_save({
	interval_seconds = 120, -- s
	save_workspaces = true,
	save_windows = false,
	save_tabs = false,
})

-- Configure workspace_switcher (plugin will be required automatically in the event_listeners)
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
workspace_switcher.zoxide_path = "/usr/local/bin/zoxide"
workspace_switcher.workspace_formatter = function(label)
	return wezterm.format({
		{ Foreground = { AnsiColor = "Green" } },
		{ Text = "󱂬 : " .. label },
	})
end

-------------------
-- EVENTS
-------------------

-- Use our event listeners implementation
local listeners = require("utils.event_listeners")
listeners.setup()

local helpers = require("utils.helpers")

----------------
-- FONTS
----------------

if not constants.is_windows then
	Config.font = wezterm.font_with_fallback({
		{
			family = "Operator Mono SSm Lig",
			weight = "Light",
			harfbuzz_features = { "liga=1", "calt=1", "clig=1" },
			assume_emoji_presentation = false,
			style = "Normal",
			stretch = "Normal",
			freetype_load_target = "Light",
			freetype_render_target = "Light",
			freetype_load_flags = "DEFAULT",
		},
		{
			family = "Symbols Nerd Font Mono",
			weight = "Regular",
			harfbuzz_features = { "calt=0", "clig=0", "liga=0" },
			freetype_load_target = "Light",
			freetype_render_target = "Light",
			freetype_load_flags = "DEFAULT",
			stretch = "Normal",
			style = "Normal",
			assume_emoji_presentation = false,
		},
		{
			family = "Hack Nerd Font Mono",
			weight = "Regular",
			harfbuzz_features = { "calt=0", "clig=0", "liga=0" },
			freetype_load_target = "Light",
			freetype_render_target = "Light",
			freetype_load_flags = "DEFAULT",
			stretch = "Normal",
			style = "Normal",
			assume_emoji_presentation = false,
		},
	})
end

Config.use_cap_height_to_scale_fallback_fonts = false
Config.font_size = constants.get_font_size()

----------------
-- LAUNCH MENU
----------------

if constants.is_mac then
	Config.launch_menu = require("launcher")
end

---------------
-- KEY BINDINGS
---------------

-- Disable default keybindings
Config.disable_default_key_bindings = true

-- Define the LEADER key
Config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1500 }
-- to be seen if the leader key can be changed contextually

-- Key configuration
local standard_keys = require("keybindings.standard_keys")

local extended_keys = require("keybindings.extended_keys").setup(scheme, resurrect, workspace_switcher, tabline)

-- finalized all the keybindings
Config.keys = helpers.deepMerge(standard_keys, extended_keys)

----------------
-- TAB BAR
----------------

local tabline_setup = require("tab.tabline_setup")
tabline_setup.setup(Config, tabline, scheme)

----------------
-- PANE SETTINGS
----------------

Config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.7 }

---------------
-- TITLE BAR
---------------

-- Title bar
Config.window_decorations = "RESIZE|TITLE"

---------------
-- SMART_SPLIT
---------------

smart_splits.apply_to_config(Config, {
	direction_keys = {
		move = { "h", "j", "k", "l" },
		resize = { "LeftArrow", "DownArrow", "UpArrow", "RightArrow" },
	},
	-- modifier keys to combine with direction_keys
	modifiers = {
		move = "CTRL", -- modifier to use for pane movement, e.g. CTRL+h to move left
		resize = "CTRL", -- modifier to use for pane resize, e.g. META+h to resize to the left
	},
})

-- and finally, return the configuration to wezterm
return Config
