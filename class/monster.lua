require('class.character')
require('class.player')

Monster = class('Monster', Character)

MONSTER_DIFFICULTY = {scarab = 1,
                      bird = 5,
                      cat = 20,
                      snake = nil,
                      mummy = 30,
                      archer = 40,
                      ghost = 60}

function Monster:init(game, monsterType)
    Character.init(self)

    self.game = game

    self.monsterType = monsterType

    self:add_enemy_class(Player)
    self:add_enemy(self.game.wizard)

    -- Copy monster difficulty level
    self.difficulty = MONSTER_DIFFICULTY[monsterType]

    -- Set monster properties
    if self.monsterType == 'scarab' then
        self.images = images.monsters.scarab
        self.maxHealth = 10

        self.ai.choiceTimer.delay = .25
        self.ai.level.attack = {dist = 10, prob = 5, delay = .3}
        self.ai.level.flee = {dist = 15, prob = 9, delay = 0}
        self.ai.level.loot = {dist = 6, prob = 3, delay = .5}
    elseif self.monsterType == 'bird' then
        self.images = images.monsters.bird
        self.maxHealth = 20

        local claws = Weapon('claws')
        claws.meleeDamage = 15
        self:pick_up(claws)

        self.ai.choiceTimer.delay = .5
        self.ai.level.attack = {dist = 10, prob = 8, delay = .3}
        self.ai.level.dodge = {dist = 5, prob = 5, delay = .5}
        self.ai.level.chase = {dist = 10, prob = 8, delay = .3}
        self.ai.level.flee = {dist = 15, prob = 9, delay = .3}
        self.ai.level.loot = {dist = 10, prob = 2, delay = .5}
        self.ai.level.explore = {dist = 15, prob = 8, delay = .5}
    elseif self.monsterType == 'cat' then
        self.images = images.monsters.cat
        self.maxHealth = 40

        local claws = Weapon('claws')
        claws.meleeDamage = 10
        self:pick_up(claws)

        self.ai.choiceTimer.delay = .25
        self.ai.level.attack = {dist = 20, prob = 9, delay = .1}
        self.ai.level.chase = {dist = 10, prob = 9, delay = .1}
        self.ai.level.dodge = {dist = 7, prob = 7, delay = .2}
        self.ai.level.flee = {dist = 15, prob = 9, delay = .1}
        self.ai.level.loot = {dist = 10, prob = 9, delay = .2}
        self.ai.level.explore = {dist = 15, prob = 8, delay = .5}
    elseif self.monsterType == 'snake' then
        self.images = images.monsters.snake
        self.maxHealth = 30

        local claws = Weapon('claws')
        claws.meleeDamage = 40
        self:pick_up(claws)

        self.ai.choiceTimer.delay = .1
        self.ai.level.attack = {dist = 20, prob = 10, delay = .5}
        self.ai.level.chase = {dist = 2, prob = 5, delay = .1}
        self.ai.level.dodge = {dist = 7, prob = 7, delay = .6}
        self.ai.level.flee = {dist = 15, prob = 9, delay = .1}
        self.ai.level.loot = {dist = 2, prob = 4, delay = .2}
    elseif self.monsterType == 'mummy' then
        self.images = images.monsters.mummy
        self.maxHealth = 40
        self.magic = 50

        local claws = Weapon('claws')
        claws.meleeDamage = 20
        self:pick_up(claws)

        self.ai.choiceTimer.delay = .5
        self.ai.level.attack = {dist = 15, prob = 8, delay = .2}
        self.ai.level.chase = {dist = 20, prob = 8, delay = .2}
        self.ai.level.dodge = {dist = 5, prob = 7, delay = .2}
        self.ai.level.flee = {dist = 15, prob = 9, delay = .2}
        self.ai.level.heal = {prob = 8, delay = .5}
        self.ai.level.loot = {dist = 20, prob = 6, delay = .4}
        self.ai.level.explore = {dist = 15, prob = 8, delay = .5}
    elseif self.monsterType == 'archer' then
        self.images = images.monsters.archer
        self.maxHealth = 60

        --local claws = Weapon('claws')
        --claws.meleeDamage = 15
        --self:pick_up(claws)
        local sword = Weapon('sword')
        sword.meleeDamage = 15
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
    elseif self.monsterType == 'ghost' then
        self.images = images.monsters.ghost
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
    if self.monsterType == 'ghost' then
        return false
    end

    return Monster.super.hit(self, patient)
end

function Monster:receive_hit(agent)
    if self.monsterType == 'ghost' then
        -- Only magic hits ghosts
        if agent.isMagic then
            return true
        else
            return false
        end
    end

    return Monster.super.receive_hit(self, agent)
end
