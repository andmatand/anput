require('item')
require('monster')
require('turret')

-- A RoomFiller fills a room with monsters, items
RoomFiller = class('RoomFiller')

function RoomFiller:init(room)
	self.room = room
end

function RoomFiller:add_objects(num, fTest, fNew, freeTiles)
	args = {}
	for i = 1, num do
		for tries = 1, 5 do
			position = freeTiles[math.random(1, #freeTiles)]

			ok = true
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
	numTurrets = math.random(0, #self.room.bricks * .03)
	self:add_turrets(numTurrets)

	-- Find difficulty percentage based on distance from the final room
	easiness = self.room.distanceFromEnd / game.rooms[1].distanceFromEnd

	-- Add monsters
	maxMonsters = #self.room.freeTiles * .04
	--numMonsters = math.random(0, (maxMonsters - (maxMonsters * easiness)))
	numMonsters = maxMonsters - ((maxMonsters * easiness) - 1)
	fNew = function(args) return Monster(args.position, math.random(1, 5)) end
	self:add_objects(numMonsters, nil, fNew, self.room.freeTiles)

	-- Add items
	numItems = math.random(0, #self.room.freeTiles * .02)
	fNew = function(pos) return Item(args.position, math.random(1, 2)) end
	self:add_objects(numItems, nil, fNew, self.room.freeTiles)
end
