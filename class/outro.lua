require('class.outside')

Outro = class('Outro')

function Outro:init(game)
    self.game = game

    -- Create an outside environment which we can manipulate
    self.outside = Outside()

    -- Start with the temple door open
    self.outside.door:open(true)

    -- Save the y position of the fake outside player
    local y = self.outside.player.position.y

    -- Substitute the actual game's player for the the fake outside player
    self.outside.player = self.game.player

    -- Start the scene with the player facing left at the door of the temple
    self.outside.player:set_position({x = 31, y = y})
    self.outside.player.dir = 4

    self.artifact = self.outside.player:get_artifact()
    if self.artifact then
        self.artifact.position = nil
    end

    if self.artifact then
        self.state = 'talk win'
    else
        self.state = 'talk'
    end

    self.outside:add_dialogue(self:choose_speech())
end

function Outro:choose_speech()
    local lines = {}

    -- If the player has the artifact
    if self.state == 'talk win' then
        if self.game.numOutsideVisits >= 20 then
            lines = {{m = 'YOU ACTUALLY FOUND AN ARTIFACT???'},
                     {m = 'NOT GONNA LIE; I WAS HOPING YOU WOULDN\'T ' ..
                          'MAKE IT BACK'},
                     {m = 'OH WELL'},
                     {m = 'LET\'S HAVE A LOOK AT IT'}}
        elseif self.game.numOutsideVisits >= 5 then
            lines = {{m = 'TOOK YOU LONG ENOUGH'},
                     {m = 'BRING IT OVER HERE'}}
        else
            lines = {{m = 'AT LAST!'},
                     {m = 'THE ARTIFACT'}}
        end

        return lines
    elseif self.state == 'edutain' then
        if self.artifact.itemType == 'ankh' then
            lines = {{p = 'IT IS AN ANKH'},
                     {p = 'THE ANKH IS AN EGYPTIAN SYMBOL OF LIFE'},
                     {p = 'IT IS ALSO A HIEROGLYPH'}}
        end

        return lines
    elseif self.state == 'talk' then
        local choices = {
            {{m = 'DID YOU FIND AN ARTIFACT YET?'},
             {p = '...'}},
            {{m = 'WHERE IS THE ARTIFACT?'},
             {p = '...'}},
            {{m = 'DON\'T JUST STAND THERE'},
             {m = 'GO FIND AN ARTIFACT'}},
            {{m = 'DON\'T COME BACK WITHOUT AN ARTIFACT'}},
            {{m = 'GET BACK IN THERE AND FIND AN ARTIFACT'}},
            {{m = 'ENJOYING THE FRESH AIR?'}},
            {{m = '*AHEM*'}},
            {{m = 'SMOKE BREAK\'S OVER'}},
            {{m = 'BUT SERIOUSLY'}},
            {{m = 'HOW\'S THAT ARTIFACT COMING?'}},
            {{m = 'IF YOU BRING AN ARTIFACT SOON, YOU CAN RIDE ON THE ' ..
                  'STEGASAURUS LIKE YOU\'VE ALWAYS WANTED'}},
            {{m = 'OKAY FINE, THE T-REX TOO'}},
            {{m = 'IF YOU DON\'T FIND AN ARTIFACT, ALL OF THE ORPHANS WILL ' ..
                  'BE SO SAD THAT THEY WILL CONTRACT MEASLES AND DIE'}},
            {{m = 'HAVE YOU NO CONCERN FOR THE REPUTATION OF THIS MUSEUM?'}},
            {{m = 'HOW MANY TIMES DO I HAVE TO TELL YOU?'}},
            {{m = 'FIND AN ARTIFACT!'}},
            {{m = 'NOW!'}},
            {{m = '!'}},
            {{m = '!!!!!!'}},
            {{m = 'LET ME GUESS'},
             {m = 'YOU STILL HAVEN\'T FOUND AN ARTIFACT, HAVE YOU?'},
             {p = '...'}},
            {{m = 'I KNEW WE SHOULD HAVE GONE WITH THAT DR. JONES GUY'}},
            {{m = 'OR EVEN THAT ONE CHICK WHOSE ONLY EXPERIENCE WAS WITH' ..
                  ' TOMBS'}},
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

    if self.artifact and self.artifact.position then
        self.artifact:draw()
    end
end

function Outro:key_pressed(key)
    if key == KEYS.SKIP_DIALOG then
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
        end
    elseif self.state == 'talk win' then
        if not self.outside.room:update_messages() then
            self.state = 'walk'
            self.frameTimer = love.timer.getTime() + .2
        end
    elseif self.state == 'walk' then
        if self.outside.player.position.x > 11 then
            if love.timer.getTime() >= self.frameTimer + .2 then
                self.outside.player:step(4)
                self.frameTimer = love.timer.getTime()
            end
        else
            self.state = 'drop'
        end
    elseif self.state == 'drop' then
        self.artifact:set_position({x = self.outside.player.position.x - 1,
                                    y = self.outside.player.position.y})
        self.outside.player:drop_item(self.artifact)

        self.frameTimer = love.timer.getTime()
        self.state = 'edutain'
        self.outside:add_dialogue(self:choose_speech())
    elseif self.state == 'edutain' then
        if love.timer.getTime() >= self.frameTimer + .25 then
            if not self.outside.room:update_messages() then
                --self.state = 'next'
            end
        end
    elseif self.state == 'turn' then
        self.outside.player.dir = 2
        self.state = 'finish'
        self.frameTimer = love.timer.getTime()
    elseif self.state == 'finish' then
        if love.timer.getTime() >= self.frameTimer + .2 then
            if self.game.status == 'game over' then
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
