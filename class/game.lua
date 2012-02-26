require('map')
require('player')
require('table')
require('tile')

-- A Game handles a collection of rooms
Game = class('Game')

function Game:init()
	self.frameState = 1 -- 0: erase, 1: draw
	self.showMap = true
	self.paused = false
end

function Game:switch_to_room(roomIndex)
	print('switching to room ' .. roomIndex)

	prevRoom = self.currentRoom

	-- Remove player from previous room
	if prevRoom ~= nil then
		prevRoom:remove_sprite(self.player)
	end

	-- Set the new room as the current room
	self.currentRoom = self.rooms[roomIndex]
	self.currentRoom.visited = true
	print('room distance from end:', self.currentRoom.distanceFromEnd)

	-- Add player to current room
	self.currentRoom:add_object(self.player)

	-- Move player to corresponding doorway
	if prevRoom ~= nil then
		exit = self.currentRoom:get_exit({roomIndex = prevRoom.index})
		self.player:move_to(exit:get_doorway())
	end

	-- Make sure room has been generated
	if self.rooms[roomIndex].generated == false then
		self.rooms[roomIndex]:generate()
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

	if self.showMap then
		self.map:draw(self.currentRoom)
	end

	self:draw_sidepane()
end

function Game:draw_progress_bar(barInfo, x, y, w, h)
	bar = {}
	bar.x = x + SCALE_X
	bar.y = y + SCALE_Y
	bar.w = w - (SCALE_X * 2)
	bar.h = TILE_H - (SCALE_Y * 2)
	
	-- Draw border
	love.graphics.setColor(255, 255, 255)
	love.graphics.rectangle('fill', x, y, w, h)

	-- Draw black bar inside
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle('fill', bar.x, bar.y, bar.w, bar.h)

	-- Set width of bar
	bar.w = (barInfo.num * bar.w) / barInfo.max

	-- Draw progress bar
	love.graphics.setColor(255, 0, 255)
	love.graphics.rectangle('fill', bar.x, bar.y, bar.w, bar.h)
end

function Game:draw_sidepane()
	love.graphics.setColor(255, 255, 255)

	-- Display HP
	self:print('HP', ROOM_W, 0)
	self:draw_progress_bar({num = self.player.health, max = 100},
	                       (ROOM_W + 3) * TILE_W, 0,
						   (SCREEN_W - ROOM_W - 3) * TILE_W, TILE_H)

	for _,w in pairs(self.player.weapons) do
		if self.player.currentWeapon == w then
			love.graphics.setColor(255, 0, 255)
		else
			love.graphics.setColor(255, 255, 255)
		end

		w:draw({x = ROOM_W, y = 1 + w.order})

		-- If this weapon has ammo
		if w.ammo ~= nil then
			-- Display the ammount of ammo
			self:print(w.ammo, ROOM_W + 2, 1 + w.order)
		end
	end

	--self:print('ARROWS: ' .. self.player.weapons.bow.ammo, ROOM_W, 1)
	--self:print('MAGIC: ' .. self.player.magic.ammo, ROOM_W, 2)
	if self.paused then
		love.graphics.setColor(255, 255, 255)
		self:print('PAUSED', ROOM_W, 6)
	end
end

function Game:generate()
	-- Generate a new map
	mapPath = {}
	self.map = Map()
	self.rooms = self.map:generate()

	-- Create a player
	self.player = Player()

	-- Switch to the first room and put the player at the midPoint
	self:switch_to_room(1)
	self.player:move_to(self.currentRoom.midPoint)
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
		-- Switch to weapon by specific number
		self.player:set_current_weapon(tonumber(key))
	elseif key == 'tab' then
		-- Cycle through weapons
		changedWeapon = false
		for _,w in pairs(self.player.weapons)  do
			-- If this weapons order is 1 more than that of the current weapon
			if w.order == self.player.currentWeapon.order + 1 then
				self.player.currentWeapon = w
				changedWeapon = true
				break
			end
		end
		-- If we haven't changed weapons yet
		if changedWeapon == false then
			-- Change to the first weapon
			self.player:set_current_weapon(1)
		end
	end

	-- If the game is paused
	if self.paused then
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

function Game:print(text, x, y)
	love.graphics.print(text, x * TILE_W, y * TILE_H, 0, SCALE_X, SCALE_Y)
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
	self.currentRoom:update()

	-- Switch rooms when player is on an exit
	for i,e in pairs(self.currentRoom.exits) do
		if tiles_overlap(self.player.position, e) then
			self:switch_to_room(e.roomIndex)
			break
		end
	end
end
