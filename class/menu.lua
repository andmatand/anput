require('class.menuitem')
require('class.timer')
require('util.input')

Menu = class('Menu')

function Menu:init(title, itemNames, itemOptions)
    self.title = title

    self.items = {}
    for i, name in pairs(itemNames) do
        local options
        if itemOptions and itemOptions[i] then
            options = itemOptions[i]
        end

        self.items[i] = MenuItem(name, nil, options)
    end

    self.flashTimer = Timer(5)
    self.flashState = true
    self.highlightIndex = 1
    self.y = math.floor((GRID_H / 2) - (#self.items / 2)) - 1
end

-- Subclasses can override this method
function Menu:apply_option()
end

function Menu:draw()
    cga_print(self.title, GRID_W / 2, self.y, {center = true})

    local y = self.y + 1
    for i = 1, #self.items do
        if self.items[i].isVisible then
            y = y + 1

            self.items[i]:draw(GRID_W / 2,
                               y,
                               (self.highlightIndex == i),
                               self.flashState)
        end
    end
end

function Menu:exit()
    self.isExited = true
end

-- Subclasses can override this method
function Menu:execute_item(index)
end

function Menu:get_highlight_index()
    return self.highlightIndex
end

function Menu:get_highlighted_item()
    return self.items[self.highlightIndex]
end

function Menu:is_exited()
    return self.isExited == true
end

function Menu:move_highlight_up()
    self.highlightIndex = self.highlightIndex - 1

    -- Wrap around
    if self.highlightIndex < 1 then
        self.highlightIndex = #self.items
    end

    -- If the item now highlighted is not visible
    if not self.items[self.highlightIndex].isVisible then
        -- Skip over this item
        self:move_highlight_up()
    end
end

function Menu:move_highlight_down()
    self.highlightIndex = self.highlightIndex + 1

    -- Wrap around
    if self.highlightIndex > #self.items then
        self.highlightIndex = 1
    end

    -- If the item now highlighted is not visible
    if not self.items[self.highlightIndex].isVisible then
        -- Skip over this item
        self:move_highlight_down()
    end
end

function Menu:key_pressed(key)
    local dir = get_direction_input(key)

    if dir then
        self:reset_flash_timer()

        if dir == 1 then
            self:move_highlight_up()
        elseif dir == 3 then
            self:move_highlight_down()
        elseif dir == 4 then
            self:get_highlighted_item():select_previous_option()
            self:apply_option(self.highlightIndex)
        elseif dir == 2 then
            self:get_highlighted_item():select_next_option()
            self:apply_option(self.highlightIndex)
        end
    elseif key == KEYS.CONTEXT then
        self:execute_item(self.highlightIndex)
    elseif key == KEYS.EXIT then
        self:exit()
    end
end

function Menu:key_released(key)
end

function Menu:reset_flash_timer()
    self.flashTimer:reset()
    self.flashState = true
end

function Menu:update()
    if self.flashTimer:update() then
        self.flashTimer:reset()
        self.flashState = not self.flashState
    end
end
