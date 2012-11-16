require('class.watertile')
require('util.tile')

Lake = class('Lake')

function Lake:init(tiles)
    -- Convert all the given tiles to WaterTiles
    self.tiles = {}
    for _, t in pairs(tiles) do
        table.insert(self.tiles, WaterTile(t))
    end

    self.frames = images.water
    self.frameNumber = 1
    self.frameTimer = {delay = 10, value = 0}
    self.offset = {x = 0, y = 0, dir = 1,
                   timer = {delay = 5, value = 0}}

    self.drawBox = find_box_surrounding(tiles)
    self.drawBox.x1 = self.drawBox.x1 - 1
    self.drawBox.x2 = self.drawBox.x2 + 1

    -- Make a spritebatch for each frame
    self.spriteBatches = {}
    for _, image in pairs(self.frames) do
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

        table.insert(self.spriteBatches, sb)
    end

    local stencilFunction =
        function()
            love.graphics.setColor(255, 255, 255, 255)
            for _, t in pairs(self.tiles) do
                love.graphics.rectangle('fill',
                                        upscale_x(t.x), upscale_y(t.y),
                                        upscale_x(1), upscale_y(1))
            end
        end

    self.stencil = love.graphics.newStencil(stencilFunction)
end

function Lake:draw(fov)
    -- Enable the stencil
    if not DEBUG then
        love.graphics.setStencil(self.stencil)
    end

    love.graphics.setColorMode('modulate')
    love.graphics.setColor(255, 255, 255, LIGHT)
    love.graphics.draw(self.spriteBatches[self.frameNumber],
                       self.offset.x * SCALE_X, self.offset.y * SCALE_Y,
                       0, SCALE_X, SCALE_Y)

    -- Darken tiles that are out of the FOV
    love.graphics.setColor(0, 0, 0, LIGHT - DARK)
    for y = self.drawBox.y1, self.drawBox.y2 do
        for x = self.drawBox.x1, self.drawBox.x2 do
            if not tile_in_table({x = x, y = y}, fov) and not DEBUG then
                love.graphics.rectangle('fill',
                                        upscale_x(x), upscale_y(y),
                                        upscale_x(1), upscale_y(1))
            end
        end
    end

    -- Remove the stencil
    love.graphics.setStencil()
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
