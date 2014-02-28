require('util.input')
require('util.tile')

local function add_padding(pos)
    return {x = pos.x * 1.5, y = pos.y * 1.5}
end

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
    self.position = {x = math.floor((GRID_W / 2) - self.size.w - 4),
                     y = math.floor((GRID_H / 2) - (self.size.h / 2))}

    self.slotPositions = {{x = 0, y = 0},
                          {x = 1, y = 0},
                          {x = 2, y = 0},
                          {x = 0, y = 1},
                          {x = 1, y = 1},
                          {x = 2, y = 1},
                          {x = 0, y = 2},
                          {x = 1, y = 2},
                          {x = 2, y = 2}}

    self.selectedSlot = 1
    self.flashTimer = {delay = 5, value = 0, state = false}
    self.selectorColor = MAGENTA
end

function InventoryMenu:draw()
    if not self.items then
        self:update()
    end

    -- Draw a border
    draw_border(self.position.x, self.position.y, self.size.w, self.size.h)

    -- Treat the top-left of the box as (0, 0)
    love.graphics.push()
    love.graphics.translate(upscale_x(self.position.x) + upscale_x(.5),
                            upscale_y(self.position.y) + upscale_y(.5))

    -- Switch to 2x scale
    SCALE_X = SCALE_X * 2
    SCALE_Y = SCALE_Y * 2

    --if self.owner.isDead then
    --    rotation = math.rad(-90)
    --    self.owner.dir = 2
    --    pos.y = pos.y + upscale_y(1)
    --end

    if self.flashTimer.state then
        -- Draw the box around the selected item
        local pos = self.slotPositions[self.selectedSlot]
        pos = add_padding(pos)

        love.graphics.setColor(self.selectorColor)
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
        local pos = item:get_position()
        item:draw()

        --local itemsOfThisType = self.owner.inventory:get_items(item.itemType)
        --pos.x = upscale_x(pos.x) + upscale_x(.5)
        --pos.y = upscale_y(pos.y) + upscale_y(.5) - 1
        --cga_print(#itemsOfThisType, nil, nil, {position = pos})
    end

    -- Switch back to normal scale
    SCALE_X = SCALE_X / 2
    SCALE_Y = SCALE_Y / 2

    love.graphics.pop()

    if self.selectedItem then
        local itemsOfThisType = self.owner.inventory:get_items(
                                self.selectedItem.itemType)
        local num = #itemsOfThisType
        local caption = Message({text = ITEM_NAME[self.selectedItem.itemType]})
        if num > 1 then
            caption.text = num .. ' ' .. caption.text

            -- If the item name does not already end in "S"
            if string.sub(caption.text, -1) ~= 'S' then
                -- Add an "S" to the end
                caption.text = caption.text .. 'S'
            end
        end
        --caption:wrap(self.size.w)

        -- Draw the text in the status bar
        local pos = {x = upscale_x(ROOM_W / 2), y = upscale_y(ROOM_H)}

        cga_print(caption.text, nil, nil, {position = pos, center = true})
    end
end

function InventoryMenu:key_pressed(key)
    local dir = get_direction_input(key)

    -- If a direction key was pressed
    if dir then
        local currentPosition = self.slotPositions[self.selectedSlot]

        for slot, pos in pairs(self.slotPositions) do
            -- If this slot position is to the direction which was pressed
            if tiles_overlap(pos, add_direction(currentPosition, dir)) then
                --sounds.menuSelect:play()
                self:reset_flash_timer()
                self.selectedSlot = slot
                break
            end
        end
    elseif key == KEYS.CONTEXT and self.selectedItem then
        self:reset_flash_timer()
        if self.selectedItem:use() then
            self.selectorColor = WHITE
        else
            self.selectorColor = BLACK
        end
    elseif key == KEYS.DROPITEM and self.selectedItem then
        self:reset_flash_timer()
        self.owner:drop_items({self.selectedItem})
    elseif key == KEYS.INVENTORY or key == KEYS.EXIT then
        return true
    end
end

function InventoryMenu:key_released(key)
    if key == KEYS.CONTEXT then
        if self.selectorColor == BLACK then
            self:reset_flash_timer()
        end

        self.selectorColor = MAGENTA
    end
end

function InventoryMenu:refresh_items()
    -- Find the items the owner is holding, and position them in the slots
    self.items = {}
    local i = 1
    for _, item in ipairs(self.owner.inventory:get_unique_items()) do
        item:set_position(add_padding(copy_table(self.slotPositions[i])))
        table.insert(self.items, item)

        i = i + 1
    end
    self.selectedItem = self.items[self.selectedSlot]
end

function InventoryMenu:reset_flash_timer()
    -- Reset the flash timer
    self.flashTimer.value = self.flashTimer.delay
    self.flashTimer.state = true
end

function InventoryMenu:update()
    -- Update the flash timer
    if self.flashTimer.value > 1 then
        self.flashTimer.value = self.flashTimer.value - 1
    else
        self.flashTimer.value = self.flashTimer.delay
        self.flashTimer.state = not self.flashTimer.state
    end

    for _, item in ipairs(self.owner.inventory:get_unique_items()) do
        -- Update the item (for animations)
        item:update()
    end

    self:refresh_items()

    -- Update the owner's frame
    self.owner:update_image()
end
