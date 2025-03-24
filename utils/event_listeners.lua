local wezterm = require("wezterm") --[[@as Wezterm]] --- this type cast invokes the LSP module for Wezterm
local constants = require("utils.constants")
local helpers = require("utils.helpers")

local M = {}

local function basename(s)
	return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

function M.setup(resurrect, workspace_switcher, tabline)
	------------------------------------
	-- EVENT LISTENERS CONFIGURATION
	------------------------------------

	local is_periodic_save = false

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
			message = "Configuration reloaded",
		},
		["resurrect.error"] = {
			message = "Resurrect error!",
			log_message = "ERROR!",
			error = true,
		},
		["resurrect.state_manager.delete_state.finished"] = {
			message = "State %s deleted",
			format = 1,
		},
		["resurrect.tab_state.restore_tab.finished"] = {
			message = "Tab restored",
		},
		["resurrect.window_state.restore_window.finished"] = {
			message = "Window restored",
		},
		["resurrect.workspace_state.restore_workspace.finished"] = {
			message = "Workspace restored",
		},
		["resurrect.state_manager.save_state.finished"] = {
			fn = function(args)
				is_periodic_save = false
			end,
		},
		["resurrect.periodic_save"] = {
			fn = function(args)
				is_periodic_save = true
				resurrect.state_manager.write_current_state(wezterm.mux.get_active_workspace(), "workspace")
			end,
		},
	}

	for event, opts in pairs(event_listeners) do
		wezterm.on(event, function(...)
			local sections = helpers.get_sections(event)
			local args = { ... }

			if opts.fn then
				opts.fn(args)
			end
			if opts.check_periodic_save then
				is_periodic_save = false
			end
			if opts.message then
				local msg = opts.message
				if opts.format then
					msg = string.format(msg, args[opts.format])
				end
				helpers.notify(msg)
			end
			if opts.log_message then
				local log = event .. ":"
				for _, v in ipairs(args) do
					log = log .. " " .. tostring(v)
				end
				if opts.error then
					wezterm.log_error(opts.log_message, log)
				elseif opts.warn then
					wezterm.log_warn(opts.log_message, log)
				else
					wezterm.log_info(opts.log_message, log)
				end
			end
		end)
	end
end

return M
