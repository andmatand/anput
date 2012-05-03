require('class/character')

Monster = class('Monster', Character)

Monster.static.difficulties = {
     1, -- 1. Scarab
     5, -- 2. Bird
    10, -- 3. mummy
    15, -- 4. cat
    40  -- 5. ghost
    }

function Monster:init(pos, monsterType)
    Character.init(self)

    Monster.static.numMonsterTypes = 5

    self.position = pos
    self.monsterType = monsterType

    self.team = 2 -- Bad guys

    -- Copy monster difficulty level
    self.difficulty = Monster.static.difficulties[monsterType]

    -- Set monster properties
    if self.monsterType == 1 then
        self.images = monsterImg.scarab
        self.health = 10

        self.ai.dodge = {dist = 5, prob = 2, delay = 4}
        self.ai.flee = {dist = 15, prob = 9, delay = 3}
    elseif self.monsterType == 2 then
        self.images = monsterImg.bird
        self.health = 20

        self:pick_up(Weapon('sword'), false)

        self.ai.dodge = {dist = 5, prob = 5, delay = 5}
        self.ai.chase = {dist = 10, prob = 5, delay = 5}
    elseif self.monsterType == 3 then
        self.images = monsterImg.mummy
        self.health = 40

        self:pick_up(Weapon('sword'), false)
        local bow = Weapon('bow')
        bow:add_ammo(20)
        self:pick_up(bow, false)

        self.ai.dodge = {dist = 5, prob = 7, delay = 4}
        self.ai.chase = {dist = 20, prob = 7, delay = 10}
        self.ai.shoot = {dist = 15, prob = 7, delay = 4}
    elseif self.monsterType == 4 then
        self.images = monsterImg.cat
        self.health = 40

        self.inventory:add(Weapon('sword'))
        local bow = Weapon('bow')
        bow:add_ammo(20)
        self:pick_up(bow, false)

        self.ai.dodge = {dist = 7, prob = 9, delay = 3}
        self.ai.chase = {dist = 10, prob = 9, delay = 3}
        self.ai.shoot = {dist = 15, prob = 5, delay = 3}
    elseif self.monsterType == 5 then
        self.images = monsterImg.ghost
        self.health = 80
        self.isCorporeal = false

        local staff = Weapon('staff')
        staff:add_ammo(20)
        staff:set_projectile_class(Fireball)
        self:pick_up(staff, false)

        self.ai.dodge = {dist = 5, prob = 9, delay = 3}
        self.ai.chase = {dist = 20, prob = 1, delay = 3}
        self.ai.shoot = {dist = 10, prob = 7, delay = 4}
    end
end

function Monster:die()
    Character.die(self)

    sound.monsterDie:play()
end

function Monster:hit(patient)
    return Character.hit(self, patient)
end

function Monster:receive_hit(agent)
    if self.monsterType == 5 then -- A ghost
        -- Only magic hits ghosts
        if instanceOf(Fireball, agent) then
            return true
        else
            return false
        end
    end

    return Character.receive_hit(self, agent)
end
