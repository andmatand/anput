require('class.outside')

Outro = class('Outro')

function Outro:init(game)
    self.game = game

    -- Create an outside environment which we can manipulate
    self.outside = Outside()

    -- Start with the temple door open
    self.outside.door.height = self.outside.door.maxHeight

    -- Save the y position of the fake outside player
    local y = self.outside.player.position.y

    -- Substitute the actual game's player for the the fake outside player
    self.outside.player = self.game.player

    -- Start the scene with the player facing left at the door of the temple
    self.outside.player:set_position({x = 31, y = y})
    self.outside.player.dir = 4

    self:choose_speech()
    self.state = 'talk'
end

function Outro:choose_speech()
    local choices

    -- If the player has the artifact
    if self.game.player:has_artifact() then
    else
        choices = {
            {{m = 'DID YOU FIND AN ARTIFACT YET?'},
             {p = '...'}},
            {{m = 'LET ME GUESS'},
             {m = 'YOU STILL HAVEN\'T FOUND AN ARTIFACT, HAVE YOU?'},
             {m = 'I KNEW WE SHOULD HAVE GONE WITH THAT DR. JONES GUY'},
             {p = '...'}}
        }
    end

    n = math.random(1, #choices)
    for _, line in pairs(choices[n]) do
        for actor, text in pairs(line) do
            if actor == 'm' then
                table.insert(self.outside.room.messages,
                             Message({text = text,
                                      room = self.outside.room,
                                      avatar = self.outside.museum}))
            elseif actor == 'p' then
                table.insert(self.outside.room.messages,
                             Message({text = text,
                                      room = self.outside.room,
                                      avatar = self.outside.player}))
            end
        end
    end
end

function Outro:draw()
    self.outside:draw()
end

function Outro:keypressed(key)
    if key == '.' then
        -- If there is a message on the queue
        if self.outside.room.messages[1] then
            -- Skip it
            self.outside.room.messages[1].finished = true
        end
    end
end

function Outro:update()
    print(self.state)
    if self.state == 'talk' then
        if not self.outside.room:update_messages() then
            self.state = 'walk'
            self.outside.player.stepTimer = love.timer.getTime() + .3
        end
    elseif self.state == 'walk' then
        if love.timer.getTime() >= self.outside.player.stepTimer + .1 then
            if self.outside.player:get_position().x < 30 then
                --self.outside.player.mirrored = false
                self.outside.player:step(2)
            else
                self.state = 'open'
            end
            self.outside.player.stepTimer = love.timer.getTime()
        end
        self.state = 'finish'
        self.finishTimer = love.timer.getTime()
    elseif self.state == 'finish' then
        if love.timer.getTime() >= self.finishTimer + .2 then
            if self.game.player:has_artifact() then
                self.state = 'win'
            else
                self.state = 'go back'
            end
        end
    end

    self.outside.player:update()
    self.outside.player:physics()
    self.outside.player:post_physics()
end
