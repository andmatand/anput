require('class.ai')
require('class.armory')
require('class.inventory')
require('class.log')
require('class.mouth')
require('class.sprite')
require('util.graphics')
require('util.tile')

--local DEBUG = true

-- A Character is a Sprite with AI
Character = class('Character', Sprite)

function Character:init()
    Sprite.init(self)

    self.frameHoldTimer = {delay = 3, value = 0}

    self.health = 100
    self.maxHealth = 100
    self.hurtTimer = love.timer.getTime()
    self.usedMagicTimer = love.timer.getTime()
    self.flashTimer = 0
    self.team = 1 -- Good guys
    self.isCorporeal = true
    self.isMovable = true

    self.ai = AI(self)

    self.inventory = Inventory(self)
    self.armory = Armory(self)
    self.log = Log()
    self.visitedRooms = {}
end

function Character:add_health(amount)
    if self.dead then
        return false
    end

    if self.health < 100 then
        self.health = self.health + amount

        if self.health > 100 then
            self.health = 100
        end

        -- Play sound depending on who gained health
        --if instanceOf(Player, patient) then
        --    sound.playerGetHP:play()
        --else
        --    if self:is_audible() then
        --        sound.monsterGetHP:play()
        --    end
        --end

        return true
    end

    return false
end

function Character:add_magic(amount)
    if not self.magic then
        return false
    end

    local oldMagic = self.magic
    self.magic = self.magic + amount

    if self.magic < 0 then self.magic = 0 end
    if self.magic > 100 then self.magic = 100 end

    -- If the amount changed
    if oldMagic ~= self.magic then
        -- If magic was used
        if amount < 0 then
            self.usedMagicTimer = self:get_time()
        end

        return true
    else
        return false
    end
end

function Character:add_visited_room(room)
    for _, r in pairs(self.visitedRooms) do
        -- If we have already visited this room
        if r == room then
            return
        end
    end

    table.insert(self.visitedRooms, room)
end

function Character:check_for_items()
    local pickedSomethingUp = false

    -- Don't pick things up if we're dead
    if self.dead then
        return
    end

    for _, item in pairs(self.room.items) do
        -- If this item has a position
        if item.position then
            -- If we are standing on this item
            if tiles_overlap(self.position, item.position) then
                -- Pick it up
                if self:pick_up(item) then
                    -- If we didn't already pick something up, and we are in a
                    -- room, and it is the game's current room, or we are a
                    -- player
                    if (not pickedSomethingUp) then
                        -- Play a pick-up sound depending on who we are
                        if instanceOf(Player, self) then
                            sound.playerGetItem:play()
                        else
                            if self:is_audible() then
                                sound.monsterGetItem:play()
                            end
                        end
                    end

                    pickedSomethingUp = true
                end
            end
        end
    end
end

function Character:die()
    Sprite.die(self)

    local itemsToDrop = {}

    for _, item in pairs(self.inventory.items) do
        local ok = true

        -- If this item is a weapon
        if instanceOf(Weapon, item) then
            -- If we are a not a player
            if not instanceOf(Player, self) then
                -- If the weapon is claws
                if item.itemType == ITEM_TYPE.claws then
                    -- Do not drop it
                    ok = false
                end
            end
        end

        if ok then
            table.insert(itemsToDrop, item)
        end
    end

    -- Drop all items in our inventory
    self:drop_items(itemsToDrop)
end

function Character:direction_to(position)
    -- If the target position is the same as our position
    if tiles_overlap(self.position, position) then
        -- Return a random direction
        return math.random(1, 4)
    end

    return direction_to(self.position, position)
end

function Character:draw(pos, rotation)
    if not self.currentImage then
        return
    end

    local position
    if pos then
        position = pos
    else
        position = {x = upscale_x(self.position.x),
                    y = upscale_y(self.position.y)}
    end

    if self.flashTimer == 0 or self.room.game.paused then
        if self.color then
            love.graphics.setColor(self.color)
        else
            love.graphics.setColor(255, 255, 255)
        end

        if not self.stepped then
            if self.dir == 2 then
                self.mirrored = false
            elseif self.dir == 4 then
                self.mirrored = true
            end
        end

        local x, sx
        if self.mirrored then 
            x = position.x + (self.currentImage:getWidth() * SCALE_X)
            sx = -SCALE_X
        else
            x = position.x
            sx = SCALE_X
        end

        love.graphics.draw(self.currentImage,
                           x, position.y,
                           rotation,
                           sx, SCALE_Y)

        if DEBUG and not instanceOf(Player, self) then
            -- Put a health bar above the character's head
            draw_progress_bar({num = self:get_health_percentage(),
                               max = 100, color = MAGENTA},
                              position.x, position.y - (SCALE_Y * 3),
                              upscale_x(1), 12)
        end
    end
end

function Character:drop_items(items)
    -- If we are not dead
    if not self.dead then
        -- If we are a player
        if instanceOf(Player, self) then
            sound.playerDropItem:play()
        end
    end

    while #items > 0 do
        -- Create a group of items which will be dropped in the same spot
        local itemGroup = {}

        -- Find other items of the same type as the first item
        for i, item in pairs(items) do
            -- If this item is of the same type as the first item
            if item.itemType == items[1].itemType then
                -- Add it to the group
                table.insert(itemGroup, item)
            end
        end

        -- Drop the items in a good position
        self:drop_item_group(itemGroup)

        -- Remove all the items that were dropped from the items table
        for _, item in pairs(itemGroup) do
            remove_value_from_table(item, items)
        end
    end
end

-- Drops a table of items, choosing a good position for them
function Character:drop_item_group(items)
    local position

    -- Try a good starting position
    if self.dead then
        -- Position the items where we just died
        position = self.position
    else
        -- Position the items on the tile we are facing
        position = add_direction(self:get_position(), self.dir)
    end

    repeat
        -- If this position is not empty
        if self.room:tile_is_droppoint(position, self) then
            break
        else
            -- Forget about this position
            position = nil

            -- Find all neighboring tiles
            local neighbors = find_neighbor_tiles(self.position)

            -- Make a working copy of neighbors
            local tempNeighbors = copy_table(neighbors)

            -- Try to find a free neighboring tile
            while #tempNeighbors > 0 do
                -- Choose a random neighboring tile
                local index = math.random(1, #tempNeighbors)
                local n = tempNeighbors[index]

                -- If the spot is free
                if self.room:tile_is_droppoint(n) then
                    position = {x = n.x, y = n.y}
                    break
                else
                    -- Remove it from the working copy of neighbors
                    table.remove(tempNeighbors, index)
                end
            end

            -- If we still don't have a position
            if not position then
                -- Make a working copy of neighbors
                local tempNeighbors = copy_table(neighbors)

                -- Find a neighboring tile which is inside the room, regardless
                -- of whether or not it already contains an item
                while #tempNeighbors > 0 do
                    local index = math.random(1, #tempNeighbors)
                    local n = tempNeighbors[index]

                    if self.room:tile_in_room(n) then
                        -- Use this position
                        position = {x = n.x, y = n.y}
                        break
                    else
                        -- Remove it from the working copy of neighbors
                        table.remove(tempNeighbors, index)
                    end
                end
            end
        end
    until position

    -- Assign positions to the items and add them to the room
    for _, item in pairs(items) do
        item:set_position(position)
        self:drop_item(item)
    end
end

-- Drops a single item into the room (the item must have a position)
function Character:drop_item(item)
    -- Remove the item from our inventory
    self.inventory:remove(item)

    -- If the item is a Weapon
    if instanceOf(Weapon, item) then
        -- Remove it from our armory
        self.armory:remove(item)

        -- Clear the frame hold timer; we want to appear unarmed right away if
        -- this was our last weapon
        self.frameHoldTimer.value = 0
    end

    -- Add the item to the room
    self.room:add_object(item)
end

function Character:get_health_percentage()
    -- Return health as a percentage of maximum health
    return (self.health / self.maxHealth) * 100
end

function Character:get_time()
    return self.room.game.time
end

function Character:has_item(itemType, quantity)
    return self.inventory:has_item(itemType, quantity)
end

function Character:has_melee_weapon()
    for _, w in pairs(self.armory.weapons) do
        if w.meleeDamage then
            return true
        end
    end

    return false
end

function Character:has_usable_weapon(againstCharacter)
    for _, w in pairs(self.armory.weapons) do
        if w.meleeDamage or (w.ammoCost and w:get_ammo() >= w.ammoCost) then
            local ok = true

            if againstCharacter then
                if not w:is_effective_against(againstCharacter) then
                    ok = false
                end
            end

            if ok then
                return true
            end
        end
    end

    return false
end

function Character:hit(patient)
    -- Damage other characters with melee weapons
    if (instanceOf(Character, patient) and -- We hit a character
        self.armory.currentWeapon and -- We have a current weapon
        self.armory.currentWeapon.meleeDamage and -- It's a melee weapon
        self:is_enemies_with(patient)) then -- Patient is an enemy
        -- If the patient receives our hit
        if patient:receive_hit(self) then
            patient:receive_damage(self.armory.currentWeapon.meleeDamage, self)
            self.attackedDir = self.dir
        else
            return false
        end
    end

    return Character.super.hit(self, patient)
end

function Character:input()
    -- DEBUG: if we are a player, let the user override our movements
    if instanceOf(Player, self) and self.stepped then
        return
    end

    if self.ai then
        self.attackedDir = nil
        self.ai:update()
    end
end

function Character:is_audible()
    if self.room then
        local playerKills = self.room.game.player.log:get_kills()

        -- If the player just killed us
        if playerKills[#playerKills] == self then
            return true
        end
    end

    return Character.super.is_audible(self)
end

function Character:is_enemies_with(character)
    if character.team ~= self.team then
        return true
    else
        return false
    end
end

function Character:pick_up(item)
    -- If the item is already being held by someone, or is already used up
    if item.owner then
        -- Don't pick it up
        return false
    end

    -- Check if there's room in our inventory to pick this item up
    if not self.inventory:has_room_for(item) then
        return false
    end

    -- If the item is a weapon
    if instanceOf(Weapon, item) then
        -- If we already have this type of weapon
        if self:has_item(item.itemType) then
            -- Don't pick it up
            return false
        end

        -- Add it to our armory
        self.armory:add(item)
    end

    -- Add the item to our inventory
    self.inventory:add(item)

    return true
end

function Character:receive_damage(amount, agent)
    if self.dead then
        -- Do not receive any damage
        return false
    end

    self.health = self.health - amount
    self.hurt = true
    self.hurtTimer = self:get_time()

    if self.health <= 0 then
        self.health = 0

        -- If an agent was given
        if agent then
            -- Find who was ultimately responsible for this kill, if this was
            -- e.g. an arrow
            local topAgent = agent
            while topAgent.owner do
                topAgent = topAgent.owner
            end

            if topAgent.log then
                -- Give the agent credit for the kill
                topAgent.log:add_kill(self)
            end
        end

        self:die()
    end

    if not instanceOf(Player, self) and not self.dead then
        if self:is_audible() then
            sound.monsterCry:play()
        end
    end

    return true
end

function Character:receive_hit(agent)
    -- If we are not a player (since players make their own decisions about
    -- what team they're on)
    if not instanceOf(Player, self) then
        -- If the agent is a projectile
        if instanceOf(Projectile, agent) then
            -- If it has an owner
            if agent.owner then
                -- If the owner is on our team
                if agent.owner.team == self.team then
                    -- Turn against him
                    if self.mouth then
                        self.mouth.speech = "THAT WAS NOT VERY NICE"
                        self.mouth:speak(true)
                    end
                    self.team = 3
                end
            end
        end
    end

    return Character.super.receive_hit(self)
end

function Character:recharge()
    if not self.rechargeTimer then
        self.rechargeTimer = {delay = 4, value = 0}
    end

    if self.rechargeTimer.value > 0 then
        self.rechargeTimer.value = self.rechargeTimer.value - 1
    else
        self.rechargeTimer.value = self.rechargeTimer.delay

        -- If we have magic
        if self.magic then
            -- If it's been > 2 seconds since we used magic
            if love.timer.getTime() > self.usedMagicTimer + 2 then
                -- Recharge magic
                self:add_magic(1)
            end
        end

        -- If it's been > 2 seconds since we were hurt
        if self:get_time() > self.hurtTimer + 2 then
            -- Recharge health
            self:add_health(1)
        end
    end
end

function Character:shoot(dir)
    -- If we don't have a weapon, or we are dead
    if not self.armory.currentWeapon or self.dead then
        return false
    end

    -- If we still don't have a weapon that shoots
    if not self.armory.currentWeapon.projectileClass then
        return false
    end

    -- Check if we are trying to shoot into a brick
    for _,b in pairs(self.room.bricks) do
        if tiles_overlap(add_direction(self.position, dir), b) then
            -- Save ourself the ammo
            return false
        end
    end

    -- Try to create a new projectile
    local newProjectile = self.armory.currentWeapon:shoot(dir)

    -- If the weapon created a projectile
    if newProjectile then
        -- Add it to the room
        self.room:add_object(newProjectile)
        self.shot = true
        return true
    else
        return false
    end
end

function Character:step(dir)
    if not dir then
        self.velocity.x = 0
        self.velocity.y = 0
        self.stepped = false
    end

    -- If we just attacked in this direction
    if self.attackedDir == dir then
        return
    end

    self.stepped = true
    if dir == 1 then
        self.velocity.x = 0
        self.velocity.y = -1
    elseif dir == 2 then
        self.velocity.x = 1
        self.velocity.y = 0
    elseif dir == 3 then
        self.velocity.x = 0
        self.velocity.y = 1
    elseif dir == 4 then
        self.velocity.x = -1
        self.velocity.y = 0
    end

    -- Store this direction for directional attacking
    self.dir = dir
end

function Character:step_toward(dest)
    if self.position.x < dest.x then
        self:step(2)
    elseif self.position.x > dest.x then
        self:step(4)
    elseif self.position.y < dest.y then
        self:step(3)
    elseif self.position.y > dest.y then
        self:step(1)
    end
end

function Character:update()
    if self.flashTimer > 0 then
        self.flashTimer = self.flashTimer - 1
    end

    if self.hurt then
        -- Flash if hurt
        self.flashTimer = 2
        self.hurt = false
    end

    self.oldImage = self.currentImage
    self:update_image()

    -- If we changed images
    if self.currentImage ~= self.oldImage then
        -- Start the frame-hold timer
        self.frameHoldTimer.value = self.frameHoldTimer.delay
    end

    self.stepped = false
    self.shot = false
end

function Character:update_image()
    -- Determine which image of this character to draw
    if self.images.bow_shoot and self.shot then
        self.currentImage = self.images.bow_shoot
    elseif self.images.dodge and self.ai.path.action == AI_ACTION.dodge then
        self.currentImage = self.images.dodge
    elseif (self.images.walk and (self.ai.path.nodes or self.stepped)) then
        self.currentImage = self.images.walk
    elseif (self.images.sword and
            self.armory:get_current_weapon_name() == 'sword') then
        self.currentImage = self.images.sword
    elseif (self.images.bow and
            self.armory:get_current_weapon_name() == 'bow') then
        self.currentImage = self.images.bow
    elseif (self.images.staff and
            self.armory:get_current_weapon_name() == 'staff') then
        self.currentImage = self.images.staff
    else
        -- Hold the frame before going back to the default image
        if self.frameHoldTimer.value > 0 then
            self.frameHoldTimer.value = self.frameHoldTimer.value - 1
        else
            self.currentImage = self.images.default
        end
    end
end

function Character:visited_room(room)
    return value_in_table(room, self.visitedRooms)
end
