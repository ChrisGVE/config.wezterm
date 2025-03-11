local wezterm = require("wezterm") --[[@as Wezterm]] --- this type cast invokes the LSP module for Wezterm
local color = require("utils.color")
local glyph = require("utils.glyph")
local constants = require("utils.constants")

local M = {}

local mux = wezterm.mux
local nerdfonts = wezterm.nerdfonts

local process_custom_icons = {
	["brew"] = " ",
	["curl"] = nerdfonts.md_arrow_down_box,
	["gitui"] = nerdfonts.dev_github_badge,
	["kubectl"] = nerdfonts.md_kubernetes,
	["kuberlr"] = nerdfonts.md_kubernetes,
	["python"] = { nerdfonts.md_language_python, color = { fg = color.CATPPUCCIN_MOCHA_BLUE } },
	["taskwarrior"] = { " ", color = { fg = color.CATPPUCCIN_MOCHA_PEACH } },
	["tmux"] = nerdfonts.cod_terminal_tmux,
}

-- function returns an icon for zoomed panes
---@param tab table
---@param opts table
---@return string
local function zoomed(tab, opts)
	if tab == nil then
		return ""
	end
	for _, pane in ipairs(tab.panes) do
		if pane.is_zoomed then
			return " "
		end
	end
	return ""
end

-- function returns the index of the tab
---@param tab table
---@return string
local function index(tab)
	if tab ~= nil then
		return tab.tab_index + 1
	else
		return ""
	end
end

function M.setup(config, tabline, scheme)
	tabline.setup({
		options = {

			-- THEME

			color_overrides = {
				tab = {
					active = {
						fg = scheme.ansi[5],
						-- bg = scheme.tab_bar.active_tab.bg_color,
					},
					inactive = {
						fg = scheme.tab_bar.inactive_tab.fg_color,
						bg = scheme.tab_bar.inactive_tab.bg_color,
					},
					inactive_hover = {
						fg = scheme.tab_bar.inactive_tab_hover.fg_color,
						bg = scheme.tab_bar.inactive_tab_hover.bg_color,
					},
				},
				normal_mode = {
					a = { bg = color.CATPPUCCIN_MOCHA_LAVENDER },
					b = { fg = color.CATPPUCCIN_MOCHA_LAVENDER },
					c = { fg = color.CATPPUCCIN_MOCHA_LAVENDER },
				},
			},
			tab_separators = {
				left = "",
				right = "",
			},
		},

		-- SECTIONS DEFINITIONS

		sections = {

			-- LEFT SECTION

			tabline_a = {
				{
					"mode",
					icons_enabled = true,
					fmt = function(str)
						return str:sub(1, 1)
					end,
				},
			},
			tabline_b = {
				cond = function()
					return mux.get_active_workspace() ~= constants.DEFAULT_WORKSPACE
				end,
				function()
					local workspace = mux.get_active_workspace()
					if workspace == constants.DEFAULT_WORKSPACE then
						return ""
					else
						return nerdfonts.cod_terminal_tmux .. " " .. string.match(workspace, "[^/\\]+$")
					end
				end,
				padding = 0,
			},
			tabline_c = { cond = false },

			-- ACTIVE TAB

			tab_active = {
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { Color = scheme.selection_fg } },
				{ Background = { Color = scheme.tab_bar.inactive_tab.bg_color } },
				glyph.LOWER_RIGHT_WEDGE,
				{ Foreground = { Color = scheme.tab_bar.active_tab.fg_color } },
				{ Background = { Color = scheme.selection_fg } },
				index,
				{ Foreground = { Color = scheme.selection_fg } },
				{ Background = { Color = scheme.tab_bar.inactive_tab_edge } },
				glyph.UPPER_LEFT_WEDGE,
				"ResetAttributes",
				{ Attribute = { Intensity = "Bold" } },
				{
					process_to_icon = process_custom_icons,
					"process",
				},
				" ",
				zoomed,
				{ Foreground = { Color = scheme.tab_bar.inactive_tab_edge } },
				{ Background = { Color = scheme.tab_bar.inactive_tab.bg_color } },
				glyph.UPPER_LEFT_WEDGE,
				" ",
			},

			-- INACTIVE TAB

			tab_inactive = {
				{ Attribute = { Italic = true } },
				{ Foreground = { Color = scheme.selection_bg } },
				{ Background = { Color = scheme.tab_bar.inactive_tab.bg_color } },
				glyph.LOWER_RIGHT_WEDGE,
				{ Foreground = { Color = scheme.tab_bar.inactive_tab.fg_color } },
				{ Background = { Color = scheme.selection_bg } },
				index,
				{ Foreground = { Color = scheme.selection_bg } },
				{ Background = { Color = scheme.tab_bar.inactive_tab.bg_color } },
				glyph.UPPER_LEFT_WEDGE,
				"ResetAttributes",
				{ Attribute = { Italic = true } },
				{
					process_to_icon = process_custom_icons,
					"process",
				},
				"output",
			},

			-- RIGHT SECTIONS

			-- Removed this section to gain some space
			tabline_x = { "cpu", throttle = constants.CPU_LOAD_INTERVAL },
			-- tabline_x = {},
			tabline_y = {
				{
					"datetime",
					-- style = "%a, %d-%b-%y %H:%M",
					style = " %d-%b %H:%M",
					hour_to_icon = {
						["00"] = nerdfonts.md_clock_time_twelve_outline,
						["01"] = nerdfonts.md_clock_time_one_outline,
						["02"] = nerdfonts.md_clock_time_two_outline,
						["03"] = nerdfonts.md_clock_time_three_outline,
						["04"] = nerdfonts.md_clock_time_four_outline,
						["05"] = nerdfonts.md_clock_time_five_outline,
						["06"] = nerdfonts.md_clock_time_six_outline,
						["07"] = nerdfonts.md_clock_time_seven_outline,
						["08"] = nerdfonts.md_clock_time_eight_outline,
						["09"] = nerdfonts.md_clock_time_nine_outline,
						["10"] = nerdfonts.md_clock_time_ten_outline,
						["11"] = nerdfonts.md_clock_time_eleven_outline,
						["12"] = nerdfonts.md_clock_time_twelve,
						["13"] = nerdfonts.md_clock_time_one,
						["14"] = nerdfonts.md_clock_time_two,
						["15"] = nerdfonts.md_clock_time_three,
						["16"] = nerdfonts.md_clock_time_four,
						["17"] = nerdfonts.md_clock_time_five,
						["18"] = nerdfonts.md_clock_time_six,
						["19"] = nerdfonts.md_clock_time_seven,
						["20"] = nerdfonts.md_clock_time_eight,
						["21"] = nerdfonts.md_clock_time_nine,
						["22"] = nerdfonts.md_clock_time_ten,
						["23"] = nerdfonts.md_clock_time_eleven,
					},
				},
			},
			tabline_z = { "hostname" },
		},
		extensions = { "resurrect", "smart_workspace_switcher" },
	})

	tabline.apply_to_config(config)

	config.tab_bar_at_bottom = false
	config.status_update_interval = constants.TAB_UPDATE_INTERVAL

	config.tab_max_width = constants.TAB_MAX_SIZE
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
end

return M
