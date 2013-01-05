Door = class('Door')

function Door:init(position, dir)
    Door.super.init(self, position)

    -- Position is on the tile grid
    self.position = {x = position.x, y = position.y}

    self.dir = dir

    self.state = 'closed'
    self.offset = 0
    self.maxOffset = 4
    self.timer = {delay = .2, value = love.timer.getTime()}
end

function Door:draw(alpha)
    -- Draw the blackness inside
    love.graphics.setColor(BLACK)
    love.graphics.rectangle('fill',
                            upscale_x(self.position.x),
                            upscale_y(self.position.y),
                            upscale_x(1), upscale_y(1))

    love.graphics.setScissor(SCREEN_X + upscale_x(self.position.x),
                             SCREEN_Y + upscale_y(self.position.y),
                             upscale_x(1), upscale_y(1))

    local rotation = 0
    local offset = {x = 0, y = 0}

    -- If we are on the north or south edge of the sreen
    if self.dir == 1 or self.dir == 3 then
        -- Open the door horizontally
        offset.x = -(self.offset * 2 * SCALE_X)
    else
        -- Open the door vertically
        offset.y = -(self.offset * 2 * SCALE_Y)
    end

    love.graphics.setColorMode('modulate')

    -- Draw the door's background color
    love.graphics.setColor(MAGENTA[1], MAGENTA[2], MAGENTA[3], alpha)
    love.graphics.rectangle('fill',
                            upscale_x(self.position.x) + offset.x,
                            upscale_y(self.position.y) + offset.y,
                            upscale_x(1), upscale_y(1))

    -- Draw the foreground of the door
    if self.room then
        love.graphics.setColor(WHITE[1], WHITE[2], WHITE[3], alpha)
        love.graphics.draw(images.door,
                           upscale_x(self.position.x) + offset.x,
                           upscale_y(self.position.y) + offset.y,
                           rotation, SCALE_X, SCALE_Y)
    end

    love.graphics.setScissor()
end

function Door:get_position()
    return self.position
end

function Door:close(instantly)
    if instantly then
        self.offset = 0
        self.state = 'closed'
    else
        self.state = 'closing'
    end

    -- If we have a sister door, close it too
    self.helpingSister = true
    if self.sister and not self.sister.helpingSister then
        self.sister.timer.value = self.timer.value
        self.sister:close(instantly)
    end
    self.helpingSister = false
end

function Door:is_audible()
    if self.room then
        return self.room:is_audible()
    else
        return true
    end
end

function Door:open(instantly)
    if instantly then
        self.offset = self.maxOffset
        self.state = 'open'
    else
        self.state = 'opening'
    end

    -- If we have a sister door, open it too
    self.helpingSister = true
    if self.sister and not self.sister.helpingSister then
        self.sister:open(instantly)
    end
    self.helpingSister = false
end

function Door:receive_hit(agent)
    if self.state == 'open' then
        return false
    else
        return true
    end
end

function Door:set_sister(sister)
    self.sister = sister
end

function Door:update()
    if self.state == 'open' or self.state == 'closed' then
        return
    end

    if self:wait_for_delay() then
        local oldOffset = self.offset
        if self.state == 'opening' then
            if self.offset < self.maxOffset then
                self.offset = self.offset + 1
            end
        elseif self.state == 'closing' then
            if self.offset > 0 then
                self.offset = self.offset - 1
            end
        end

        if oldOffset ~= self.offset and self:is_audible() then
            local key = 'open' .. self.offset
            if sounds.door[key] then
                sounds.door[key]:play()
            end
        end

        if self.offset == self.maxOffset then
            self.state = 'open'
        elseif self.offset == 0 then
            self.state = 'closed'
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
