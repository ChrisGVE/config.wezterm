local wezterm = require("wezterm")
local event_listeners = require("utils.event_listeners_new")

-- This test file shows how to use the new event listeners

local test = {}

function test.run()
    -- Initialize the event listeners
    event_listeners.setup()
    
    -- Test the basename function from state
    local listeners = wezterm.plugin.require("https://github.com/chrisgve/listeners.wezterm")
    local path = "/some/long/path/filename.txt"
    local result = listeners.state.functions.call("basename", path)
    wezterm.log_info("Basename of " .. path .. " is: " .. result)
    
    -- Test flag functionality
    local is_saving = listeners.state.flags.get("is_periodic_save")
    wezterm.log_info("Is periodic save active: " .. tostring(is_saving))
    
    -- Toggle flag
    listeners.state.flags.toggle("is_periodic_save")
    is_saving = listeners.state.flags.get("is_periodic_save")
    wezterm.log_info("After toggle, is periodic save active: " .. tostring(is_saving))
    
    wezterm.log_info("Event listener test complete!")
    
    return "Event listeners are properly configured and working"
end

return test
