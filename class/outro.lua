require('class.credits')
require('class.curtaincall')
require('class.outside')
require('class.timer')
require('util.graphics')
require('util.settings')

Outro = class('Outro')

function Outro:init(game)
    self.game = game

    -- Create an outside environment which we can manipulate
    self.outside = Outside() 

    -- Start with the temple door open
    self.outside.door:open(true)

    -- Make a syntactical shortcut to access the outside puppets
    self.puppets = self.outside.puppets

    -- Give the game player's current image to the puppet player
    self.puppets.player.image = self.game.player.currentImage

    -- Start the scene with the player facing left at the door of the temple
    self.puppets.player.position.x = 31
    self.puppets.player.dir = 4

    local artifact = game.player:get_artifact()

    -- If the player has an artifact
    if artifact then
        self.puppets.artifact = Puppet({image = artifact.image})
        self.puppets.artifact.enabled = false

        self.state = 'win talk'
    else
        self.state = 'talk'
    end

    self.outside:add_dialogue(self:choose_speech())

    -- Set the museum's dance animation
    outsideImg.museum.image2 = new_image('museum2.png')
    local museumDance = Animation({{image = outsideImg.museum.image2,
                                    delay = DANCE_DELAY},
                                  {image = outsideImg.museum.image1,
                                   delay = DANCE_DELAY}})
    self.outside.puppets.museum.danceAnimation = museumDance


    -- Set the players's dance animation
    outsideImg.player = {dance = new_image('player-dance.png')}
    local playerDance = Animation({{image = outsideImg.player.dance,
                                    delay = DANCE_DELAY},
                                  {image = playerImg.default,
                                   delay = DANCE_DELAY}})
    self.outside.puppets.player.danceAnimation = playerDance

    -- Load the victory theme
    sounds.victoryTheme = Sound('res/sfx/victory-theme.wav')

    -- Load the dance music
    self.danceMusic = {}
    self.danceMusic.sounds = {Sound('res/sfx/funky-i.wav'),
                              Sound('res/sfx/funky-iv.wav'),
                              Sound('res/sfx/funky-v.wav'),
                              Sound('res/sfx/funky-i-hits.wav'),
                              Sound('res/sfx/funky-iv-hits.wav'),
                              Sound('res/sfx/funky-v-hits.wav')}
    self.danceMusic.playlist = {1, 1,
                                2, 1,
                                3, 2,
                                1, 1,
                                4, 4,
                                5, 4,
                                6, 5,
                                4, 4}
    self.danceMusic.playlistIndex = 1
    self.danceMusic.timer = Timer(DANCE_DELAY * 4)

    -- Speed up the music a little bit, to better match the dance speed
    for _, sound in pairs(self.danceMusic.sounds) do
        sound.source:setPitch(1.05)
    end

    -- Compensate for bug in OpenAL apparently
    for _, sound in pairs(self.danceMusic.sounds) do
        sound.source:setVolume(sounds.thud.source:getVolume())
    end
    apply_sound_setting()
end

function Outro:key_pressed(key)
    self.outside:key_pressed(key)
end

function Outro:choose_speech()
    local lines = {}

    -- If the player has the artifact
    if self.state == 'win talk' then
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
                     {m = 'THE ARTIFACT!'}}
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

    if self.credits then
        self.credits:draw()
    end
end

function Outro:update()
    if self.state == 'talk' then
        -- If the dialogue is finished
        if self.outside.messageQueue:is_empty() then
            self.state = 'turn'
        end
    elseif self.state == 'win talk' then
        -- If the dialogue is finished
        if self.outside.messageQueue:is_empty() then
            self.puppets.player:walk(4, 20, 2)
            self.state = 'win walk' end
    elseif self.state == 'win walk' then
        if self.puppets.player.position.x == 11 then
            self.delayStart = love.timer.getTime()
            self.state = 'win drop'
        end
    elseif self.state == 'win drop' then
        if love.timer.getTime() >= self.delayStart + .5 then
            -- Drop the artifact
            local position = {x = self.puppets.player.position.x - 1,
                              y = self.puppets.player.position.y}
            self.puppets.artifact:set_position(position)
            self.puppets.artifact.enabled = true

            self.delayStart = love.timer.getTime()
            self.state = 'win music'
        end
    elseif self.state == 'win music' then
        if love.timer.getTime() >= self.delayStart + .5 then
            sounds.victoryTheme:play()
            self.delayStart = love.timer.getTime()
            self.state = 'win listen'
        end
    elseif self.state == 'win listen' then
        if love.timer.getTime() >= self.delayStart + 4 then
            self.state = 'win dance'

            -- Ensure that the dance music starts playing at the same
            -- time the dancing starts
            self.danceMusic.timer:move_to_end()

            self.delayStart = love.timer.getTime()
        end
    elseif self.state == 'win dance' then
        self.puppets.museum:dance()
        self.puppets.player:dance()
        if love.timer.getTime() >= self.delayStart + 6 then
            -- Turn the player to the right
            self.puppets.player.dir = 2

            -- Start the credits, paused (so that they only advance manually
            -- for now)
            self.credits = Credits()
            self.credits:pause()

            -- Start the curtain call
            self.curtainCall = CurtainCall(self.puppets.player, self.outside,
                                           self.credits)
            self.state = 'credits'
        end
    elseif self.state == 'credits' then
        -- Do something??
    elseif self.state == 'turn' then
        self.puppets.player.dir = 2
        self.state = 'finish'
        self.delayStart = love.timer.getTime()
    elseif self.state == 'finish' then
        if love.timer.getTime() >= self.delayStart + .2 then
            if self.game.status == 'game over' then
                love.event.quit()
            else
                self.state = 'go back inside'
            end
        end
    end

    self.outside:update()
    
    if self.curtainCall then
        self.curtainCall:update()
    end

    if self.credits then
        self.credits:update()
    end

    if self.state == 'win dance' or self.state == 'credits' then
        self:play_dance_music()
    end
end

function Outro:play_dance_music()
    if self.danceMusic.timer:update() then
        self.danceMusic.timer:reset()

        local soundIndex
        soundIndex = self.danceMusic.playlist[self.danceMusic.playlistIndex]

        self.danceMusic.sounds[soundIndex]:play()
        self.danceMusic.playlistIndex = self.danceMusic.playlistIndex + 1

        if self.danceMusic.playlistIndex > #self.danceMusic.playlist then
            self.danceMusic.playlistIndex = 1
        end
    end
end
