require('class.character')
require('class.player')

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

function Monster:init(game, monsterType)
    Character.init(self)

    self.game = game

    self.monsterType = monsterType

    self:add_enemy_class(Player)
    self:add_enemy(self.game.wizard)

    -- Copy monster difficulty level
    self.difficulty = MONSTER_DIFFICULTY[monsterType]

    -- Set monster properties
    if self.monsterType == MONSTER_TYPE.scarab then
        self.images = monsterImg.scarab
        self.maxHealth = 10

        self.ai.choiceTimer.delay = .25
        self.ai.level.attack = {dist = 10, prob = 5, delay = .3}
        self.ai.level.flee = {dist = 15, prob = 9, delay = 0}
        self.ai.level.loot = {dist = 6, prob = 3, delay = .5}
    elseif self.monsterType == MONSTER_TYPE.bird then
        self.images = monsterImg.bird
        self.maxHealth = 20

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
        self.maxHealth = 40

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
        self.maxHealth = 40
        self.magic = 50

        local claws = Weapon('claws')
        claws.damage = 20
        self:pick_up(claws)

        self.ai.choiceTimer.delay = .5
        self.ai.level.attack = {dist = 15, prob = 8, delay = .2}
        self.ai.level.chase = {dist = 20, prob = 8, delay = .2}
        self.ai.level.dodge = {dist = 5, prob = 7, delay = .2}
        self.ai.level.flee = {dist = 15, prob = 9, delay = .2}
        self.ai.level.heal = {prob = 8, delay = .5}
        self.ai.level.loot = {dist = 20, prob = 6, delay = .4}
        self.ai.level.explore = {dist = 15, prob = 8, delay = .5}
    elseif self.monsterType == MONSTER_TYPE.archer then
        self.images = monsterImg.archer
        self.maxHealth = 60

        --local claws = Weapon('claws')
        --claws.damage = 15
        --self:pick_up(claws)
        local sword = Weapon('sword')
        sword.damage = 15
        self:pick_up(sword)

        local bow = Weapon('bow')
        self:pick_up(bow)
        bow:add_ammo(20)

        self.ai.choiceTimer.delay = .5
        self.ai.level.aim = {dist = 15, prob = 9, delay = .1}
        self.ai.level.attack = {dist = 15, prob = 9, delay = .1}
        self.ai.level.chase = {dist = 20, prob = 6, delay = .15}
        self.ai.level.dodge = {dist = 7, prob = 8, delay = .1}
        self.ai.level.heal = {prob = 8, delay = .5}
        self.ai.level.loot = {dist = 20, prob = 6, delay = .5}
        self.ai.level.explore = {dist = 15, prob = 8, delay = .5}
    elseif self.monsterType == MONSTER_TYPE.ghost then
        self.images = monsterImg.ghost
        self.maxHealth = 80
        self.magic = 100
        self.isCorporeal = false

        local staff = Weapon('firestaff')
        self:pick_up(staff)

        self.ai.choiceTimer.delay = .25
        self.ai.level.aim = {dist = 20, prob = 8, delay = .1}
        self.ai.level.attack = {dist = 20, prob = 8, delay = .3}
        self.ai.level.dodge = {dist = 5, prob = 9, delay = .3}
        self.ai.level.explore = {dist = 15, prob = 8, delay = .5}
        self.ai.level.flee = {dist = 10, prob = 8, delay = .3}
    end

    self.health = self.maxHealth
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
        if agent.isMagic then
            return true
        else
            return false
        end
    end

    return Monster.super.receive_hit(self, agent)
end
