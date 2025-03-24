local M = {}

---@param t1 table
---@param t2 table
---@return table
function M.deepMerge(t1, t2)
	-- If both tables are arrays, concatenate them
	if #t1 > 0 and #t2 > 0 then
		local merged = {}
		for _, v in ipairs(t1) do
			table.insert(merged, v)
		end
		for _, v in ipairs(t2) do
			table.insert(merged, v)
		end
		return merged
	end

	-- Otherwise, merge as key-value pairs
	local merged = {}
	for k, v in pairs(t1) do
		if type(v) == "table" and type(t2[k]) == "table" then
			merged[k] = deepMerge(v, t2[k])
		else
			merged[k] = v
		end
	end

	for k, v in pairs(t2) do
		if merged[k] == nil then
			merged[k] = v
		end
	end

	return merged
end

-- Create a cache table to store previously split results
M.split_cache = {}

function M.get_sections(str)
	-- Return cached result if it exists
	if M.split_cache[str] then
		return M.split_cache[str]
	end

	-- Split and cache the result if it's new
	local sections = {}
	for section in str:gmatch("([^%.]+)") do
		table.insert(sections, section)
	end

	-- Store in cache and return
	M.split_cache[str] = sections
	return sections
end

function M.notify(message)
	local window = wezterm.gui.gui_windows()[1]
	window:toast_notification("wezterm", message, nil, constants.NOTIFICATION_TIME)
end

return M
