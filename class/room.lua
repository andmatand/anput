require('class.fovfinder')
require('class.roombuilder')
require('class.roomfiller')

Room = class('Room')

function Room:init(args)
    self.isGenerated = false
    self.isSecret = false
    self.visited = false
    self.bricksDirty = true

    -- Drawables
    self.bricks = {}
    self.hieroglyphs = {}
    self.items = {}
    self.thunderbolts = {}
    self.sprites = {}

    self.exits = {}
    self.freeTiles = {}
    self.fovCache = {}
    self.messages = {}
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
        -- Add this sprite to the room's sprite table
        table.insert(self.sprites, obj)
    elseif instanceOf(Turret, obj) then
        -- Add this turret to the room's turret table
        table.insert(self.turrets, obj)
    elseif instanceOf(Item, obj) then
        -- Add this item to the room's item table
        table.insert(self.items, obj)

        -- Clear ownership
        obj.owner = nil

        -- Re-enable animation
        obj.animationEnabled = true
    elseif instanceOf(Thunderbolt, obj) then
        table.insert(self.thunderbolts, obj)
    elseif instanceOf(Brick, obj) then
        table.insert(self.bricks, obj)
    else
        return false
    end

    -- Add a reference to this room to the object
    obj.room = self
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

    if DEBUG then
        -- Show freeTiles
        for _, t in pairs(self.freeTiles) do
            love.graphics.setColor(0, 255, 0, 100)
            if tiles_overlap(t, self.midPoint) then
                love.graphics.setColor(255, 0, 0, 100)
            end
            love.graphics.rectangle('fill', upscale_x(t.x), upscale_x(t.y),
                                    upscale_x(1), upscale_y(1))
        end

        -- Show midPaths
        for _, tile in pairs(self.midPaths) do
            love.graphics.setColor(150, 0, 200)
            love.graphics.rectangle('fill',
                                    upscale_x(tile.x), upscale_y(tile.y),
                                    upscale_x(1), upscale_y(1))
        end
    end

    -- Draw bricks
    self:draw_bricks()
    
    -- Draw items
    for _, i in pairs(self.items) do
        if tile_in_table(i.position, self.fov) or DEBUG then
            i:draw()
        end
    end

    -- Draw sprites
    for _, s in pairs(self.sprites) do
        if tile_in_table(s.position, self.fov) or s.isThundershocked or
           DEBUG then
            s:draw()
        end
    end

    -- Draw thunderbolts
    for _, tb in pairs(self.thunderbolts) do
        tb:draw()
    end

    self:draw_messages()

    if DEBUG then
        -- Show tiles in FOV
        for _, tile in pairs(self.fov) do
            love.graphics.setColor(0, 255, 0)
            love.graphics.setLine(1, 'rough')
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
        local alpha
        local dist
        for _, b in pairs(self.bricks) do
            --dist = manhattan_distance(b, self.game.player.position)
            if tile_in_table(b, self.fov) then
                --alpha = LIGHT - ((2 ^ dist) * .05)
                alpha = LIGHT
            else
                alpha = DARK
            end
            --if alpha < DARK then alpha = DARK end

            self.brickBatch:setColor(255, 255, 255, alpha)
            self.brickBatch:add(b.x * TILE_W, b.y * TILE_H)
        end

        self.brickBatch:unbind()

        self.bricksDirty = false
    end

    --love.graphics.setColor(WHITE)
    love.graphics.draw(self.brickBatch, 0, 0, 0, SCALE_X, SCALE_Y)

    self:draw_hieroglyphs()
end

function Room:draw_hieroglyphs()
    for _, h in pairs(self.hieroglyphs) do
        if tile_in_table(h.position, self.fov) then
            alpha = LIGHT
        else
            alpha = DARK
        end
        love.graphics.setColor(255, 255, 255, alpha)

        h:draw()
    end
end

function Room:draw_messages()
    -- If there is a message on the queue
    if self.messages[1] then
        -- Draw the message
        self.messages[1]:draw()
    end
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
        self.roomFiller = RoomFiller(self)
    end

    -- Continue filling the room with monsters, items, etc.
    if self.roomFiller:fill_next_step() then
        -- Make a spriteBatch for bricks within the player's FOV
        self.brickBatch = love.graphics.newSpriteBatch(brickImg, #self.bricks)

        -- Mark the generation process as complete
        self.isGenerated = true

        -- Free up the memory used by the roomBuilder
        --self.roomBuilder = nil

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

function Room:get_exit(search)
    for i, e in pairs(self.exits) do
        if (e.x ~= nil and e.x == search.x) or
           (e.y ~= nil and e.y == search.y) or
           --(e.roomIndex ~= nil and e.roomIndex == search.roomIndex) or
           (e.targetRoom ~= nil and e.targetRoom == search.targetRoom) then
            return e
        end
    end
end

function Room:get_obstacles()
    return self.bricks
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

function Room:plot_path(src, dest, characterTeam)
    local addCharacters = true
    local path

    while true do
        -- Create a table of the room's occupied nodes
        local hotLava = {}
        for _, b in pairs(self.bricks) do
            table.insert(hotLava, {x = b.x, y = b.y})
        end
        if addCharacters then
            for _, c in pairs(self:get_characters()) do
                -- If this character is on the team of the one who called this
                -- function
                --if c.team == characterTeam then
                table.insert(hotLava, {x = c.position.x, y = c.position.y})
                --end
            end
        end

        local pf = PathFinder(src, dest, hotLava, nil, {smooth = true})
        path = pf:plot()

        if #path == 0 and addCharacters then
            addCharacters = false
        else
            break
        end
    end

    -- Remove first node from path
    table.remove(path, 1)

    if #path > 0 then
        return path
    else
        return nil
    end
end

local function remove_dead_objects(objects)
    local temp = {}
    for _, o in pairs(objects) do
        if not o.dead then
            table.insert(temp, o)
        end
    end
    return temp
end

function Room:remove_object(obj)
    if instanceOf(Item, obj) then
        for i, item in pairs(self.items) do
            if item == obj then
                table.remove(self.items, i)
                break
            end
        end
    elseif instanceOf(Sprite, obj) then
        for i, s in pairs(self.sprites) do
            if s == obj then
                table.remove(self.sprites, i)
                break
            end
        end
    end
end

function Room:sweep()
    -- Remove dead sprites
    self.sprites = remove_dead_objects(self.sprites)

    -- Remove dead bricks
    self.bricks = remove_dead_objects(self.bricks)

    -- Remove dead turrets
    self.turrets = remove_dead_objects(self.turrets)

    -- Remove dead thunderbolts
    self.thunderbolts = remove_dead_objects(self.thunderbolts)

    -- Keep only items with a position and no owner
    local items = {}
    for _, item in pairs(self.items) do
        if item.position and not item.owner then
            table.insert(items, item)
        end
    end
    self.items = items
end

-- Returns a table of everything within a specified tile
function Room:tile_contents(tile)
    contents = {}

    if tile_offscreen(tile) then
        return nil
    end

    for _, b in pairs(self.bricks) do
        if tiles_overlap(tile, b) then
            -- Nothing can overlap a brick, so return here
            return {b}
        end
    end

    for _, s in pairs(self.sprites) do
        if tiles_overlap(tile, s.position) then
            table.insert(contents, s)
        end
    end

    for _, item in pairs(self.items) do
        if item:get_position() then
            if tiles_overlap(tile, item:get_position()) then
                table.insert(contents, item)
            end
        end
    end

    return contents
end

-- Returns true if an item can be safely dropped here
function Room:tile_is_droppoint(tile, ignoreCharacter)
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

    -- If the tile is in the room, and it doesn't overlap with any bricks,
    -- characters, or existing items
    if (self:tile_in_room(tile) and
        not tile_in_table(tile, concat_tables({self.bricks,
                                               characters,
                                               self.items}))) then
        return true
    else
        return false
    end
end

function Room:tile_in_room(tile, options)
    if tile_offscreen(tile) then
        return false
    end

    if tile_in_table(tile, self.freeTiles) then
        return true
    end

    if options and options.includeBricks then
        if tile_in_table(tile, self.bricks) then
            return true
        end
    end

    return false
end

-- Return true if tile can be walked on right now (contains no collidable
-- objects)
function Room:tile_walkable(tile)
    -- If the tile is on an exit
    for _, e in pairs(self.exits) do
        if tiles_overlap(tile, e:get_position()) then
            return true
        end
    end

    -- If the tile is not inside the room, or the tile is occupied by a brick
    if not self:tile_in_room(tile) or tile_in_table(tile, self.bricks) then
        return false
    end

    -- Create a table of collidable characters
    local collidables = {}
    for _, c in pairs(self:get_characters()) do
        -- If this character is corporeal (not a ghost)
        if c.isCorporeal then
            table.insert(collidables, c)
        end
    end

    -- If the tile's position is occupied by that of a collidable sprite
    if tile_in_table(tile, collidables) then
        return false
    end

    return true
end

function Room:update()
    -- Get monsters' directional input
    self:character_input()

    -- Let characters shoot projectile weapons
    for _, c in pairs(self:get_characters()) do
        if c.shootDir and c.armory.currentWeapon and
           c.armory.currentWeapon.projectileClass then
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

    -- Update sprites
    for _, s in pairs(self.sprites) do
        -- If this is a character on the good-guy team
        if instanceOf(Character, s) and s.team == 1 then
            -- Recharge HP/ammo
            s:recharge()
        end

        s:update()
    end

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
    for _, s in pairs(self.sprites) do
        s:post_physics()

        -- Reset all one-frame variables
        s.isThundershocked = false
        self.wantsToTrade = false
        self.isGrabbing = false
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
        tb.dead = true
    end

    if self.game.player.moved and not self.game.player.dead then
        -- Iterate through the room objects which can have mouths
        for _, o in pairs(self.sprites) do
            -- If this object has a mouth which should speak
            if o.mouth and o.mouth:should_speak() then
                if type(o.mouth.speech) == 'string' then
                    o.mouth:speak()
                end
            end
        end
    end

    -- Update messages
    self:update_messages()

    -- If this is the game's current room
    if self.game.currentRoom == self then
        if self.game.player.moved then
            --and self:tile_in_room(self.game.player.position)) then
            self:update_fov()
        end

        -- If the player moved
        --if self.game.player.moved then
        --    -- Flag the bricks for a redraw
        --    --self.bricksDirty = true
        --end
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
        self.messages[1]:update()

        -- If the message is finished displaying
        if self.messages[1].finished then
            -- Remove it from the queue
            table.remove(self.messages, 1)
        end

        return true
    end

    return false
end
