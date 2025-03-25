local wezterm = require("wezterm") --[[@as Wezterm]] --- this type cast invokes the LSP module for Wezterm

local M = {}

M.is_mac = wezterm.target_triple:find("apple") ~= nil
M.is_windows = wezterm.target_triple:find("windows") ~= nil
M.is_linux = wezterm.target_triple:find("linux") ~= nil

local home_env
local state_env
if M.is_windows then
	home_env = "HOMEPATH"
	state_env = "LOCALAPPDATA"
else
	home_env = "HOME"
	state_env = "XDG_STATE_HOME"
end
M.HOME = os.getenv(home_env)
M.STATE = os.getenv(state_env) or M.HOME .. "/.local/state"

function M.get_font_size()
	if M.is_mac then
		return 16
	elseif M.is_windows then
		return 16
	elseif M.is_linux then
		return 12
	end
end

function M.get_tab_font_size()
	if M.is_mac then
		return 14
	elseif M.is_windows then
		return 14
	elseif M.is_linux then
		return 10
	end
end

M.TAB_MAX_SIZE = 28
M.TAB_UPDATE_INTERVAL = 250 -- ms
M.CPU_LOAD_INTERVAL = 2 -- s

M.NOTIFICATION_TIME = 2000

M.DEFAULT_WORKSPACE = "~"
return M
