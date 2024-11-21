---------
-- SYSTEM
---------
--
-- Pull in the wezterm API
local wezterm = require("wezterm")

-- Install plugins
local smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

-- Update the plugins
wezterm.plugin.update_all()

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Confirm configuration reloads
wezterm.on("window-config-reloaded", function(window, pane)
	window:toast_notification("wezterm", "configuration reloaded!", nil, 4000)
end)

-- Remove confirmation when closing wezterm
config.window_close_confirmation = "NeverPrompt"

-- Change the environment path
config.set_environment_variables = {
	PATH = os.getenv("PATH") .. ":/usr/local/bin",
}

------------
-- CONSTANTS
------------

local HARD_LEFT_ARROW = wezterm.nerdfonts.pl_left_hard_divider
local SOFT_LEFT_ARROW = wezterm.nerdfonts.pl_right_soft_divider
local HARD_RIGHT_ARROW = wezterm.nerdfonts.pl_right_hard_divider
local SOFT_RIGHT_ARROW = wezterm.nerdfonts.pl_right_soft_divider

local LOWER_LEFT_WEDGE = wezterm.nerdfonts.ple_lower_left_triangle
local UPPER_LEFT_WEDGE = wezterm.nerdfonts.ple_upper_left_triangle
local LOWER_RIGHT_WEDGE = wezterm.nerdfonts.ple_lower_right_triangle
local UPPER_RIGHT_WEDGE = wezterm.nerdfonts.ple_upper_right_triangle

local BACKSLASH_SEPARATOR = wezterm.nerdfonts.ple_backslash_separator
local FORWARDSLASH_SEPARATOR = wezterm.nerdfonts.ple_forwardslash_separator

local HOME = os.getenv("HOME")

local TABSIZE = 20

-- Selecting the color scheme
config.color_scheme = "Catppuccin Mocha"
local scheme = wezterm.color.get_builtin_schemes()[config.color_scheme]
-- print(scheme)

---------------------
-- FEATURE MANAGEMENT
---------------------

-- Various utilities settings

-- RESURRECT
resurrect.change_state_save_dir("/Users/chris/.local/state/wezterm/resurrect/")

resurrect.periodic_save({
	interval_seconds = 30,
	save_workspace = true,
	save_window = true,
	save_tabs = true,
})

-- Sending a notification when specified events occur but suppress on `periodic_save()`:
local resurrect_event_listeners = {
	"resurrect.error",
	"resurrect.save_state.finished",
}
local is_periodic_save = false
wezterm.on("resurrect.periodic_save", function()
	is_periodic_save = true
end)
for _, event in ipairs(resurrect_event_listeners) do
	wezterm.on(event, function(...)
		if event == "resurrect.save_state.finished" and is_periodic_save then
			is_periodic_save = false
			return
		end
		local args = { ... }
		local msg = event
		for _, v in ipairs(args) do
			msg = msg .. " " .. tostring(v)
		end
		wezterm.gui.gui_windows()[1]:toast_notification("Wezterm - resurrect", msg, nil, 4000)
	end)
end

-- SMART WORKSPACE

workspace_switcher.zoxide_path = "/usr/local/bin/zoxide"

-- custom workspace formatter
workspace_switcher.workspace_formatter = function(label)
	return wezterm.format({
		{ Foreground = { AnsiColor = "Green" } },
		{ Background = { Color = scheme.tab_bar.background } },
		{ Attribute = { Italic = false } },
		{ Text = "󱂬: " },
		{ Attribute = { Italic = true } },
		{ Foreground = { Color = scheme.foreground } },
		{ Text = label },
	})
end

wezterm.on("smart_workspace_switcher.workspace_switcher.chosen", function(window, workspace)
	local gui_win = window:gui_window()
	local base_path = string.gsub(workspace, "(.*[/\\])(.*)", "%2")
	gui_win:set_right_status(workspace_switcher.workspace_formatter(base_path))
end)

-- Load the state whenever I create a new workspace
wezterm.on("smart_workspace_switcher.workspace_switcher.created", function(window, path, label)
	local workspace_state = resurrect.workspace_state

	workspace_state.restore_workspace(resurrect.load_state(label, "workspace"), {
		window = window,
		relative = true,
		restore_text = true,
		on_pane_restore = resurrect.tab_state.default_on_pane_restore,
	})

	-- update right status bar
	local gui_win = window:gui_window()
	local base_path = string.gsub(label, "(.*[/\\])(.*)", "%2")
	gui_win:set_right_status(workspace_switcher.workspace_formatter(base_path))
end)

-- Saves the state whenever I select a workspace
wezterm.on("smart_workspace_switcher.workspace_switcher.selected", function(window, path, label)
	local workspace_state = resurrect.workspace_state
	resurrect.save_state(workspace_state.get_workspace_state())
end)

-- AUGMENT COMMAND PALETTE

wezterm.on("augment-command-palette", function(window, pane)
	local workspace_state = resurrect.workspace_state
	return {
		{
			brief = "Window | Workspace: Switch Workspace",
			icon = "md_briefcase_arrow_up_down",
			action = workspace_switcher.switch_workspace(),
		},
		{
			brief = "Window | Workspace: Rename Workspace",
			icon = "md_briefcase_edit",
			action = wezterm.action.PromptInputLine({
				description = "Enter new name for workspace",
				action = wezterm.action_callback(function(window, pane, line)
					if line then
						wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
						resurrect.save_state(workspace_state.get_workspace_state())
					end
				end),
			}),
		},
	}
end)

----------------
-- UI APPEARANCE
----------------

-- Configuration of the tab bar
--
-- Utility constants
config.tab_max_width = 30

local TICKS = 0
local __HAS_UNSEEN_OUTPUT = false

local function has_unseen_output(tab)
	if os.clock() - TICKS < 0.5 then
		return __HAS_UNSEEN_OUTPUT
	end
	TICKS = os.clock()
	local result = false
	for _, pane in ipairs(tab.panes) do
		if pane.has_unseen_output then
			result = true
			break
		end
	end
	__HAS_UNSEEN_OUTPUT = result
	return result
end

-- configuration of the tabline plugin
--

tabline.setup({
	options = {
		theme = config.color_scheme,
	},
})

local tabline_scheme = tabline.get_colors()

tabline.setup({
	options = {
		color_overrides = {
			tab = {
				inactive = {
					fg = scheme.tab_bar.inactive_tab.fg_color,
					bg = scheme.tab_bar.inactive_tab.bg_color,
				},
				inactive_hover = {
					fg = scheme.tab_bar.inactive_tab_hover.fg_color,
					bg = scheme.tab_bar.inactive_tab_hover.bg_color,
				},
			},
		},
		section_separators = {
			left = HARD_LEFT_ARROW,
			right = HARD_RIGHT_ARROW,
		},
		component_separators = {
			left = SOFT_LEFT_ARROW,
			right = SOFT_RIGHT_ARROW,
		},
		tab_separators = {
			left = "",
			right = "",
			-- left = UPPER_LEFT_WEDGE,
			-- right = LOWER_RIGHT_WEDGE,
		},
	},
	sections = {
		tabline_a = { {
			"mode",
			fmt = function(str)
				return str:sub(1, 1)
			end,
		} },
		tabline_b = { "workspace" },
		tabline_c = { " " },
		tab_active = {
			{ Attribute = { Intensity = "Bold" } },
			{ Foreground = { Color = scheme.tab_bar.active_tab.fg_color } },
			{ Background = { Color = scheme.selection_fg } },
			UPPER_LEFT_WEDGE,
			"index",
			{ Foreground = { Color = scheme.selection_fg } },
			{ Background = { Color = tabline_scheme.tab.active.bg } },
			UPPER_LEFT_WEDGE,
			"ResetAttributes",
			{ Attribute = { Intensity = "Bold" } },
			" ",
			function(tab)
				local cwd
				local cwd_uri = tab.active_pane.current_working_dir
				if cwd_uri then
					local file_path = cwd_uri.file_path
					cwd = file_path:gsub(HOME, "~")
					if #cwd > TABSIZE then
						local inc = ""
						local output = ""
						while #(inc .. "/" .. output) <= TABSIZE + 1 do -- we'll remove the trailing slash
							output = inc .. "/" .. output
							inc = cwd:match("([^/]+)/?$")
							cwd = cwd:sub(1, #cwd - #inc - 1)
						end
						return output:sub(1, #output - 1)
					else
						return cwd
					end
				end
			end,
			" ",
			{ "zoomed", padding = 0 },
			" ",
			{ Foreground = { Color = tabline_scheme.tab.active.bg } },
			{ Background = { Color = tabline_scheme.tab.inactive.bg } },
			UPPER_LEFT_WEDGE,
			" ",
		},
		tab_inactive = {
			{ Attribute = { Italic = true } },
			{ Foreground = { Color = scheme.selection_bg } },
			{ Background = { Color = scheme.tab_bar.active_tab.fg_color } },
			LOWER_RIGHT_WEDGE,
			-- {
			-- 	Foreground = {
			-- 		Color = function(tab)
			-- 			if has_unseen_output(tab) then
			-- 				return scheme.ansi[2]
			-- 			else
			-- 				return scheme.tab_bar.inactive_tab.fg_color
			-- 			end
			-- 		end,
			-- 	},
			-- },
			{ Foreground = { Color = scheme.tab_bar.inactive_tab.fg_color } },
			{ Background = { Color = scheme.selection_bg } },
			"index",
			{ Foreground = { Color = scheme.selection_bg } },
			{ Background = { Color = tabline_scheme.tab.inactive.bg } },
			UPPER_LEFT_WEDGE,
			"ResetAttributes",
			{ Attribute = { Italic = true } },
			{
				"process",
				process_to_icon = {
					["apt"] = wezterm.nerdfonts.dev_debian,
					["bash"] = wezterm.nerdfonts.cod_terminal_bash,
					["bat"] = wezterm.nerdfonts.md_bat,
					["cmd.exe"] = wezterm.nerdfonts.md_console_line,
					["curl"] = wezterm.nerdfonts.md_flattr,
					["debug"] = wezterm.nerdfonts.cod_debug,
					["default"] = wezterm.nerdfonts.md_application,
					["docker"] = wezterm.nerdfonts.linux_docker,
					["docker-compose"] = wezterm.nerdfonts.linux_docker,
					["git"] = wezterm.nerdfonts.dev_git,
					["go"] = wezterm.nerdfonts.md_language_go,
					["lazydocker"] = wezterm.nerdfonts.linux_docker,
					["lazygit"] = wezterm.nerdfonts.cod_github,
					["lua"] = wezterm.nerdfonts.seti_lua,
					["make"] = wezterm.nerdfonts.seti_makefile,
					["nix"] = wezterm.nerdfonts.linux_nixos,
					["node"] = wezterm.nerdfonts.md_nodejs,
					["npm"] = wezterm.nerdfonts.md_npm,
					["nvim"] = wezterm.nerdfonts.custom_neovim,
					["psql"] = wezterm.nerdfonts.dev_postgresql,
					["zsh"] = wezterm.nerdfonts.dev_terminal,
					-- and more...
				},
				padding = { left = 0, right = 2 },
			},
			{ Foreground = { Color = tabline_scheme.tab.inactive.bg } },
			{ Background = { Color = tabline_scheme.tab.inactive.bg } },
			UPPER_LEFT_WEDGE,
			" ",
		},
		tabline_x = { "ram", "cpu" },
		tabline_y = {
			{
				"datetime",
				style = "%a, %d-%b-%y %H:%M",
				hour_to_icon = {
					["00"] = wezterm.nerdfonts.md_clock_time_twelve_outline,
					["01"] = wezterm.nerdfonts.md_clock_time_one_outline,
					["02"] = wezterm.nerdfonts.md_clock_time_two_outline,
					["03"] = wezterm.nerdfonts.md_clock_time_three_outline,
					["04"] = wezterm.nerdfonts.md_clock_time_four_outline,
					["05"] = wezterm.nerdfonts.md_clock_time_five_outline,
					["06"] = wezterm.nerdfonts.md_clock_time_six_outline,
					["07"] = wezterm.nerdfonts.md_clock_time_seven_outline,
					["08"] = wezterm.nerdfonts.md_clock_time_eight_outline,
					["09"] = wezterm.nerdfonts.md_clock_time_nine_outline,
					["10"] = wezterm.nerdfonts.md_clock_time_ten_outline,
					["11"] = wezterm.nerdfonts.md_clock_time_eleven_outline,
					["12"] = wezterm.nerdfonts.md_clock_time_twelve,
					["13"] = wezterm.nerdfonts.md_clock_time_one,
					["14"] = wezterm.nerdfonts.md_clock_time_two,
					["15"] = wezterm.nerdfonts.md_clock_time_three,
					["16"] = wezterm.nerdfonts.md_clock_time_four,
					["17"] = wezterm.nerdfonts.md_clock_time_five,
					["18"] = wezterm.nerdfonts.md_clock_time_six,
					["19"] = wezterm.nerdfonts.md_clock_time_seven,
					["20"] = wezterm.nerdfonts.md_clock_time_eight,
					["21"] = wezterm.nerdfonts.md_clock_time_nine,
					["22"] = wezterm.nerdfonts.md_clock_time_ten,
					["23"] = wezterm.nerdfonts.md_clock_time_eleven,
				},
			},
		},
		tabline_z = { "hostname" },
	},
	extensions = { "resurrect", "smart_workspace_switcher" },
})

tabline.apply_to_config(config)
config.tab_bar_at_bottom = true

-- Fonts configuration
config.font = wezterm.font_with_fallback({
	{ family = "Operator Mono SSm Lig", harfbuzz_features = { "liga=1", "calt=1", "clig=1" } },
	{ family = "Operator Mono Lig", harfbuzz_features = { "liga=1", "calt=1", "clig=1" } },
	{ family = "Symbols Nerd Font" },
})

config.use_cap_height_to_scale_fallback_fonts = true

config.font_size = 15

---------------
-- KEY BINDINGS
---------------
--
-- Disable default keybindings
config.disable_default_key_bindings = true

-- Define the LEADER key
config.leader = { key = "s", mods = "CTRL", timeout_milliseconds = 1500 }

-- Key configuration
config.keys = {
	{ mods = "CMD", key = "q", action = wezterm.action.QuitApplication },
	{ mods = "CMD", key = "w", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
	{ mods = "CMD", key = "n", action = wezterm.action.SpawnWindow },
	{ mods = "CMD", key = "t", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
	{ mods = "CMD", key = "c", action = wezterm.action.CopyTo("Clipboard") },
	{ mods = "CMD", key = "v", action = wezterm.action.PasteFrom("Clipboard") },
	{ mods = "LEADER", key = "-", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ mods = "LEADER|SHIFT", key = "_", action = wezterm.action.SplitPane({ direction = "Down", top_level = true }) },
	{ mods = "LEADER", key = "\\", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ mods = "LEADER|SHIFT", key = "|", action = wezterm.action.SplitPane({ direction = "Right", top_level = true }) },
	{ mods = "LEADER", key = "z", action = wezterm.action.TogglePaneZoomState },
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
	{ mods = "LEADER", key = "q", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
	{ mods = "LEADER", key = "w", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
	{ mods = "LEADER", key = "d", action = wezterm.action.ShowDebugOverlay },
	{ mods = "LEADER", key = "?", action = wezterm.action.ActivateCommandPalette },
	{ mods = "LEADER", key = "v", action = wezterm.action.ActivateCopyMode },
	{
		mods = "LEADER",
		key = "s",
		-- this is invoking `zoxide query -l <extra_args>`
		-- action = workspace_switcher.switch_workspace({ extra_args = " | rg -Fxf ~/.projects" }),
		action = workspace_switcher.switch_workspace(),
		-- this is the plain version of the above
		-- action = workspace_switcher.switch_workspace(),
	},
	{ mods = "LEADER|SHIFT", key = "S", action = workspace_switcher.switch_to_prev_workspace() },
	{
		mods = "LEADER",
		key = "w",
		action = wezterm.action_callback(function(win, pane)
			resurrect.save_state(resurrect.workspace_state.get_workspace_state())
		end),
	},
	{ mods = "LEADER|SHIFT", key = "W", action = resurrect.window_state.save_window_action() },
	{ mods = "LEADER|SHIFT", key = "T", action = resurrect.tab_state.save_tab_action() },
	{
		mods = "LEADER",
		key = "a",
		action = wezterm.action_callback(function(win, pane)
			resurrect.save_state(resurrect.workspace_state.get_workspace_state())
			resurrect.window_state.save_window_action()
		end),
	},
	{
		mods = "LEADER|SHIFT",
		key = "R",
		action = wezterm.action_callback(function(win, pane)
			resurrect.fuzzy_load(win, pane, function(id, label)
				local type = string.match(id, "^([^/]+)") -- match before '/'
				id = string.match(id, "([^/]+)$") -- match after '/'
				id = string.match(id, "(.+)%..+$") -- remove file extension
				local opts = {
					relative = true,
					restore_text = true,
					on_pane_restore = resurrect.tab_state.default_on_pane_restore,
				}
				if type == "workspace" then
					local state = resurrect.load_state(id, "workspace")
					resurrect.workspace_state.restore_workspace(state, opts)
				elseif type == "window" then
					local state = resurrect.load_state(id, "window")
					resurrect.window_state.restore_window(pane:window(), state, opts)
				elseif type == "tab" then
					local state = resurrect.load_state(id, "tab")
					resurrect.tab_state.restore_tab(pane:tab(), state, opts)
				end
			end)
		end),
	},
	{
		mods = "LEADER|SHIFT",
		key = "D",
		action = wezterm.action_callback(function(win, pane)
			resurrect.fuzzy_load(win, pane, function(id)
				resurrect.delete_state(id)
			end, {
				title = "Delete State",
				description = "Select State to Delete and press Enter = accept, Esc = cancel, / = filter",
				fuzzy_description = "Search State to Delete: ",
				is_fuzzy = true,
			})
		end),
	},
}

-- smart_splits configuration
smart_splits.apply_to_config(config, {
	-- the default config is here, if you'd like to use the default keys,
	-- you can omit this configuration table parameter and just use
	-- smart_splits.apply_to_config(config)

	-- directional keys to use in order of: left, down, up, right
	-- direction_keys = { 'h', 'j', 'k', 'l' },
	-- if you want to use separate direction keys for move vs. resize, you
	-- can also do this:
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
