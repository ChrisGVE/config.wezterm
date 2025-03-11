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

return M
