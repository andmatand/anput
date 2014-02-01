require('class.watertile')
require('util.tile')

Lake = class('Lake')

function Lake:init(tiles)
    -- Convert all the given tiles to WaterTiles
    self.tiles = {}
    for _, t in pairs(tiles) do
        table.insert(self.tiles, WaterTile(t, self))
    end

    self.frames = images.water
    self.frameNumber = 1
    self.frameTimer = {delay = 10, value = 0}
    self.offset = {x = 0, y = 0, dir = 1,
                   timer = {delay = 5, value = 0}}

    self.drawBox = find_box_surrounding(tiles)
    self.drawBox.x1 = self.drawBox.x1 - 1
    self.drawBox.x2 = self.drawBox.x2 + 1

    self.spriteBatches = {}
    self:refresh_stencil()
end

function Lake:draw(fov)
    -- Enable the stencil
    love.graphics.push()
    love.graphics.setStencil(self.stencilFunction)

    --if DEBUG then love.graphics.setStencil() end

    if not self.spriteBatches[self.frameNumber] then
        self:create_spritebatch(self.frameNumber)
    end

    love.graphics.setColor(255, 255, 255, LIGHT)
    love.graphics.draw(self.spriteBatches[self.frameNumber],
                       self.offset.x * SCALE_X, self.offset.y * SCALE_Y,
                       0, SCALE_X, SCALE_Y)

    if not DEBUG then
    -- Darken tiles that are out of the FOV
    for _, tile in pairs(self.tiles) do
        local pos = tile:get_position()
        if tile_in_table(pos, fov) then
            tile.hasBeenSeen = true
        else
            if tile.hasBeenSeen then
                love.graphics.setColor(0, 0, 0, LIGHT - DARK)
            else
                love.graphics.setColor(0, 0, 0, 255)
            end

            love.graphics.rectangle('fill',
                                    upscale_x(pos.x), upscale_y(pos.y),
                                    upscale_x(1), upscale_y(1))
        end

    end
    end

    -- Remove the stencil
    love.graphics.pop()
    love.graphics.setStencil()
end

function Lake:create_spritebatch(frameNumber)
    print('lake: creating spritebatch for frame ' .. frameNumber)

    -- Make a spritebatch for each frame
    local image = self.frames[frameNumber]
    local sb = love.graphics.newSpriteBatch(image, box_area(self.drawBox))

    sb:bind()
    sb:clear()
    for y = self.drawBox.y1, self.drawBox.y2 do
        for x = self.drawBox.x1, self.drawBox.x2 do
            for _, t in pairs(self.tiles) do
                if tiles_touching({x = x, y = y}, t) then
                    sb:add(x * TILE_W, y * TILE_H)
                    break
                end
            end
        end
    end
    sb:unbind()

    self.spriteBatches[frameNumber] = sb
end

function Lake:refresh_stencil()
    self.stencilFunction =
        function()
            love.graphics.setColor(255, 255, 255, 255)
            for _, t in pairs(self.tiles) do
                love.graphics.rectangle('fill',
                                        upscale_x(t.x), upscale_y(t.y),
                                        upscale_x(1), upscale_y(1))
            end
        end
end

function Lake:update()
    if self.frameTimer.value > 0 then
        self.frameTimer.value = self.frameTimer.value - 1
    else
        self.frameTimer.value = self.frameTimer.delay

        self.frameNumber = self.frameNumber + 1
        if self.frameNumber > #self.frames then
            self.frameNumber = 1
        end

    end

    if self.offset.timer.value > 0 then
        self.offset.timer.value = self.offset.timer.value - 1
    else
        self.offset.timer.value = self.offset.timer.delay

        self.offset.x = self.offset.x + self.offset.dir
        if math.abs(self.offset.x) == 3 then
            self.offset.dir = -self.offset.dir
        end
    end
end
