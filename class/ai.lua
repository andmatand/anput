require('util.tile')

AI = class('AI')

AI_ACTION = {dodge = 1,  -- Dodge a sprite (if it's coming at us)
             flee = 2,   -- Flee from an enemy
             chase = 3,  -- Chase an enemy
             seek = 4,   -- Walk around to try to find something interesting
             shoot = 5}  -- Shoot (if a target is lined up)

function AI:init(owner)
    self.owner = owner

    self.path = {nodes = nil, character = nil, destination = nil}

    -- Default AI levels
    self.level = {}
    self.level.dodge = {dist = nil, prob = nil, target = nil, delay = nil}
    self.level.flee = {dist = nil, prob = nil, target = nil, delay = nil}
    self.level.chase = {dist = nil, prob = nil, target = nil, delay = 1}
    self.level.loot = {dist = nil, prob = nil, target = nil, delay = nil}
    self.level.seek = {dist = nil, prob = nil, target = nil, delay = nil}
    self.level.shoot = {dist = nil, prob = nil, target = nil, delay = nil}
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
    if self.owner.tag then
        print('AI: chasing new target:', target)
    end

    -- Find the position of the target
    local pos
    if target.get_position then
        pos = target:get_position()
    elseif target.x and target.y then
        pos = target
    end

    -- Set path to destination
    self:plot_path(pos)
    self.path.action = AI_ACTION.chase
    self.path.target = target

    -- Start following the path
    self:follow_path(true)
end

function AI:choose_action()
    -- Go through each of our actions and roll the dice
    for action, properties in pairs(self.level) do
        local ok = false

        -- If this action is not permanently disabled
        if properties.prob then
            if math.random(properties.prob, 10) == 10 or force then
                if self:do_action(action) then
                    return true
                end
            end
        end
    end

    return false
end

function AI:do_action(action, force)
    if not force then
        if not self:waited_to(action) then
            return false
        end
    end

    local target

    if action == 'chase' then
        target = self:find_enemy()

        local ok = false

        -- If a potential target was found
        if target then
            -- If we aren't current following a target
            if not self.path.target then
                ok = true
            -- If this target is different from our current path's target
            elseif target ~= self.path.target then
                -- If this target is closer than our current destination
                if self:should_follow(target) then
                    ok = true
                end
            end
        end

        if ok then
            if self:target_in_range(target, action) then
                --if self.owner.tag then
                --    print('AI: found enemy:', target)
                --end

                self:chase(target)
                return true
            end
        end
    elseif action == 'dodge' then
        target = self:find_projectile()
        if target then
            self:dodge(target)
            return true
        end
    elseif action == 'flee' then
        target = self:find_enemy()
        if target and self:target_in_range(target, action) then
            self:flee_from(target)
            return true
        end
    elseif action == 'loot' then
        target = self:find_item()
        if (target and self:target_in_range(target, action) and
            self:should_follow(target)) then
            self:chase(target)
            return true
        end
    elseif action == 'seek' then
        if self:do_action('chase', true) then
            return true
        elseif self:do_action('loot', true) then
            return true
        elseif not self.path.target then
            target = self:find_exit()

            if target and self:target_in_range(target, action) then
                self:chase(target)
                return true
            else
                if self.owner.tag then
                    print('AI: seeking')
                end
                self:chase(self:find_random_position())
                return true
            end
        end
    elseif action == 'shoot' then
        -- Check if there's an enemy in our sights we should shoot
        for _, c in pairs(self.owner.room:get_characters()) do
            if c.team ~= self.owner.team then
                if (self:target_in_range(c, action) and
                    self.owner:line_of_sight(c)) then
                    return self.owner:shoot(self.owner:direction_to(c.position))
                end
            end
        end
    elseif action == 'wander' then
        -- Step in a random direction
        self.owner:step(math.random(1, 4))
        return true
    end

    return false
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
    local x = self.owner.position.x
    local y = self.owner.position.y
    local destination = nil
    local switchedDir = false
    local firstLoop = true
    local previousSearchPosition
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
                -- We already tried the other direction; 
                destination = previousSearchPosition
                break
            end
        else
            previousSearchPosition = {x = x, y = y}
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
        self:plot_path(destination)
        self.path.action = AI_ACTION.dodge

        -- Start following the path
        self:follow_path()
    end
end

function AI:find_enemy()
    -- Find the closest character on other team
    local closestEnemy
    local closestDist = 999
    for _, s in pairs(self.owner.room.sprites) do
        -- If this is a character on the other team
        if instanceOf(Character, s) and s.team ~= self.owner.team then
            dist = manhattan_distance(s.position, self.owner.position)

            -- If it's closer than the current closest
            if dist < closestDist then
                closestDist = dist
                closestEnemy = s
            end
        end
    end

    return closestEnemy
end

function AI:find_random_position()
    local positions = copy_table(self.owner.room.freeTiles)

    repeat
        local index = math.random(1, #positions)
        local pos = positions[index]

        local ok = true

        -- Don't allow non-walkable tiles in the room
        if not self.owner.room:tile_walkable(pos) then
            ok = false
        end

        -- Don't allow doorways
        for _, e in pairs(self.owner.room.exits) do
            if tiles_overlap(pos, e:get_doorway()) then
                ok = false
                break
            end
        end

        if ok then
            return pos
        else
            -- Remove this position from consideration
            table.remove(positions, index)
        end
    until #positions == 0
end

function AI:find_exit()
    -- Find a random exit in the room
    local exits = copy_table(self.owner.room.exits)
    repeat
        local index = math.random(1, #exits)

        local ok = true

        -- If we are in the doorway of this exit (and thus just came from it)
        if tiles_overlap(self.owner.position, exits[index]:get_doorway()) then
            ok = false
        -- If the exit is concealed by a false brick
        elseif exits[index]:is_hidden() then
            ok = false
        end

        if ok then
            return exits[index]
        else
            -- Remove this exit from consideration
            table.remove(exits, index)
        end
    until #exits == 0
end

function AI:find_item()
    -- Find the closest item in the room
    local closestItem
    local closestDist = 999
    for _, item in pairs(self.owner.room.items) do
        if item.position then
            dist = manhattan_distance(item.position, self.owner.position)

            -- If it's closer than the current closest
            if dist < closestDist then
                closestDist = dist
                closestItem = item
            end
        end
    end

    return closestItem
end

function AI:get_distance_to_destination()
    -- If our path has a destination
    if self.path.destination then
        return manhattan_distance(self.owner.position, self.path.destination)
    end
end

function AI:get_time()
    return self.owner.room.game.time
end

function AI:plot_path(dest)
    if self.owner.tag then
        print('AI: finding path to', dest.x, dest.y)
    end

    self.path.nodes = self.owner.room:plot_path(self.owner.position, dest,
                                                self.owner.team)
    self.path.destination = {x = dest.x, y = dest.y}

    if self.owner.tag and self.path.nodes then
        print('AI: new path\'s length: ', #self.path.nodes)
    end
end

function AI:find_projectile()
    local closestProjectile

    -- See if there is a projectile we should dodge
    local closestDist = 999
    for _, s in pairs(self.owner.room.sprites) do
        if instanceOf(Projectile, s) then
            -- If this is a projectile type that we want to dodge, and if it is
            -- heading toward us
            if self:afraid_of(s) and s:will_hit(self.owner) then
                local dist = manhattan_distance(s.position,
                                                self.owner.position)

                -- If it's closer than the current closest projectile
                if dist < closestDist then
                    closestDist = dist
                    closestProjectile = s
                end
            end
        end
    end

    return closestProjectile
end

function AI:flee_from(sprite)
    if not self:waited_to('flee') then
        return false
    end

    local currentDistance = manhattan_distance(self.owner.position,
                                               sprite.position)
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
                return true
            end
        end
    end

    return false
end

function AI:follow_path(force)
    if self.path.action == AI_ACTION.chase then
        if not force then
            if not self:waited_to('chase') then
                return false
            end
        end
    elseif self.path.action == AI_ACTION.dodge then
        if not force then
            if not self:waited_to('dodge') then
                return false
            end
        end
    end

    if not self.path.nodes then
        return false
    end

    if self.owner.tag then
        print('AI: following path...')
    end

    -- If we have a specific object as our path's target
    if self.path.target then
        -- If the target is not an exit, and it has a room, and it has entered
        -- another room
        if (not instanceOf(Exit, self.path.target) and
            self.path.target.room and
            self.path.target.room ~= self.owner.room) then
            if self.owner.tag then
                print('AI: target left the room')
            end
            -- Find the exit through which we can follow the target
            local exit = self.owner.room:get_exit({room =
                                                   self.path.target.room})

            if exit then
                -- Start a new path toward the exit
                self:chase(exit)
                return true
            else
                self.path.destination = nil
                self.path.nodes = nil
                self.path.target = nil
            end
        end
    end

    -- If we are adjacent to the next tile of the path
    if tiles_touching(self.owner.position, self.path.nodes[1]) then
        if self.owner.tag then
            print('AI: stepping')
        end

        -- Step onto the next tile of the path
        self.owner:step(self.owner:direction_to(self.path.nodes[1]))

        -- Pop the step off the path
        table.remove(self.path.nodes, 1)

        if #self.path.nodes == 0 then
            if self.owner.tag then
                print('AI: path complete!')
            end
            self.path.destination = nil
            self.path.nodes = nil
            self.path.target = nil
        end
    else
        -- We got off the path somehow; abort
        self.path.destination = nil
        self.path.nodes = nil
        self.path.target = nil

        if self.owner.tag then
            print('AI: aborted path')
        end
        return false
    end

    return true
end

function AI:path_obsolete()
    -- If we're chasing a character (since characters can move)
    if (self.path.destination and self.path.target and
        instanceOf(Character, self.path.target)) then
        -- If the destination of our path is too far away from where the
        -- character now is
        if manhattan_distance(self.path.destination,
                              self.path.target:get_position()) > 5 then
            if self.owner.tag then
                print('AI: path is obsolete')
            end
            return true
        end
    end
    return false
end

function AI:target_in_range(target, action)
    if not self.level[action].dist then
        return false
    end

    local targetPosition = target:get_position()

    if targetPosition then
        if manhattan_distance(self.owner.position, targetPosition) <=
           self.level[action].dist then
            return true
        end
    end

    return false
end

function AI:should_follow(target)
    -- If we don't currently have a destination
    if not self.path.destination then
        return true
    else
        local targetPosition
        if target.get_position then
            targetPosition = target:get_position()
        else
            targetPosition = {x = target.x, y = target.y}
        end

        -- If the given target's position is closer to us than our current
        -- destination
        if (manhattan_distance(self.owner.position, targetPosition) <
            self:get_distance_to_destination()) then
            return true
        else
            return false
        end
    end
end

function AI:update()
    self.choseAction = false

    -- Continue to follow our current path (if we have one)
    local followedPath = self:follow_path()
    
    if not self.path.nodes and not followedPath then
        -- Check if we are standing in a doorway
        for _, e in pairs(self.owner.room.exits) do
            if tiles_overlap(self.owner.position, e:get_doorway()) then
                if self.owner.tag then
                    print('AI: in doorway; leaving')
                end

                -- If we just came in from a different room
                if self.owner.room ~= self.oldRoom then
                    -- Try actions that will get us further into the room
                    if self:do_action('chase', true) then
                        self.choseAction = true
                    elseif self:do_action('loot', true) then
                        self.choseAction = true
                    else
                        self:chase(self:find_random_position())
                        self.choseAction = true
                    end
                --else
                --    -- Go through the doorway
                --    self.owner:step_toward(e:get_position())
                --    self.choseAction = true
                end

            end
        end
    end

    -- If we just entered a different room
    if self.owner.room ~= self.oldRoom then
        self.oldRoom = self.owner.room
    end

    -- Check if we should dodge a Player on our team walking at us
    for _, s in pairs(self.owner.room.sprites) do
        if instanceOf(Player, s) and s.team == self.owner.team then
            if s:will_hit(self.owner) then
                self:dodge(s)
                self.choseAction = true
            end
        end
    end

    if not self.choseAction then
        self:choose_action()
        self.choseAction = true
    end

    self:update_timers()
end

function AI:update_timers()
    -- Update the delay timers for each action
    for action, properties in pairs(self.level) do
        if properties.delay then
            if (not properties.timer or
                self:get_time() >= properties.timer + properties.delay) then
                properties.timer = self:get_time()
            end
        end
    end
end

-- Returns true if we already waited the required delay # of seconds
function AI:waited_to(action)
    if not self.level[action].delay or not self.level[action].timer then
        return false
    end

    if (self:get_time() >= self.level[action].timer +
                                self.level[action].delay) then
        return true
    else
        return false
    end
end
