require('class.brick')

-- A FalseBrick is a brick that is breakable and conceals a hidden exit
FalseBrick = class('FalseBrick', Brick)

function FalseBrick:set_sister(falseBrick)
    self.sister = falseBrick
end

function FalseBrick:is_audible()
    return self.room:is_audible()
end

function FalseBrick:receive_hit(agent)
    if agent then
        -- Stop agent from moving until direction is pressed again
        agent.attackedDir = agent.dir
    end

    -- Die when we are hit
    self.isDead = true

    -- Remove ourself from the room's tile cache
    local tile = self.room:get_tile(self:get_position())
    remove_value_from_table(self, tile.contents)

    -- Force a redraw of the room's bricks
    self.room.bricksDirty = true

    if self:is_audible() then
        sounds.monster.die:play()
        sounds.secret:play()
    end

    if self.sister and not self.sister.isDead then
        self.sister:receive_hit()
    end

    return FalseBrick.super.receive_hit(self, agent)
end
