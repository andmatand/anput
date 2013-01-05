require('class.character')

Golem = class('Golem', Character)

function Golem:init(owner)
    Golem.super.init(self)

    self.owner = owner

    self.color = MAGENTA
    self.images = copy_table(images.monsters.golem)
    self.isSpawning = true
    self.maxHealth = 1
    self.health = 1

    local claws = Weapon('claws')
    claws.meleeDamage = 5
    self:pick_up(claws)

    self.ai.choiceTimer.delay = .5
    self.ai.level.attack = {dist = 40, prob = 9, delay = .15}
    self.ai.level.chase = {dist = 40, prob = 9, delay = .15}
    self.ai.level.loot = {dist = 40, prob = 9, delay = .15}
    self.ai.level.follow = {dist = 0, delay = .15}
    self.ai.level.follow.target = self.owner
    self.ai.level.dodge.delay = .15

    self.ai.wants_item = function(self, item)
        local pos = item:get_position()
        if pos then
            dist = manhattan_distance(pos, self.owner.position)

            if manhattan_distance(item.position,
                                  self.owner.owner:get_position()) < 5 then
                return false
            end
        end

        return true
    end

    self.room = self.owner.room
    if self:is_audible() then
        sounds.golem.spawn:play()
    end
end

function Golem:receive_damage(amount, agent)
    if instanceOf(ThunderStaff, agent) then
        -- We are grounded, being made of clay, so take no electrical damage
        return false
    else
        return Golem.super.receive_damage(self, amount, agent)
    end
end

function Golem:bring_item_to_owner(item)
    self.ai.level.follow.prob = 10
    self.ai.level.chase.prob = nil

    local dist = manhattan_distance(self:get_position(),
                                    self.ai.level.follow.target:get_position())
    if dist <= 3 then
        -- Drop it next to our owner
        self:drop_item_next_to_owner(item)
    end
end

function Golem:drop_item_next_to_owner(item)
    local neighbors = find_neighbor_tiles(self:get_position())
    local best = {tile, distance}
    for _, n in pairs(neighbors) do
        if self.room:tile_is_droppoint(n) then
            local dist = manhattan_distance(n, self.owner:get_position())
            if not best.distance or dist < best.distance then
                best.tile = n
                best.distance = dist
            end
        end
    end

    if best.tile then
        item:set_position(best.tile)
        self:drop_item(item)
        if self:is_audible() then
            sounds.monster.dropItem:play()
        end
    end
end

function Golem:is_enemies_with(character)
    -- Be enemies with the same dudes our owner is enemies with
    return self.owner:is_enemies_with(character)
end

function Golem:set_position(position)
    Golem.super.set_position(self, position)
end


function Golem:update()
    Golem.super.update(self)

    self.ai.level.follow.prob = nil
    self.ai.level.chase.prob = 10

    -- If we have anything other than just our claws, drop it
    for _, item in pairs(self.inventory.items) do
        if item.weaponType ~= 'claws' then
            self:bring_item_to_owner(item)

            -- Only bring one item at a time, since our items table may have
            -- changed
            break
        end
    end
end
