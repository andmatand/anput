-- A Sprite is a physics object
Sprite = class('Sprite')

function Sprite:init()
    self.room = nil
    self.position = {x = nil, y = nil}
    self.oldPosition = self.position
    self.velocity = {x = 0, y = 0}
    self.friction = 1
    self.moved = false
    self.didPhysics = false
    self.canMove = true

    -- Alias x and y for position
    --self.x = function() return self.position.x end
    --self.y = function() return self.position.y end
end

function Sprite:die()
    self.isDead = true
end

function Sprite:get_position()
    return {x = self.position.x, y = self.position.y}
end

function Sprite:is_audible()
    return self.room:is_audible()
end

-- Preview what position the sprite will be at when its velocity is added
function Sprite:preview_position()
    if not self.position.x or not self.position.y then
        return {x = nil, y = nil}
    end

    -- Only one axis may have velocity at a time
    if self.velocity.x and self.velocity.x ~= 0 then
        return {x = self.position.x + self.velocity.x, y = self.position.y}
    elseif self.velocity.y and self.velocity.y ~= 0 then
        return {x = self.position.x, y = self.position.y + self.velocity.y}
    else
        return {x = self.position.x, y = self.position.y}
    end
end

-- Default hit method
function Sprite:hit(patient)
    if patient then
        if instanceOf(Projectile, patient) then
            -- Don't stop when hitting a projectile
            return false
        elseif not patient.receive_hit or not patient:receive_hit(self) then
            -- Don't stop if the patient did not receive the hit
            return false
        end

        if not self.hitSomethingLastFrame then
            if instanceOf(Brick, patient) or instanceOf(Door, patient) then
                if self:is_audible() then
                    sounds.thud:play()
                end
            end
        end
    end

    -- Stop
    self.velocity.x = 0
    self.velocity.y = 0

    self.hitSomething = true

    -- Valid hit
    return true
end

function Sprite:move_to_room(room)
    if self.room then
        -- Remove ourself from our current room
        self.room:remove_object(self)
    end

    -- Add ourself to the new room
    room:add_object(self)

    if instanceOf(Character, self) then
        self:add_visited_room(room)
    end
end

function Sprite:physics(force)
    if (self.didPhysics or not self.room.isGenerated or not self.canMove) and
       not force then
        return
    else
        self.didPhysics = true
    end

    self.oldPosition = {x = self.position.x, y = self.position.y}
    self.moved = false
    self.hitSomethingLastFrame = self.hitSomething
    self.hitSomething = false

    -- Do nothing if the sprite is not moving
    if self.velocity.x == 0 and self.velocity.y == 0 then
        if instanceOf(Monster, self) then
            -- Clear attackedDir
            self.attackedDir = nil
        end
        if not force then
            return
        end
    end

    -- Make sure velocity does not contain nil values
    if not self.velocity.x then self.velocity.x = 0 end
    if not self.velocity.y then self.velocity.y = 0 end

    -- Create a test version of our position and room
    local test = {position = {x = self.position.x, y = self.position.y},
                  room = self.room}

    -- Restrict velocity to only one axis at a time (no diagonal moving)
    if self.velocity.x ~= 0 and self.velocity.y ~= 0 then
        self.velocity.y = 0
    end

    -- Compute test coordinates for potential new position
    test.position.x = test.position.x + self.velocity.x
    test.position.y = test.position.y + self.velocity.y
    
    -- Check for collision with collidable objects
    local tile = test.room:get_tile(test.position)
    for i = 1, #tile.contents do
        local object = tile.contents[i]
        if self:hit(object) then
            -- Register this as a hit; we are done with physics
            return
        end
    end

    -- Iterate through the room's exits
    for _, e in pairs(test.room.exits) do
        -- If we are going to hit this exit
        if tiles_overlap(test.position, e) then
            -- If we are a player
            if instanceOf(Player, self) then
                -- Generate the room if it hasn't already been generated
                if not e.targetRoom.isGenerated then
                    e.targetRoom:generate_all()
                end
            end

            -- If the room it leads to has been generated
            if e.targetRoom.isGenerated then
                local oldRoom = test.room

                -- Move test object to new room
                test.room = e.targetRoom

                -- Move the test coordinates to the doorway of the
                -- corresponding exit
                local newExit = test.room:get_exit({targetRoom = oldRoom})
                test.position = newExit:get_doorway()

                break
            else
                return
            end
        end
    end

    -- Check for collision with other sprites
    for i = 1, #test.room.sprites do
        local s = test.room.sprites[i]

        if s and s ~= self then
            if tiles_overlap(test.position, s.position) then
                -- If the other sprite hasn't done its physics yet
                if s.didPhysics == false and s.owner ~= self then
                    -- Run its physics
                    s.physics(s)
                end

                -- If we are still colliding with the other sprite
                if tiles_overlap(test.position, s.position) then
                    -- Hit the sprite
                    if self:hit(s) then
                        if test.room ~= self.room then
                            -- Sweep up in case we killed something
                            test.room:sweep()
                        end

                        -- Registered as a hit; done with physics
                        return
                    end
                end
            -- If the other sprite hasn't done physics yet, and we would have
            -- hit it if it had already
            elseif s.didPhysics == false and
                   tiles_overlap(test.position, s:preview_position()) then
                -- Allow us to move
                self.position = {x = test.position.x, y = test.position.y}
                if test.room ~= self.room then
                    self:move_to_room(test.room)
                end
                self.moved = true

                -- Do physics on the other sprite (will hit us)
                s.physics(s)

                -- Register a hit for us
                if self:hit(s) then
                    return
                end
            end
        end
    end

    -- Check for collision with water tiles
    for _, lake in pairs(test.room.lakes) do
        for i = 1, #lake.tiles do
            local tile = lake.tiles[i]

            if tiles_overlap(test.position, tile) then
                if self:hit(tile) then
                    if instanceOf(Player, self) then
                        self.mouth:set_speech('LOOKS LIKE THIS AREA IS FLOODED')
                        self.mouth:speak()
                    end

                    return
                end
            end
        end
    end

    -- Apply friction
    if self.velocity.x < 0 then
        self.velocity.x = self.velocity.x + self.friction
    elseif self.velocity.x > 0 then
        self.velocity.x = self.velocity.x - self.friction
    end
    if self.velocity.y < 0 then
        self.velocity.y = self.velocity.y + self.friction
    elseif self.velocity.y > 0 then
        self.velocity.y = self.velocity.y - self.friction
    end

    -- Since there were no hits, make the move for real
    self.position = {x = test.position.x, y = test.position.y}
    if test.room ~= self.room then
        self:move_to_room(test.room)
    end

    self.moved = true
end

-- Default post-physics method
function Sprite:post_physics()
    self.didPhysics = false
end

function Sprite:receive_hit(agent)
    -- Register as a hit
    return true
end

function Sprite:set_position(position)
    self.position = {x = position.x, y = position.y}
end

function Sprite:update()
end

--function Sprite:get_direction()
--    if self.velocity.y == -1 then
--        return 1
--    elseif self.velocity.x == 1 then
--        return 2
--    elseif self.velocity.y == 1 then
--        return 3
--    elseif self.velocity.x == -1 then
--        return 4
--    end
--end

function Sprite:line_of_sight(patient)
    return self.room:line_of_sight(self.position, patient.position)
end

function Sprite:will_hit(patient)
    ok = false

    if self.velocity.y == -1 then
        -- Moving north
        if self.position.x == patient.position.x and
           (self.position.y == patient.position.y + 1 or
            (self.friction == 0 and self.position.y > patient.position.y)) then
            ok = true
        end
    end
    if self.velocity.y == 1 then
        -- Moving south
        if self.position.x == patient.position.x and
           (self.position.y == patient.position.y - 1 or
            (self.friction == 0 and self.position.y < patient.position.y)) then
            ok = true
        end
    end
    if self.velocity.x == -1 then
        -- Moving west
        if self.position.y == patient.position.y and
           (self.position.x == patient.position.x + 1 or
            (self.friction == 0 and self.position.x > patient.position.x)) then
            ok = true
        end
    end
    if self.velocity.x == 1 then -- Moving east
        if self.position.y == patient.position.y and
           (self.position.x == patient.position.x - 1 or
            (self.friction == 0 and self.position.x < patient.position.x)) then
            ok = true
        end
    end

    if ok and self:line_of_sight(patient) then
        return true
    else
        return false
    end
end


-- Non-Class Functions
function get_ultimate_owner(obj)
    while obj.owner do
        obj = obj.owner
    end

    return obj
end
