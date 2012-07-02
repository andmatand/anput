require('util/tile')

AI = class('AI')

AI_ACTION = {dodge = 1,
             flee = 2,
             chase = 3,
             shoot = 4,
             wander = 5}

function AI:init(owner)
    self.owner = owner

    self.path = {nodes = nil, character = nil, destination = nil}

    -- Default AI levels
    self.level = {}
    self.level.dodge = {dist = nil, prob = nil, target = nil, delay = nil}
    self.level.flee = {dist = nil, prob = nil, target = nil, delay = nil}
    self.level.chase = {dist = nil, prob = nil, target = nil, delay = nil}
    self.level.shoot = {dist = nil, prob = nil, target = nil, delay = nil}
    self.level.wander = {dist = nil, prob = nil, target = nil, delay = nil}

    self.aiTimer = 0
end

function AI:afraid_of(sprite)
    if instanceOf(Arrow, sprite) then
        if self.owner.monsterType == MONSTER_TYPE.ghost then
            return false
        end
    end

    return true
end

function AI:chase(target)
    -- Set path to destination
    self:find_path(target:get_position())
    self.path.action = AI_ACTION.chase
    if instanceOf(Character, target) then
        self.path.character = target
    else
        self.path.character = nil
    end

    -- Start following the path
    self:follow_path()
end

function AI:choose_action()
    self.level.dodge.target = nil
    if self:waited_to('dodge') then
        -- See if there is a projectile we should dodge
        local closestDist = 999
        for _, s in pairs(self.owner.room.sprites) do
            if instanceOf(Projectile, s) then
                -- If this is a projectile type that we want to dodge, and if
                -- it is heading toward us
                if self:afraid_of(s) and s:will_hit(self.owner) then
                    local dist = manhattan_distance(s.position,
                                                    self.owner.position)

                    -- If it's closer than the current closest projectile
                    if dist < closestDist then
                        closestDist = dist
                        self.level.dodge.target = s
                    end
                end
            end
        end
    end

    self.closestEnemy = nil
    if (self:waited_to('chase') or self:waited_to('shoot') or
        self:waited_to('flee')) then
        -- Find the closest character on other team
        local closestDist = 999
        for _, s in pairs(self.owner.room.sprites) do
            -- If this is a character on the other team
            if instanceOf(Character, s) and s.team ~= self.owner.team then
                dist = manhattan_distance(s.position, self.owner.position)

                -- If it's closer than the current closest
                if dist < closestDist then
                    closestDist = dist
                    self.closestEnemy = s
                end
            end
        end
    end

    self.level.shoot.target = nil
    if self:waited_to('shoot') then
        -- Check if there's an enemy in our sights we should shoot
        for _,s in pairs(self.owner.room.sprites) do
            if instanceOf(Character, s) and s.team ~= self.owner.team then
                if self.owner:line_of_sight(s) then
                    self.level.shoot.target = s
                end
            end
        end
    end

    self.level.chase.target = nil
    if self:waited_to('chase') then
        -- If we are chasing a character
        if self.path.character then
            -- If the character we were chasing entered another room
            if self.path.character.room ~= self.owner.room then
                local exit = self.owner.room:get_exit({room =
                                                 self.path.character.room})
                self.level.chase.target = exit

                if DEBUG then
                    print('new chase target: exit')
                end
            end
        end

        -- If we don't already have a potential chase target
        if not self.level.chase.target then
            -- If we are not already following a path, or we are following a
            -- path that is now obsolete
            if not self.path.nodes or self:path_obsolete() then
                --if DEBUG then
                --    print('new chase target: closest enemy')
                --end

                -- Set the closest enemy as our chase target
                self.level.chase.target = self.closestEnemy
            end
        end
    end

    -- Set the flee target
    self.level.flee.target = self.closestEnemy

    -- Give random scores to each of the AI actions
    for k, a in pairs(self.level) do
        if (a.prob and -- This action is not disabled
            a.target and -- This action has a target
            manhattan_distance(self.owner.position, -- Target is close enough
                               a.target:get_position()) <= a.dist) then
            a.score = math.random(a.prob, 10)
        else
            a.score = -1
        end
    end

    -- See which action has the best score
    local highestProb = 0
    local action = nil
    for k, v in pairs(self.level) do
        if v.score == 10 and v.prob > highestProb then
            highestProb = v.prob
            action = AI_ACTION[k]
            --print('best so far:', k)
        end
    end

    -- If no action was chosen, and we're not following a path
    if not action and not self.path.nodes then
        if self.level.wander.prob then
            if math.random(self.level.wander.prob, 10) == 10 then
                action = AI_ACTION.wander
            end
        end
    end

    return action
end

function AI:dodge(sprite)
    -- Determine which direction we should search
    if sprite.velocity.y == -1 then
        -- Sprite is moving north, so search north
        searchDir = 1
    elseif sprite.velocity.x == 1 then
        -- Sprite is moving east, so search east
        searchDir = 2
    elseif sprite.velocity.y == 1 then
        -- Sprite is moving south, so search south
        searchDir = 3
    elseif sprite.velocity.x == -1 then
        -- Sprite is moving west, so search west
        searchDir = 4
    else
        -- Sprite is not moving; nothing to dodge
        return
    end

    -- Find the nearest tile which is out of the path of the projectile
    x = self.owner.position.x
    y = self.owner.position.y
    destination = nil
    switchedDir = false
    firstLoop = true
    while not destination do
        -- Add the lateral tiles
        if searchDir == 1 then
            laterals = {{x = x - 1, y = y}, {x = x + 1, y = y}}
        elseif searchDir == 2 then
            laterals = {{x = x, y = y - 1}, {x = x, y = y + 1}}
        elseif searchDir == 3 then
            laterals = {{x = x - 1, y = y}, {x = x + 1, y = y}}
        elseif searchDir == 4 then
            laterals = {{x = x, y = y - 1}, {x = x, y = y + 1}}
        end

        -- If the center tile is occupied
        if (firstLoop == false and
            not self.owner.room:tile_walkable({x = x, y = y})) then
            if switchedDir == false then
                -- We can't get to the lateral tiles, start searching in the
                -- other direction
                for i = 1,2 do -- Increment direction by two, wrapping around
                    searchDir = searchDir + 1
                    if searchDir > 4 then
                        searchDir = 1
                    end
                end
                x = self.owner.position.x
                y = self.owner.position.y
                switchedDir = true
            else
                -- We already tried the other direction; abort
                break
            end
        else
            while #laterals > 0 do
                index = math.random(1, #laterals)
                choice = laterals[index]

                -- If this tile choice is occupied
                if not self.owner.room:tile_walkable(choice) then
                    -- Remove this choice from the table
                    table.remove(laterals, index)
                else
                    destination = choice
                    break
                end
            end
        end

        -- Move to forward/back from the sprite we're trying to dodge
        if searchDir == 1 then
            y = y - 1
        elseif searchDir == 2 then
            x = x + 1
        elseif searchDir == 3 then
            y = y + 1
        elseif searchDir == 4 then
            x = x - 1
        end

        firstLoop = false
    end

    if destination ~= nil then
        -- Set path to destination
        self:find_path(destination)
        self.path.action = AI_ACTION.dodge

        -- Start following the path
        self:follow_path()
    end
end

function AI:flee_from(sprite)
    if not self:waited_to('flee') then
        return
    end

    local currentDistance = manhattan_distance(self.owner.position, sprite.position)
    local neighborTiles = find_neighbor_tiles(self.owner.position,
                                              self.owner.room.bricks,
                                              {diagonals = false})

    -- Iterate through our neighboring tiles
    for _, n in pairs(neighborTiles) do
        -- If this tile is not occupied by a brick
        if not n.occupied then
            -- If this tile is farther away from the sprite than our current
            -- position
            if manhattan_distance(n, sprite.position) > currentDistance then
                self.owner:step_toward(n)
                break
            end
        end
    end
end

function AI:find_path(dest)
    if DEBUG then
        print('finding path to', dest.x, dest.y)
    end

    self.path.nodes = self.owner.room:find_path(self.owner.position, dest,
                                                self.owner.team)
    self.path.destination = {x = dest.x, y = dest.y}
end

function AI:follow_path()
    if self.path.action == AI_ACTION.chase then
        if not self:waited_to('chase') then
            return
        end
    elseif self.path.action == AI_ACTION.dodge then
        if not self:waited_to('dodge') then
            return
        end
    end

    if not self.path.nodes then
        return false
    end

    -- If we are adjacent to the next tile of the path
    if tiles_touching(self.owner.position, self.path.nodes[1]) then
        -- Step onto the next tile of the path
        self.owner:step(self.owner:direction_to(self.path.nodes[1]))

        -- Pop the step off the path
        table.remove(self.path.nodes, 1)

        if #self.path.nodes == 0 then
            if DEBUG then
                print('path complete!')
            end
            self.path.nodes = nil
        end
    else
        -- We got off the path somehow; abort
        self.path.nodes = nil
        if DEBUG then
            print('aborted path')
        end
        return false
    end

    return true
end

function AI:path_obsolete()
    -- If we're chasing a character
    if self.path.destination and self.path.character then
        -- If the destination of our path is too far away from where the
        -- character now is
        if manhattan_distance(self.path.destination,
                              self.path.character.position) > 5 then
            --print('path is obsolete')
            return true
        end
    end
    return false
end

function AI:update()
    -- Increment timer for AI delay
    self.aiTimer = self.aiTimer + 1
    if self.aiTimer > 99 then
        self.aiTimer = 0
    end

    -- Continue to follow our current path (if we have one)
    self:follow_path()

    -- Check if we should dodge a Player on our team walking at us
    for _, s in pairs(self.owner.room.sprites) do
        if instanceOf(Player, s) and s.team == self.owner.team then
            if s:will_hit(self.owner) then
                self:dodge(s)
                return
            end
        end
    end

    self.action = self:choose_action()

    if self.action == AI_ACTION.dodge then
        --print('action: dodge')
        self:dodge(self.level.dodge.target)
    elseif self.action == AI_ACTION.flee then
        --print('action: flee')
        self:flee_from(self.level.flee.target)
    elseif self.action == AI_ACTION.chase then
        -- print('action: chase')
        self:chase(self.level.chase.target)
    elseif self.action == AI_ACTION.shoot then
        --print('action: shoot')
        self.owner:shoot(self.owner:direction_to(
                                    self.level.shoot.target.position))
    elseif self.action == AI_ACTION.wander then
        -- Step in a random direction
        self.owner:step(math.random(1, 4))
    end
end

-- Returns true if we already waited the required delay # of frames
function AI:waited_to(action)
    if not self.level[action].delay then
        return false
    end

    if (self.aiTimer % self.level[action].delay == 0 or
        self.level[action].delay == 0) then
        return true
    else
        return false
    end
end
