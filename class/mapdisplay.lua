-- A MapDisplay draws a visual representation of the map
MapDisplay = class('MapDisplay')

function MapDisplay:init(nodes)
    self.nodes = nodes

    -- Place the display in the center of the screen
    self.nodeSize = 3 * SCALE_X

    self.size = {w = 9, h = 9}

    local position = {x = math.floor((SCREEN_W / 2) - (self.size.w / 2)),
                      y = math.floor((SCREEN_H / 2) - (self.size.h / 2))}
    self.position = {x = upscale_x(position.x),
                     y = upscale_y(position.y)}
end

function MapDisplay:draw(currentRoom)
    if self.mapOffset == nil then
        self:find_map_offset()
    end

    -- Draw a border
    love.graphics.setColor(WHITE)
    love.graphics.rectangle('fill',
                            self.position.x - upscale_x(1),
                            self.position.y - upscale_y(1),
                            upscale_x(self.size.w + 2),
                            upscale_y(self.size.h + 2))
    love.graphics.setColor(BLACK)
    love.graphics.rectangle('fill',
                            self.position.x,
                            self.position.y,
                            upscale_x(self.size.w),
                            upscale_y(self.size.h))

    love.graphics.push()
    love.graphics.translate(self.position.x + self.mapOffset.x,
                            self.position.y + self.mapOffset.y)

    for _, n in pairs(self.nodes) do
        if n.room.visited then
            if n.room == currentRoom then
                love.graphics.setColor(MAGENTA)
            elseif n.finalRoom then
                love.graphics.setColor(CYAN)
            elseif n.room:contains_npc() then
                love.graphics.setColor(CYAN)
            else
                love.graphics.setColor(WHITE)
            end

            love.graphics.rectangle('fill',
                                    n.x * self.nodeSize, n.y * self.nodeSize,
                                    self.nodeSize, self.nodeSize)
        end
    end

    -- Undo the graphics translation
    love.graphics.pop()
end

-- Find offset necessary to center the map onscreen
function MapDisplay:find_map_offset()
    -- Find the furthest outside positions in the cardinal directions
    local n = 0
    local e = 0
    local s = 0
    local w = 0

    for _,j in pairs(self.nodes) do
        if j.y < n then
            n = j.y
        end
        if j.x > e then
            e = j.x
        end
        if j.y > s then
            s = j.y
        end
        if j.x < w then
            w = j.x
        end
    end

    local mapW = ((e - w) + 1) * self.nodeSize
    local mapH = ((s - n) + 1) * self.nodeSize

    local displayW = upscale_x(self.size.w) --self.x2 - self.x1 + 1
    local displayH = upscale_y(self.size.h) --self.y2 - self.y1 + 1

    self.mapOffset = {x = (displayW / 2) - (mapW / 2) - (w * self.nodeSize),
                      y = (displayH / 2) - (mapH / 2) - (n * self.nodeSize)}
end
