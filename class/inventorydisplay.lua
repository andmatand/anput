-- An InventoryDisplay is a visual representation of a character's inventory,
-- i.e. weapons and items
InventoryDisplay = class('InventoryDisplay')

function InventoryDisplay:init(owner)
	self.owner = owner

	self.position = {x = ROOM_W, y = 2}
	self.selectedItemNum = nil
end

function InventoryDisplay:draw()
	local x = self.position.x
	local y = self.position.y

	-- DEBUG
	--print('InventoryDisplay says this is inventory:')
	--for k, v in pairs(self.owner.inventory) do
	--	print(k, v)
	--end

	-- Display HP
	--love.graphics.draw(healthImg,
	--				   x * TILE_W, 0 * TILE_H, 0, SCALE_X, SCALE_Y)
	x = x + 2
	self:draw_progress_bar({num = self.owner.health, max = 100,
	                        color = MAGENTA},
	                       x * TILE_W, 2,
						   (SCREEN_W - x) * TILE_W, TILE_H - 4)

	if self.owner.weapons then
		local numWeapons = 0
		x = self.position.x

		-- Display weapons
		for k, w in pairs(self.owner.weapons) do
			y = self.position.y + (w.order - 1)

			love.graphics.setColor(WHITE)
			w:draw({x = x, y = y})

			-- If this is the bow
			if w.projectileClass then
				x = x + 1
				-- Draw a picture of that projectile
				local proj = w.projectileClass(nil, 1)
				proj.position = {x = x, y = y}
				proj.new = false
				proj:draw()
			end

			-- If this weapon has a maximum ammo
			if w.maxAmmo then
				x = x + 1
				-- Draw a progress bar
				self:draw_progress_bar({num = w.ammo, max = w.maxAmmo,
										color = CYAN},
									   x * TILE_W,
									   (y * TILE_H) + 2,
									   ((SCREEN_W - x) * TILE_W) - 2,
									   TILE_H - 4)
			-- If this weapon has an arbitrary amount of ammo
			elseif w.ammo then
				-- Display the numeric ammount of ammo
				x = x + 1
				love.graphics.setColor(WHITE)
				tile_print(w.ammo, x, y)
			end

			x = self.position.x
			numWeapons = numWeapons + 1
		end

		y = self.position.y + numWeapons
	end

	-- Display items
	if self.owner.inventory then
		x = self.position.x
		y = y + 1

		-- Get totals for each item type
		local invTotals = {}
		for _, i in pairs(self.owner.inventory) do
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

		-- Display each item type and its total
		local itemNum = 0
		for _, i in pairs(self.owner.inventory) do
			-- If we haven't already displayed an item of this type
			if invTotals[i.itemType] ~= nil then
				itemNum = itemNum + 1

				-- If this type isn't in oldInvTotals yet
				if oldInvTotals[i.itemType] == nil then
					-- Set it to zero so we can compare it numerically, later
					oldInvTotals[i.itemType] = 0
				end

				-- If the count increased since last time and the item has more
				-- than one frame
				if (oldInvTotals[i.itemType] < invTotals[i.itemType] and
				    #i.frames > 1) then
					-- Run the item's animation once through
					i.animationEnabled = true
					i.currentFrame = 2
				elseif i.currentFrame == 1 then
					-- Stop the animation at frame 1
					i.animationEnabled = false
				end

				-- Highlight current item
				if itemNum == self.selectedItemNum then
					love.graphics.setColor(MAGENTA)
					love.graphics.rectangle('fill',
					                        x * TILE_W, y * TILE_H,
					                        TILE_W, TILE_H)
				end

				-- Draw the item
				i.position = {x = x, y = y}
				love.graphics.setColor(WHITE)
				i:draw()

				-- If there is more than one of this type of item
				if invTotals[i.itemType] > 1 then
					-- Print the total number of this type of item
					tile_print(invTotals[i.itemType], x + 1, y)
					x = x + 1
				end

				-- Save the old count
				oldInvTotals[i.itemType] = invTotals[i.itemType]

				-- Mark this inventory type as already displayed
				invTotals[i.itemType] = nil

				x = x + 1
				if x > SCREEN_W then
					x = self.position.x
					y = y + 1
				end
			end
		end
	end
end

function InventoryDisplay:draw_progress_bar(barInfo, x, y, w, h)
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


function InventoryDisplay:move_cursor(dir)
	if dir == 'up' then
	end
end
