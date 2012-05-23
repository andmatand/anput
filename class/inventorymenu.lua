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
        if self.selectedItem.isUsable then
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

    -- If an item is currently selected
    if self.selectedItem then
        -- If the owner is no longer holding it
        if self.selectedItem.owner ~= self.owner then
            self:post_use_item()
        end
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
        if self.state == 'inventory' then
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
                else
                    sound.noAmmo:play()
                end

                return
            elseif dir == 4 then
                self.verbs.drop.isPushed = true
                self.selectedItem.position = nil
                self.owner:drop({self.selectedItem})
                self:post_use_item()

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
    if dir == 2 then
        self.verbs.use.isPushed = false
    elseif dir == 4 then
        self.verbs.drop.isPushed = false
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
        self:go_back()
    end
end
