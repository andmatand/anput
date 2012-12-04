Door = class('Door')

function Door:init(position)
    -- Position is one th tile grid
    self.position = {x = position.x, y = position.y}

    self.state = 'closed'
    self.height = 0
    self.maxHeight = 5
    self.timer = {delay = .2, value = love.timer.getTime()}
end

function Door:draw()
    -- Draw the blackness inside
    love.graphics.setColor(BLACK)
    love.graphics.rectangle('fill',
                            upscale_x(self.position.x),
                            upscale_y(self.position.y),
                            upscale_x(1),
                            self.maxHeight * 2 * SCALE_Y)

    -- Draw the door
    love.graphics.setColor(MAGENTA)
    love.graphics.rectangle('fill',
                            upscale_x(self.position.x),
                            upscale_y(self.position.y),
                            upscale_x(1),
                            ((self.maxHeight * 2) - self.height * 2) * SCALE_Y)
end

function Door:get_state()
    return self.state
end

function Door:close()
    if self:wait_for_delay() then
        if self.height > 0 then
            sounds.door['open' .. self.height]:play()
            self.height = self.height - 1
        else
            self.state = 'closed'
        end
    end
end

function Door:open(instantly)
    if instantly then
        self.height = self.maxHeight
        self.state = 'open'
        return
    end

    if self:wait_for_delay() then
        if self.height < self.maxHeight then
            self.height = self.height + 1
            sounds.door['open' .. self.height]:play()
        else
            self.state = 'open'
        end
    end
end

function Door:wait_for_delay()
    if love.timer.getTime() >= self.timer.value + self.timer.delay then
        self.timer.value = love.timer.getTime()
        return true
    else
        return false
    end
end