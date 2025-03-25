local wezterm = require("wezterm") --[[@as Wezterm]] --- this type cast invokes the LSP module for Wezterm

---------
-- SYSTEM
---------

-- Update the plugins
wezterm.plugin.update_all()

-- Install plugins
local smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")

local resurrect = wezterm.plugin.require("https://github.com/chrisgve/resurrect.wezterm")

local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")

local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

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

Config.scrollback_lines = 5000

--- workspace_switcher config
workspace_switcher.zoxide_path = "/usr/local/bin/zoxide"

--- resurrect config
resurrect.state_manager.set_max_nlines(Config.scrollback_lines)

-- resurrect.state_manager.change_state_save_dir(constants.STATE .. "/wezterm/resurrect/")
resurrect.state_manager.periodic_save({
	interval_seconds = 120, -- s
	save_workspaces = true,
	save_windows = false,
	save_tabs = false,
})

-- if is_mac then
-- 	-- Resurrect set encryption
-- 	resurrect.state_manager.set_encryption({
-- 		enable = true,
-- 		method = "/usr/local/bin/rage",
-- 		private_key = constants.HOME .. "/.secret/rage-wezterm.txt",
-- 		public_key = "age1k429zd7js54x484ya5apata96sa5z7uaf4h6s8l4t4xnc2znm4us9kum3e",
-- 	})
-- end

-------------------
-- EVENTS
-------------------

local listeners = require("utils.event_listeners")
listeners.setup(resurrect, workspace_switcher, tabline)

local helpers = require("utils.helpers")

----------------
-- FONTS
----------------

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

Config.use_cap_height_to_scale_fallback_fonts = true
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
tabline_setup.setup(Config, tabline, scheme)

----------------
-- PANE SETTINGS
----------------

Config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.7 }

---------------
-- TITLE BAR
---------------

-- TODO: work on the title bar which is very bare

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

-- and finally, return the configuration to weztermp
return Config
