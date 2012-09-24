require('class.ai')
require('class.animation')
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

    self.color = CYAN
    self.frameHoldTimer = {delay = 3, value = 0}

    self.health = 100
    self.maxHealth = 100
    self.hurtTimer = 0
    self.usedMagicTimer = 0
    self.flashTimer = 0
    self.rechargeTimer = {delay = 4, value = 0}
    self.isCorporeal = true
    self.isMovable = true

    self.enemies = {characters = {}, classes = {}}

    self.ai = AI(self)

    self.inventory = Inventory(self)
    self.armory = Armory(self)
    self.log = Log()
    self.visitedRooms = {}
end

function Character:add_enemy(character)
    table.insert(self.enemies.characters, character)
end

function Character:add_enemy_class(class)
    table.insert(self.enemies.classes, class)
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

        -- If this was not auto regeneration
        if amount > 1 then
            if self:is_audible() then
                -- Play a sound
                if instanceOf(Player, self) then
                    sounds.player.getHP:play()
                else
                    sounds.monster.getHP:play()
                end
            end
        end

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
        else
            -- If this was not auto regeneration
            if amount > 1 then
                if self:is_audible() then
                    -- Play a sound
                    if instanceOf(Player, self) then
                        sounds.player.getMagic:play()
                    else
                        sounds.monster.getMagic:play()
                    end
                end
            end
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
                        if self:is_audible() then
                            -- Play a sound
                            if instanceOf(Player, self) then
                                sounds.player.getItem:play()
                            else
                                sounds.monster.getItem:play()
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
                if item.itemType == 'claws' then
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

    if self:is_audible() then
        -- Play a sound
        if instanceOf(Player, self) then
            sounds.player.die:play()
        else
            sounds.monster.die:play()
        end
    end
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
        self:update_image()
    end

    local position
    if pos then
        position = pos
    else
        position = {x = upscale_x(self.position.x),
                    y = upscale_y(self.position.y)}
    end

    if self.flashTimer == 0 or self.isThundershocked or
       self.room.game.paused then
        love.graphics.setColorMode('modulate')

        if self.isThundershocked then
            love.graphics.setColor(WHITE)
        elseif self.color then
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

        local drawable
        if instanceOf(Animation, self.currentImage) then
            drawable = self.currentImage:get_drawable()
        else
            drawable = self.currentImage
        end

        local x, y, sx
        x = position.x
        y = position.y

        if self.mirrored then 
            x = position.x + (drawable:getWidth() * SCALE_X)
            sx = -SCALE_X
        else
            sx = SCALE_X
        end

        local offsetDir
        if self.hitSomething and not self.hitSomethingLastFrame then
            offsetDir = self.dir
        end

        if offsetDir then
            if offsetDir == 1 then
                y = y - SCALE_Y
            elseif offsetDir == 2 then
                x = x + SCALE_X
            elseif offsetDir == 3 then
                y = y + SCALE_Y
            elseif offsetDir == 4 then
                x = x - SCALE_X
            end
        end

        love.graphics.draw(drawable,
                           x, y,
                           rotation,
                           sx, SCALE_Y)

    end

    if DEBUG and not instanceOf(Player, self) then
        -- Put a health bar above the character's head
        local h = 3 * SCALE_Y
        draw_progress_bar({num = self:get_health_percentage(), max = 100,
                           color = MAGENTA},
                          position.x, position.y - h,
                          upscale_x(1), h)
    end
end

function Character:drop_items(items)
    -- If we are not dead
    if not self.dead then
        if self:is_audible() then
            -- Play a sound
            if instanceOf(Player, self) then
                sounds.player.dropItem:play()
            else
                sounds.monster.dropItem:play()
            end
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
    if instanceOf(Character, patient) then
        if self:is_enemies_with(patient) then -- Patient is an enemy
            -- If our current weapon is a melee weapon
            if (self.armory.currentWeapon and
                self.armory.currentWeapon.meleeDamage) then 
                -- If the patient receives our hit
                if patient:receive_hit(self) then
                    patient:receive_damage(
                            self.armory.currentWeapon.meleeDamage, self)
                    self.attackedDir = self.dir
                    self.attacked = true
                else
                    return false
                end
            end
        -- If patient is not an enemy, and has AI
        --elseif patient.ai then
        --    -- Tell our teammate to dodge us
        --    patient.ai:dodge(self)
            --return false
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
    if Character.super.is_audible(self) then
        return true
    end

    if self.room then
        -- If the player just killed us
        local kills = self.room.game.player.log:get_kills()
        if kills[#kills] == self then
            return true
        end

        -- If the player just hit us
        local hits = self.room.game.player.log:get_hits()
        if hits[#hits] == self then
            return true
        end
    end

    return false
end

function Character:is_enemies_with(character)
    if value_in_table(character, self.enemies.characters) then
        return true
    end

    local DEBUG
    if instanceOf(Player, character) then
        --DEBUG = true
    end

    if DEBUG then
        print('enemy classes:')
    end
    for _, c in pairs(self.enemies.classes) do
        if DEBUG then
            print('  ', c)
            print('    instance:', instanceOf(c,character))
        end
        if instanceOf(c, character) then
            return true
        end
    end

    return false
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

    -- Find out who was ultimately responsible for this damage (e.g. if it was
    -- an arrow, get the owner (character) of the owner (bow) of the arrow)
    local perpetrator = get_ultimate_owner(agent)

    if perpetrator and perpetrator.log then
        -- Give the perp credit for the hit
        perpetrator.log:add_hit(self)
    end

    self.health = self.health - amount
    self.hurt = true
    self.hurtTimer = self:get_time()

    if self.health <= 0 then
        self.health = 0

        if perpetrator and perpetrator.log then
            -- Give the perp credit for the kill
            perpetrator.log:add_kill(self)
        end

        self:die()
    end

    if not self.dead then
        if self:is_audible() then
            -- Play a sound
            if instanceOf(Player, self) then
                sounds.player.cry:play()
            else
                sounds.monster.cry:play()
            end
        end
    end

    if self.ai then
        self.ai:receive_damage(amount, agent)
    end

    return true
end

function Character:recharge_health()
    if self.rechargeTimer.value > 0 then
        return
    end

    -- If it's been > 2 seconds since we were hurt
    if self:get_time() > self.hurtTimer + 2 then
        -- Recharge health
        self:add_health(1)
    end
end

function Character:recharge_magic()
    if self.rechargeTimer.value > 0 then
        return
    end

    -- If we have magic
    if self.magic then
        -- If it's been > 2 seconds since we used magic
        if self:get_time() > self.usedMagicTimer + 2 then
            -- Recharge magic
            self:add_magic(1)
        end
    end
end

function Character:shoot(dir)
    -- If we don't have a weapon, or we are dead
    if not self.armory.currentWeapon or self.dead then
        return false
    end

    -- If we have a weapon that shoots projectiles
    if self.armory.currentWeapon.projectileClass then
        -- Check if we are trying to shoot into a brick
        for _,b in pairs(self.room.bricks) do
            if tiles_overlap(add_direction(self:get_position(), dir), b) then
                -- Save ourself the ammo
                return false
            end
        end
    end

    if self.armory.currentWeapon:shoot(dir) then
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
    -- Update the health/magic recharging timer
    if self.rechargeTimer.value > 0 then
        self.rechargeTimer.value = self.rechargeTimer.value - 1
    else
        self.rechargeTimer.value = self.rechargeTimer.delay
    end


    if self.flashTimer > 0 then
        self.flashTimer = self.flashTimer - 1
    end

    if self.hurt then
        -- Flash if hurt
        self.flashTimer = 1
        self.hurt = false
    end

    self.oldImage = self.currentImage
    self:update_image()

    -- If our current image is an animation
    if instanceOf(Animation, self.currentImage) then
        -- Update the animation
        self.currentImage:update()
    end

    -- If we changed images
    if self.currentImage ~= self.oldImage then
        -- Start the frame-hold timer
        self.frameHoldTimer.value = self.frameHoldTimer.delay

        -- If the current image is an animation
        if instanceOf(Animation, self.currentImage) then
            -- Reset it to frame one
            self.currentImage:advance_to_frame(1)
        end
    end

    self.attacked = false
    self.shot = false
    self.stepped = false
end

function Character:update_image()
    if not self.convertedAnimations then
        -- Find any images that are tables and convert them to animation
        -- objects
        for key, image in pairs(self.images) do
            if type(image) == 'table' and not instanceOf(Animation, image) then
                self.images[key] = Animation(copy_table(image))
            end
        end
        self.convertedAnimations = true
    end

    -- Determine which image of this character to draw
    if self.images.attack and self.attacked then
        self.currentImage = self.images.attack
    elseif self.images.bow_shoot and self.shot then
        self.currentImage = self.images.bow_shoot
    elseif self.images.dodge and self.ai.path.action == AI_ACTION.dodge then
        self.currentImage = self.images.dodge
    elseif self.images.step and self.stepped then
        if self.currentImage == self.images.step then
            self.currentImage = self.images.default
        else
            self.currentImage = self.images.step
        end
    elseif self.images.walk and (self.ai.path.nodes or self.stepped) then
        self.currentImage = self.images.walk

        --if instanceOf(Animation, self.currentImage) then
        --    self.currentImage.loop = false

        --    if self.stepped and self.currentImage:is_stopped() then
        --        self.currentImage:advance_to_frame(1)
        --    end
        --end
    elseif (self.images.sword and
            self.armory:get_current_weapon_type() == 'sword') then
        self.currentImage = self.images.sword
    elseif (self.images.bow and
            self.armory:get_current_weapon_type() == 'bow') then
        self.currentImage = self.images.bow
    elseif (self.images.firestaff and
            self.armory:get_current_weapon_type() == 'firestaff') then
        self.currentImage = self.images.firestaff
    elseif (self.images.thunderstaff and
            self.armory:get_current_weapon_type() == 'thunderstaff') then
        self.currentImage = self.images.thunderstaff
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
