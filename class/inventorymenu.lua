-- An InventoryMenu is a visual representation of a character's items and a
-- menu system for interacting with them
InventoryMenu = class('InventoryMenu')

function InventoryMenu:init(owner)
    self.owner = owner

    self.position = {x = ROOM_W, y = 2}
    self.size = {w = 11, h = 11}
    self.selectedItemNum = nil
end

function InventoryMenu:draw()
    local x = (SCREEN_W / 2) - (self.size.w / 2)
    local y = (SCREEN_H / 2) - (self.size.h / 2)

    -- Draw a border
    love.graphics.setColor(WHITE)
    love.graphics.rectangle('fill',
                            upscale_x(x), upscale_y(y),
                            upscale_x(self.size.w),
                            upscale_y(self.size.h))
    love.graphics.setColor(BLACK)
    love.graphics.rectangle('fill',
                            upscale_x(x + 1), upscale_y(y + 1),
                            upscale_x(self.size.w - 2),
                            upscale_y(self.size.h - 2))

    -- Scale everything 2x
    love.graphics.push()
    love.graphics.scale(2, 2)

    -- Set x, y to center of box
    x = ((SCREEN_W / 2) / 2) - .5
    y = ((SCREEN_H / 2) / 2) - .5

    -- Draw the player in the middle
    self.owner:draw({x = x, y = y})

    local itemPositions = {{x = x, y = y - 1.5},
                           {x = x + 1.5, y = y},
                           {x = x, y = y + 1.5},
                           {x = x - 1.5, y = y}}

    -- Draw each item
    local i = 0
    for _, item in ipairs(self.owner.inventory.items) do
        if item ~= self.owner.armory.currentWeapon then
            i = i + 1
            item.position = itemPositions[i]
            item:draw()
        end
    end

    love.graphics.pop()

    if true then
        return
    end

    -- Draw each item
    if self.owner.inventory then
        x = self.position.x
        y = y + 1

        -- Get totals for each item type
        local invTotals = {}
        for _, i in pairs(self.owner.inventory.items) do
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
        for _, i in pairs(self.owner.inventory:get_non_weapons()) do
            -- If we haven't already displayed an item of this type
            if invTotals[i.itemType] ~= nil then
                itemNum = itemNum + 1

                -- If this type isn't in oldInvTotals yet
                if oldInvTotals[i.itemType] == nil then
                    -- Set it to zero so we can compare it numerically,
                    -- later
                    oldInvTotals[i.itemType] = 0
                end

                -- If the count increased since last time and the item has
                -- more than one frame
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
                                            upscale_x(x), upscale_y(y),
                                            TILE_W, TILE_H)
                end

                -- Draw the item
                i.position = {x = x, y = y}
                love.graphics.setColor(WHITE)
                i:draw()

                -- If there is more than one of this type of item
                if invTotals[i.itemType] > 1 then
                    -- Print the total number of this type of item
                    cga_print(tostring(invTotals[i.itemType]), x + 1, y)
                    x = x + tostring(invTotals[i.itemType]):len() + 1
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

function InventoryMenu:update()
end

function InventoryMenu:move_cursor(dir)
    if dir == 'up' then
    end
end
