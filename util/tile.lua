function manhattan_distance(a, b)
	return math.abs(b.x - a.x) + math.abs(b.y - a.y)
end

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

function tile_offscreen(tile)
	if tile.x < 0 or tile.x > ROOM_W - 1 or
	   tile.y < 0 or tile.y > ROOM_H - 1 then
		return true
	else
		return false
	end
end

function tiles_overlap(a, b)
	if a.x == b.x and a.y == b.y then
		return true
	else
		return false
	end
end
