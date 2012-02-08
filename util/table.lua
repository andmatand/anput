function concat_tables(tableList)
	combined = {}
	for i,t in ipairs(tableList) do
		for k,v in ipairs(t) do
			table.insert(combined, v)
		end
	end
	return combined
end
