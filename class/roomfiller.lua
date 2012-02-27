require('item')
require('monster')
require('turret')

-- A RoomFiller fills a room with monsters, items
RoomFiller = class('RoomFiller')

function RoomFiller:init(room)
	self.room = room
end

function RoomFiller:add_monsters(max)
	-- Create a table of monsters with difficulties as high as possible in
	-- order to meet room difficulty level, without exceding the room's maximum
	-- occupancy
	local monsters = {}
	local totalDifficulty = 0
	while totalDifficulty < self.room.difficulty and #monsters < max do
		-- Find the hardest monster diffculty we still have room for
		local hardest = 0
		local monsterType = nil
		for mt, diff in ipairs(Monster.static.difficulties) do
			if diff + totalDifficulty > self.room.difficulty then
				break
			end
			hardest = diff
			monsterType = mt
		end

		totalDifficulty = totalDifficulty + hardest
		table.insert(monsters, Monster({}, monsterType))
	end

	-- DEBUG
	print('actual difficulty: ' .. totalDifficulty)

	-- Give items to the monsters
	for _, m in pairs(monsters) do
		if math.random(m.difficulty, 100) >= 30 then
			m.item = Item({}, math.random(1, 2))
		end
	end

	self:position_objects(monsters)
end

function RoomFiller:position_objects(objects)
	local freeTiles = copy_table(self.room.freeTiles)

	for i, o in pairs(objects) do
		-- Pick a random free tile
		local position = freeTiles[math.random(1, #freeTiles)]

		-- Set the object's position to that of our chosen tile
		o.position = {x = position.x, y = position.y}

		-- Remove this tile from the freeTiles table
		table.remove(freeTiles, i)

		-- Add this object to the room
		self.room:add_object(o)
	end
end

function RoomFiller:add_objects(num, fTest, fNew, freeTiles)
	args = {}
	for i = 1, num do
		for tries = 1, 5 do
			local position = freeTiles[math.random(1, #freeTiles)]

			local ok = true
			if fTest == nil then
				-- Default test function: Don't place in occupied tile
				if self.room:tile_occupied(position) then
					ok = false
				end
			else
				testResult = fTest(self, position)
				ok = testResult.ok
				for k,v in pairs(testResult) do
					if k ~= 'ok' then
						args[k] = v
					end
				end
			end

			if ok then
				args.position = position
				self.room:add_object(fNew(args))
				break
			end
		end
	end
end

function RoomFiller:add_turrets(numTurrets)
	fTest =
		function(roomFiller, pos)
			-- Find a direction in which we can fire
			dirs = {1, 2, 3, 4}
			print()
			while #dirs > 0 do
				index = math.random(1, #dirs)
				dir = dirs[index]
				pos2 = {x = pos.x, y = pos.y}

				-- Find the coordinates of three spaces ahead
				if dir == 1 then
					pos2.y = pos2.y - 3 -- North
				elseif dir == 2 then
					pos2.x = pos2.x + 3 -- East
				elseif dir == 3 then
					pos2.y = pos2.y + 3 -- South
				elseif dir == 4 then
					pos2.x = pos2.x - 3 -- West
				end

				-- Check if there is a line of sight between these tiles
				if roomFiller.room:line_of_sight(pos, pos2) then
					return {dir = dir, ok = true}
				else
					table.remove(dirs, index)
				end
			end
			return {ok = false}
		end
	fNew =
		function(pos)
			return Turret(args.position, args.dir, 5 * math.random(1, 10))
		end
	self:add_objects(numTurrets, fTest, fNew, self.room.bricks)
end

function RoomFiller:fill()
	-- Add turrets
	local numTurrets = math.random(0, #self.room.bricks * .03)
	self:add_turrets(numTurrets)

	-- Add monsters
	local maxMonsters = #self.room.freeTiles * .04
	self:add_monsters(maxMonsters)

	-- Add items
	--local numItems = math.random(0, #self.room.freeTiles * .02)
	--local fNew = function(pos) return Item(args.position, math.random(1, 2)) end
	--self:add_objects(numItems, nil, fNew, self.room.freeTiles)
end
