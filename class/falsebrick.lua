require('class.brick')

-- A FalseBrick is a brick that is breakable and conceals a hidden exit
FalseBrick = class('FalseBrick', Brick)

function FalseBrick:is_audible()
    return self.room:is_audible()
end

function FalseBrick:receive_hit(agent)
    -- Die when we are hit
    self.dead = true

    -- Stop agent from moving until direction is pressed again
    agent.attackedDir = agent.dir

    -- Force a redraw of the room's bricks
    self.room.bricksDirty = true

    if self:is_audible() then
        sounds.monster.die:play()
        sounds.secret:play()
    end

    return FalseBrick.super.receive_hit(self, agent)
end
