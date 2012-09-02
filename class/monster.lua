require('class.character')

MONSTER_TYPE = {scarab = 1,
                bird = 2,
                cat = 3,
                mummy = 4,
                archer = 5,
                ghost = 6}

Monster = class('Monster', Character)

MONSTER_DIFFICULTY = {
     1, -- 1 scarab
     5, -- 2 bird
    10, -- 3 cat
    20, -- 4 mummy
    40, -- 5 archer
    60  -- 6 ghost
    }

--MONSTER_TEMPLATE = {
--    scarab = {difficulty = 1,
--              images = monsterImg.scarab,
--              health = 10,
--              ai.level.flee = {dist = 15, prob = 9, delay = .3}},
--    bird   = {difficulty = 5, images = monsterImg.bird},
--    cat    = {difficulty = 10, images = monsterImg.cat},
--    mummy  = {difficulty = 20, images = monsterImg.mummy},
--    archer = {difficulty = 40, images = monsterImg.archer},
--    ghost  = {difficulty = 60, images = monsterImg.ghost}}

function Monster:init(monsterType)
    Character.init(self)

    Monster.static.numMonsterTypes = 5

    self.monsterType = monsterType

    self.team = 2 -- Bad guys

    -- Copy monster difficulty level
    self.difficulty = MONSTER_DIFFICULTY[monsterType]

    -- Set monster properties
    if self.monsterType == MONSTER_TYPE.scarab then
        self.images = monsterImg.scarab
        self.health = 10

        self.ai.choiceTimer.delay = .25
        self.ai.level.attack = {dist = 10, prob = 5, delay = .3}
        self.ai.level.flee = {dist = 15, prob = 9, delay = 0}
        self.ai.level.loot = {dist = 6, prob = 3, delay = .5}
    elseif self.monsterType == MONSTER_TYPE.bird then
        self.images = monsterImg.bird
        self.health = 20

        local claws = Weapon('claws')
        claws.damage = 15
        self:pick_up(claws)

        self.ai.choiceTimer.delay = .5
        self.ai.level.attack = {dist = 10, prob = 8, delay = .3}
        self.ai.level.dodge = {dist = 5, prob = 5, delay = .5}
        self.ai.level.chase = {dist = 10, prob = 8, delay = .3}
        self.ai.level.flee = {dist = 15, prob = 9, delay = .3}
        self.ai.level.loot = {dist = 10, prob = 2, delay = .5}
        self.ai.level.explore = {dist = 15, prob = 8, delay = .5}
    elseif self.monsterType == MONSTER_TYPE.cat then
        self.images = monsterImg.cat
        self.health = 40

        local claws = Weapon('claws')
        claws.damage = 10
        self:pick_up(claws)

        self.ai.choiceTimer.delay = .25
        self.ai.level.attack = {dist = 20, prob = 9, delay = .1}
        self.ai.level.chase = {dist = 10, prob = 9, delay = .1}
        self.ai.level.dodge = {dist = 7, prob = 7, delay = .2}
        self.ai.level.flee = {dist = 15, prob = 9, delay = .1}
        self.ai.level.loot = {dist = 10, prob = 9, delay = .2}
        self.ai.level.explore = {dist = 15, prob = 8, delay = .5}
    elseif self.monsterType == MONSTER_TYPE.mummy then
        self.images = monsterImg.mummy
        self.health = 40
        self.magic = 50

        local claws = Weapon('claws')
        claws.damage = 20
        self:pick_up(claws)

        self.ai.choiceTimer.delay = .5
        self.ai.level.attack = {dist = 15, prob = 8, delay = .2}
        self.ai.level.chase = {dist = 20, prob = 8, delay = .2}
        self.ai.level.dodge = {dist = 5, prob = 7, delay = .2}
        self.ai.level.flee = {dist = 15, prob = 9, delay = .2}
        self.ai.level.loot = {dist = 20, prob = 6, delay = .5}
        self.ai.level.explore = {dist = 15, prob = 8, delay = .5}
    elseif self.monsterType == MONSTER_TYPE.archer then
        self.images = monsterImg.archer
        self.health = 60

        local claws = Weapon('claws')
        claws.damage = 15
        self:pick_up(claws)

        local bow = Weapon('bow')
        bow:add_ammo(20)
        self:pick_up(bow)

        self.ai.choiceTimer.delay = .5
        self.ai.level.aim = {dist = 15, prob = 9, delay = .1}
        self.ai.level.attack = {dist = 15, prob = 9, delay = .1}
        self.ai.level.dodge = {dist = 5, prob = 7, delay = .2}
        self.ai.level.chase = {dist = 20, prob = 6, delay = .15}
        self.ai.level.loot = {dist = 20, prob = 6, delay = .5}
        self.ai.level.explore = {dist = 15, prob = 8, delay = .5}
    elseif self.monsterType == MONSTER_TYPE.ghost then
        self.images = monsterImg.ghost
        self.health = 80
        self.magic = 100
        self.isCorporeal = false

        local staff = Weapon('staff')
        staff:set_projectile_class(Fireball)
        self:pick_up(staff)

        self.ai.choiceTimer.delay = .25
        self.ai.level.aim = {dist = 20, prob = 8, delay = .1}
        self.ai.level.attack = {dist = 20, prob = 8, delay = .3}
        self.ai.level.dodge = {dist = 5, prob = 9, delay = .3}
        self.ai.level.explore = {dist = 15, prob = 8, delay = .5}
    end
end

function Monster:die()
    Character.die(self)

    if self:is_audible() then
        sound.monsterDie:play()
    end
end

function Monster:hit(patient)
    if self.monsterType == MONSTER_TYPE.ghost then
        return false
    end

    return Monster.super.hit(self, patient)
end

function Monster:receive_hit(agent)
    if self.monsterType == MONSTER_TYPE.ghost then
        -- Only magic hits ghosts
        if instanceOf(Fireball, agent) then
            return true
        else
            return false
        end
    end

    return Monster.super.receive_hit(self, agent)
end
