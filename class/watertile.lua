WaterTile = class('WaterTile')

function WaterTile:init(pos, lake)
    self.x = pos.x
    self.y = pos.y
    self.lake = lake
end

function WaterTile:receive_hit(agent)
    if instanceOf(Projectile, agent) then
        return false
    end

    return true
end

function WaterTile:get_position()
    return {x = self.x, y = self.y}
end
