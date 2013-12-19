require('class.brick')
require('class.door')
require('class.fovfinder')
require('class.roombuilder')
require('class.roomfiller')
require('class.tilecache')
require('class.spike')
require('class.switch')
require('class.turret')

Room = class('Room')

function Room:init(args)
    self.isGenerated = false
    self.isSecret = false
    self.isVisited = false
    self.bricksDirty = true
    self.physicsEnabled = true

    self.tileCache = TileCache()
    self.tileCache.room = self

    -- Drawables
    self.bricks = {}
    self.doors = {}
    self.hieroglyphs = {}
    self.items = {}
    self.lakes = {}
    self.spikes = {}
    self.sprites = {}
    self.switches = {}
    self.thunderbolts = {}

    self.exits = {}
    self.freeTiles = {}
    self.fovCache = {}
    self.messages = {}
    self.newMessageTimer = {value = 0, delay = 2}
    self.requiredObjects = {}
    self.turrets = {}

    if args then
        self.game = args.game
        self.exits = args.exits or {}
        self.index = args.index
    end
end

function Room:add_object(obj)
    if instanceOf(Sprite, obj) then
        table.insert(self.sprites, obj)
    elseif instanceOf(Brick, obj) then
        table.insert(self.bricks, obj)
    elseif instanceOf(Door, obj) then
        table.insert(self.doors, obj)
    elseif instanceOf(Hieroglyph, obj) then
        table.insert(self.hieroglyphs, obj)
    elseif instanceOf(Item, obj) then
        -- Add this item to the room's item table
        table.insert(self.items, obj)

        -- Clear ownership
        obj.owner = nil

        -- Re-enable animation
        obj.animationEnabled = true
    elseif instanceOf(Spike, obj) then
        table.insert(self.spikes, obj)
    elseif instanceOf(Switch, obj) then
        table.insert(self.switches, obj)
    elseif instanceOf(Thunderbolt, obj) then
        table.insert(self.thunderbolts, obj)
    elseif instanceOf(Turret, obj) then
        table.insert(self.turrets, obj)
    else
        return false
    end

    -- Add a reference to this room to the object
    obj.room = self

    if instanceOf(Hieroglyph, obj) or instanceOf(Switch, obj) or
       instanceOf(Brick, obj) or instanceOf(Door, obj) then
        -- Add the object to our tilecache
        self.tileCache:add(obj:get_position(), obj)
    end
end

function Room:add_message(message)
    table.insert(self.messages, message)
end

function Room:character_input()
    for _, c in pairs(self:get_characters()) do
        c:input()
    end
end

function Room:contains_npc()
    if self.isGenerated then
        for _, c in pairs(self:get_characters()) do
            if c.name then
                return true
            end
        end
    elseif self.requiredObjects then
        for _, ro in pairs(self.requiredObjects) do
            if instanceOf(Character, ro) and ro.name then
                return true
            end
        end
    end

    return false
end

function Room:draw()
    -- If we haven't found the FOV yet
    if not self.fov then
        -- Update the FOV
        self:update_fov()
    end

    -- Draw spikes
    self:draw_spikes()

    -- Draw bricks
    self:draw_bricks()

    -- Draw objects which can be seen darkly even when outside the FOV
    self:draw_objects_with_fov_alpha(self.hieroglyphs)
    self:draw_objects_with_fov_alpha(self.doors)
    self:draw_objects_with_fov_alpha(self.switches)

    for _, lake in pairs(self.lakes) do
        lake:draw(self.fov)
    end

    -- Draw items
    for _, i in pairs(self.items) do
        if tile_in_table(i.position, self.fov) or DEBUG then
            i:draw()
        end
    end

    -- Draw sprites
    for _, s in pairs(self.sprites) do
        if tile_in_table(s.position, self.fov) or s.isThundershocked or
            instanceOf(Fireball, s) or DEBUG then
            s:draw()
        end
    end

    -- Draw thunderbolts
    for _, tb in pairs(self.thunderbolts) do
        tb:draw()
    end

    self:draw_messages()

    if DEBUG then
        -- Show freeTiles
        for _, t in pairs(self.freeTiles) do
            love.graphics.setColor(255, 255, 255, 25)
            love.graphics.rectangle('fill', upscale_x(t.x), upscale_x(t.y),
                                    upscale_x(1), upscale_y(1))
        end

        -- Show midPaths
        for _, tile in pairs(self.midPaths) do
            if tiles_overlap(tile, self.midPoint) then
                love.graphics.setColor(255, 0, 0, 255)
            else
                love.graphics.setColor(100, 100, 100, 200)
            end
            love.graphics.rectangle('fill',
                                    upscale_x(tile.x), upscale_y(tile.y),
                                    upscale_x(1), upscale_y(1))
        end

        -- Show zone tiles
        --for _, tile in pairs(self.zoneTiles) do
        --    love.graphics.setColor(255, 243, 48, 180)
        --    love.graphics.rectangle('fill',
        --                            upscale_x(tile.x), upscale_y(tile.y),
        --                            upscale_x(1), upscale_y(1))
        --end

        -- Show nook tiles
        for _, nook in pairs(self.nooks) do
            for _, tile in pairs(nook) do
                love.graphics.setColor(255, 243, 48, 180)
                love.graphics.rectangle('fill',
                                        upscale_x(tile.x), upscale_y(tile.y),
                                        upscale_x(1), upscale_y(1))
            end
        end

        -- Show spikes
        for _, spike in pairs(self.spikes) do
            love.graphics.setColor(0, 200, 50, 180)
            love.graphics.rectangle('fill',
                                    upscale_x(spike.position.x),
                                    upscale_y(spike.position.y),
                                    upscale_x(1), upscale_y(1))
        end

        -- Show tiles in FOV
        for _, tile in pairs(self.fov) do
            love.graphics.setColor(0, 255, 0)
            love.graphics.setLineWidth(1)
            love.graphics.setLineStyle('rough')
            love.graphics.rectangle('line',
                                    upscale_x(tile.x), upscale_y(tile.y),
                                    upscale_x(1), upscale_y(1))
        end

        -- Show turrets
        for _, t in pairs(self.turrets) do
            love.graphics.setColor(0, 0, 255, 255)
            love.graphics.rectangle('fill',
                                    upscale_x(t.position.x),
                                    upscale_y(t.position.y),
                                    upscale_x(1), upscale_y(1))
        end

        -- Show false bricks
        for _, b in pairs(self.bricks) do
            if instanceOf(FalseBrick, b) then
                love.graphics.setColor(50, 50, 255, 255)
                love.graphics.rectangle('fill', upscale_x(b.x), upscale_x(b.y),
                                        upscale_x(1), upscale_y(1))
            end
        end

        -- Show AI targets
        for _, c in pairs(self:get_characters()) do
            if c.ai and c.ai.path.destination then
                local pos = c.ai.path.destination
                love.graphics.setColor(220, 100, 0, 200)
                love.graphics.rectangle('fill',
                                        upscale_x(pos.x), upscale_y(pos.y),
                                        upscale_x(1), upscale_y(1))
            end
        end
    end
end

function Room:draw_bricks()
    if self.bricksDirty then
        self.brickBatch:bind()

        -- Clear old bricks
        self.brickBatch:clear()

        -- Add each brick to the correct spriteBatch
        local lightness
        local dist
        for _, b in pairs(self.bricks) do
            --local dist = manhattan_distance(b, self.game.player.position)
            if tile_in_table(b, self.fov) then
                b.hasBeenSeen = true
                --lightness = LIGHT - dist * .04--((2 ^ dist) * .05)
                lightness = LIGHT
            else
                lightness = DARK
            end

            if DEBUG then
                lightness = LIGHT
            end

            if b.hasBeenSeen or DEBUG then
                self.brickBatch:setColor(lightness, lightness, lightness)
                self.brickBatch:add(b.x * TILE_W, b.y * TILE_H)
            end
        end

        self.brickBatch:unbind()

        self.bricksDirty = false
    end

    --love.graphics.setColor(WHITE)
    love.graphics.draw(self.brickBatch, upscale_x(0), upscale_y(0),
                       0, SCALE_X, SCALE_Y)
end

function Room:draw_messages()
    -- If there is a message on the queue
    if self.messages[1] then
        -- Draw the message
        self.messages[1]:draw()
    end
end

function Room:draw_objects_with_fov_alpha(objects)
    for _, object in pairs(objects) do
        local alpha
        if tile_in_table(object:get_position(), self.fov) then
            object.hasBeenSeen = true
            alpha = LIGHT
        else
            alpha = DARK
        end

        if DEBUG then alpha = LIGHT end

        if object.hasBeenSeen or DEBUG then
            love.graphics.setColor(255, 255, 255, alpha)
            object:draw(alpha)
        end
    end
end

function Room:draw_spikes()
    for _, spike in pairs(self.spikes) do
        local tiles = spike:get_visible_tiles()
        for i, tile in pairs(tiles) do
            local inFOV = tile_in_table(tile, self.fov)
            local lightness

            if inFOV then
                lightness = LIGHT
                spike.hasBeenSeen[i] = true
            else
                lightness = DARK
            end

            if DEBUG then lightness = LIGHT end

            local stencilFunction =
                function ()
                    love.graphics.rectangle('fill',
                                            upscale_x(tile.x),
                                            upscale_y(tile.y),
                                            upscale_x(1), upscale_y(1))
                end

            love.graphics.push()
            love.graphics.setStencil(stencilFunction)

            if spike.hasBeenSeen[i] or DEBUG then
                spike:draw(nil, lightness)
            end

            love.graphics.setStencil()
            love.graphics.pop()
        end
    end
end

function Room:find_exit(search)
    return search_table(self.exits, search)
end

function Room:generate_all()
    if not self.isBuilt then
        -- Ignore any current build
        self.isBeingBuilt = false

        local roomBuilder = RoomBuilder(self)
        roomBuilder:build()
    end

    repeat until self:generate_next_piece()
end

function Room:generate_next_piece()
    if self.isGenerated then
        return true
    end

    if not self.roomFiller then
        -- Update the tile cache with the locations of bricks, exits, and
        -- freeTiles from the roombuilder
        self:add_roombuilder_result_to_tilecache()
        self.roomFiller = RoomFiller(self)
    end

    -- Continue filling the room with monsters, items, etc.
    if self.roomFiller:fill_next_step() then
        -- Make a spriteBatch for drawing bricks
        self.brickBatch = love.graphics.newSpriteBatch(brickImg, #self.bricks)

        -- Mark the generation process as complete
        self.isGenerated = true

        -- Free up the memory used by the roomBuilder and roomFiller
        self.roomBuilder = nil
        self.roomFiller = nil

        if DEBUG then
            print('generated room ' .. self.index)
        end

        -- Flag that room is generated
        return true
    end

    -- Flag that room is not finished generating
    return false
end

-- Returns a table of all characters in the room
function Room:get_characters()
    local characters = {}

    for _, s in pairs(self.sprites) do
        if instanceOf(Character, s) then
            table.insert(characters, s)
        end
    end

    return characters
end

function Room:get_collidable_objects()
    return concat_tables({self.bricks, self.doors})
end

-- Return a random free position in the room
function Room:get_free_tile()
    local freeTiles = copy_table(self.freeTiles)
    while #freeTiles > 0 do
        local index = love.math.random(1, #freeTiles)
        if self:tile_walkable(freeTiles[index]) then
            return freeTiles[index]
        else
            table.remove(freeTiles, index)
        end
    end
end

-- Returns a table of all monsters in the room
function Room:get_monsters()
    local monsters = {}

    for _, s in pairs(self.sprites) do
        if instanceOf(Monster, s) then
            table.insert(monsters, s)
        end
    end

    return monsters
end

function Room:get_next_room()
    if #self.exits == 2 then
        for _, exit in pairs(self.exits) do
            if exit.targetRoom.distanceFromStart > self.distanceFromStart then
                return exit.targetRoom
            end
        end
    end
end

function Room:get_previous_room()
    if #self.exits == 2 then
        for _, exit in pairs(self.exits) do
            if exit.targetRoom.distanceFromStart < self.distanceFromStart then
                return exit.targetRoom
            end
        end
    end
end

function Room:is_audible()
    if self.game.currentRoom == self then
        return true
    else
        return false
    end
end

function Room:line_of_sight(a, b)
    if tiles_overlap(a, b) then
        return true
    end

    -- Vertical
    if a.x == b.x then
        xDir = 0
        if a.y < b.y then
            yDir = 1
        else
            yDir = -1
        end
    -- Horizontal
    elseif a.y == b.y then
        yDir = 0
        if a.x < b.x then
            xDir = 1
        else
            xDir = -1
        end
    else
        return false
    end

    -- Find any occupied tiles between a and b
    local x, y = a.x, a.y
    while true do
        x = x + xDir
        y = y + yDir

        if tiles_overlap({x = x, y = y}, b) then
            -- Reached the destination
            return true
        end

        if not self:tile_walkable({x = x, y = y}) then
            -- Encountered an occupied tile
            return false
        end
    end
end

function Room:plot_path(src, dest)
    -- Create a table of the room's occupied nodes
    local hotLava = {}
    for _, brick in pairs(self.bricks) do
        table.insert(hotLava, brick:get_position())
    end
    for _, door in pairs(self.doors) do
        if door:is_collidable() then
            table.insert(hotLava, door:get_position())
        end
    end

    local characterPositions = {}
    for _, c in pairs(self:get_characters()) do
        table.insert(characterPositions, c:get_position())
    end

    local pf = PathFinder(src, dest, hotLava, characterPositions,
                          {smooth = true})
    local path = pf:plot()

    -- Remove first node from path
    table.remove(path, 1)

    if #path > 0 then
        return path
    else
        return nil
    end
end

function Room:remove_dead_objects(objects)
    local temp = {}
    for _, o in pairs(objects) do
        if o.isDead then
            --self:remove_object(o)
        else
            table.insert(temp, o)
        end
    end
    return temp
end

function Room:remove_object(obj)
    -- Remove the object from its tile in our tile cache
    if obj.get_position then
        self.tileCache:remove(obj:get_position(), obj)
    end

    if instanceOf(Item, obj) then
        for i, item in pairs(self.items) do
            if item == obj then
                table.remove(self.items, i)
                break
            end
        end
    elseif instanceOf(Sprite, obj) then
        --for i, s in pairs(self.sprites) do
        --    if s == obj then
        --        table.remove(self.sprites, i)
        --        break
        --    end
        --end
        remove_value_from_table(obj, self.sprites)
    end
end

function Room:sweep()
    -- Remove dead sprites
    self.sprites = self:remove_dead_objects(self.sprites)

    -- Remove dead bricks
    self.bricks = self:remove_dead_objects(self.bricks)

    -- Remove dead turrets
    self.turrets = self:remove_dead_objects(self.turrets)

    -- Remove dead thunderbolts
    self.thunderbolts = self:remove_dead_objects(self.thunderbolts)

    -- Keep only items with a position and no owner
    local items = {}
    for _, item in pairs(self.items) do
        if item.position and not item.owner then
            table.insert(items, item)
        end
    end
    self.items = items
end

-- Returns true if an item can be safely dropped here
function Room:tile_is_droppoint(tile, ignoreCharacter)
    -- Check if the tile is overlapping with a collidable object in the tile
    -- cache, or the tile is not in the room
    local furnitureTile = self.tileCache:get_tile(tile)
    if furnitureTile.isExit then
        return false
    elseif furnitureTile.isPartOfRoom then
        for _, object in pairs(furnitureTile.contents) do
            if object:is_collidable() then
                return false
            end
        end
    else
        return false
    end

    local characters = self:get_characters()

    -- If a character was specified to ignore
    if ignoreCharacter then
        for i, c in pairs(characters) do
            if c == ignoreCharacter then
                table.remove(characters, i)
                break
            end
        end
    end

    -- If this tile overlaps with a character or an item
    if tile_in_table(tile, concat_tables({characters, self.items})) then
        return false
    end

    return true
end

function Room:tile_in_room(tile)
    local furnitureTile = self.tileCache:get_tile(tile)
    if furnitureTile.isPartOfRoom then
        return true
    else
        return false
    end
end

-- Return true if tile can be walked on right now (contains no collidable
-- objects)
function Room:tile_walkable(tile)
    local cachedTile = self.tileCache:get_tile(tile)

    -- If the tile is not in the room
    if not cachedTile.isPartOfRoom then
        return false
    end

    -- Check if there is a collidable object in the tile
    for _, object in pairs(cachedTile.contents) do
        if object:is_collidable() then
            return false
        end
    end

    -- Create a table of collidable characters
    local collidables = {}
    for _, c in pairs(self:get_characters()) do
        if c:is_collidable() then
            table.insert(collidables, c)
        end
    end

    -- If the tile's position is occupied by that of a collidable sprite
    for _, c in pairs(collidables) do
        if tiles_overlap(tile, c:get_position()) then
            -- Return both false and the specific character which is blocking
            -- this tile
            return false, c
        end
    end

    return true
end

function Room:update()
    if not self.isGenerated then
        return
    end

    -- Get monsters' directional input
    self:character_input()

    -- Clear some character states
    for _, c in pairs(self:get_characters()) do
        c.isThundershocked = false
        c.rug = false
        c.wasHurtBySpike = false
    end

    -- Let characters shoot all weapons except thunderstaves
    for _, c in pairs(self:get_characters()) do
        if c.shootDir and
           c.armory:get_current_weapon_type() ~= 'thunderstaff' then
            c:shoot(c.shootDir)
            c.shootDir = nil
        end
    end

    -- Update turrets
    for _, t in pairs(self.turrets) do
        t:update()
    end

    -- Update items
    for _, i in pairs(self.items) do
        i:update()
    end

    -- Update switches
    for _, switch in pairs(self.switches) do
        switch:update()
    end

    -- Update doors
    for _, door in pairs(self.doors) do
        door:update()
    end

    -- If we have a spike timer
    if self.spikeTimer then
        -- Update the spike timer
        if self.spikeTimer.value > 0 then
            self.spikeTimer.value = self.spikeTimer.value - 1
        else
            self.spikeTimer.value = self.spikeTimer.delay

            if self:is_audible() and #self.spikes > 0 then
                sounds.spikes:play()
            end

            for _, spike in pairs(self.spikes) do
                spike:trigger()
            end
        end
    end

    -- Update spikes
    for _, spike in pairs(self.spikes) do
        spike:update()
    end

    -- Update lakes
    for _, lake in pairs(self.lakes) do
        lake:update()
    end

    -- Update sprites
    for _, s in pairs(self.sprites) do
        if instanceOf(Character, s) then
            -- If this is a player or an NPC
            --if instanceOf(Player, s) or s.name then
            --    -- Regenerate health
            --    s:recharge_health()
            --end

            s:recharge_magic()
        end

        s:update()
    end

    if self.physicsEnabled then
        -- Run physics on all sprites
        for _, s in pairs(self.sprites) do
            s:physics()

            -- If the sprite is still in this room
            if s.room == self then
                -- If this is a character
                if instanceOf(Character, s) then
                    -- Check if he is on an item
                    s:check_for_items()
                end
            end
        end
    end
    for _, s in pairs(self.sprites) do
        if self.physicsEnabled then
            s:post_physics()
        end

        -- Reset one-frame variables
        s.wantsToTrade = false
        s.isGrabbing = false
    end

    -- Let characters shoot any remaining weapons
    for _, c in pairs(self:get_characters()) do
        if c.shootDir then
            c:shoot(c.shootDir)
            c.shootDir = nil
        end
    end

    -- Clean up dead objects
    self:sweep()

    -- Mark all thunderbolts as dead so they will be swept up next time
    for _, tb in pairs(self.thunderbolts) do
        tb.isDead = true
    end

    if self.game.player.moved and not self.game.player.isDead then
        for _, sprite in pairs(self.sprites) do
            if not instanceOf(Trader, sprite) then
                -- If this sprite has a mouth which should speak
                if sprite.mouth and sprite.mouth:should_speak() then
                    sprite.mouth:speak()

                    -- Face the player
                    --local dir = sprite:direction_to(self.game.player:get_position())
                    --sprite.dir = dir
                end
            end
        end
    end

    -- Update messages
    self:update_messages()

    -- If this is the game's current room
    if self.game.currentRoom == self then
        if self.game.player.moved then
            self:update_fov()
        end
    end
end

function Room:update_fov()
    self.bricksDirty = true

    -- Check if the player's position is in the FOV cache
    for _, fov in pairs(self.fovCache) do
        if tiles_overlap(fov.origin, self.game.player.position) then
            self.fov = fov.fov

            if DEBUG then
                print('used cached FOV')
            end
            return
        end
    end

    -- Clear the old FOV
    self.fov = {}

    -- Find player's Field Of View
    fovFinder = FOVFinder({origin = self.game.player.position,
                           room = self,
                           radius = 10})
    self.fov = fovFinder:find()

    -- Add this FOV to the FOV cache
    table.insert(self.fovCache, {origin = self.game.player.position,
                                 fov = self.fov})
end

function Room:update_messages()
    -- If there is a message on our queue
    if self.messages[1] then
        if self.newMessageTimer.value > 0 then
            self.newMessageTimer.value = self.newMessageTimer.value - 1
        else
            self.messages[1]:update()
        end

        local removeMessage = false

        -- If the message is finished displaying
        if self.messages[1].finished then
            -- Remove it from the queue
            removeMessage = true

        -- If the message's mouth is no longer in the room
        elseif self.messages[1].mouth and self.messages[1].mouth.sprite and
           self.messages[1].mouth.sprite.room ~= self then
            -- Move the message to the new room
            self.messages[1].mouth.sprite.room:add_message(self.messages[1])
            removeMessage = true
        end

        if removeMessage then
            local oldMessage = self.messages[1]
            table.remove(self.messages, 1)
            local newMessage = self.messages[1]

            -- If there is another message on the queue
            if newMessage then
                -- If the new message has a different speaker
                if newMessage.avatar ~= oldMessage.avatar or
                   newMessage.mouth ~= oldMessage.mouth then
                   -- Start a timer so that the next message does not display
                   -- in the very next frame
                   self.newMessageTimer.value = self.newMessageTimer.delay
                else
                    -- Start the next message now
                    newMessage:update()
                end
            end
        end

        return true
    end

    return false
end

function Room:add_roombuilder_result_to_tilecache()
    -- Add bricks
    for _, brick in pairs(self.bricks) do
        self.tileCache:add(brick:get_position(), brick)
    end

    -- Add freeTiles
    for _, ft in pairs(self.freeTiles) do
        self.tileCache:add(ft)
    end

    -- Add exits
    for _, exit in pairs(self.exits) do
        self.tileCache:add(exit:get_position(), exit, {isExit = true})

        -- Add the exit's doorway
        self.tileCache:add(exit:get_doorway(), nil, {isDoorway = true})
    end
end
