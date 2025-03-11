local wezterm = require("wezterm") --[[@as Wezterm]] --- this type cast invokes the LSP module for Wezterm

---------
-- SYSTEM
---------
local is_mac = (wezterm.target_triple == "x86_64-apple-darwin" or wezterm.target_triple == "aarch64-apple-darwin")

-- Update the plugins
wezterm.plugin.update_all()

-- Install plugins
local smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")

local resurrect
if is_mac then
	resurrect = wezterm.plugin.require("file:///Users/chris/dev/projects/plugins/resurrect.wezterm")
else
	resurrect = wezterm.plugin.require("https://github.com/chrisgve/resurrect.wezterm")
end

local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")

local tabline
if is_mac then
	tabline = wezterm.plugin.require("file:///Users/chris/dev/projects/plugins/tabline.wez")
else
	tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
end

-- This will hold the configuration.
local config = wezterm.config_builder()

local color = require("utils.color")
local glyph = require("utils.glyph")
local constants = require("utils.constants")

-- Selecting the color scheme
config.color_scheme = "Catppuccin Mocha"
local scheme = wezterm.color.get_builtin_schemes()[config.color_scheme]

config.default_workspace = constants.DEFAULT_WORKSPACE

-- Remove confirmation when closing wezterm
config.window_close_confirmation = "NeverPrompt"

-- Change the environment path
config.set_environment_variables = {
	PATH = os.getenv("PATH") .. ":/usr/local/bin",
}

config.enable_kitty_graphics = true

config.scrollback_lines = 5000

--- workspace_switcher config
workspace_switcher.zoxide_path = "/usr/local/bin/zoxide"

--- resurrect config
resurrect.state_manager.set_max_nlines(config.scrollback_lines)
resurrect.state_manager.change_state_save_dir(constants.STATE .. "/wezterm/resurrect/")
resurrect.state_manager.periodic_save({
	interval_seconds = 120, -- s
	save_workspaces = true,
	save_windows = true,
	save_tabs = true,
})

-- Resurrect set encryption
resurrect.state_manager.set_encryption({
	enable = true,
	method = "/usr/local/bin/rage",
	private_key = constants.HOME .. "/.secret/rage-wezterm.txt",
	public_key = "age1k429zd7js54x484ya5apata96sa5z7uaf4h6s8l4t4xnc2znm4us9kum3e",
})

-------------------
-- EVENTS
-------------------

local listeners = require("utils.event_listeners")
listeners.setup(resurrect, workspace_switcher, tabline)

local helpers = require("utils.helpers")

----------------
-- FONTS
----------------

config.font = wezterm.font_with_fallback({
	{
		family = "Operator Mono SSm Lig",
		weight = "Light",
		harfbuzz_features = { "liga=1", "calt=1", "clig=1" },
		assume_emoji_presentation = false,
	},
	{ family = "Symbols Nerd Font Mono" },
	{ family = "Hack Nerd Font Mono" },
})

config.use_cap_height_to_scale_fallback_fonts = true

config.font_size = 16

----------------
-- LAUNCH MENU
----------------

config.launch_menu = require("launcher")

---------------
-- KEY BINDINGS
---------------

-- Disable default keybindings
config.disable_default_key_bindings = true

-- Define the LEADER key
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1500 }
-- to be seen if the leader key can be changed contextually

-- Key configuration
local standard_keys = require("keybindings.standard_keys")

local extended_keys = require("keybindings.extended_keys").setup(scheme, resurrect, workspace_switcher, tabline)

-- finalized all the keybindings
config.keys = helpers.deepMerge(standard_keys, extended_keys)

-- AUGMENT COMMAND PALETTE
-- TODO: Work on the augment command palette as the palette is currently unusable
-- wezterm.on("augment-command-palette", function(window, pane)
-- 	local workspace_state = resurrect.workspace_state
-- 	return {
-- 		{
-- 			brief = "Window | Workspace: Switch Workspace",
-- 			icon = "md_briefcase_arrow_up_down",
-- 			action = workspace_switcher.switch_workspace(),
-- 		},
-- 		{
-- 			brief = "Window | Workspace: Rename Workspace",
-- 			icon = "md_briefcase_edit",
--			action = wezterm.action.PromptInputLine({
-- 				description = "Enter new name for workspace",
-- 				action = wezterm.action_callback(function(window, pane, line)
-- 					if line then
-- 						wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
-- 						resurrect.save_state(workspace_state.get_workspace_state())
-- 					end
-- 				end),
-- 			}),
-- 		},
-- 	}
-- end)

----------------
-- TAB BAR
----------------

local tabline_setup = require("tab.tabline_setup")
tabline_setup.setup(config, tabline, scheme)

----------------
-- PANE SETTINGS
----------------

config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.7 }

---------------
-- TITLE BAR
---------------

-- TODO: work on the title bar which is very bare

-- Title bar
config.window_decorations = "RESIZE|TITLE"

---------------
-- SMART_SPLIT
---------------

smart_splits.apply_to_config(config, {
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

-- and finally, return the configuration to weztermp
return config
