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

    self.outside:add_dialogue(self:choose_speech())
    self.state = 'talk'
end

function Outro:choose_speech()
    local lines = {}

    -- If the player has the artifact
    if self.game.player:has_artifact() then
    else
        local choices = {
            {{m = 'DID YOU FIND AN ARTIFACT YET?'},
             {p = '...'}},
            {{m = 'WHERE IS THE ARTIFACT?'},
             {p = '...'}},
            {{m = 'DON\'T JUST STAND THERE'},
             {m = 'GO FIND AN ARTIFACT'}},
            {{m = 'DON\'T COME BACK WITHOUT AN ARTIFACT'}},
            {{m = 'GET BACK IN THERE AND FIND AN ARTIFACT'}},
            {{m = 'HOW MANY TIMES DO I HAVE TO TELL YOU?'}},
            {{m = 'ENJOYING THE FRESH AIR?'}},
            {{m = 'SMOKE BREAK\'S OVER'}},
            {{m = 'FIND AN ARTIFACT!'}},
            {{m = 'NOW!'}},
            {{m = '!'}},
            {{m = '!!!!!!'}},
            {{m = 'LET ME GUESS'},
             {m = 'YOU STILL HAVEN\'T FOUND AN ARTIFACT, HAVE YOU?'},
             {p = '...'}},
            {{m = 'I KNEW WE SHOULD HAVE GONE WITH THAT DR. JONES GUY'}},
            {{m = 'OR EVEN THAT ONE CHICK WHOSE ONLY EXPERIENCE WAS WITH' ..
                  'TOMBS'}},
            {{m = 'THE MUSEUM GIVES YOU ONE THING TO DO'}},
            {{m = 'WORST. ARCHAEOLOGIST. EVER.'}},
            {{m = 'THAT\'S IT'},
             {m = 'YOU\'RE FIRED!'}}
        }

        local n = self.game.numOutsideVisits
        if n > #choices then
            n = #choices
        end

        if n == #choices then
            self.game.status = 'game over'
        end

        lines = choices[n]
    end

    return lines
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
    if self.state == 'talk' then
        if not self.outside.room:update_messages() then
            self.state = 'turn'
            self.outside.player.stepTimer = love.timer.getTime() + .3
        end
    elseif self.state == 'turn' then
        self.outside.player.dir = 2
        self.state = 'finish'
        self.finishTimer = love.timer.getTime()
    elseif self.state == 'finish' then
        if love.timer.getTime() >= self.finishTimer + .2 then
            if self.game.player:has_artifact() then
                self.state = 'win'
            elseif self.game.status == 'game over' then
                love.event.quit()
            else
                self.state = 'go back'
            end
        end
    end

    self.outside.player:update()
    self.outside.player:physics()
    self.outside.player:post_physics()
end
