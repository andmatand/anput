require('class.character')
require('class.timer')

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
    self.mouth.speakToNeighbor = false

    self.teleportWaitTimer = Timer(15)
    self.teleportFlashTimer = Timer(8)

    self.state = 'wait for player'
end

function Set:die()
    -- Open the doors blocking the exits
    self.roadblockInfo.exitDoor:open()
    self.roadblockInfo.entranceDoor:open()

    Set.super.die(self)
end

function Set:update()
    Set.super.update(self)
    
    if self.state == 'wait for player' then
        if self.room.game.player.room == self.room and self.room.fov then
            -- If we are within the player's field of view
            if tile_in_table(self:get_position(), self.room.fov) then
                -- Play our musical cue
                sounds.set.encounter:play()
                self.state = 'speech'

                -- Close the door blocking the entrance
                self.roadblockInfo.entranceDoor:close()
            end
        end
    elseif self.state == 'speech' then
        self.mouth:set_speech('WITNESS THE THUNDEROUS MIGHT OF SET')
        self.mouth:speak()

        self.state = 'wait for speech end'

        -- Pause all physics in the room
        self.room.physicsEnabled = false
    elseif self.state == 'wait for speech end' then
        if not self.mouth.isSpeaking then
            -- Resume the room's physics
            self.room.physicsEnabled = true

            -- Begin attacking
            self.state = 'attack'
        end
    elseif self.state == 'attack' then
        -- Enable our AI
        self.ai.choiceTimer.delay = 0
        self.ai.level.attack = {dist = 15, prob = 8, delay = 0}

        if self.teleportWaitTimer:update() then
            self.teleportWaitTimer:reset()

            -- If the player is close enough to us
            if manhattan_distance(self.room.game.player:get_position(),
                                  self:get_position()) < 10 then
                -- Teleport to somewhere
                self.state = 'pre-teleport'
            end
        end
    end

    if self.state == 'pre-teleport' or self.state == 'teleport' or
       self.state == 'post-teleport' then
        -- Change to a random color
        local colors = {CYAN, MAGENTA, WHITE}
        self.color = colors[math.random(1, #colors)]

        if self.teleportFlashTimer:update() then
            self.teleportFlashTimer:reset()

            if self.state == 'pre-teleport' then
                self.state = 'teleport'
            elseif self.state == 'post-teleport' then
                self.color = CYAN
                self.state = 'attack'
            end
        end
    end

    if self.state == 'teleport' then
        -- Play a teleporting sound
        sounds.set.teleport:play()

        self:set_position(self.room:get_free_tile())
        self.state = 'post-teleport'
    end
end
