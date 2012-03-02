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
	print('room distance from start:', self.currentRoom.distanceFromStart)
	print('room difficulty:', self.currentRoom.difficulty)

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
	bar.h = h - (SCALE_Y * 2)
	
	-- Draw border
	love.graphics.setColor(255, 255, 255)
	love.graphics.rectangle('fill', x, y, w, h)

	-- Draw black bar inside
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle('fill', bar.x, bar.y, bar.w, bar.h)

	-- Set width of bar
	bar.w = (barInfo.num * bar.w) / barInfo.max

	-- Draw progress bar
	love.graphics.setColor(barInfo.color)
	love.graphics.rectangle('fill', bar.x, bar.y, bar.w, bar.h)
end

function Game:draw_sidepane()
	love.graphics.setColor(255, 255, 255)

	-- Display HP
	--self:print('HP', ROOM_W, 0)
	--love.graphics.draw(healthImg,
	--				   ROOM_W * TILE_W, 0 * TILE_H, 0, SCALE_X, SCALE_Y)
	self:draw_progress_bar({num = self.player.health, max = 100,
	                        color = MAGENTA},
	                       (ROOM_W + 2) * TILE_W, 2,
						   (SCREEN_W - ROOM_W - 2) * TILE_W, TILE_H - 4)

	-- Display weapons
	for _,w in pairs(self.player.weapons) do
		-- Draw box around current weapon
		--if self.player.currentWeapon == w then
		--	love.graphics.setColor(MAGENTA)
		--	love.graphics.setLine(2, 'rough')
		--	love.graphics.rectangle('line',
		--	                        ROOM_W * TILE_W, 
		--							((1 + w.order) * TILE_H) + 1,
		--	                        TILE_W,
		--	                        TILE_H)
		--end

		-- Highlight current weapon
		if self.player.currentWeapon == w then
			love.graphics.setColor(MAGENTA)
		else
			love.graphics.setColor(WHITE)
		end
		--love.graphics.setColor(WHITE)
		w:draw({x = ROOM_W, y = 1 + w.order})

		-- If this weapon has a maximum ammo
		if w.maxAmmo ~= nil then
			-- Draw a progress bar
			self:draw_progress_bar({num = w.ammo, max = w.maxAmmo,
			                        color = CYAN},
			                       (ROOM_W + 2) * TILE_W,
			                       ((1 + w.order) * TILE_H) + 2,
			                       ((SCREEN_W - ROOM_W - 2) * TILE_W) - 2,
			                       TILE_H - 4)
		-- If this weapon has an arbitrary amount of ammo
		elseif w.ammo ~= nil then
			-- Display the numeric ammount of ammo
			love.graphics.setColor(WHITE)
			self:print(w.ammo, ROOM_W + 2, 1 + w.order)
		end
	end

	-- Display inventory
	if self.player.inventory ~= nil then
		-- Get totals for each item type
		local invTotals = {}
		for _, i in pairs(self.player.inventory) do
			-- If there is no total for this type yet
			if invTotals[i.itemType] == nil then
				-- Initialize it to 0
				invTotals[i.itemType] = 0
			end

			-- Add 1 to the total for this tyep
			invTotals[i.itemType] = invTotals[i.itemType] + 1
		end

		-- Create oldInvTotals table
		if oldInvTotals == nil then
			oldInvTotals = {}
		end

		local x = ROOM_W
		local y = 7
		for _, i in pairs(self.player.inventory) do
			-- If we haven't already displayed an item of this type
			if invTotals[i.itemType] ~= nil then
				-- If this type isn't in oldInvTotals yet
				if oldInvTotals[i.itemType] == nil then
					-- Set it to zero so we can compare it numerically
					oldInvTotals[i.itemType] = 0
				end

				-- If the count increased since last time
				if (oldInvTotals[i.itemType] < invTotals[i.itemType]) then
					-- Run the item's animation once through
					i.animationEnabled = true
					i.currentFrame = 2
				elseif i.currentFrame == 1 then
					-- Stop the animation at frame 1
					i.animationEnabled = false
				end

				love.graphics.setColor(WHITE)

				-- Draw the item
				i.position = {x = x, y = y}
				i:draw()

				-- Print the total number of this type of item
				self:print(invTotals[i.itemType], x + 2, y)

				y = y + 1

				-- Save the old count
				oldInvTotals[i.itemType] = invTotals[i.itemType]

				-- Mark this inventory type as already displayed
				invTotals[i.itemType] = nil
			end
		end
	end

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
	elseif (key == 'tab' or key == 'lshift' or key == 'rshift' or
	        key == 'rctrl') then
		-- Cycle through weapons
		changedWeapon = false
		for _,w in pairs(self.player.weapons)  do
			-- If this weapons order is 1 more than that of the current weapon
			if w.order == self.player.currentWeapon.order + 1 then
				self.player:set_current_weapon(w.order)
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

	if self.player.weapons.staff ~= nil then
		-- Recharge the staff
		
		-- If player didn't move
		if self.player.moved == false then
			-- Recharge faster
			amount = .5
		else
			-- Recharge slowly
			amount = .25
		end
		self.player.weapons.staff:add_ammo(amount)
	end
end
