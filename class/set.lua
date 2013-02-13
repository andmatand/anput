require('class.character')

Set = class('Set', Character)

function Set:init()
    Set.super.init(self)

    -- Appearance
    self.name = 'SET'
    self.images = images.npc.set
    self.magic = 100

    -- Give him the thunderstaff
    local staff = ThunderStaff()
    self:pick_up(staff)

    self:add_enemy_class(Golem)
    self:add_enemy_class(Monster)
    self:add_enemy_class(Player)

    -- AI
    self.ai.choiceTimer.delay = 0
    self.ai.level.attack = {dist = 15, prob = 8, delay = 0}

    -- Mouth
    self.mouth = Mouth({sprite = self})
end
