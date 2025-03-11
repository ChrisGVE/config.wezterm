local wezterm = require("wezterm") --[[@as Wezterm]] --- this type cast invokes the LSP module for Wezterm
local nerdfonts = wezterm.nerdfonts

return {
	HARD_LEFT_ARROW = nerdfonts.pl_left_hard_divider,
	SOFT_LEFT_ARROW = nerdfonts.pl_left_soft_divider,
	HARD_RIGHT_ARROW = nerdfonts.pl_right_hard_divider,
	SOFT_RIGHT_ARROW = nerdfonts.pl_right_soft_divider,

	LOWER_LEFT_WEDGE = nerdfonts.ple_lower_left_triangle,
	UPPER_LEFT_WEDGE = nerdfonts.ple_upper_left_triangle,
	LOWER_RIGHT_WEDGE = nerdfonts.ple_lower_right_triangle,
	UPPER_RIGHT_WEDGE = nerdfonts.ple_upper_right_triangle,

	BACKSLASH_SEPARATOR = nerdfonts.ple_backslash_separator,
	FORWARDSLASH_SEPARATOR = nerdfonts.ple_forwardslash_separator,
}
