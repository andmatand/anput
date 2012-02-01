require 'class/map.lua'
require 'class/player.lua'

-- A Game handles a collection of rooms
Game = class()

function Game:switch_to_room(roomIndex)
	print('switching to room ' .. roomIndex)

	prevRoom = self.currentRoom

	-- Make sure room has been generated
	if self.rooms[roomIndex].generated == false then
		self.rooms[roomIndex]:generate()
	end

	table.remove(self.currentRoom.sprites, 1)
	self.currentRoom = self.rooms[roomIndex]
	table.insert(self.currentRoom.sprites, 1, self.player)

	-- Move player to corresponding doorway
	exit = self.currentRoom:get_exit({roomIndex = prevRoom.index})
	self.player:move_to(exit:get_doorway())
end

function Game:draw()
	self.currentRoom:draw()
end

function Game:generate()
	mapPath = {}
	self.map = Map()
	self.rooms = self.map:generate()

	-- Generate the first room
	self.currentRoom = self.rooms[1]
	self.currentRoom:generate()

	-- Put a player in the first room
	self.player = Player()
	self.player:move_to(self.currentRoom.midPoint)
	table.insert(self.currentRoom.sprites, 1, self.player)
end

function Game:keypressed(key)
	if key == 'w' then
		self.player.velocity.y = -1
	elseif key == 's' then
		self.player.velocity.y = 1
	elseif key == 'a' then
		self.player.velocity.x = -1
	elseif key == 'd' then
		self.player.velocity.x = 1
	end

	-- Shoot arrows
	if key == 'up' then
		table.insert(self.currentRoom.sprites,
		             Arrow({x = self.player.position.x,
		                    y = self.player.position.y - 1},
		                   1))
	end
end

function Game:update()
	--if love.keyboard.isDown('a') then self.player.velocity.x = -1 end
	self.currentRoom:update()

	-- Switch rooms when player is on an exit
	for i,e in pairs(self.currentRoom.exits) do
		if tiles_overlap(self.player.position, e) then
			self:switch_to_room(e.roomIndex)
			break
		end
	end
end
