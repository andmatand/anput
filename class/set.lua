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

    -- Mouth
    self.mouth = Mouth({sprite = self})

    self.state = 'wait for player'
end

function Set:update()
    Set.super.update(self)
    
    if self.state == 'wait for player' then
        if self.room.game.player.room == self.room and self.room.fov then
            -- If we are within the player's field of view
            if tile_in_table(self:get_position(), self.room.fov) then
                -- Play our musical cue
                --sounds.set.encounter:play()
                self.state = 'speech'
            end
        end
    elseif self.state == 'speech' then
        self.mouth:set_speech('I AM SET, THE THUNDER GOD DUDE')
        --self.mouth:set_speech('WITNESS THE STORM OF SET, GOD OF THUNDER')
        self.mouth:speak()
        self.mouth:set_speech()

        self.state = 'wait for speech end'
    elseif self.state == 'wait for speech end' then
        if not self.mouth.isSpeaking then
            self.state = 'attack'
        end
    elseif self.state == 'attack' then
        -- Enable our AI
        self.ai.choiceTimer.delay = 0
        self.ai.level.attack = {dist = 15, prob = 8, delay = 0}
    end
end
