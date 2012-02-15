function concat_tables(tableList)
	combined = {}
	for _,t in ipairs(tableList) do
		for _,v in ipairs(t) do
			table.insert(combined, v)
		end
	end
	return combined
end
