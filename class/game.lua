require 'class/map.lua'
require 'class/player.lua'

-- A Game handles a collection of rooms
Game = class()

function Game:init()
	self.keyState = 0
	self.frameState = 1 -- 0: erase, 1: draw
end

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
	if flickerMode and self.frameState == 0 then
		self.currentRoom:erase()
	else
		self.currentRoom:draw()
	end
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
	--if key == 'w' then
	--	self.player.velocity.y = -1
	--elseif key == 's' then
	--	self.player.velocity.y = 1
	--elseif key == 'a' then
	--	self.player.velocity.x = -1
	--elseif key == 'd' then
	--	self.player.velocity.x = 1
	--end

	-- Shoot arrows
	shootDir = nil
	if key == 'up' then
		shootDir = 1
	elseif key == 'right' then
		shootDir = 2
	elseif key == 'down' then
		shootDir = 3
	elseif key == 'left' then
		shootDir = 4
	end
	if shootDir ~= nil then
		self.currentRoom:character_shoot(self.player, shootDir)
	end
end

function Game:keydown()
	if self.keyState == 0 then
		self.keyState = 1
		self.keyTimer = love.timer.getTime()
	end
	if self.keyState == 1 and love.timer.getTime() > self.keyTimer + .05 then
		self.keyState = 2
	end
	self.keyState = 2 -- DEBUG
end

function Game:keyOkay()
	if self.keyState == 0 or self.keyState == 2 then
		return true
	else
		return false
	end
end

function Game:update()
	if flickerMode and self.frameState == 0 then
		self.frameState = 1
		return
	else
		self.frameState = 0
	end

	if love.keyboard.isDown('w') then
		if self:keyOkay() then
			self.player:step(1)
		end
		self:keydown()
	elseif love.keyboard.isDown('d') then
		if self:keyOkay() then
			self.player:step(2)
		end
		self:keydown()
	elseif love.keyboard.isDown('s') then
		if self:keyOkay() then
			self.player:step(3)
		end
		self:keydown()
	elseif love.keyboard.isDown('a') then
		if self:keyOkay() then
			self.player:step(4)
		end
		self:keydown()
	else
		self.keyState = 0
	end

	self.currentRoom:update()

	-- Switch rooms when player is on an exit
	for i,e in pairs(self.currentRoom.exits) do
		if tiles_overlap(self.player.position, e) then
			self:switch_to_room(e.roomIndex)
			break
		end
	end
end
