require('util.tile')

AI = class('AI')

AI_ACTION = {aim = 'aim', -- Get into a shooting position
             attack = 'attack', -- Use a weapon (if it would hurt an enemy)
             avoid = 'avoid', -- Avoid dangerous areas
             chase = 'chase', -- Move toward an enemy
             dodge = 'dodge', -- Get out of the (straight-line) path of a
                              -- sprite (if it's coming toward us)
             explore = 'explore', -- Walk around to try to find something
                                  -- interesting
             flee = 'flee', -- Move away from an enemy (if they are a threat)
             follow = 'follow', -- Move toward a specific target
             globetrot = 'globetrot', -- Move constantly from room to room
             heal = 'heal', -- Use an exilir (if we have one and need one)
             loot = 'loot'} -- Move toward an item

function AI:init(owner)
    self.owner = owner

    self.path = {nodes = nil, character = nil, destination = nil, retries = 0}

    -- Default AI levels
    -- Each level has:
    --   {dist = nil, prob = nil, target = nil, delay = nil}
    -- Aim distance is how close an enemy must be before we bother aiming at
    -- him

    -- Set the default AI levels
    self.level = {}
    for _, action in pairs(AI_ACTION) do
        self.level[action] = {}
    end

    -- Give dodge a default delay so we can get out of the way of our teammates
    self.level.dodge = {delay = .5}

    -- Give explore a default delay so any level of AI can get out of doorways
    self.level.explore = {delay = .5}

    self.reactions = {avenge = false}

    self.choiceTimer = {value = 0, delay = 0}

    self.exploredPositions = {}
end

function AI:aim_at(target)
    -- If we're already aimed at the target
    if self:is_aimed_at(target) then
        return false
    end

    local positions = {}

    -- Find the farthest (out from the target) eligible position on each of the
    -- four sides of the target
    for dir = 1, 4 do
        for dist = self.level.attack.dist - 1, 1, -1 do
            local pos = add_direction(target:get_position(), dir, dist)

            if self.owner.room:tile_walkable(pos) and
               self.owner.room:line_of_sight(pos, target:get_position()) then
                table.insert(positions, pos)
                break
            end
        end
    end

    -- Choose the position closest to us
    local best = {dist = 999, pos = nil}
    for _, pos in pairs(positions) do
        local dist = manhattan_distance(self.owner:get_position(), pos)
        if dist < best.dist then
            best.dist = dist
            best.pos = pos
        end
    end

    if best.pos then
        self:plot_path(best.pos, AI_ACTION.aim)
        return true
    end

    return false
end

function AI:attack()
    --local rangedWeapon = self.owner.armory:get_best_ranged_weapon()
    if self.owner.armory:switch_to_ranged_weapon() then
        -- Check if there's an enemy in our sights we should shoot
        for _, c in pairs(self.owner.room:get_characters()) do
            if self.owner:is_enemies_with(c) then
                if self:is_aimed_at(c) then
                    if self.owner.tag then
                        print('AI: shooting')
                    end

                    -- Switch to the ranged weapon
                    --self.owner.armory:set_current_weapon(rangedWeapon)

                    -- Express our desire to shoot
                    self.owner.shootDir = self.owner:direction_to(c.position)
                    self:reset_timer(AI_ACTION.attack)
                    return true
                end
            end
        end
    end

    local meleeWeapon = self.owner.armory:get_best_melee_weapon()
    if meleeWeapon then
        -- Check if there's an enemy next to us who we can hit
        for _, c in pairs(self.owner.room:get_characters()) do
            if self.owner:is_enemies_with(c) and
               tiles_touching(self.owner:get_position(), c:get_position()) then
                -- Switch to the melee weapon
                self.owner.armory:set_current_weapon(meleeWeapon)

                -- Walk into the enemy
                self.owner:step_toward(c:get_position())

                self:reset_timer(AI_ACTION.attack)
                return true
            end
        end
    end
end

function AI:avoid(area)
    -- If we are not in the area
    if not tile_in_table(self.owner:get_position(), area) then
        -- We don't need to avoid the area
        return false
    end

    -- Find a tile somewhere in the room that is not within the area
    while true do
        local tile = self.owner.room:get_free_tile()
        if not tile_in_table(tile, area) then
            self:plot_path(tile, AI_ACTION.avoid)
            return true
        end
    end
end

function AI:chase(target)
    if self.owner.tag then
        print('chase: new target:', target)
    end

    if target.room and target.room ~= self.owner.room then
        if self.owner.tag then
            print('chase: target is in different room')
        end

        target = self:find_exit_toward_target(target)

        -- If no exit was found (the target is > 1 room away)
        if not target then
            return
        end
    end

    -- Find the position of the target
    local pos
    if target.get_position then
        pos = target:get_position()
    elseif target.x and target.y then
        pos = target
    end

    -- Set path to destination
    if self:plot_path(pos, AI_ACTION.chase) then
        if not instanceOf(Exit, target) and
           not instanceOf(WaterTile, target) then
            if #self.path.nodes < 2 then
                self:delete_path()
                return false
            end

            -- Remove the last node so our destination is standing next to the
            -- target instead of bumping the target (chasing is distinct from
            -- attacking)
            table.remove(self.path.nodes, #self.path.nodes)

            -- Set the new last node as the new destination
            self.path.destination = self.path.nodes[#self.path.nodes]
        end

        self.path.target = target
        return true
    else
        self:delete_path()
        return false
    end
end

function AI:choose_action()
    if self.owner.tag then
        print('AI:choose_action()')
    end

    -- Go through each of our actions and roll the dice
    for action, properties in pairs(self.level) do
        -- If this action is not permanently disabled
        if properties.prob then
            if love.math.random(properties.prob, 10) == 10 then
                if self:do_action(action) then
                    if self.owner.tag then
                        print('  chose action ' .. action)
                    end
                    --return true
                end
            end
        end
    end

    return false
end

function AI:delete_path()
    self.path.destination = nil
    self.path.nodes = nil
    self.path.target = nil
    self.path.action = nil
end

function AI:do_action(action)
    local target

    if action == 'aim' then
        target = self:find_enemy()

        if target and self:target_in_range(target, action) then
            -- If we successfully switch to a ranged weapon with ammo
            if self.owner.armory:switch_to_ranged_weapon(true) then
                if self:aim_at(target) then
                    return true
                end
            end
        end
    elseif action == 'attack' and self:waited_to(action) then
        if self:attack() then
            return true
        end
    elseif action == 'avoid' and self:waited_to(action) and
           self.path.action ~= AI_ACTION.avoid and
           self.path.action ~= AI_ACTION.follow then
        local areas = self:find_dangerous_areas()

        -- If there are any dangerous areas
        if areas then
            for _, area in pairs(areas) do
                -- Try to avoid the area
                if self:avoid(area) then
                    return true
                end
            end
        end
    elseif action == 'chase' and
           (not self.path.nodes or self.path.action == AI_ACTION.explore) then
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
                if self:should_chase(target) then
                    ok = true
                end
            end
        end

        if ok then
            if self:target_in_range(target, action) and
               not self:is_afraid_of(target) then
                -- If we successfully switch to a melee weapon
                if self.owner.armory:switch_to_melee_weapon() then
                    self:chase(target)
                    return true
                end
            end
        end
    elseif action == 'dodge' then
        target = self:find_projectile()
        if target and self:target_in_range(target, action) then
            self:dodge(target)
            return true
        end
    elseif action == 'drop' and self:waited_to(action) then
        if self:drop_item() then
            return true
        end
    elseif action == 'flee' and self.path.action ~= AI_ACTION.flee then
        local threat = self:find_threat()
        if threat and self:target_in_range(threat, action) then
            self:flee_from(threat)
            return true
        end
    elseif action == 'follow' then
        target = self.level[action].target

        if self:follow(target) then
            return true
        end
    elseif action == 'globetrot' and
           (not self.path.nodes or
            self.path.action ~= AI_ACTION.globetrot) then
        if self:globetrot() then
            return true
        end
    elseif action == 'heal' and self:waited_to(action) then
        if self:heal() then
            return true
        end
    elseif action == 'loot' and
           (not self.path.nodes or self.path.action == AI_ACTION.explore) then
        target = self:find_item()
        if (target and self:target_in_range(target, action) and
            self:should_chase(target)) then
            self:plot_path(target:get_position(), AI_ACTION.loot)
            return true
        end
    elseif action == 'explore' and not self.path.nodes then
        -- Make sure we couldn't chase or loot first; only explore if we don't
        -- see anything interesting
        target = self:find_enemy()
        if target and self:target_in_range(target, AI_ACTION.attack) then
            return false
        end

        target = self:find_item()
        if target and self:target_in_range(target, AI_ACTION.loot) then
            return false
        end

        if not self.path.target then
            target = self:find_exit()

            if target and self:target_in_range(target, action) then
                if self.owner.tag then
                    print('    exploring toward exit')
                end
                self:plot_path(target:get_position(), AI_ACTION.explore)
            else
                self:plot_path(self:find_random_position(), AI_ACTION.explore)
            end

            return true
        end
    elseif action == 'wander' then
        -- Step in a random direction
        self.owner:step(love.math.random(1, 4))
        return true
    end

    return false
end

function AI:dodge(sprite, searchDir, followPathImmediately)
    local callFollowPath = true
    if followPathImmediately ~= nil then
        callFollowPath = followPathImmediately
    end

    if not searchDir then
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
    end

    -- Find the nearest tile which is out of the path of the projectile
    local x = self.owner.position.x
    local y = self.owner.position.y
    local destination, fallbackDestination
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

        local centerTileIsOccupied = false
        if not firstLoop then
            local ok, character
            ok, character = self.owner.room:tile_walkable({x = x, y = y})

            -- If the center tile is occupied with a character that is not us
            if character and character ~= self.owner then
                -- If the character is not our enemy
                if not self.owner:is_enemies_with(character) then
                    -- See this tile as unoccupied, since the character can
                    -- dodge us
                    ok = true
                end
            end

            if not ok or
               tiles_overlap({x = x, y = y}, sprite:get_position()) then
               centerTileIsOccupied = true
            end
        end

        -- If the center tile is occupied
        if centerTileIsOccupied then
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
                -- We already tried the other direction

                -- If we have a fallbackDestination
                if fallbackDestination then
                    destination = fallbackDestination
                else
                    destination = previousSearchPosition
                end

                break
            end
        else
            previousSearchPosition = {x = x, y = y}
            while #laterals > 0 do
                index = love.math.random(1, #laterals)
                choice = laterals[index]

                local ok, character = self.owner.room:tile_walkable(choice)

                -- If this tile choice contains a character that is not our
                -- enemy and thus who can dodge us if we walk into them
                if character then
                    if not self.owner:is_enemies_with(character) then
                        fallbackDestination = choice
                    end
                end

                -- If this tile choice is unoccupied
                if ok then
                    destination = choice
                    break
                else
                    -- Remove this choice from the table
                    table.remove(laterals, index)
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

    if destination ~= nil and
       not tiles_overlap(destination, self.owner:get_position()) then
       -- Set path to destination
       self:plot_path(destination, AI_ACTION.dodge)

       if callFollowPath then
           -- Start following the path
           self:follow_path(true)
       end
   end
end

function AI:drop_item()
    -- Check if we are holding anything we don't want
    for _, item in pairs(self.owner.inventory.items) do
        if not self.owner:wants_item(item) then
            --self.owner:drop_item_group({item})
            self.owner:drop_items({item})

            -- Only drop one item at a time, since our items table may have
            -- changed
            return true
        end
    end
end

function AI:find_dangerous_areas()
    local areas = {}

    -- Add any spikes in the room
    local area = {}
    for _, spike in pairs(self.owner.room.spikes) do
        for _, tile in pairs(spike:get_visible_tiles()) do
            table.insert(area, tile)
        end
    end
    table.insert(areas, area)

    return areas
end

function AI:find_enemy()
    -- Find the closest enemy
    local closestEnemy
    local closestDist = 999
    for _, s in pairs(self.owner.room.sprites) do
        -- If this is a character we see as an enemy
        if instanceOf(Character, s) and self.owner:is_enemies_with(s) then
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

function AI:find_exit()
    local visitedExits = {}

    -- Find a random exit in the room
    local exits = copy_table(self.owner.room.exits)
    repeat
        local index = love.math.random(1, #exits)
        local exit = exits[index]

        local ok = true

        -- If we are in the doorway of this exit (and thus just came from it)
        if tiles_overlap(self.owner.position, exit:get_doorway()) then
            ok = false
        -- If the exit is concealed by a false brick
        elseif exit:is_hidden() then
            ok = false
        -- If the exit leads to outside
        elseif exit.targetRoom == self.owner.room.game.outside then
            ok = false
        elseif self.owner:visited_room(exit.targetRoom) then
            ok = false
            table.insert(visitedExits, exit)
        end

        if ok then
            return exits[index]
        else
            -- Remove this exit from consideration
            table.remove(exits, index)
        end
    until #exits == 0

    -- If we still haven't chosen an exit, just choose one of the exits we have
    -- already been through
    if #visitedExits > 0 then
        return visitedExits[love.math.random(1, #visitedExits)]
    end
end

function AI:find_exit_toward_target(target)
    return self.owner.room:find_exit({targetRoom = target.room})
end

function AI:find_item()
    -- Find the closest item in the room
    local closestItem
    local closestDist = 999
    for _, item in pairs(self.owner.room.items) do
        if item.position then
            dist = manhattan_distance(item.position, self.owner.position)

            -- If the item is closer than the current closest, and we can pick
            -- it up
            if (dist < closestDist and
                self.owner.inventory:can_pick_up(item) and
                self:wants_item(item)) then
                closestDist = dist
                closestItem = item
            end
        end
    end

    return closestItem
end

function AI:find_projectile()
    local closestProjectile

    -- See if there is a projectile we should dodge
    local closestDist = 999
    for _, s in pairs(self.owner.room.sprites) do
        if instanceOf(Projectile, s) then
            -- If this is a projectile type that we want to dodge, and if it is
            -- heading toward us
            if self:should_dodge(s) and s:will_hit(self.owner) then
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

function AI:find_threat()
    -- Find the closest character who is a threat
    local best = {dist = 999, character = nil}
    for _, c in pairs(self.owner.room:get_characters()) do
        -- If the character is an enemy
        if self.owner:is_enemies_with(c) and self:is_afraid_of(c) then
            dist = manhattan_distance(c:get_position(), self.owner.position)

            -- If it's closer than the current closest
            if dist < best.dist then
                best.dist = dist
                best.character = c
            end
        end
    end

    if best.character then
        return best.character
    end
end

function AI:find_random_position()
    local positions = copy_table(self.owner.room.freeTiles)

    repeat
        local index = love.math.random(1, #positions)
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

        -- Don't go here if we have already explored a spot near here
        for _, exploredPos in pairs(self.exploredPositions) do
            if manhattan_distance(pos, exploredPos) <= 15 then
                ok = false
                break
            end
        end

        -- If this is the last spot left
        if #positions == 1 then
            ok = true
        end

        if ok then
            return pos
        else
            -- Remove this position from consideration
            table.remove(positions, index)
        end
    until #positions == 0
end

-- Find a diagonal position away from the threat
function AI:flee_from(threat)
    local tiles = copy_table(self.owner.room.freeTiles)

    -- Find directions that would take us closer to the threat
    local dirsToThreat = directions_to(self.owner:get_position(),
                                       threat:get_position())

    -- Make a table of directions that wouldn't take us closer to the threat
    local dirs = {}
    for i = 1, 4 do
        if not value_in_table(i, dirsToThreat) then
            table.insert(dirs, i)
        end
    end

    -- Pick a random valid direction in which to find a clear straight line
    local testTile = self.owner:get_position()
    local prevTile
    local dist = 0
    local movements = 0
    while #dirs > 0 and movements < 2 do
        local index = love.math.random(1, #dirs)
        local dir = dirs[index]

        repeat
            prevTile = testTile
            testTile = add_direction(testTile, dir)
            dist = dist + 1

            if self.owner.monsterType == 'scarab' then
                -- Randomly stop early and shorten the path, to look more
                -- erratic like a bug
                if dist >= 3 then
                    if love.math.random(1, 4) == 1 then
                        break
                    end
                end
            end
        until not self.owner.room:tile_walkable(testTile)
        dist = dist - 1
        testTile = prevTile

        -- Remove this direction from further consideration
        table.remove(dirs, index)

        movements = movements + 1
    end
    if dist >= 1 then
        self:plot_path(prevTile, AI_ACTION.flee)
        return true
    end

    self.owner:step(dirs[1])

    return false
end

function AI:follow(target)
    -- If we have any "avoid" AI
    if self.level.avoid.prob and self.level.avoid.prob > 0 then
        local areas = self:find_dangerous_areas()
        for _, area in pairs(areas) do
            -- If the target is in this dangerous area
            if tile_in_table(target:get_position(), area) then
                -- Do not follow the target
                return false
            end
        end
    end

    -- If the player is far enough away from us, or in a different room
    --if self:target_in_range(target, action) or
    if manhattan_distance(target:get_position(), self.owner:get_position()) >=
       self.level['follow'].dist or target.room ~= self.owner.room then
        if not self.path.nodes or self.path.action == AI_ACTION.explore then
            -- Follow the target
            self:chase(target)
            self.path.action = AI_ACTION.follow

            if self.path.nodes then
                -- Remove some nodes from the end of the path so that we end up
                -- staying our follow distance behind the target
                for i = 1, self.level['follow'].dist - 2 do
                    if #self.path.nodes > 1 then
                        table.remove(self.path.nodes)
                    else
                        break
                    end
                end
                self.path.destination = self.path.nodes[#self.path.nodes]
            end

            return true
        end
    end

    return false
end

function AI:follow_path(force)
    if self.owner.tag then
        if self.path.nodes then
            print('AI: follow_path()')
        end
        if self.path.action then
            print('  self.path.action: ', self.path.action)
        end
    end

    if not force then
        if self.path.action then
            if self:waited_to(self.path.action) then
                self:reset_timer(self.path.action)
            else
                return false
            end
        end
    end

    if not self.path.nodes then
        self:delete_path()
        return false
    end

    if self.owner.tag then
        print('AI: following path...')
    end

    -- If we have a specific object as our path's target
    if self.path.target then
        -- If the target is has a room, and it has entered another room
        if (self.path.target.room and
            self.path.target.room ~= self.owner.room) then
            if self.owner.tag then
                print('AI: target left the room')
            end
            -- Find the exit through which we can follow the target
            local exit = self:find_exit_toward_target(self.path.target)

            if exit then
                -- Start a new path toward the exit
                local pathAction = self.path.action
                self:chase(exit)
                self.path.action = pathAction
                return true
            else
                self:delete_path()
                return false
            end
        end
    end

    if self.owner.tag then
        print('  current position:', self.owner.position.x,
              self.owner.position.y)
        print('  next node:       ', self.path.nodes[1].x,
              self.path.nodes[1].y)
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
            self:delete_path()
            self.path.retries = 0
        end
    else
        -- We got off the path somehow; abort
        self:delete_path()

        if self.owner.tag then
            print('AI: aborted path')
        end

        --if self.path.destination and self.path.retries < 3 then
        --    if self.owner.tag then
        --        print('AI: got off path; plotting a new path to destination')
        --    end

        --    local oldPathAction = self.path.action
        --    self:plot_path(self.path.destination)
        --    self.path.retries = self.path.retries + 1
        --    self.path.action = oldPathAction
        --    return true
        --else
        --    self.path.retries = 0
        --    self:delete_path()

        --    return false
        --end
    end

    return true
end

function AI:get_distance_to_destination()
    -- If our path has a destination
    if self.path.destination then
        return manhattan_distance(self.owner.position, self.path.destination)
    end
end

function AI:globetrot()
    -- Make a copy of the room's exits
    local exits = copy_table(self.owner.room.exits)

    while #exits > 0 do
        local index = love.math.random(1, #exits)
        local e = exits[index]

        if not e:is_hidden() and
           e.targetRoom ~= self.owner.room.game.outside and
           #e.targetRoom.lakes == 0 then
            -- If this exit would not take us to the room where we just were,
            -- or this is the last exit left in consideration
            if e.targetRoom ~= self.oldRoom or #exits == 1 then
                -- Choose this exit
                self:plot_path(e:get_position(), AI_ACTION.globetrot)
                break
            end
        end

        -- Remove this exit from future consideration
        table.remove(exits, index)
    end

    return true
end

function AI:heal()
    local elixir = self.owner.inventory:get_item('elixir')

    if elixir and self.owner:get_health_percentage() < 50 then
        elixir:use()
    end
end

function AI:is_afraid_of(threat)
    local afraid = false

    -- If the threat has a usable weapon
    if threat:has_usable_weapon(self.owner) then
        afraid = true
    end

    if afraid then
        -- Check if we have a weapon we can use against the threat
        if self.owner:has_usable_weapon(threat) then
            afraid = false
        end
    end

    -- If we have low health and the threat is armed
    if self.owner:get_health_percentage() <= 25 and
       threat:has_usable_weapon(self.owner) then
        afraid = true
    end

    return afraid
end

function AI:is_aimed_at(target)
    if self:target_in_range(target, AI_ACTION.attack) then
        if instanceOf(ThunderStaff, self.owner.armory.currentWeapon) then
            return true
        elseif self.owner:line_of_sight(target) and
           not tiles_overlap(self.owner:get_position(),
                             target:get_position()) then
            return true
        end
    end
    return false
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

function AI:plot_path(dest, action)
    if self.owner.tag then
        print('  AI:plot_path()')
        print('    dest: ' .. dest.x .. ', ' .. dest.y)
        print('    action: ', action)
    end

    --if self.path.destination then
    --    if tiles_overlap(dest, self.path.destination) then
    --        self.path.nodes = nil
    --        return false
    --    end
    --end

    -- Cancel any previous steps this turn
    self.owner:step()

    -- Clear any previous path
    self:delete_path()

    self.path.action = action
    if self.owner.tag then
        print('AI: finding path to', dest.x, dest.y)
    end

    self.path.nodes = self.owner.room:plot_path(self.owner.position, dest)
    if not self.path.nodes then
        return false
    end

    self.path.destination = {x = dest.x, y = dest.y}

    if self.owner.tag and self.path.nodes then
        print('AI: new path\'s length: ', #self.path.nodes)
    end

    return true
end

function AI:receive_damage(amount, agent)
    if amount <= 0 then
        return
    end

    local perpetrator = get_ultimate_owner(agent)

    -- If the dude that hit us is not currently an enemy
    if not self.owner:is_enemies_with(perpetrator) then
        if self.reactions.avenge then
            -- See him as an enemy now
            self.owner:add_enemy(perpetrator)

            -- If the owner has an avenge() function
            if self.owner.avenge then
                self.owner:avenge()
            end
        else
            -- If the owner has a forgive() function
            if self.owner.forgive then
                self.owner:forgive()
            end
        end
    end
end

function AI:reset_timer(action)
    self.level[action].timer = self.owner:get_time()
end

function AI:should_dodge(sprite)
    if instanceOf(Arrow, sprite) then
        -- Ghosts are not afraid of arrows
        if self.owner.monsterType == 'ghost' then
            return false
        end
    end

    return true
end


function AI:should_chase(target)
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

function AI:target_in_range(target, action)
    if not self.level[action].dist then
        return false
    end

    local targetPosition = target:get_position()

    if targetPosition then
        local dist = manhattan_distance(self.owner.position, targetPosition)
        if action == 'chase' and self.owner.room == target.room and
           tiles_touching(self.owner.position, targetPosition) then
            -- We don't need to chase if we are standing right next to the
            -- target
            return false
        elseif dist <= self.level[action].dist then
            return true
        end
    end

    return false
end

function AI:add_to_explored_positions(position)
    if not tile_in_table(position, self.exploredPositions) then
        table.insert(self.exploredPositions, pos)
    end
end

function AI:update()
    if self.owner.tag then
        print('AI:update()')
    end

    -- If we just entered a different room
    if self.owner.room ~= self.oldRoom then
        -- Clear the old table of explored areas
        self.exploredPositions = {}
    end

    -- If we are outside (in a cutscene)
    if self.owner.room == self.owner.room.game.outside then
        -- Don't do any AI
        return
    end

    self.choseAction = false

    -- Continue to follow our current path (if we have one)
    local followedPath = self:follow_path()

    if followedPath then
        self:add_to_explored_positions(self.owner:get_position())
        self.choseAction = true
    end
    
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
                    if self:do_action('chase') then
                        self.choseAction = true
                    elseif self:do_action('loot') then
                        self.choseAction = true
                    else
                        self:plot_path(self:find_random_position())
                        self.path.action = AI_ACTION.explore
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

    if not self.choseAction then
        if self:waited_to_choose() then
            self:choose_action()
            self.choseAction = true

            -- If we just entered a different room
            if self.owner.room ~= self.oldRoom then
                self.oldRoom = self.owner.room
            end
        end
    end

    -- Update the choice delay timer
    if self.owner:get_time() >= (self.choiceTimer.value +
                                 self.choiceTimer.delay) then
        self.choiceTimer.value = self.owner:get_time()
    end
end

-- Returns true if we already waited the required delay # of seconds
function AI:waited_to(action)
    if not self.level[action].delay then
        return false
    end

    if not self.level[action].timer then
        self.level[action].timer = self.owner:get_time()
    end

    if (self.owner:get_time() >= self.level[action].timer +
                                self.level[action].delay) then
        return true
    else
        return false
    end
end

function AI:waited_to_choose()
    if self.owner:get_time() >= (self.choiceTimer.value +
                                 self.choiceTimer.delay) then
        return true
    else
        return false
    end
end

-- This function should be overridden if needed
function AI:wants_item(item)
    -- By default, we want all items
    return true
end
