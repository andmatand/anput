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
    self.newItems = {}

    self.contextMessage = {buttons = {}, text = nil}

    self.flash = {timer = 0, state = true}
end

function StatusBar:add_new_item(newItem)
    -- Iterate through the items that are already queued up to show
    for _, existingItem in pairs(self.newItems) do
        -- If the new item is of the same type as this one
        if newItem.itemType == existingItem.item.itemType then
            -- Reset this item's toast instead of adding a new item
            existingItem.toast:show()
            return false
        end
    end

    -- Add the item to the queue
    local newToast = Toast()
    newToast:show()
    table.insert(self.newItems, {item = newItem, toast = newToast})
end

function StatusBar:draw()
    local x = 0
    local y = self.position.y

    if self.game:is_paused() then
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

    if not self.game:is_paused() then
        -- Display the most recently picked up item for a few seconds
        self:draw_new_item()

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

function StatusBar:draw_new_item()
    if self.newItems[1] and self:can_show_new_items() then
        local newItem = self.newItems[1]
        local x = upscale_x((ROOM_W / 2) - 1)
        local y = newItem.toast:get_y()

        local text

        -- If the newest item is a weapon
        --if #instanceOf(Weapon, newItem.item) then
        local num = #self.owner.inventory:get_items(newItem.item.itemType)
        if num == 1 then
            -- Show the weapon name
            text = ITEM_NAME[newItem.item.itemType]
        else
            -- Show the total number of this type of item in the inventory
            text = tostring(num)
        end

        if text then
            x = x - upscale_x(math.floor(text:len() / 2))
            cga_print(text, nil, nil, {position = {x = x, y = y}})
            x = x + upscale_x(text:len())
        end

        newItem.item:draw({x = x, y = y})
    end
end

function StatusBar:show_context_message(buttons, text)
    self.contextMessage = {buttons = buttons, text = text}
end

function StatusBar:update()
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

    self:update_new_items()

    -- Update the health toast popup
    self.healthMeter.toast:update()

    self.contextMessage.text = nil
end

function StatusBar:can_show_new_items()
    if self.game:is_paused() or self.contextMessage.text then
        return false
    else
        return true
    end
end

function StatusBar:update_new_items()
    -- If there is an item on the queue
    if self.newItems[1] then
        if self:can_show_new_items() then
            self.newItems[1].toast:unfreeze()
        else
            -- Freeze the item's toast
            self.newItems[1].toast:freeze()
        end

        self.newItems[1].toast:update()

        -- If the item has not gone all the way down offscreen yet
        if self.newItems[1].toast:is_visible() then
            if self:can_show_new_items() then
                -- Update the item's animation
                self.newItems[1].item:update()
            end
        else
            -- Remove the item from the queue
            table.remove(self.newItems, 1)
        end
    end
end
