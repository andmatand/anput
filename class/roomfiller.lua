require 'class/monster.lua'
require 'class/turret.lua'

-- A RoomFiller fills a room with monsters, items
RoomFiller = class('RoomFiller')

function RoomFiller:init(room)
	self.room = room
end

function RoomFiller:fill()
	-- Add turrets
	numTurrets = math.random(0, #self.room.bricks * .03)
	for i = 1, numTurrets do
		pos = self.room.bricks[math.random(1, #self.room.bricks)]

		-- Find a direction in which we can fire
		ok = false
		dirs = {1, 2, 3, 4}
		while #dirs > 0 do
			index = math.random(1, #dirs)
			dir = dirs[index]
			print('testing turret direction ' .. dir)
			pos2 = {x = pos.x, y = pos.y}

			-- Find the coordinates of three spaces ahead
			if dir == 1 then
				pos2.y = pos2.y - 2 -- North
			elseif dir == 2 then
				pos2.x = pos2.x + 2 -- East
			elseif dir == 3 then
				pos2.y = pos2.y + 2 -- South
			elseif dir == 4 then
				pos2.x = pos2.x - 2 -- West
			end

			-- Check if there is a line of sight between these tiles
			if self.room:line_of_sight(pos, pos2) then
				ok = true
				break
			else
				table.remove(dirs, index)
			end
		end

		if ok then
			self.room:add_turret(Turret({x = pos.x, y = pos.y},
			                            dir, math.random(10, 70)))
			print('added turret')
		end
	end

	-- Add monsters
	numMonsters = math.random(0, #self.room.freeTiles * .04)
	for i = 1, numMonsters do
		pos = self.room.freeTiles[math.random(1, #self.room.freeTiles)]

		-- Don't place monster on top of another sprite
		ok = true
		--for i,s in pairs(self.room.sprites) do
		--	if tiles_overlap(pos, s.position) then
		--		ok = false
		--	end
		--end
		if self.room:tile_occupied(pos) then
			ok = false
		end

		if ok then
			self.room:add_sprite(Monster(pos, 1))
		end
	end
end
