local wezterm = require("wezterm") --[[@as Wezterm]] --- this type cast invokes the LSP module for Wezterm

local M = {}

M.HOME = os.getenv("HOME")
M.STATE = os.getenv("XDG_STATE_HOME") or M.HOME .. "/.local/state"

M.is_mac = wezterm.target_triple:find("apple") ~= nil
M.is_windows = wezterm.target_triple:find("windows") ~= nil
M.is_linux = wezterm.target_triple:find("linux") ~= nil

M.TAB_MAX_SIZE = 28
M.TAB_UPDATE_INTERVAL = 250 -- ms
M.CPU_LOAD_INTERVAL = 2 -- s

M.NOTIFICATION_TIME = 2000

M.DEFAULT_WORKSPACE = "~"
return M
