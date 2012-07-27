require('class.toast')

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

-- A StatusBar is a horizontal line at the bottom of the screen which displays
-- health, ammo, etc.
StatusBar = class('StatusBar')

function StatusBar:init(owner)
    self.owner = owner

    self.position = {x = ROOM_W, y = 2}
    self.selectedItemNum = nil

    self.healthMeter = {toast = Toast()}
    self.newestItem = {item = nil, toast = Toast()}

    self.flash = {timer = 0, state = true}
end

function StatusBar:draw()
    local x = 0
    local y = ROOM_H

    -- Display the health meter
    self:draw_health_meter()

    -- Display the most recently picked up item for a few seconds
    self:draw_newest_item()

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

            cga_print(tostring(w.ammo), x, y, {color = textColor})
        end
    end
end

function StatusBar:draw_health_meter()
    if self.owner.health < 100 then
        self.healthMeter.toast:show()
        self.healthMeter.toast:freeze()
    end

    -- If the health meter is positioned offscreen
    if not self.healthMeter.toast:is_visible() then
        -- Don't bother drawing it
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
    
    local x = 0
    local y = self.healthMeter.toast:get_y()

    draw_progress_bar({num = self.owner.health, max = 100,
                       color = MAGENTA, borderColor = borderColor},
                      upscale_x(x) + SCALE_X,
                      --upscale_y(y + .5) - SCALE_Y,
                      y + (upscale_y(1) / 2) - SCALE_Y,
                      upscale_x(8) - (SCALE_X * 2),
                      upscale_y(1) / 2)
end

function StatusBar:draw_newest_item()
    if self.owner.inventory.newestItem then
        -- If the owner's newest item is different than the previous newest
        -- item we displayed, and it's not a weapon
        if (self.owner.inventory.newestItem ~= self.newestItem.item and
            not instanceOf(Weapon, self.owner.inventory.newestItem)) then
            self.newestItem.item = self.owner.inventory.newestItem
            self.newestItem.toast:show()
        end
    else
        self.newestItem.item = nil
        return
    end

    if self.newestItem.toast:is_visible() then
        local x = upscale_x((ROOM_W / 2) - 1)
        local y = self.newestItem.toast:get_y()
        local num =
            #self.owner.inventory:get_items(self.newestItem.item.itemType)

        love.graphics.setColor(WHITE)
        love.graphics.print(num, x, y)
        self.newestItem.item:draw({x = x + (upscale_x(1) *
                                            tostring(num):len()),
                                   y = y})
    end
end

function StatusBar:update()
    -- If the health meter is full
    if self.owner.health >= 100 then
        self.healthMeter.toast:unfreeze()
    end

    -- Update the toast popups
    self.healthMeter.toast:update()
    self.newestItem.toast:update()

    -- If there is an item popup showing, and the game is not paused
    if (self.newestItem.item and self.newestItem.toast:is_visible() and
        not self.owner.room.game.paused) then
        -- Update the newestItem's animation
        self.newestItem.item:update()
    end

    -- Decrement the flash timer
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
