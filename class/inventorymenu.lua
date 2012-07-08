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

    self.size = {w = 9, h = 9}
    self.position = {x = math.floor((SCREEN_W / 2) - (self.size.w / 2)),
                     y = math.floor((SCREEN_H / 2) - (self.size.h / 2))}

    -- Set the center of the box
    local x, y
    x = self.position.x + (self.size.w / 2)
    x = (x / 2) - .5
    y = self.position.y + (self.size.h / 2)
    y = (y / 2) - .5
    self.center = {x = x, y = y}
    self.dropPosition = {x = x, y = y + 3}

    -- Set the positions of each item/action slot
    self.slotPositions = {{x = x, y = y - 1.5},
                          {x = x + 1.5, y = y},
                          {x = x, y = y + 1.5},
                          {x = x - 1.5, y = y}}

    -- Initialize the menu state
    self.state = 'inventory'

    -- Initialize the verb button states
    self.verbs = {use = {isPushed = false},
                  drop = {isPushed = false}}
end

function InventoryMenu:draw()
    if not self.items then
        self:update()
    end

    -- Draw a border
    love.graphics.setColor(WHITE)
    love.graphics.rectangle('fill',
                            upscale_x(self.position.x - 1),
                            upscale_y(self.position.y - 1),
                            upscale_x(self.size.w + 2),
                            upscale_y(self.size.h + 2))
    love.graphics.setColor(BLACK)
    love.graphics.rectangle('fill',
                            upscale_x(self.position.x),
                            upscale_y(self.position.y),
                            upscale_x(self.size.w),
                            upscale_y(self.size.h))

    -- Set only the inside of the box as the drawable area
    love.graphics.setScissor(upscale_x(self.position.x),
                             upscale_y(self.position.y),
                             upscale_x(self.size.w),
                             upscale_y(self.size.h))

    -- Switch to 2x scale
    SCALE_X = SCALE_X * 2
    SCALE_Y = SCALE_Y * 2
    --love.graphics.push()
    --love.graphics.scale(2, 2)

    if self.state == 'inventory' then
        local pos, rotation
        pos = {x = upscale_x(self.center.x), y = upscale_y(self.center.y)}

        if self.owner.dead then
            rotation = math.rad(-90)
            pos.y = pos.y + upscale_y(1)
        end

        -- Draw the player in the middle
        self.owner:draw(pos, rotation)
    end

    if self.state == 'inventory' then
        -- Draw all the items
        for i, item in ipairs(self.items) do
            item:draw()
        end
    elseif (self.state == 'item' or self.state == 'selecting item' or
            self.state == 'deselecting item' or
            self.state == 'dropping item') and self.selectedItem then

            -- Draw the selected item
            self.selectedItem:draw()
    end

    if self.state == 'item' or self.state == 'dropping item' then
        if self.verbs.use.isPushed or (self.selectedItem and
                                       self.selectedItem.isUsable) then
            -- Set the color based on whether this verb button is pressed
            if self.verbs.use.isPushed then
                love.graphics.setColor(MAGENTA)
            else
                love.graphics.setColor(WHITE)
            end

            -- Draw the USE verb
            love.graphics.draw(useImg,
                               upscale_x(self.slotPositions[2].x),
                               upscale_y(self.slotPositions[2].y),
                               0, SCALE_X, SCALE_Y)
        end

        if self.selectedItem or self.verbs.drop.isPushed then
            -- Set the color based on whether this verb button is pressed
            if self.verbs.drop.isPushed then
                love.graphics.setColor(MAGENTA)
            else
                love.graphics.setColor(WHITE)
            end

            -- Draw the USE verb
            love.graphics.draw(dropImg,
                               upscale_x(self.slotPositions[4].x),
                               upscale_y(self.slotPositions[4].y),
                               0, SCALE_X, SCALE_Y)
        end
    end

    -- Switch back to normal scale
    --love.graphics.pop()
    SCALE_X = SCALE_X / 2
    SCALE_Y = SCALE_Y / 2

    -- Enable drawing everywhere again
    love.graphics.setScissor()

    if self.state == 'item' and self.selectedItem then
        -- Create a real-pixel-coordinate version of the center
        local center = {x = upscale_x(self.center.x + .5) * 2,
                        y = upscale_y(self.center.y + .5) * 2}

        --cga_print('USE', nil, nil,
        --          {position = {x = center.x,
        --                       y = center.y - upscale_y(3)},
        --           center = true})

        local num = #self.owner.inventory:get_items(self.selectedItem.itemType)
        --if num > 1 then
        --    cga_print(tostring(num), nil, nil,
        --              {position = {x = center.x,
        --                           y = center.y - (upscale_y(3))},
        --               center = true})
        --end

        local caption = Message({text =
                                 ITEM_NAME[self.selectedItem.itemType]})
        if num > 1 then
            caption.text = num .. ' ' .. caption.text

            -- If the item name does not already end in "S"
            if string.sub(caption.text, -1) ~= 'S' then
                -- Add an "S" to the end
                caption.text = caption.text .. 'S'
            end
        end
        caption:wrap(8)

        cga_print(caption.text, nil, nil,
                  {position = {x = center.x,
                               y = center.y + upscale_y(2)},
                   center = true})
    end
end

function InventoryMenu:refresh_items()
    -- Find the items the owner is holding, and position them in a circle
    self.items = {}
    local i = 1
    for _, item in ipairs(self.owner.inventory:get_unique_items()) do
        if item ~= self.owner.armory.currentWeapon then
            if self.selectedItem ~= item then
                item.position = copy_table(self.slotPositions[i])
            end
            table.insert(self.items, item)

            i = i + 1
        end
    end
end

function InventoryMenu:update()
    for _, item in ipairs(self.owner.inventory:get_unique_items()) do
        -- Update the item (for animations)
        item:update()
    end

    -- If an item is currently selected
    if self.selectedItem then
        -- If the owner is no longer holding it
        if self.selectedItem.owner ~= self.owner and
           self.state ~= 'dropping item' then
            self:post_use_item()
        end
    end

    self:refresh_items()

    if self.state == 'inventory' then
        self.selectedItem = nil
    elseif self.state == 'selecting item' and self.selectedItem then
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
    elseif self.state == 'dropping item' then
        if tiles_overlap(self.selectedItem.position, self.dropPosition) then
            self.selectedItem.position = nil
            self.owner:drop({self.selectedItem})
            self:post_use_item()

            if self.selectedItem then
                self.state = 'item'
            else
                if self.verbs.drop.isPushed then
                    self.state = 'item'
                else
                    self:go_back()
                end
            end
        else
            self:move_item_toward(self.dropPosition)
        end
    end
end

function InventoryMenu:move_item_toward(destination)
    local dist = manhattan_distance(self.selectedItem.position, destination)
    -- If the distance is a negligable amount, or the item is being dropped and
    -- it has gone below its y destination
    if dist < .125 or (self.state == 'dropping item' and
                       self.selectedItem.position.y > destination.y) then
        -- Move the item to the destination
        self.selectedItem.position.x = destination.x
        self.selectedItem.position.y = destination.y
        return
    end

    local vel
    -- If the item is being dropped
    if self.state == 'dropping item' then
        -- Accelerate as it drops
        vel = 1 / dist
    else
        -- Come to a smooth stop
        vel = dist / 1.5
    end

    local dir = direction_to(self.selectedItem.position, destination)
    if dir == 1 then
        self.selectedItem.position.y = self.selectedItem.position.y - vel
    elseif dir == 2 then
        self.selectedItem.position.x = self.selectedItem.position.x + vel
    elseif dir == 3 then
        self.selectedItem.position.y = self.selectedItem.position.y + vel
    elseif dir == 4 then
        self.selectedItem.position.x = self.selectedItem.position.x - vel
    end
end

local function get_direction_input(key)
    if key == 'up' or key == 'w' then
        return 1
    elseif key == 'right' or key == 'd' then
        return 2
    elseif key == 'down' or key == 's' then
        return 3
    elseif key == 'left' or key == 'a' then
        return 4
    end
end

function InventoryMenu:go_back()
    -- Go back to the previous menu
    if self.state == 'inventory' then
        return true
    elseif not self.selectedItem then
        self.state = 'inventory'
    elseif self.state == 'item' or self.state == 'selecting item' then
        self.state = 'deselecting item'
    end
end

function InventoryMenu:keypressed(key)
    local dir = get_direction_input(key)

    if key == 'escape' then
        return self:go_back()
    end

    -- If a direction key was pressed
    if dir then
        if self.state == 'inventory' or self.state == 'deselecting item' then
            if self.items and self.items[dir] then
                sound.menuSelect:play()
                self.selectedItemIndex = dir
                self.selectedItem = self.items[dir]
                self.state = 'selecting item'
                return
            end
        elseif self.state == 'item' or self.state == 'selecting item' then
            if dir == 2 and self.selectedItem.isUsable then
                self.verbs.use.isPushed = true
                if self.selectedItem:use() then
                    self:post_use_item()
                end

                return
            elseif dir == 4 then
                self.verbs.drop.isPushed = true
                self.state = 'dropping item'
                --self:post_use_item()

                return
            end
        end

        -- Nothing was triggered by this direction since we are still here, so
        -- go back to the previous menu
        self:go_back()
    end
end

function InventoryMenu:keyreleased(key)
    local dir = get_direction_input(key)

    -- Un-push the verb buttons
    if dir == 2 and self.verbs.use.isPushed then
        self.verbs.use.isPushed = false

        if not self.selectedItem then
            self:go_back()
        end
    elseif dir == 4 and self.verbs.drop.isPushed then
        self.verbs.drop.isPushed = false

        if not self.selectedItem and self.state ~= 'dropping item' then
            self:go_back()
        end
    end
end

function InventoryMenu:reset()
    self.state = 'inventory'
    self:update()
end

function InventoryMenu:post_use_item()
    local dups = {}

    if not instanceOf(Weapon, self.selectedItem) then
        -- Find all items of the same type as the one currently selected
        dups = self.owner.inventory:get_items(self.selectedItem.itemType)
    end

    -- Clear the selected item
    self.selectedItem = nil

    -- If we still have items of this type left
    if #dups > 0 then
        -- Select the first of those items
        self.selectedItem = dups[1]
        self.selectedItem:set_position(self.center)
    else
        -- Go back to the main inventory screen
        --self:go_back()
    end
end
