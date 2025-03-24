local wezterm = require("wezterm") --[[@as Wezterm]] --- this type cast invokes the LSP module for Wezterm
local constants = require("utils.constants")
local helpers = require("utils.helpers")

local M = {}

function M.setup(scheme, resurrect, workspace_switcher, tabline)
	return {

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

		-- Save workspace, window, and tab
		{
			mods = "ALT",
			key = "w",
			action = wezterm.action_callback(function(win, pane)
				local workspace_state = resurrect.workspace_state
				resurrect.state_manager.save_state(workspace_state.get_workspace_state())
				resurrect.window_state.save_window_action()
				resurrect.tab_state.save_tab_action()
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
						local state = resurrect.state_manager.load_state(id, "window")
						resurrect.window_state.restore_window(pane:window(), state, opts)
					elseif type == "tab" then
						opts.spawn_in_workspace = true
						local state = resurrect.sate_manager.load_state(id, "tab")
						resurrect.tab_state.restore_tab(pane:tab(), state, opts)
					end
				end, {
					is_fuzzy = false,
					show_state_with_date = true,
					date_format = "%d-%b-%Y %H:%M",
					ignore_screen_width = false,
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
					is_fuzzy = false,
					show_state_with_date = true,
					date_format = "%d-%b-%Y %H:%M",
					ignore_screen_width = false,
				})
			end),
		},
	}
end

return M
