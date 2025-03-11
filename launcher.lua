local wezterm = require("wezterm") --[[@as Wezterm]] --- this type cast invokes the LSP module for Wezterm
local constants = require("utils.constants")

local nerdfonts = wezterm.nerdfonts

local launch_menu = {
	{
		label = nerdfonts.custom_neovim .. "  config zsh",
		args = { os.getenv("SHELL"), "-c", 'exec $EDITOR "' .. constants.HOME .. '/.config/zsh/zshrc"' },
		cwd = constants.HOME .. "/.config/zsh",
	},
	{
		label = nerdfonts.custom_neovim .. "  config neovim",
		args = { os.getenv("SHELL"), "-c", "exec $EDITOR " .. constants.HOME .. "/.config/nvim/lua" },
		cwd = constants.HOME .. "/.config/nvim/lua",
	},
	{
		label = nerdfonts.custom_neovim .. "  config wezterm",
		args = { os.getenv("SHELL"), "-c", 'exec $EDITOR "' .. wezterm.config_dir .. '/wezterm.lua"' },
		cwd = constants.HOME .. "/.config/wezterm",
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

return launch_menu
