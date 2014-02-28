require('class.mainpausemenu')

MenuManager = class('MenuManager')

function MenuManager:init()
    self.stack = {}
end

function MenuManager:push(menu)
    table.insert(self.stack, menu)
end

function MenuManager:draw()
    self.stack[#self.stack]:draw()
end

function MenuManager:key_pressed(key)
    -- Send the keypress to the current menu
    self.stack[#self.stack]:key_pressed(key)

    if self.stack[#self.stack]:is_exited() then
        table.remove(self.stack)

        -- If there are no more menus left
        if #self.stack == 0 then
            return true
        end
    end
end

function MenuManager:key_released(key)
    self.stack[#self.stack]:key_released(key)
end

function MenuManager:update()
    self.stack[#self.stack]:update()
end
