function tile_occupied(tile, otherTilesTable)
	for i,t in pairs(otherTilesTable) do
		for j,n in pairs(t) do
			if tile.x == n.x and tile.y == n.y then
				return true
			end
		end
	end
	return false
end

function tiles_overlap(a, b)
	if a.x == b.x and a.y == b.y then
		return true
	else
		return false
	end
end
