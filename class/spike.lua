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
    self.hasBeenSeen = {}
    self.extension = SPIKE_MIN_EXTENSION
    self.state = 'retracted'
    self.postExtensionTimer = {delay = 8, value = 0}
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

    if self.room and self.giveDamage then
        for _, c in pairs(self.room:get_characters()) do
            for _, tile in pairs(self:get_visible_tiles()) do
                if tiles_overlap(tile, c:get_position()) then
                    if c:receive_hit(self) then
                        c:receive_damage(50, self)
                    end
                end
            end
        end

        self.giveDamage = false
    end
end

function Spike:draw(manualPosition, lightness)
    local enableGridOffset = true

    local x, y
    if manualPosition then
        x = manualPosition.x
        y = manualPosition.y
        enableGridOffset = false
    else
        x = upscale_x(self.position.x)
        y = upscale_y(self.position.y)
    end
    local w = self.image:getWidth()
    local h = self.image:getHeight()

    local offset
    if enableGridOffset then
        offset = self:get_draw_offset()
    else
        offset = self:get_extension_offset()
    end
    x = x + (offset.x * SCALE_X) + ((w * SCALE_X) / 2)
    y = y + (offset.y * SCALE_Y) + ((h * SCALE_Y) / 2)

    -- Determine the rotation/flipping
    local r, sx, sy = get_rotation(self.dir)

    love.graphics.setColor(lightness, lightness, lightness)
    love.graphics.draw(self.image, x, y, r, sx, sy, w / 2, h / 2)
end

function Spike:extend()
    self.extension = self.extension + 4

    if self.extension > SPIKE_MAX_EXTENSION then
        self.extension = SPIKE_MAX_EXTENSION
    end

    if self.extension == SPIKE_MAX_EXTENSION then
        if self.state ~= 'extended' then
            self.giveDamage = true
            self.state = 'extended'
            self.postExtensionTimer.value = self.postExtensionTimer.delay
        end
    end
end

-- This function returns one or two grid-tiles with which the visible spike
-- overlaps
function Spike:get_visible_tiles()
    local tiles = {}

    -- Add the main tile into which the spike protrudes
    tiles[1] = add_direction(self.position, self.dir)

    local dir = self:get_interleave_offset_direction()
    if dir then
        tiles[2] = add_direction(tiles[1], dir)
    end

    return tiles
end

function Spike:get_draw_offset()
    local extensionOffset = self:get_extension_offset()
    local interleaveOffset = self:get_grid_offset()
    return {x = extensionOffset.x + (interleaveOffset.x * TILE_W),
            y = extensionOffset.y + (interleaveOffset.y * TILE_H)}
end

-- This function returns an offset in unscaled pixels
function Spike:get_extension_offset()
    local offset = {x = 0, y = 0}
    return add_direction(offset, self.dir, self.extension)
end

-- This function returns an offset in grid coordinates
function Spike:get_grid_offset()
    local offset = {x = 0, y = 0}

    local dir = self:get_interleave_offset_direction()

    if dir then
        offset = add_direction(offset, dir, .5)
    end

    return offset
end

function Spike:get_interleave_offset_direction()
    if self.dir == 3 then
        return 2
    elseif self.dir == 4 then
        return 3
    end
end

function Spike:receive_hit(agent)
    -- If we are at least half way retracted
    if self.extension <= SPIKE_MAX_EXTENSION / 2 then
        -- Objects cannot collide with us
        return false
    else
        -- Objects can collide with us
        return true
    end
end

function Spike:retract()
    if self.extension > SPIKE_MIN_EXTENSION then
        self.extension = self.extension - 1
    end

    if self.extension == SPIKE_MIN_EXTENSION then
        self.state = 'retracted'
    end
end
