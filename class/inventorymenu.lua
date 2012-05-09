require('util/tile')

local function first_line(string)
    local pos = string:find('\n')

    if pos then
        return string:sub(1, pos - 1)
    else
        return string
    end
end

-- An InventoryMenu is a visual representation of a character's items and a
-- menu system for interacting with them
InventoryMenu = class('InventoryMenu')

function InventoryMenu:init(owner)
    self.owner = owner

    self.size = {w = 11, h = 11}
    self.position = {x = math.floor((SCREEN_W / 2) - (self.size.w / 2)),
                     y = math.floor((SCREEN_H / 2) - (self.size.h / 2))}

    -- Set the center of the box
    local x, y
    x = self.position.x + (self.size.w / 2)
    x = (x / 2) - .5
    y = self.position.y + (self.size.h / 2)
    y = (y / 2) - .5
    self.center = {x = x, y = y}

    -- Set the positions of each item/action slot
    self.slotPositions = {{x = x, y = y - 1.5},
                          {x = x + 1.5, y = y},
                          {x = x, y = y + 1.5},
                          {x = x - 1.5, y = y}}

    -- Set the menu state
    self.state = 'inventory'
end

function InventoryMenu:draw()
    if not self.items then
        self:update()
    end

    local x = self.position.x
    local y = self.position.y

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

    -- Switch to 2x scale
    SCALE_X = SCALE_X * 2
    SCALE_Y = SCALE_Y * 2
    --love.graphics.push()
    --love.graphics.scale(2, 2)

    if self.state == 'inventory' then
        -- Draw the player in the middle
        self.owner:draw({x = self.center.x, y = self.center.y})
    end

    if self.state == 'inventory' then
        -- Draw all the items
        for i, item in ipairs(self.items) do
            item:draw()
        end
    elseif (self.state == 'item' or self.state == 'selecting item' or
            self.state == 'deselecting item') then

            -- Draw only the selected item
            self.selectedItem:draw()

    end

    if self.state == 'item' then
        -- Draw the verbs
        love.graphics.setColor(WHITE)
        love.graphics.draw(handImg,
                           upscale_x(self.slotPositions[2].x),
                           upscale_y(self.slotPositions[2].y),
                           0, SCALE_X, SCALE_Y)
    end

    -- Switch back to normal scale
    --love.graphics.pop()
    SCALE_X = SCALE_X / 2
    SCALE_Y = SCALE_Y / 2

    if self.state == 'item' then
        -- Create a real-pixel-coordinate version of the center
        local center = {x = upscale_x(self.center.x + .5) * 2,
                        y = upscale_y(self.center.y + .5) * 2}

        --cga_print('USE', nil, nil,
        --          {position = {x = center.x,
        --                       y = center.y - upscale_y(3)},
        --           center = true})

        local num = #self.owner.inventory:get_items(self.selectedItem.itemType)
        if num > 1 then
            cga_print(tostring(num), nil, nil,
                      {position = {x = center.x,
                                   y = center.y - (upscale_y(3))},
                       center = true})
        end

        local name = ITEM_NAME[self.selectedItem.itemType]

        cga_print(name, nil, nil,
                  {position = {x = center.x,
                               y = center.y + upscale_y(2)},
                   center = true})
    end
end

function InventoryMenu:update()
    for _, item in ipairs(self.owner.inventory:get_unique_items()) do
        -- Update the item (for animations)
        item:update()
    end

    if self.state == 'inventory' then
        -- Find and position the items
        self.items = {}
        local i = 0
        for _, item in ipairs(self.owner.inventory:get_unique_items()) do
            if item ~= self.owner.armory.currentWeapon then
                i = i + 1
                self.items[i] = item
                self.items[i].position = copy_table(self.slotPositions[i])
            end
        end
    elseif self.state == 'selecting item' then
        if tiles_overlap(self.selectedItem.position, self.center) then
            self.state = 'item'
        else
            self:move_item_toward(self.center)
        end
    elseif self.state == 'deselecting item' then
        if tiles_overlap(self.selectedItem.position,
                         self.slotPositions[self.selectedItemIndex]) then
            self.state = 'inventory'
        else
            self:move_item_toward(self.slotPositions[self.selectedItemIndex])
        end
    end
end

function InventoryMenu:move_item_toward(destination)
    local pos = self.selectedItem.position

    local dir = direction_to(self.selectedItem.position, destination)
    if dir == 1 then
        self.selectedItem.position.y = self.selectedItem.position.y - .5
    elseif dir == 2 then
        self.selectedItem.position.x = self.selectedItem.position.x + .5
    elseif dir == 3 then
        self.selectedItem.position.y = self.selectedItem.position.y + .5
    elseif dir == 4 then
        self.selectedItem.position.x = self.selectedItem.position.x - .5
    end
end


function InventoryMenu:keypressed(key)
    local dir
    if key == 'up' or key == 'w' then
        dir = 1
    elseif key == 'right' or key == 'd' then
        dir = 2
    elseif key == 'down' or key == 's' then
        dir = 3
    elseif key == 'left' or key == 'a' then
        dir = 4
    end

    if key == 'escape' then
        if self.state == 'inventory' then
            return true
        elseif self.state == 'item' or self.state == 'selecting item' then
            self.state = 'deselecting item'
        end
    end

    if dir then
        if self.state == 'inventory' then
            if self.items and self.items[dir] then
                sound.switchWeapon:play()
                self.selectedItemIndex = dir
                self.selectedItem = self.items[dir]
                self.state = 'selecting item'
            end
        elseif self.state == 'item' or self.state == 'selecting item' then
            --local reverseDir
            --reverseDir = self.selectedItemIndex + 2
            --if reverseDir > 4 then
            --    reverseDir = reverseDir - 4
            --end

            --if dir == reverseDir then
            --    self.state = 'deselecting item'
            --elseif dir == self.selectedItemIndex then
            --    if self.selectedItem:use() then
            --        self.state = 'inventory'
            --    end
            --end
            --

            if dir == 1 or dir == 3 then
                self.state = 'deselecting item'
            elseif dir == 2 then
                if self.selectedItem:use() then
                    self.state = 'inventory'
                end
            end
        end
    end
end
