WaterTile = class('WaterTile')

function WaterTile:init(pos)
    self.x = pos.x
    self.y = pos.y
end

function WaterTile:receive_hit(agent)
    if instanceOf(Projectile, agent) then
        return false
    end

    return true
end
