---------
-- SYSTEM
---------
--
-- Pull in the wezterm API
local wezterm = require("wezterm") --[[@as Wezterm]] --- this type cast invokes the LSP module for Wezterm

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

-- Remove confirmation when closing wezterm
config.window_close_confirmation = "NeverPrompt"

-- Change the environment path
config.set_environment_variables = {
	PATH = os.getenv("PATH") .. ":/usr/local/bin",
}

-- Default SHELL
-- config.default_prog = { "/usr/local/bin/nu" }

-- Enable kitty's image protocol
config.enable_kitty_graphics = true

config.scrollback_lines = 5000

------------
-- CONSTANTS
------------

local nerdfonts = wezterm.nerdfonts

local HOME = os.getenv("HOME")
local STATE = os.getenv("XDG_STATE_HOME") or HOME .. "/.local/state"

local TAB_TEXT_SIZE = 20
local TAB_MAX_SIZE = 28
local TAB_UPDATE_INTERVAL = 250 -- ms

local color = require("utils.color")
local glyph = require("utils.glyph")

-- Selecting the color scheme
config.color_scheme = "Catppuccin Mocha"
local scheme = wezterm.color.get_builtin_schemes()[config.color_scheme]

config.default_workspace = "~"

-------------------
-- HELPER FUNCTIONS
-------------------

---@param t1 table
---@param t2 table
---@return table
local function deepMerge(t1, t2)
	-- If both tables are arrays, concatenate them
	if #t1 > 0 and #t2 > 0 then
		local merged = {}
		for _, v in ipairs(t1) do
			table.insert(merged, v)
		end
		for _, v in ipairs(t2) do
			table.insert(merged, v)
		end
		return merged
	end

	-- Otherwise, merge as key-value pairs
	local merged = {}
	for k, v in pairs(t1) do
		if type(v) == "table" and type(t2[k]) == "table" then
			merged[k] = deepMerge(v, t2[k])
		else
			merged[k] = v
		end
	end

	for k, v in pairs(t2) do
		if merged[k] == nil then
			merged[k] = v
		end
	end

	return merged
end

local function basename(s)
	return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

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

local launch_menu = {
	{
		label = nerdfonts.custom_neovim .. "  config zsh",
		args = { os.getenv("SHELL"), "-c", 'exec $EDITOR "' .. HOME .. '/.config/zsh/zshrc"' },
		cwd = HOME .. "/.config/zsh",
	},
	{
		label = nerdfonts.custom_neovim .. "  config neovim",
		args = { os.getenv("SHELL"), "-c", "exec $EDITOR " .. HOME .. "/.config/nvim/lua" },
		cwd = HOME .. "/.config/nvim/lua",
	},
	{
		label = nerdfonts.custom_neovim .. "  config wezterm",
		args = { os.getenv("SHELL"), "-c", 'exec $EDITOR "' .. wezterm.config_dir .. '/wezterm.lua"' },
		cwd = HOME .. "/.config/wezterm",
	},
	{
		label = nerdfonts.cod_terminal_tmux .. "  tmux main",
		args = { "tmux", "new-session", "-ADs main" },
		cwd = "~",
	},
	{
		label = nerdfonts.cod_terminal_tmux .. "  tmux config",
		args = { "tmux", "new-session", "-ADs config" },
		cwd = "~/.config",
	},
	{
		label = "  taskwarrior",
		args = { os.getenv("SHELL"), "-c", "taskwarrior-tui" },
	},
	{
		label = nerdfonts.md_chart_areaspline .. "  btop",
		args = { os.getenv("SHELL"), "-c", "btop" },
	},
}

config.launch_menu = launch_menu

----------------
-- NOTIFICATIONS
----------------

-- Confirm configuration reloads
wezterm.on("window-config-reloaded", function(window, pane)
	window:toast_notification("wezterm", "configuration reloaded!", nil, 4000)
end)

-- Sending a notification when specified events occur but suppress on `periodic_save()`:
local resurrect_event_listeners = {
	"resurrect.error",
	"resurrect.file_io.decrypt.finished",
	"resurrect.fuzzy_loader.fuzzy_load.start",
	"resurrect.state_manager.delete_state.finished",
	"resurrect.state_manager.load_state.start",
	"resurrect.state_manager.save_state.finished",
	"resurrect.tab_state.restore_tab.start",
	"resurrect.window_state.restore_window.start",
	"resurrect.workspace_state.restore_workspace.start",
}

local is_periodic_save = false
wezterm.on("resurrect.periodic_save", function()
	is_periodic_save = true
	-- resurrect.write_current_state(wezterm.mux.get_active_workspace(), "workspace")
end)

for _, event in ipairs(resurrect_event_listeners) do
	wezterm.on(event, function(...)
		if event == "resurrect.state_manager.save_state.finished" and is_periodic_save then
			is_periodic_save = false
			return
		end
		local args = { ... }
		local msg = event
		for _, v in ipairs(args) do
			msg = msg .. " " .. tostring(v)
		end
		wezterm.gui.gui_windows()[1]:toast_notification("Wezterm - resurrect", msg, nil, 4000)
		if event == "resurrect.error" then
			wezterm.log_error("ERROR!", msg)
		end
	end)
end

---------------
-- KEY BINDINGS
---------------

-- Disable default keybindings
config.disable_default_key_bindings = true

-- Define the LEADER key
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1500 }
-- to be seen if the leader key can be changed contextually

-- Key configuration
local standard_keys = {
	{ mods = "CMD", key = "q", action = wezterm.action.QuitApplication },
	{ mods = "CMD", key = "w", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
	{ mods = "CMD", key = "n", action = wezterm.action.SpawnWindow },
	{ mods = "CMD", key = "t", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
	{ mods = "CMD", key = "c", action = wezterm.action.CopyTo("Clipboard") },
	{ mods = "CMD", key = "v", action = wezterm.action.PasteFrom("Clipboard") },
	{ mods = "CMD", key = "1", action = wezterm.action.ActivateTab(0) },
	{ mods = "CMD", key = "2", action = wezterm.action.ActivateTab(1) },
	{ mods = "CMD", key = "3", action = wezterm.action.ActivateTab(2) },
	{ mods = "CMD", key = "4", action = wezterm.action.ActivateTab(3) },
	{ mods = "CMD", key = "5", action = wezterm.action.ActivateTab(4) },
	{ mods = "CMD", key = "6", action = wezterm.action.ActivateTab(5) },
	{ mods = "CMD", key = "7", action = wezterm.action.ActivateTab(6) },
	{ mods = "CMD", key = "8", action = wezterm.action.ActivateTab(7) },
	{ mods = "LEADER", key = "-", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ mods = "LEADER|SHIFT", key = "_", action = wezterm.action.SplitPane({ direction = "Down", top_level = true }) },
	{ mods = "LEADER", key = "\\", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ mods = "LEADER|SHIFT", key = "|", action = wezterm.action.SplitPane({ direction = "Right", top_level = true }) },
	{ mods = "LEADER", key = "z", action = wezterm.action.TogglePaneZoomState },
	{ mods = "CMD", key = "z", action = wezterm.action.TogglePaneZoomState },
	{ mods = "LEADER", key = "Space", action = wezterm.action.RotatePanes("Clockwise") },
	{ mods = "LEADER", key = "0", action = wezterm.action.PaneSelect({ mode = "SwapWithActive" }) },
	{ mods = "LEADER", key = "1", action = wezterm.action.ActivateTab(0) },
	{ mods = "LEADER", key = "2", action = wezterm.action.ActivateTab(1) },
	{ mods = "LEADER", key = "3", action = wezterm.action.ActivateTab(2) },
	{ mods = "LEADER", key = "4", action = wezterm.action.ActivateTab(3) },
	{ mods = "LEADER", key = "5", action = wezterm.action.ActivateTab(4) },
	{ mods = "LEADER", key = "6", action = wezterm.action.ActivateTab(5) },
	{ mods = "LEADER", key = "7", action = wezterm.action.ActivateTab(6) },
	{ mods = "LEADER", key = "8", action = wezterm.action.ActivateTab(7) },
	{ mods = "LEADER", key = "9", action = wezterm.action.ActivateTab(-1) },
	{ mods = "LEADER", key = "]", action = wezterm.action.ActivateTabRelative(1) },
	{ mods = "LEADER", key = "[", action = wezterm.action.ActivateTabRelative(-1) },
	{ mods = "LEADER", key = "r", action = wezterm.action.ReloadConfiguration },
	{ mods = "LEADER", key = "y", action = wezterm.action.CopyTo("Clipboard") },
	{ mods = "LEADER", key = "p", action = wezterm.action.PasteFrom("Clipboard") },
	{ mods = "LEADER", key = "Y", action = wezterm.action.CopyTo("PrimarySelection") },
	{ mods = "LEADER", key = "P", action = wezterm.action.PasteFrom("PrimarySelection") },
	{ mods = "LEADER", key = "c", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
	{ mods = "LEADER", key = ",", action = wezterm.action.MoveTabRelative(-1) },
	{ mods = "LEADER", key = ".", action = wezterm.action.MoveTabRelative(1) },
	-- { mods = "LEADER", key = "w", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
	-- { mods = "LEADER", key = "q", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
	{ mods = "LEADER", key = "d", action = wezterm.action.ShowDebugOverlay },
	{ mods = "ALT", key = "x", action = wezterm.action.ShowDebugOverlay },
	{ mods = "LEADER", key = "?", action = wezterm.action.ActivateCommandPalette },
	{ mods = "LEADER", key = "v", action = wezterm.action.ActivateCopyMode },
	{ mods = "LEADER", key = "l", action = wezterm.action.ShowLauncher },
	{ mods = "ALT", key = "=", action = wezterm.action.IncreaseFontSize },
	{ mods = "ALT", key = "-", action = wezterm.action.DecreaseFontSize },
	{
		mods = "LEADER|SHIFT",
		key = "l",
		action = wezterm.action.ShowLauncherArgs({
			flags = "FUZZY|LAUNCH_MENU_ITEMS|DOMAINS|TABS|WORKSPACES|COMMANDS",
			title = "Launcher",
		}),
	},
}

--**********************
-- EXTENSIONS MANAGEMENT
--**********************

--------------------------------
-- SMART WORKSPACE and RESURRECT
--------------------------------

workspace_switcher.zoxide_path = "/usr/local/bin/zoxide"

resurrect.state_manager.set_max_nlines(config.scrollback_lines)

resurrect.state_manager.change_state_save_dir(STATE .. "/wezterm/resurrect/")

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
	private_key = HOME .. "/.secret/rage-wezterm.txt",
	public_key = "age1k429zd7js54x484ya5apata96sa5z7uaf4h6s8l4t4xnc2znm4us9kum3e",
})

wezterm.on("smart_workspace_switcher.workspace_switcher.chosen", function(window, path, label)
	wezterm.log_info(window)

	window:gui_window():set_right_status(wezterm.format({
		{ Foreground = { Color = "green" } },
		{ Text = basename(path) .. "  " },
	}))
	-- local gui_win = window:gui_window()
	-- local base_path = string.gsub(workspace, "(.*[/\\])(.*)", "%2")
	-- gui_win:set_right_status(wezterm.format({
	-- 	{ Foreground = { Color = "green" } },
	-- 	{ Text = base_path .. "  " },
	-- }))
end)

wezterm.on("smart_workspace_switcher.workspace_switcher.created", function(window, workspace, label)
	window:gui_window():set_right_status(wezterm.format({
		{ Foreground = { Color = "green" } },
		{ Text = "󱂬 : " .. label },
	}))

	local workspace_state = resurrect.workspace_state

	workspace_state.restore_workspace(resurrect.state_manager.load_state(label, "workspace"), {
		window = window,
		relative = true,
		restore_text = true,
		resize_window = false,
		on_pane_restore = resurrect.tab_state.default_on_pane_restore,
	})
end)

-- Saves the state whenever I select a workspace
wezterm.on("smart_workspace_switcher.workspace_switcher.selected", function(window, path, label)
	wezterm.log_info(window)
	local workspace_state = resurrect.workspace_state
	resurrect.state_manager.save_state(workspace_state.get_workspace_state())
	resurrect.state_manager.write_current_state(label, "workspace")
end)

wezterm.on("smart_workspace_switcher.workspace_switcher.start", function(window, _)
	wezterm.log_info(window)
end)
wezterm.on("smart_workspace_switcher.workspace_switcher.canceled", function(window, _)
	wezterm.log_info(window)
end)

-- resurrect the last closed workspace
wezterm.on("gui-startup", resurrect.state_manager.resurrect_on_gui_startup)

local extended_keys = {
	-- SMART_WORKSPACE_SWITCHER
	--
	-- switch workspace
	{
		mods = "LEADER",
		key = "s",
		-- this is invoking `zoxide query -l <extra_args>`
		-- action = workspace_switcher.switch_workspace({ extra_args = " | rg -Fxf ~/.projects" }),
		-- this is the plain version of the above
		action = workspace_switcher.switch_workspace({}),
	},

	-- switch to previous workspace
	{ mods = "LEADER|SHIFT", key = "S", action = workspace_switcher.switch_to_prev_workspace() },

	-- create a new workspace
	{ -- Prompt for a name to use for a new workspace and switch to it.
		mods = "LEADER|SHIFT",
		key = "C",
		action = wezterm.action.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { Color = scheme.ansi[5] } },
				{ Text = "Enter name for the new workspace" },
			}),
			action = wezterm.action_callback(function(window, pane, line)
				-- line will be `nil` if they hit escape without entering anything
				-- An empty string if they just hit enter
				-- Or the actual line of text they wrote
				if line and #string.gsub(line, "^%s*(.-)%s*$", "%1") ~= 0 then
					window:perform_action(wezterm.action.SwitchToWorkspace({ name = line }), pane)
				end
			end),
		}),
	},

	-- RESURRECT

	-- Save workspace
	{
		mods = "ALT",
		key = "w",
		action = wezterm.action_callback(function(win, pane)
			local workspace_state = resurrect.workspace_state
			resurrect.state_manager.save_state(workspace_state.get_workspace_state())
			resurrect.state_manager.write_current_state(wezterm.mux.get_active_workspace(), "workspace")
		end),
	},

	-- save window state
	{ mods = "ALT|SHIFT", key = "W", action = resurrect.window_state.save_window_action() },

	-- save tab state
	{ mods = "ALT|SHIFT", key = "T", action = resurrect.tab_state.save_tab_action() },

	{
		mods = "ALT",
		key = "s",
		action = wezterm.action_callback(function(win, pane)
			local workspace_state = resurrect.workspace_state
			resurrect.state_manager.save_state(workspace_state.get_workspace_state())
			resurrect.window_state.save_window_action()
			resurrect.state_manager.write_current_state(wezterm.mux.get_active_workspace(), "workspace")
		end),
	},

	-- Read the resurrect state file (use the fuzzy finder)
	{
		mods = "ALT",
		key = "r",
		action = wezterm.action_callback(function(win, pane)
			resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
				print(label)
				local type = string.match(id, "^([^/]+)") -- match before '/'
				id = string.match(id, "([^/]+)$") -- match after '/'
				id = string.match(id, "(.+)%..+$") -- remove file extension
				local opts = {
					relative = true,
					restore_text = true,
					on_pane_restore = resurrect.tab_state.default_on_pane_restore,
				}
				if type == "workspace" then
					local state = resurrect.state_manager.load_state(id, "workspace")
					resurrect.workspace_state.restore_workspace(state, opts)
				elseif type == "window" then
					opts.close_open_tabs = true
					opts.window = pane:window()
					local state = resurrect.state_manager .. load_state(id, "window")
					resurrect.window_state.restore_window(pane:window(), state, opts)
				elseif type == "tab" then
					opts.spawn_in_workspace = true
					local state = resurrect.sate_manager.load_state(id, "tab")
					resurrect.tab_state.restore_tab(pane:tab(), state, opts)
				end
			end, {
				is_fuzzy = true,
				show_state_with_date = true,
				date_format = "%d-%b-%Y %H:%M",
			})
		end),
	},
	-- Delete a saved state
	{
		mods = "ALT",

		key = "d",
		action = wezterm.action_callback(function(win, pane)
			resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id)
				resurrect.state_manager.delete_state(id)
			end, {
				title = "Delete State",
				description = "Select State to Delete and press Enter = accept, Esc = cancel, / = filter",
				fuzzy_description = "Search State to Delete: ",
				is_fuzzy = true,
				show_state_with_date = true,
				date_format = "%d-%b-%Y %H:%M",
			})
		end),
	},
}

-- finalized all the keybindings
config.keys = deepMerge(standard_keys, extended_keys)

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

-- Actual setup of the tab_line
local tabline_setup = require("tab.tabline_setup")
tabline_setup.scheme = scheme
tabline_setup.default_workspace = config.default_workspace

tabline.setup(tabline_setup.get_setup())

tabline.apply_to_config(config)

config.tab_bar_at_bottom = false
config.status_update_interval = TAB_UPDATE_INTERVAL

config.tab_max_width = TAB_MAX_SIZE
config.show_new_tab_button_in_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true
config.window_frame = {
	font = wezterm.font({ family = "Operator Mono", weight = "Book" }),
	font_size = 14,
	active_titlebar_bg = scheme.tab_bar.inactive_tab.bg_color,
	inactive_titlebar_bg = scheme.tab_bar.inactive_tab.bg_color,
}

config.colors = {
	tab_bar = {
		inactive_tab_edge = scheme.tab_bar.inactive_tab.bg_color,
		active_tab = {
			fg_color = color.CATPPUCCIN_MOCHA_BLUE,
			bg_color = scheme.tab_bar.inactive_tab_edge,
			italic = false,
		},
		inactive_tab = {
			fg_color = scheme.foreground,
			bg_color = scheme.tab_bar.inactive_tab.bg_color,
			italic = true,
		},
		new_tab = {
			bg_color = scheme.tab_bar.inactive_tab_edge,
			fg_color = color.CATPPUCCIN_MOCHA_TEXT,
		},
		new_tab_hover = {
			bg_color = scheme.tab_bar.inactive_tab.bg_color,
			fg_color = color.CATPPUCCIN_MOCHA_RED,
		},
	},
}

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
