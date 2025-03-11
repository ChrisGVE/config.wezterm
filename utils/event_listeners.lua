local wezterm = require("wezterm") --[[@as Wezterm]] --- this type cast invokes the LSP module for Wezterm

local M = {}

local function basename(s)
	return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

function M.setup(resurrect, workspace_switcher, tabline)
	-------------------
	-- EVENT RESPONDERS
	-------------------

	-- resurrect the last closed workspace
	wezterm.on("gui-startup", function()
		wezterm.log_info("gui-startup:", "resurrect starting")
		resurrect.state_manager.resurrect_on_gui_startup()
		wezterm.log_info("gui-startup:", "resurrect ended")
	end)

	-- Saves the state upon workspace selection
	wezterm.on("smart_workspace_switcher.workspace_switcher.selected", function(window, path, label)
		wezterm.log_info(window)
		local workspace_state = resurrect.workspace_state
		resurrect.state_manager.save_state(workspace_state.get_workspace_state())
	end)

	-- Saves the state after workspace switching
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
		resurrect.state_manager.write_current_state(label, "workspace")
	end)

	--
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

	wezterm.on("smart_workspace_switcher.workspace_switcher.start", function(window, _)
		wezterm.log_info("smart_workspace_switcher.workspace_switcher.start:", window)
	end)

	wezterm.on("smart_workspace_switcher.workspace_switcher.canceled", function(window, _)
		wezterm.log_info("smart_workspace_switcher.workspace_switcher.canceled:", window)
	end)

	------------------------------------
	-- EVENT LISTENERS FOR NOTIFICATIONS
	------------------------------------

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
		resurrect.state_manager.write_current_state(wezterm.mux.get_active_workspace(), "workspace")
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
end

return M
