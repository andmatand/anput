function add_direction(tile, dir)
	if dir == 1 then
		-- North
		return {x = tile.x, y = tile.y - 1}
	elseif dir == 2 then
		-- East
		return {x = tile.x + 1, y = tile.y}
	elseif dir == 3 then
		-- East
		return {x = tile.x, y = tile.y + 1}
	elseif dir == 4 then
		-- West
		return {x = tile.x - 1, y = tile.y}
	end
end

function manhattan_distance(a, b)
	return math.abs(b.x - a.x) + math.abs(b.y - a.y)
end

function tile_occupied(tile, occupiedTiles)
	for i,t in pairs(occupiedTiles) do
		if t.position == nil then
			if tile.x == t.x and tile.y == t.y then
				return true
			end
		else
			if tile.x == t.position.x and tile.y == t.position.y then
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
	-- If either of the tiles is not in a real position
	if a.x == nil or a.y == nil or b.x == nil or b.y == nil then
		return false
	end

	if a.x == b.x and a.y == b.y then
		return true
	else
		return false
	end
end

-- Returns true if tiles touch (non-diagonally) without overlapping
function tiles_touching(a, b)
	if (a.x == b.x and a.y == b.y - 1) or -- North
	   (a.x == b.x + 1 and a.y == b.y) or -- East
	   (a.x == b.x and a.y == b.y + 1) or -- South
	   (a.x == b.x - 1 and a.y == b.y) then  -- West
		return true
	else
		return false
	end
end
