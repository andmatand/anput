require('class.ai')
require('class.armory')
require('class.inventory')
require('class.log')
require('class.mouth')
require('class.sprite')
require('util.tile')

--local DEBUG = true

-- A Character is a Sprite with AI
Character = class('Character', Sprite)

function Character:init()
    Sprite.init(self)

    self.frame = 1

    self.health = 100
    self.hurtTimer = love.timer.getTime()
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
                -- If the weapon is a sword
                if item.itemType == ITEM_TYPE.sword or
                   -- Or the item is a staff and we are not an NPC
                   (item.itemType == ITEM_TYPE.staff and not self.name) then
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
    self:drop(itemsToDrop)
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
    if not self.images then
        return
    end

    local position
    if pos then
        position = pos
    else
        position = {x = upscale_x(self.position.x),
                    y = upscale_y(self.position.y)}
    end

    -- Determine which image of this character to draw
    if (self.images.moving and
        (self.ai.path.nodes or self.moved or
         self.action == AI_ACTION.flee)) then
        self.currentImage = self.images.moving
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
        self.currentImage = self.images.default
    end

    if self.flashTimer == 0 then
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
    end
end

-- Drops a table of items, choosing good positions for them
function Character:drop(items)
    -- If we are not dead
    if not self.dead then
        -- If we are a player
        if instanceOf(Player, self) then
            sound.playerDropItem:play()
        end
    end

    -- Find all neighboring tiles
    local neighbors = find_neighbor_tiles(self.position)

    -- Assign positions to the items and add them to the room
    local i = 0
    for _, item in pairs(items) do
        i = i + 1

        if i == 1 and self.dead then
            -- Position the item where we just died
            item.position = self.position
        else
            -- Make a working copy of neighbors
            local tempNeighbors = copy_table(neighbors)

            -- Try to find a free neighboring tile
            while not item.position and #tempNeighbors > 0 do
                -- Choose a random neighboring tile
                local neighborIndex = math.random(1, #tempNeighbors)
                local n = tempNeighbors[neighborIndex]

                -- If the spot is free
                if self.room:tile_is_droppoint(n) then
                    -- Use this position
                    item.position = {x = n.x, y = n.y}
                    break
                else
                    -- Remove it from the working copy of neighbors
                    table.remove(tempNeighbors, neighborIndex)
                end
            end

            -- If the item still doesn't have a position
            if not item.position then
                -- Make a working copy of neighbors
                local tempNeighbors = copy_table(neighbors)

                -- Find a neighboring tile which is inside the room
                while not item.position and #tempNeighbors > 0 do
                    local neighborIndex = math.random(1, #tempNeighbors)
                    local n = tempNeighbors[neighborIndex]

                    if self.room:tile_in_room(n) then
                        -- Use this position
                        item.position = {x = n.x, y = n.y}
                        break
                    else
                        -- Remove it from the working copy of neighbors
                        table.remove(tempNeighbors, neighborIndex)
                    end
                end
            end
        end

        self:drop_item(item)

        if DEBUG then
            print('dropped item ' .. i)
        end
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
    end

    -- Add the item to the room
    self.room:add_object(item)
end

function Character:has_item(itemType, quantity)
    return self.inventory:has_item(itemType, quantity)
end

function Character:hit(patient)
    -- Damage other characters with melee weapons
    if (instanceOf(Character, patient) and -- We hit a character
        self.armory.currentWeapon and -- We have a current weapon
        self.armory.currentWeapon.damage and -- Our weapon does melee damage
        self.team ~= patient.team) then -- Patient is on a different team
        -- If the patient receives our hit
        if patient:receive_hit(self) then
            patient:receive_damage(self.armory.currentWeapon.damage, self)
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
            -- If the weapon has ammo
            if item.ammo and item.ammo > 0 then
                -- Put the ammo in the instance of that weapon type that we are
                -- holding
                self.inventory:get_item(item.itemType):add_ammo(item.ammo)

                -- Remove the ammo from the weapon on the ground
                item.ammo = 0

                return true
            end
            
            -- Don't pick it up
            return false
        end

        -- Add it to our armory
        self.armory:add(item)

        -- If it's a bow
        if item.itemType == ITEM_TYPE.bow then
            -- Apply any arrows
            local foundArrow
            repeat
                foundArrow = false
                for _, i in pairs(self.inventory.items) do
                    if i.itemType == ITEM_TYPE.arrow then
                        i:use()
                        foundArrow = true

                        -- Break here because Item:use() alters the inventory's
                        -- items table
                        break
                    end
                end
            until not foundArrow
        end

    -- If it's arrows and we have a bow
    elseif (item.itemType == ITEM_TYPE.arrow and
            self:has_item(ITEM_TYPE.bow)) then
        -- Apply arrows to bow instead of putting them in inventory
        item.owner = self
        item:use_on(self)
        return true
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
    self.hurtTimer = love.timer.getTime()

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

        -- If we have a staff
        if self.armory.weapons.staff then
            -- Recharge it
            self.armory.weapons.staff:add_ammo(1)
        end

        -- If it's been > 2 seconds since we were hurt
        if love.timer.getTime() > self.hurtTimer + 2 then
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

    -- If we are not a Player, and our current weapon is not of the "shooting"
    -- variety
    if (not instanceOf(Player, self) and
        not self.armory.currentWeapon.projectileClass) then
        -- Switch to a weapon that can shoot
        for _, w in pairs(self.armory.weapons) do
            if w.projectileClass then
                self.armory:set_current_weapon(w)
                break
            end
        end
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

    -- If this weapon did not (or cannot) shoot
    if newProjectile == false then
        return false
    else
        self.room:add_object(newProjectile)
        return true
    end
end

function Character:step(dir)
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
    self.stepped = false

    if self.flashTimer > 0 then
        self.flashTimer = self.flashTimer - 1
    end

    if self.hurt then
        -- Flash if hurt
        self.flashTimer = 2
        self.hurt = false
    end
end

function Character:visited_room(room)
    return value_in_table(room, self.visitedRooms)
end
