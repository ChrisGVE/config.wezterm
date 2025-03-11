local M = {}

M.HOME = os.getenv("HOME")
M.STATE = os.getenv("XDG_STATE_HOME") or M.HOME .. "/.local/state"

M.TAB_MAX_SIZE = 28
M.TAB_UPDATE_INTERVAL = 250 -- ms
M.CPU_LOAD_INTERVAL = 2 -- s

M.DEFAULT_WORKSPACE = "~"
return M
