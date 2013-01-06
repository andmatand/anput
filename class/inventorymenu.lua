require('util.tile')

local function first_line(string)
    local pos = string:find('\n')

    if pos then
        return string:sub(1, pos - 1)
    else
        return string
    end
end

local function get_direction_input(key)
    if key == KEYS.WALK.NORTH or key == KEYS.SHOOT.NORTH then
        return 1
    elseif key == KEYS.WALK.EAST or key == KEYS.SHOOT.EAST then
        return 2
    elseif key == KEYS.WALK.SOUTH or key == KEYS.SHOOT.SOUTH then
        return 3
    elseif key == KEYS.WALK.WEST or key == KEYS.SHOOT.WEST then
        return 4
    end
end


-- An InventoryMenu is a visual representation of a character's items and a
-- menu system for interacting with them
InventoryMenu = class('InventoryMenu')

function InventoryMenu:init(owner)
    self.owner = owner

    self.size = {w = 9, h = 9}
    self.position = {x = math.floor((GRID_W / 2) - (self.size.w / 2)),
                     y = math.floor((GRID_H / 2) - (self.size.h / 2))}

    self.dropPosition = {x = 1.5, y = 4.5}
    self.centerStage = {x = 1.5, y = 1.5}
    self.slotPositions = {{x = 0, y = 0},
                          {x = 1.5, y = 0},
                          {x = 3, y = 0},
                          {x = 0, y = 1.5},
                          {x = 1.5, y = 1.5},
                          {x = 3, y = 1.5}}

    -- Initialize the menu state
    self.state = 'inventory'
    self.selectedSlot = 1

    -- Initialize the verb button states
    self.verbs = {use = {isPushed = false},
                  drop = {isPushed = false}}

    self.flashTimer = {delay = 4, value = 0, state = false}
end

function InventoryMenu:draw()
    if not self.items then
        self:update()
    end

    -- Draw a border
    draw_border(self.position.x, self.position.y, self.size.w, self.size.h)

    -- Set only the inside of the box as the drawable area
    love.graphics.setScissor(SCREEN_X + upscale_x(self.position.x),
                             SCREEN_Y + upscale_y(self.position.y),
                             upscale_x(self.size.w),
                             upscale_y(self.size.h))
    love.graphics.translate(upscale_x(self.position.x) + upscale_x(.5),
                            upscale_y(self.position.y) + upscale_y(.5))

    -- Switch to 2x scale
    SCALE_X = SCALE_X * 2
    SCALE_Y = SCALE_Y * 2

    if self.state == 'inventory' then
        --if self.owner.isDead then
        --    rotation = math.rad(-90)
        --    self.owner.dir = 2
        --    pos.y = pos.y + upscale_y(1)
        --end

        if self.flashTimer.state then
            -- Draw the box around the selected item
            local pos = self.slotPositions[self.selectedSlot]
            love.graphics.setColor(MAGENTA)
            love.graphics.rectangle('fill',
                                    upscale_x(pos.x) - SCALE_X,
                                    upscale_y(pos.y) - SCALE_Y,
                                    upscale_x(1) + SCALE_X * 2,
                                    upscale_y(1) + SCALE_Y * 2)
            love.graphics.setColor(BLACK)
            love.graphics.rectangle('fill',
                                    upscale_x(pos.x),
                                    upscale_y(pos.y),
                                    upscale_x(1),
                                    upscale_y(1))
        end

        -- Draw all the items
        for i, item in ipairs(self.items) do
            item:draw()
        end

    elseif (self.state == 'item' or self.state == 'selecting item' or
            self.state == 'deselecting item' or
            self.state == 'dropping item') and self.activeItem then

            -- Draw the active item
            self.activeItem:draw()
    end

    -- Switch back to normal scale
    SCALE_X = SCALE_X / 2
    SCALE_Y = SCALE_Y / 2

    if self.state == 'item' or self.state == 'dropping item' then
        if not (self.verbs.drop.isPushed or self.state == 'dropping item') and
           (self.verbs.use.isPushed or (self.activeItem and
                                        self.activeItem.isUsable)) then
            -- Set the color based on whether this verb button is pressed
            if self.verbs.use.isPushed then
                color = MAGENTA
            else
                color = WHITE

                if instanceOf(Weapon, self.activeItem) then
                    self.verbs.use.text = 'EQUIP'
                else
                    self.verbs.use.text = 'USE'
                end
            end

            local pos = {x = upscale_x(self.centerStage.x + .5) * 2,
                         y = upscale_y(self.centerStage.y - 1) * 2}

            cga_print(self.verbs.use.text,
                      nil, nil, {position = pos, center = true, color = color})
        end

        if not self.verbs.use.isPushed and
           (self.activeItem or self.verbs.drop.isPushed) then
            -- Set the color based on whether this verb button is pressed
            if self.verbs.drop.isPushed then
                color = MAGENTA
            else
                color = WHITE
            end

            local pos = {x = upscale_x(self.centerStage.x + .5) * 2,
                         y = upscale_y(self.centerStage.y + 1.5) * 2}

            cga_print('DROP', nil, nil, {position = pos, center = true,
                                         color = color})
        end
    end

    if self.state == 'inventory' and self.items[self.selectedSlot] then
        local pos = {x = upscale_x(self.centerStage.x + .5) * 2,
                     y = upscale_y(self.centerStage.y + 1.5) * 2}

        local itemsOfThisType = self.owner.inventory:get_items(
                                self.selectedItem.itemType)
        local num = #itemsOfThisType
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

        cga_print(caption.text, nil, nil, {position = pos, center = true})
    end

    -- Remove the scissor
    love.graphics.setScissor()

end

function InventoryMenu:go_back()
    -- Go back to the previous menu
    if self.state == 'inventory' or self.state == 'deselecting item' then
        self:reset()
        return true
    elseif not self.activeItem then
        self:refresh_items()
        self.state = 'inventory'
    elseif self.state == 'item' or self.state == 'selecting item' then
        self.state = 'deselecting item'
    end
end

function InventoryMenu:key_pressed(key)
    local dir = get_direction_input(key)

    if key == KEYS.EXIT then
        return self:go_back()
    end

    -- If a direction key was pressed
    if dir then
        if self.state == 'inventory' or self.state == 'deselecting item' then
            -- Reset the flash timer
            self.flashTimer.value = self.flashTimer.delay
            self.flashTimer.state = true

            -- Move the selection box
            local oldSlot = self.selectedSlot
            local w = 3
            if dir == 1 then
                if self.selectedSlot - w >= 1 then
                    self.selectedSlot = self.selectedSlot - w
                end
            elseif dir == 2 then
                if self.selectedSlot % w ~= 0 then
                    self.selectedSlot = self.selectedSlot + 1
                end
            elseif dir == 3 then
                if self.selectedSlot + w <= #self.slotPositions then
                    self.selectedSlot = self.selectedSlot + w
                end
            elseif dir == 4 then
                if self.selectedSlot % w ~= 1 then
                    self.selectedSlot = self.selectedSlot - 1
                end
            end
            if self.selectedSlot < 1 then
                self.selectedSlot = 1
            elseif self.selectedSlot > #self.slotPositions then
                self.selectedSlot = #self.slotPositions
            end

            if self.selectedSlot ~= oldSlot then
                sounds.menuSelect:play()
            end
        elseif self.state == 'item' or self.state == 'selecting item' then
            if dir == 1 and self.activeItem.isUsable then
                self.verbs.use.isPushed = true
                if self.activeItem:use() then
                    self:post_use_item()
                end

                return
            elseif dir == 3 then
                self.verbs.drop.isPushed = true
                self.activeItem:set_position(self.centerStage)
                self.state = 'dropping item'
                --self:post_use_item()

                return
            end
        end

        -- Nothing was triggered by this direction since we are still here, so
        -- go back to the previous menu
        self:go_back()
    end

    if key == KEYS.CONTEXT then
        if self.items and self.items[self.selectedSlot] then
            sounds.menuSelect:play()
            self.activeItem = self.items[self.selectedSlot]
            self.state = 'selecting item'
            return
        end
    end
end

function InventoryMenu:key_released(key)
    local dir = get_direction_input(key)

    -- Un-push the verb buttons
    if dir == 1 and self.verbs.use.isPushed then
        self.verbs.use.isPushed = false

        if not self.activeItem then
            self:go_back()
        end
    elseif dir == 3 and self.verbs.drop.isPushed then
        self.verbs.drop.isPushed = false

        if not self.activeItem and self.state ~= 'dropping item' then
            self:go_back()
        end
    end
end

function InventoryMenu:move_item_toward(destination)
    local dist = distance(self.activeItem.position, destination)

    -- If the distance is a negligable amount, or the item is being dropped and
    -- it has gone below its y destination
    if dist < .125 or (self.state == 'dropping item' and
                       self.activeItem.position.y > destination.y) then
        -- Move the item to the destination
        self.activeItem.position.x = destination.x
        self.activeItem.position.y = destination.y
        return
    end

    local vel
    -- If the item is being dropped
    if self.state == 'dropping item' then
        -- Accelerate as it drops
        vel = 1 / dist
    else
        local n
        if self.selectedSlot == 1 or self.selectedSlot == 3 then
            n = 2
        else
            n = 1.5
        end

        -- Come to a smooth stop
        vel = dist / n
    end

    if self.activeItem.position.x > destination.x then
        self.activeItem.position.x = self.activeItem.position.x - vel
    elseif self.activeItem.position.x < destination.x then
        self.activeItem.position.x = self.activeItem.position.x + vel
    end

    if self.activeItem.position.y > destination.y then
        self.activeItem.position.y = self.activeItem.position.y - vel
    elseif self.activeItem.position.y < destination.y then
        self.activeItem.position.y = self.activeItem.position.y + vel
    end
end

function InventoryMenu:post_use_item()
    local dups = {}

    if not instanceOf(Weapon, self.activeItem) then
        -- Find all items of the same type as the active one
        dups = self.owner.inventory:get_items(self.activeItem.itemType)
    end

    -- Clear the selected item
    self.activeItem = nil

    -- If we still have items of this type left
    if #dups > 0 then
        -- Select the first of those items
        self.activeItem = dups[1]
        self.activeItem:set_position(self.centerStage)
    else
        -- Go back to the main inventory screen
        --self:go_back()
    end
end

function InventoryMenu:refresh_items()
    -- Find the items the owner is holding, and position them in the slots
    self.items = {}
    local i = 1
    for _, item in ipairs(self.owner.inventory:get_unique_items()) do
        if self.activeItem ~= item then
            item.position = copy_table(self.slotPositions[i])
        end
        table.insert(self.items, item)

        i = i + 1
    end
    self.selectedItem = self.items[self.selectedSlot]
end

function InventoryMenu:reset()
    self.state = 'inventory'
    self.activeItem = nil
    self:update()
end

function InventoryMenu:update()
    -- Update the flash timer
    if self.flashTimer.value > 0 then
        self.flashTimer.value = self.flashTimer.value - 1
    else
        self.flashTimer.value = self.flashTimer.delay
        self.flashTimer.state = not self.flashTimer.state
    end

    for _, item in ipairs(self.owner.inventory:get_unique_items()) do
        -- Update the item (for animations)
        item:update()
    end

    -- If there is an active item
    if self.activeItem then
        -- If the owner is no longer holding it
        if self.activeItem.owner ~= self.owner and
           self.state ~= 'dropping item' then
            self:post_use_item()
            if not self.activeItem then
                self:go_back()
            end
        end
    end

    self:refresh_items()

    if self.state == 'inventory' then
        self.activeItem = nil
    elseif self.state == 'selecting item' and self.activeItem then
        if tiles_overlap(self.activeItem.position, self.centerStage) then
            self.state = 'item'
        else
            self:move_item_toward(self.centerStage)
        end
    elseif self.state == 'deselecting item' then
        if tiles_overlap(self.activeItem.position,
                         self.slotPositions[self.selectedSlot]) then
            self.state = 'inventory'
        else
            self:move_item_toward(self.slotPositions[self.selectedSlot])
        end
    elseif self.state == 'dropping item' and self.activeItem then
        if tiles_overlap(self.activeItem.position, self.dropPosition) then
            self.activeItem.position = nil
            self.owner:drop_items({self.activeItem})
            self:post_use_item()

            if self.activeItem then
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

    -- Update the owner's frame
    self.owner:update_image()
end
