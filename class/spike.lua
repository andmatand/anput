require('class.tile')
require('util.tile')

Spike = class('Spike', Tile)

SPIKE_MAX_EXTENSION = TILE_W
SPIKE_MIN_EXTENSION = 1

function Spike:init(position, dir)
    Spike.super.init(self)

    self:set_position(position)
    self.dir = dir

    self.image = images.spike
    self.extension = SPIKE_MIN_EXTENSION
    self.state = 'retracted'
    self.postExtensionTimer = {delay = 4, value = 0}
end

function Spike:trigger()
    self.state = 'extending'
end

function Spike:update()
    if self.state == 'extended' then
        if self.postExtensionTimer.value > 0 then
            self.postExtensionTimer.value = self.postExtensionTimer.value - 1
        else
            self.state = 'retracting'
        end
    end

    if self.state == 'extending' then
        self:extend()
    elseif self.state == 'retracting' then
        if math.random(1, 3) > 1 then
            self:retract()
        end
    end
end

function Spike:draw(alpha)
    local x = upscale_x(self.position.x)
    local y = upscale_y(self.position.y)
    local w = self.image:getWidth()
    local h = self.image:getHeight()

    local offset = self:get_offset()
    x = x + (offset.x * SCALE_X) + ((w * SCALE_X) / 2)
    y = y + (offset.y * SCALE_Y) + ((h * SCALE_Y) / 2)

    -- Determine the rotation/flipping
    local r, sx, sy = get_rotation(self.dir)

    love.graphics.setColor(255, 255, 255, alpha)
    love.graphics.draw(self.image, x, y, r, sx, sy, w / 2, h / 2)
end

function Spike:extend()
    self.extension = self.extension + 4

    if self.extension > SPIKE_MAX_EXTENSION then
        self.extension = SPIKE_MAX_EXTENSION
    end

    if self.extension == SPIKE_MAX_EXTENSION then
        self.state = 'extended'
        self.postExtensionTimer.value = self.postExtensionTimer.delay
    end
end

function Spike:get_offset()
    local offset = {x = 0, y = 0}
    offset = add_direction(offset, self.dir, self.extension)

    if self.dir == 3 then
        offset.x = offset.x + TILE_W / 2
    elseif self.dir == 4 then
        offset.y = offset.y + TILE_H / 2
    end

    return offset
end

function Spike:retract()
    if self.extension > SPIKE_MIN_EXTENSION then
        self.extension = self.extension - 1
    end

    if self.extension == SPIKE_MIN_EXTENSION then
        self.state = 'retracted'
    end
end
