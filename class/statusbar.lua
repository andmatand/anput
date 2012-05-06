local function draw_progress_bar(barInfo, x, y, w, h)
    bar = {}
    bar.x = x + SCALE_X
    bar.y = y + SCALE_Y
    bar.w = w - (SCALE_X * 2)
    bar.h = h - (SCALE_Y * 2)
    
    -- Draw border
    love.graphics.setColor(barInfo.borderColor or WHITE)
    love.graphics.rectangle('fill', x, y, w, h)

    -- Draw black bar inside
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle('fill', bar.x, bar.y, bar.w, bar.h)

    -- Set width of bar
    bar.w = (barInfo.num * bar.w) / barInfo.max
    bar.w = math.floor(bar.w / SCALE_X) * SCALE_X

    -- Draw progress bar
    love.graphics.setColor(barInfo.color)
    love.graphics.rectangle('fill', bar.x, bar.y, bar.w, bar.h)
end

-- An StatusBar is a horizontal line at the bottom of the screen which displays
-- health, ammo, etc.
StatusBar = class('StatusBar')

function StatusBar:init(owner)
    self.owner = owner

    self.position = {x = ROOM_W, y = 2}
    self.selectedItemNum = nil
    self.healthMeterPos = {x = 0, y = ROOM_H}
    self.healthMeterOffset = {x = 0, y = 0}
    self.healthMeterHideTimer = 0
    self.flash = {timer = 0, state = true}
end

function StatusBar:draw()
    local x = 0
    local y = ROOM_H

    -- Display the health meter
    self:draw_health_meter()

    -- Display the ammo for the current weapon
    local w = self.owner.armory.currentWeapon
    if w and w.ammo then
        -- If this weapon shoots projectiles
        if w.projectileClass then
            x = SCREEN_W - 1

            -- Draw a picture of that projectile
            local proj = w.projectileClass(nil, 1)
            proj.position = {x = x, y = y}
            proj.new = false
            proj:draw()
        end

        -- If this weapon has a maximum ammo
        if w.maxAmmo then
            x = x - 8
            -- Draw a progress bar
            draw_progress_bar({num = w.ammo, max = w.maxAmmo, color = CYAN},
                              upscale_x(x) + SCALE_X,
                              upscale_y(y + .5) - SCALE_Y,
                              upscale_x(8) - (SCALE_X * 2),
                              upscale_y(1) / 2)
        else
            x = x - string.len(w.ammo)
            textColor = WHITE

            -- If the weapon is out of ammo
            if w.ammo == 0 then
                -- Flash the number
                if self.flash.state then
                    textColor = BLACK
                end
            end

            cga_print(tostring(w.ammo), x, y, textColor)
        end
    end

    if not game.paused then
        return
    end

    -- Display items
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

function StatusBar:draw_health_meter()
    if self.owner.health < 100 then
        --self.displayHealth = true
        self.healthMeterOffset.y = 0
    end

    -- If the health meter is positioned offscreen
    if self.healthMeterOffset.y > TILE_H then
        return
    end

    -- Flash the border of the health meter when the owner is hurt
    local borderColor
    if self.owner.flashTimer == 0 then
        borderColor = WHITE
    else
        borderColor = BLACK
    end

    -- If owner is dead
    if self.owner.health == 0 then
        borderColor = MAGENTA
    -- If owner's health is very low
    elseif self.owner.health < 25 then
        -- Make the border flash magenta
        if self.flash.state then
            borderColor = MAGENTA
        end
    end
    
    local x = self.healthMeterPos.x
    local y = self.healthMeterPos.y

    draw_progress_bar({num = self.owner.health, max = 100,
                       color = MAGENTA, borderColor = borderColor},
                      upscale_x(x) + SCALE_X,
                      upscale_y(y + .5) - SCALE_Y + self.healthMeterOffset.y,
                      upscale_x(8) - (SCALE_X * 2),
                      upscale_y(1) / 2)
end

function StatusBar:update()
    -- If the health meter is full
    if self.owner.health >= 100 then
        -- If the timer is not already set, and the health meter hasn't
        -- started moving offscreen
        if (self.healthMeterHideTimer == 0 and
            self.healthMeterOffset.y == 0) then
            -- Set a delay before hiding it
            self.healthMeterHideTimer = fps

        -- Decrement the timer
        elseif self.healthMeterHideTimer > 0 then
            self.healthMeterHideTimer = self.healthMeterHideTimer - 1
        end

        -- If the delay period is over
        if (self.healthMeterHideTimer == 0 and
            self.healthMeterOffset.y < TILE_H + 1) then
            -- Hide the health meter
            self.healthMeterOffset.y = self.healthMeterOffset.y + SCALE_Y
        end
    end

    if self.flash.timer > 0 then
        self.flash.timer = self.flash.timer - 1
    else
        self.flash.timer = 1
        if self.flash.state then
            self.flash.state = false
        else
            self.flash.state = true
        end
    end
end

function StatusBar:move_cursor(dir)
    if dir == 'up' then
    end
end
