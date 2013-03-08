require('class.character')
require('class.horn')

Khnum = class('Khnum', Character)

function Khnum:init()
    Khnum.super.init(self)

    self.name = 'KHNUM'
    self.images = images.npc.khnum
    self.magic = 100

    --self:add_enemy_class(Monster)
    self:add_enemy_class(Player)

    self.ai.choiceTimer.delay = .25
    self.ai.level.flee = {delay = 0}

    -- Mouth
    self.mouth = Mouth({sprite = self})
    self.mouth.speakToNeighbor = false

    -- Give him the Horn of Khnum
    self:pick_up(Horn())

    self.state = 'wait'
end

function Khnum:die()
    -- Open the doors blocking the exits
    self.roadblockInfo.exitDoor:open()
    self.roadblockInfo.entranceDoor:open()

    Khnum.super.die(self)
end

function Khnum:update()
    Khnum.super.update(self)

    if self.state == 'wait' then
        if self.room.game.player.room == self.room and self.room.fov then
            -- If we are within the player's field of view
            if tile_in_table(self:get_position(), self.room.fov) then
                -- Play our musical cue
                sounds.khnum.encounter:play()
                self.state = 'line1'
            end
        end
    elseif self.state == 'line1' then
        self.mouth:set_speech('I AM KHNUM, MOULDER OF MEN')
        self.mouth:speak()
        self.state = 'line2'

        -- If the player is in the entrance doorway (i.e. he would be hit by
        -- the door)
        local entranceDoor = self.roadblockInfo.entranceDoor
        local doorway = entranceDoor:get_position()
        if tiles_overlap(self.room.game.player:get_position(), doorway) then
            -- Make the player take a step into the room
            local dir = opposite_direction(entranceDoor:get_direction())
            self.room.game.player:step(dir)
        end

        -- Pause all physics in the room
        self.room.physicsEnabled = false

        -- Close the door blocking the entrance
        self.roadblockInfo.entranceDoor:close()
    elseif self.state == 'line2' then
        if not self.mouth.isSpeaking then
            self.mouth:set_speech('RISE, MY CLAY BABIES!')
            self.mouth:speak()

            self.state = 'wait to attack'
        end
    elseif self.state == 'wait to attack' then
        if not self.mouth.isSpeaking then
            self.state = 'attack'

            -- Resume the room's physics
            self.room.physicsEnabled = true
        end
    elseif self.state == 'attack' then
        -- If we don't have a path
        if not self.ai.path.nodes then
            -- Give us infinite magic (we are divine, after all)
            self.magic = 100

            -- If there are not already too many sprites in the room
            if #self.room.sprites < 30 then
                -- Spawn golems in all four directions
                for dir = 1, 4 do
                    self:shoot(dir)
                end
            end

            -- Plot a path to a random point in the room
            self.ai:plot_path(self.room:get_free_tile())
            self.ai.path.action = AI_ACTION.flee
        end
    end
end
