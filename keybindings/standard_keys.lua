local wezterm = require("wezterm") --[[@as Wezterm]] --- this type cast invokes the LSP module for Wezterm

local M = {
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

return M
