-- A MapDisplay draws a visual representation of the map
MapDisplay = class('MapDisplay')

function MapDisplay:init(map)
    self.map = map

    self.nodes = self.map.nodes
    self.size = {w = 9, h = 9}
    self.flash = {timer = 0, state = false}
end

function MapDisplay:draw(currentRoom)
    -- Place the display right of the center of the screen
    self.nodeSize = 3 * SCALE_X
    self.gridPosition = {x = math.floor((GRID_W / 2) + 4),
                         y = math.floor((GRID_H / 2) - (self.size.h / 2))}
    self.position = {x = upscale_x(self.gridPosition.x),
                     y = upscale_y(self.gridPosition.y)}
    self:find_map_offset()

    -- Draw a border
    draw_border(self.gridPosition.x, self.gridPosition.y,
                self.size.w, self.size.h)

    love.graphics.push()
    love.graphics.translate(self.position.x + self.mapOffset.x,
                            self.position.y + self.mapOffset.y)

    for _, n in pairs(self.nodes) do
        if n.room.isVisited or DEBUG then
            if n.room == currentRoom and self.flash.state then
                love.graphics.setColor(MAGENTA)
            elseif n.room == self.map.artifactRoom then
                love.graphics.setColor(CYAN)
            elseif n.room:contains_npc() then
                love.graphics.setColor(CYAN)
            elseif DEBUG and n.room.roadblock then
                love.graphics.setColor(1, 0, 0)
            elseif DEBUG and n.firstSecretRoom then
                love.graphics.setColor(0, 0, 1)
            elseif DEBUG and n.room.isSecret then
                love.graphics.setColor(1, 243 / 255, 48 / 255)
            elseif DEBUG and n.sourceNode ~= n then
                -- This is a branch
                love.graphics.setColor(0, 243 / 255, 48 / 255)
            else
                love.graphics.setColor(WHITE)
            end

            love.graphics.rectangle('fill',
                                    n.x * self.nodeSize, n.y * self.nodeSize,
                                    self.nodeSize, self.nodeSize)
        end
    end

    if DEBUG and not self.flash.state then
        -- Draw hotLava
        love.graphics.setColor(1, 0, 100 / 255)
        for _, n in pairs(self.map.hotLava) do
            love.graphics.rectangle('fill',
                                    n.x * self.nodeSize, n.y * self.nodeSize,
                                    self.nodeSize, self.nodeSize)
        end
    end

    -- Undo the graphics translation
    love.graphics.pop()

    if DEBUG then
        -- Display the path length
        cga_print('PATH LENGTH: ' .. #self.map.path, 1, 3)
    end
end

-- Find offset necessary to center the map onscreen
function MapDisplay:find_map_offset()
    -- Find the furthest outside positions in the cardinal directions
    local n, e, s, w

    for _, node in pairs(self.nodes) do
        if node.room.isVisited or DEBUG then
            if not n or node.y < n then
                n = node.y
            end
            if not e or node.x > e then
                e = node.x
            end
            if not s or node.y > s then
                s = node.y
            end
            if not w or node.x < w then
                w = node.x
            end
        end
    end

    local mapW = ((e - w) + 1) * self.nodeSize
    local mapH = ((s - n) + 1) * self.nodeSize

    local displayW = upscale_x(self.size.w) --self.x2 - self.x1 + 1
    local displayH = upscale_y(self.size.h) --self.y2 - self.y1 + 1

    self.mapOffset = {x = (displayW / 2) - (mapW / 2) - (w * self.nodeSize),
                      y = (displayH / 2) - (mapH / 2) - (n * self.nodeSize)}
end

function MapDisplay:update()
    if self.flash.timer > 0 then
        self.flash.timer = self.flash.timer - 1
    else
        self.flash.state = not self.flash.state
        self.flash.timer = 4
    end
end
