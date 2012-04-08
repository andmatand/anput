require('class/inventorydisplay')
require('class/map')
require('class/player')
require('util/tables')
require('util/tile')

-- A Game handles a collection of rooms
Game = class('Game')

function Game:init()
	self.frameState = 1 -- 0: erase, 1: draw
	self.showMap = true
	self.paused = false
end

function Game:do_background_jobs()
	if not self.currentRoom then
		return
	end

	for _, e in pairs(self.currentRoom.exits) do
		-- If the room that this exit leads to is not completely generated
		if not self.rooms[e.roomIndex].generated then
			self.rooms[e.roomIndex]:generate_next_piece()
			break
		end
	end
end

function Game:draw()
	if flickerMode and self.frameState == 0 then
		self.currentRoom:erase()
	else
		self.currentRoom:draw()
	end

	-- DEBUG: show turrets
	--for _,t in pairs(self.currentRoom.turrets) do
	--	love.graphics.setColor(255, 0, 0)
	--	love.graphics.circle('fill',
	--	                     (t.position.x * TILE_W) + (TILE_W / 2),
	--						 (t.position.y * TILE_H) + (TILE_H / 2), 8)
	--end

	self:draw_sidepane()
end

function Game:draw_sidepane()
	love.graphics.setColor(255, 255, 255)

	self.inventoryDisplay:draw()

	if self.showMap then
		self.map:draw(self.currentRoom)
	end

	if self.paused then
		love.graphics.setColor(255, 255, 255)
		cga_print('PAUSED', 11, 12)
	end
end

function Game:generate()
	-- DEBUG choose specific seed
	math.randomseed(39)

	-- Generate a new map
	self.map = Map()
	self.rooms = self.map:generate()

	-- Create a player
	self.player = Player()

	-- Switch to the first room and put the player at the midPoint
	self.player:move_to({x = 0, y = 0})
	self:switch_to_room(1)
	self.player:move_to(self.currentRoom.midPoint)

	-- Create an inventory display
	self.inventoryDisplay = InventoryDisplay(self.player)
end

function Game:input()
	if self.paused then
		return
	end

	-- Get player's directional input
	if love.keyboard.isDown('w') then
		self.player:step(1)
	elseif love.keyboard.isDown('d') then
		self.player:step(2)
	elseif love.keyboard.isDown('s') then
		self.player:step(3)
	elseif love.keyboard.isDown('a') then
		self.player:step(4)
	end

	-- Get monsters' directional input
	if self.currentRoom ~= nil then
		self.currentRoom:character_input()
	end
end

function Game:keypressed(key)
	-- Toggle pause
	if key == ' ' then
		self.paused = not self.paused
	end

	-- Get player input for switching weapons
	if key == '1' or key == '2' or key == '3' then
		-- Switch to specified weapon number, based on display order
		self.player.armory:switch_to_weapon_number(tonumber(key))
	elseif (key == 'tab' or key == 'lshift' or key == 'rshift' or
	        key == 'rctrl') then
		-- Switch to the next weapon
		self.player.armory:switch_to_next_weapon()
	end

	-- Get player input for using items
	if key == 'p' then
		-- Take a potion
		if self.player:has_item(ITEM_TYPE.potion) then
			self.player.inventory:get_item(ITEM_TYPE.potion):use()
		end
	end

	-- If the game is paused
	if self.paused then
		-- Allow wasd and arrows for selecting inventory items
		if key == 'w' or key == 'up' then
			self.inventoryDisplay:move_cursor('up')
		elseif key == 'd' or key == 'right' then
			self.inventoryDisplay:move_cursor('right')
		elseif key == 's' or key == 'down' then
			self.inventoryDisplay:move_cursor('down')
		elseif key == 'a' or key == 'left' then
			self.inventoryDisplay:move_cursor('left')
		end

		-- Don't allow keys below here
		return
	end

	-- Get player input for shooting arrows
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
		self.player:shoot(shootDir, self.currentRoom)
	end

	-- Get player input for moving when isDown in the input() method didn't see
	-- it
	if key == 'w' then
		self.player:step(1)
	elseif key == 'd' then
		self.player:step(2)
	elseif key == 's' then
		self.player:step(3)
	elseif key == 'a' then
		self.player:step(4)
	end

	-- Get player input for trading
	if key == 't' then
		self.player.wantsToTrade = true
	end

	-- DEBUG: toggle map with m
	if key == 'm' then
		self.showMap = not self.showMap
	end
end

function Game:keyreleased(key)
	if self.player.attackedDir == 1 and key == 'w' then
		self.player.attackedDir = nil
	elseif self.player.attackedDir == 2 and key == 'd' then
		self.player.attackedDir = nil
	elseif self.player.attackedDir == 3 and key == 's' then
		self.player.attackedDir = nil
	elseif self.player.attackedDir == 4 and key == 'a' then
		self.player.attackedDir = nil
	end
end

function Game:switch_to_room(roomIndex)
	print('switching to room ' .. roomIndex)

	prevRoom = self.currentRoom

	-- If there was a previous room
	if prevRoom then
		-- Remove player from previous room
		prevRoom:remove_sprite(self.player)

		-- Clear previous room's FOV cache to save memory
		prevRoom.fovCache = {}
	end

	-- Set the new room as the current room
	self.currentRoom = self.rooms[roomIndex]
	self.currentRoom.game = self
	self.currentRoom.visited = true
	print('room distance from start:', self.currentRoom.distanceFromStart)
	print('room difficulty:', self.currentRoom.difficulty)

	-- Add player to current room
	self.currentRoom:add_object(self.player)

	-- Move player to corresponding doorway
	if prevRoom ~= nil then
		exit = self.currentRoom:get_exit({roomIndex = prevRoom.index})
		self.player:move_to(exit:get_doorway())
	end

	-- Make sure room has been completely generated
	if not self.rooms[roomIndex].generated then
		self.rooms[roomIndex]:generate_all()
	end

	-- Update the new current room
	self.currentRoom:update()
end

function Game:update()
	if self.paused then
		return
	end

	if flickerMode and self.frameState == 0 then
		self.frameState = 1
		return
	else
		self.frameState = 0
	end

	self:input()

	-- Update the current room
	self.currentRoom:update()

	-- Switch rooms when player is on an exit
	for _, e in pairs(self.currentRoom.exits) do
		if tiles_overlap(self.player.position, e) then
			self:switch_to_room(e.roomIndex)
			break
		end
	end

	-- Update the player's inventory items (for animations)
	for _, i in pairs(self.player.inventory.items) do
		i:update()
	end
end
