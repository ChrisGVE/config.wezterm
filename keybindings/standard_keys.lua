local wezterm = require("wezterm") --[[@as Wezterm]] --- this type cast invokes the LSP module for Wezterm

local constants = require("utils.constants")
local helpers = require("utils.helpers")

local M = {
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
	{ mods = "LEADER", key = ",", action = wezterm.action.MoveTabRelative(-1) },
	{ mods = "LEADER", key = ".", action = wezterm.action.MoveTabRelative(1) },
	-- { mods = "LEADER", key = "w", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
	-- { mods = "LEADER", key = "q", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
	{ mods = "LEADER", key = "d", action = wezterm.action.ShowDebugOverlay },
	{ mods = "LEADER", key = "?", action = wezterm.action.ActivateCommandPalette },
	{ mods = "LEADER", key = "v", action = wezterm.action.ActivateCopyMode },
	{ mods = "LEADER", key = "l", action = wezterm.action.ShowLauncher },
	{
		mods = "LEADER|SHIFT",
		key = "l",
		action = wezterm.action.ShowLauncherArgs({
			flags = "FUZZY|LAUNCH_MENU_ITEMS|DOMAINS|TABS|WORKSPACES|COMMANDS",
			title = "Launcher",
		}),
	},
}

-- Os specific behaviors
local mods

--- Main actions
if constants.is_mac then
	mods = "CMD"
elseif constants.is_linux then
	mods = "SHIFT|CTRL"
elseif constants.is_windows then
	mods = "SHIFT|CTRL"
end

helpers.deepMerge(M, {
	{ mods = mods, key = "c", action = wezterm.action.CopyTo("Clipboard") },
	{ mods = mods, key = "v", action = wezterm.action.PasteFrom("Clipboard") },
	{ mods = mods, key = "q", action = wezterm.action.QuitApplication },
	{ mods = mods, key = "w", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
	{ mods = mods, key = "n", action = wezterm.action.SpawnWindow },
	{ mods = mods, key = "t", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
})

--- View
if constants.is_mac then
	mods = "CMD"
elseif constants.is_linux then
	mods = "CTRL"
elseif constants.is_windows then
	mods = "CTRL"
end

helpers.deepMerge(M, {
	{ mods = mods, key = "=", action = wezterm.action.IncreaseFontSize },
	{ mods = mods, key = "-", action = wezterm.action.DecreaseFontSize },
	{ mods = mods, key = "0", action = wezterm.action.ResetFontSize },
})

--- Tabs
if constants.is_mac then
	mods = "CMD"
elseif constants.is_linux then
	mods = "ALT"
elseif constants.is_windows then
	mods = "ALT"
end

helpers.deepMerge(M, {
	{ mods = mods, key = "z", action = wezterm.action.TogglePaneZoomState },
	{ mods = mods, key = "1", action = wezterm.action.ActivateTab(0) },
	{ mods = mods, key = "2", action = wezterm.action.ActivateTab(1) },
	{ mods = mods, key = "3", action = wezterm.action.ActivateTab(2) },
	{ mods = mods, key = "4", action = wezterm.action.ActivateTab(3) },
	{ mods = mods, key = "5", action = wezterm.action.ActivateTab(4) },
	{ mods = mods, key = "6", action = wezterm.action.ActivateTab(5) },
	{ mods = mods, key = "7", action = wezterm.action.ActivateTab(6) },
	{ mods = mods, key = "8", action = wezterm.action.ActivateTab(7) },
	{ mods = mods, key = "x", action = wezterm.action.ShowDebugOverlay },
})

return M
