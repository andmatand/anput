require('class.character')
require('class.horn')

Khnum = class('Khnum', Character)

function Khnum:init()
    Khnum.super.init(self)

    self.name = 'KHNUM'
    self.images = images.npc.khnum
    self.magic = 100

    self:add_enemy_class(Monster)
    self:add_enemy_class(Player)

    self.ai.choiceTimer.delay = .25
    self.ai.level.flee = {delay = 0}

    -- Mouth
    self.mouth = Mouth({sprite = self})

    -- Give him the Horn of Khnum
    self:pick_up(Horn())

    self.state = 'wait'
end

function Khnum:update()
    Khnum.super.update(self)

    if self.state == 'wait' then
        if self.room.game.player.room == self.room and self.room.fov then
        -- If we are within the player's field of view
            if tile_in_table(self:get_position(), self.room.fov) then
                self.state = 'line1'
            end
        end
    elseif self.state == 'line1' then
        self.mouth:set_speech('I AM KHNUM, MOULDER OF MEN')
        self.mouth:speak()
        self.state = 'line2'

        -- Prevent the player from moving
        wrapper.game.player.canMove = false
    elseif self.state == 'line2' then
        if not self.mouth.isSpeaking then
            self.mouth:set_speech('RISE, MY CLAY BABIES!')
            self.mouth:speak()
            self.mouth:set_speech()

            self.state = 'wait to attack'
        end
    elseif self.state == 'wait to attack' then
        if not self.mouth.isSpeaking then
            self.state = 'attack'

            -- Let the player move again
            wrapper.game.player.canMove = true
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
