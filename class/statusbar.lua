require('class.toast')
require('util.graphics')

-- A StatusBar is a horizontal line at the bottom of the screen which displays
-- health, ammo, etc.
StatusBar = class('StatusBar')

function StatusBar:init(owner, game)
    self.owner = owner
    self.game = game

    self.position = {x = ROOM_W, y = ROOM_H}
    self.selectedItemNum = nil

    self.healthMeter = {toast = Toast()}
    self.newestItem = {item = nil, toast = Toast()}

    self.contextMessage = {buttons = {}, text = nil}

    self.flash = {timer = 0, state = true}
end

function StatusBar:draw()
    local x = 0
    local y = self.position.y

    if self.game.paused then
        -- Draw a black background behind the entire statusbar line
        love.graphics.setColor(BLACK)
        love.graphics.rectangle('fill', x, upscale_y(y),
                                upscale_x(ROOM_W), upscale_y(1))
    end

    -- Display the health meter
    self:draw_health_meter()

    -- Display the ammo for the current weapon
    local w = self.owner.armory.currentWeapon
    if w and w:get_ammo() then
        -- If this weapon is magic
        if w.isMagic then
            x = GRID_W - 8
            -- Draw a progress bar
            draw_progress_bar({num = w:get_ammo(), max = 100,
                               color = CYAN},
                              upscale_x(x) + SCALE_X,
                              upscale_y(y + .5) - SCALE_Y,
                              upscale_x(8) - (SCALE_X * 2),
                              upscale_y(1) / 2)
        else
            x = GRID_W - 1

            -- If this weapon shoots projectiles
            if w.projectileClass then
                -- Draw a picture of that projectile
                local proj = w.projectileClass(nil, 1)
                proj.position = {x = x, y = y}
                proj.new = false
                proj:draw()
            end

            x = x - string.len(w:get_ammo())
            textColor = WHITE

            -- If the weapon is out of ammo
            if w:get_ammo() == 0 then
                -- Flash the number
                if self.flash.state then
                    textColor = BLACK
                end
            end

            cga_print(tostring(w:get_ammo()), x, y, {color = textColor})
        end
    end

    if not self.game.paused then
        -- Display the most recently picked up item for a few seconds
        self:draw_newest_item()

        self:draw_context_message()
    end
end

function StatusBar:draw_context_message()
    if not self.contextMessage.text then
        return
    end

    -- Find the total width (in pixels) of the concatenated buttons, a space,
    -- and the text
    local totalWidth = 0
    for _, key in pairs(self.contextMessage.buttons) do
        totalWidth = totalWidth +
                     (images.buttons[key]:getWidth() * SCALE_X) + SCALE_X
    end
    totalWidth = totalWidth + upscale_x(1 + self.contextMessage.text:len())

    local x = upscale_x(ROOM_W / 2) - (totalWidth / 2)

    -- Draw the buttons
    love.graphics.setColor(WHITE)
    for _, key in pairs(self.contextMessage.buttons) do
        love.graphics.draw(images.buttons[key],
                           x, upscale_y(self.position.y),
                           0, SCALE_X, SCALE_Y)
        x = x + (images.buttons[key]:getWidth() * SCALE_X) + SCALE_X
    end

    -- Draw the text
    cga_print(' ' .. self.contextMessage.text, nil, nil,
              {position = {x = x, y = upscale_y(self.position.y)}})
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

    if self.newestItem.toast:is_visible() and self.newestItem.item then
        local x = upscale_x((ROOM_W / 2) - 1)
        local y = self.newestItem.toast:get_y()
        local num =
            #self.owner.inventory:get_items(self.newestItem.item.itemType)

        cga_print(num, nil, nil, {position = {x = x, y = y}})
        self.newestItem.item:draw({x = x + (upscale_x(1) *
                                            tostring(num):len()),
                                   y = y})
    end
end

function StatusBar:show_context_message(buttons, text)
    self.contextMessage = {buttons = buttons, text = text}
end

function StatusBar:update()
    self.contextMessage.text = nil

    -- If the health meter is full
    if self.owner.health >= 100 then
        self.healthMeter.toast:unfreeze()
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

    if self.game.paused then
        -- Freeze the newestItem popup
        self.newestItem.toast:freeze()
    else
        self.newestItem.toast:unfreeze()
    end

    -- Update the health toast popups
    self.healthMeter.toast:update()
    self.newestItem.toast:update()

    if not self.game.paused then
        -- If there is an item popup showing
        if self.newestItem.item and self.newestItem.toast:is_visible() then
            -- Update the newestItem's animation
            self.newestItem.item:update()
        end
    end
end
