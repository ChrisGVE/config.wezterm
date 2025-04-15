local wezterm = require("wezterm") --[[@as Wezterm]] --- this type cast invokes the LSP module for Wezterm

-- Import our new plugin
local listeners = wezterm.plugin.require("https://github.com/chrisgve/listeners.wezterm")
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

local state = listeners.state

-- Import local modules
local constants = require("utils.constants")
local helpers = require("utils.helpers")

local M = {}

-- Store the basename function in our state for reuse
listeners.state.functions.set("basename", function(path)
	return string.gsub(path, "(.*[/\\])(.*)", "%2")
end)

-- Initialize flags
state.flags.set("is_periodic_save", false)

function M.setup()
	-- Auto-require the plugins instead of passing them as parameters

	------------------------------------
	-- EVENT LISTENERS CONFIGURATION
	------------------------------------

	local event_listeners = {
		-- Restore last workspace
		["gui-startup"] = {
			fn = function(args)
				resurrect.state_manager.resurrect_on_gui_startup()
			end,
		},

		-- Saves the state when a workspace is selected
		["smart_workspace_switcher.workspace_switcher.selected"] = {
			fn = function(args)
				local window = args[1]
				local path = args[2]
				local label = args[3]

				wezterm.log_info(window)
				local workspace_state = resurrect.workspace_state
				resurrect.state_manager.save_state(workspace_state.get_workspace_state())
			end,
		},

		-- Restores the state after a workspace has been selected
		["smart_workspace_switcher.workspace_switcher.chosen"] = {
			fn = function(args)
				local window = args[1]
				local path = args[2]
				local label = args[3]

				-- Use our state function to get basename
				local base_path = state.functions.call("basename", path)

				window:gui_window():set_right_status(wezterm.format({
					{ Foreground = { Color = "green" } },
					{ Text = base_path .. "  " },
				}))
				resurrect.state_manager.write_current_state(label, "workspace")
			end,
		},

		-- Loads the state whenever a new workspace is created
		["smart_workspace_switcher.workspace_switcher.created"] = {
			fn = function(args)
				local window = args[1]
				local workspace = args[2]
				local label = args[3]

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
			end,
		},

		["smart_workspace_switcher.workspace_switcher.start"] = {
			log_message = "Cancel!",
			info = true,
		},

		["smart_workspace_switcher.workspace_switcher.canceled"] = {
			log_message = "Cancel!",
			info = true,
		},

		["window-config-reloaded"] = {
			toast_message = "Configuration reloaded",
		},

		["resurrect.error"] = {
			toast_message = "Resurrect error!",
			log_message = "ERROR!",
			error = true,
		},

		["resurrect.state_manager.delete_state.finished"] = {
			toast_message = "State %s deleted",
			toast_arg = 1,
		},

		["resurrect.tab_state.restore_tab.finished"] = {
			toast_message = "Tab restored",
		},

		["resurrect.fuzzy_loader.fuzzy_load.start"] = {
			log_message = "resurrect.fuzzy_lader.fuzzy_load.start",
		},

		["resurrect.window_state.restore_window.finished"] = {
			toast_message = "Window restored",
		},

		["resurrect.workspace_state.restore_workspace.finished"] = {
			toast_message = "Workspace restored",
		},

		["resurrect.state_manager.save_state.finished"] = {
			state_fn = "reset_periodic_save",
		},

		["resurrect.periodic_save"] = {
			state_fn = "handle_periodic_save",
		},
	}

	-- Store function for handling periodic save
	state.functions.set("reset_periodic_save", function(args)
		state.flags.set("is_periodic_save", false)
	end)

	-- Store function for handling periodic save
	state.functions.set("handle_periodic_save", function(args)
		state.flags.set("is_periodic_save", true)
		resurrect.state_manager.write_current_state(wezterm.mux.get_active_workspace(), "workspace")
	end)

	-- Configure the listeners with our event definitions
	listeners.config(event_listeners, {
		toast_timeout = constants.NOTIFICATION_TIME,
		function_options = {
			safe = true,
		},
	})
end

return M
