require('util.graphics')

-- A Thunderbolt is a visual display of a ThunderStaff's power; it is purely
-- aesthetic
Thunderbolt = class('Thunderbolt')

function Thunderbolt:init(args)
    self.nodes = args.nodes
    self.staff = args.staff

    self.scale = SCALE_X
end

function Thunderbolt:find_points()
    self.points = {}
    for i, n in pairs(self.nodes) do
        local x, y

        if i == 1 then
            -- Put the first point directly on the ball of the staff
            if self.staff.owner and self.staff.owner.mirrored then
                x = (n.x * TILE_W) + 1
            else
                x = (n.x * TILE_W) + 6
            end
            y = (n.y * TILE_H) + 1
        elseif i == #self.nodes then
            -- Put the last point in the middle of the tile
            x = (n.x * TILE_W) + (TILE_W / 2)
            y = (n.y * TILE_H) + (TILE_H / 2)
        else
            -- Choose a random point somewhere within the unscaled screen
            -- coordinates of this tile
            x = math.random(n.x * TILE_W, (n.x + 1) * TILE_W - 1)
            y = math.random(n.y * TILE_H, (n.y + 1) * TILE_H - 1)
        end

        table.insert(self.points, {x = x, y = y})
    end
end

function Thunderbolt:draw()
    if not self.points or self.scale ~= SCALE_X then
        self.scale = SCALE_X
        self:find_points()
    end

    love.graphics.setColor(WHITE)
    love.graphics.setLine(SCALE_X, 'rough')

    for i = 1, #self.points - 1 do
        local p1 = self.points[i]
        local p2 = self.points[i + 1]

        --love.graphics.line(p1.x, p1.y, p2.x, p2.y)
        bresenham_line(p1.x, p1.y, p2.x, p2.y)
    end
end
