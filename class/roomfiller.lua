require 'class/monster.lua'

-- A RoomFiller fills a room with monsters, items
RoomFiller = class()

function RoomFiller:init(room)
	self.room = room
end

function RoomFiller:fill()
	numMonsters = math.random(0, #self.room.freeTiles * .10)
	for i = 1,numMonsters do
		pos = self.room.freeTiles[math.random(1, #self.room.freeTiles)]

		-- Don't place monster on top of another sprite
		ok = true
		for i,s in pairs(self.room.sprites) do
			if tiles_overlap(pos, s.position) then
				ok = false
			end
		end

		if ok then
			self.room:add_sprite(Monster(pos, 1))
		end
	end
end
