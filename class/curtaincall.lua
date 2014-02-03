require('class.puppet')
require('class.timer')

CurtainCall = class('CurtainCall')

function CurtainCall:init(leader, outside, credits)
    self.leader = leader
    self.outside = outside
    self.credits = credits

    self.queue = {}
    self.currentPuppet = self.leader
    self.walkDistance = 18
    self.bowTimer = Timer(FPS_LIMIT * 3)

    -- Create all the monster puppets that will come out at the curtain call
    local monsterTypes = {'scarab', 'bird', 'cat', 'cobra', 'mummy', 'archer',
                          'ghost'}
    for _, name in pairs(monsterTypes) do
        -- Find the table of images for this monster
        local img = images.monsters[name]

        local image
        local walkAnimation
        local danceAnimation

        -- If this monster has a default image
        if img.default then
            image = img.default
        -- If this monster has a bow image
        elseif img.bow then
            image = img.bow
        end

        -- If this monster has a walk image
        if img.walk then
            local frames

            -- If the walk "image" is a animation-prototype table
            if type(img.walk) == 'table' then
                -- Use the table as the animation frames
                frames = img.walk
            else
                -- Create a one-frame animation from the image
                frames = {{image = img.walk, delay = 0}}
            end

            -- Create a walk animation from the frames
            walkAnimation = Animation(frames)
        end

        if img.default and (img.walk or img.step) then
            local image2 = img.walk or img.step

            -- Create a default dance animation
            danceAnimation = Animation({{image = img.default,
                                         delay = DANCE_DELAY},
                                        {image = image2,
                                         delay = DANCE_DELAY}})
        end

        -- Create a puppet for this monster
        local puppet = Puppet({image = image,
                               walkAnimation = walkAnimation,
                               danceAnimation = danceAnimation,
                               color = CYAN})

        -- Add this puppet to the queue
        table.insert(self.queue, puppet)
    end

    -- Create a walk animation for the scarab puppet
    local scarabWalk = Animation({{image = images.monsters.scarab.step,
                                   delay = 3},
                                  {image = images.monsters.scarab.default,
                                   delay = 3}})
    self.queue[1].walkAnimation = scarabWalk

    -- Create a walk animation for the bird puppet
    local birdWalk = Animation({{image = images.monsters.bird.step,
                                 delay = 3},
                                {image = images.monsters.bird.default,
                                 delay = 3}})
    self.queue[2].walkAnimation = birdWalk

    -- Create a dance animation for the cobra puppet
    local cobraDance = Animation({{image = images.monsters.cobra.walk[2].image,
                                   delay = DANCE_DELAY},
                                  {image = images.monsters.cobra.walk[1].image,
                                   delay = DANCE_DELAY}})
    self.queue[4].danceAnimation = cobraDance

    -- Add a Wizard puppet
    table.insert(self.queue, Puppet({image = images.npc.wizard.firestaff,
                                     color = CYAN}))

    -- Add a Khnum puppet
    local khnum = Puppet({image = images.npc.khnum.default,
                          color = CYAN})
    khnum.name = 'khnum'
    table.insert(self.queue, khnum)

    -- Create two golem puppets
    self.golems = {}
    local x = 21
    for i = 1, 2 do
        local spawn = Animation(images.monsters.golem.spawn)
        spawn.loop = false

        local dance = Animation({{image = images.monsters.golem.default,
                                  delay = DANCE_DELAY},
                                 {image = images.monsters.golem.attack,
                                  delay = DANCE_DELAY}})

        local puppet = Puppet({image = images.monsters.golem.default,
                               color = MAGENTA,
                               danceAnimation = spawn})
        puppet.realDanceAnimation = dance
        puppet.name = 'golem'

        puppet:set_position({x = x, y = self.leader.position.y})
        x = x + 2

        table.insert(self.golems, puppet)
    end
    self.golemSpawnTimer = Timer(DANCE_DELAY * 2)

    -- Add a Set puppet
    table.insert(self.queue, Puppet({image = images.npc.set.default,
                                     color = CYAN}))

    -- Create a walk animation for the camel
    local camelWalk = Animation({{image = images.npc.camel.step, delay = 3},
                                 {image = images.npc.camel.default, delay = 3}})
    -- Create a dance animation for the camel
    local camelDance = Animation({{image = images.npc.camel.step,
                                   delay = DANCE_DELAY},
                                  {image = images.npc.camel.default,
                                   delay = DANCE_DELAY}})

    -- Create the Camel
    self.camel = {}
    self.camel.puppet = Puppet({image = images.npc.camel.default,
                                color = CYAN,
                                walkAnimation = camelWalk,
                                danceAnimation = camelDance})
    self.camel.puppet.enabled = false;
    self.camel.timer = Timer(200)
    self.camel.timer.value = 10

    -- Position the camel puppet offscreen, facing east
    self.camel.puppet:set_position({x = -1, y = GRID_H - 5})
    self.camel.puppet.dir = 2

    -- Add the camel puppet to the outside puppets
    table.insert(self.outside.puppets, self.camel.puppet)
end

function CurtainCall:update_camel()
    if not self.camel.puppet.enabled then return end

    if self.camel.timer:update() then
        self.camel.timer:reset()

        -- Make the camel run across the screen
        self.camel.puppet:walk(self.camel.puppet.dir, GRID_W + 1)
    end

    local x = self.camel.puppet:get_position().x

    -- If the camel is off the west side of the screen
    if x < 0 then
        -- Turn east
        self.camel.puppet.dir = 2
    -- If the camel is off the east side of the screen
    elseif x > GRID_W - 1 then
        -- Turn west
        self.camel.puppet.dir = 4
    end
end

function CurtainCall:update()
    -- If we've waited long enough for the previous puppet to take a bow
    if self.currentPuppet.state == 'dance' and self.bowTimer:update() then
        -- If there are still puppets in the curtain-call queue
        if self.queue[1] then
            -- Pop the first puppet off the curtain-call queue
            local puppet = table.remove(self.queue, 1)

            -- Put the puppet in the door of the temple, facing left
            puppet:set_position({x = 31, y = self.leader.position.y})
            puppet.dir = 4

            if puppet.name == 'khnum' then
                self.walkDistance = self.walkDistance - 1
            end

            -- Make the puppet start walking left
            puppet:walk(4, self.walkDistance, .5)
            self.walkDistance = self.walkDistance - 1

            if puppet.name == 'khnum' then
                self.walkDistance = self.walkDistance - 1
            end

            -- Add the puppet to the outside puppets table
            table.insert(self.outside.puppets, puppet)

            -- Save this puppet as our current curtain-call puppet
            self.currentPuppet = puppet

            -- Advance to the next credit
            self.credits:advance()
        else
            -- If the camel is not enabled yet
            if not self.camel.puppet.enabled then
                -- Enable the camel
                self.camel.puppet.enabled = true

                -- Let the credits advance on their own from here on
                self.credits:play()
                self.credits.timer:move_to_end()
            end
        end
    end

    -- If the current puppet is standing
    if self.currentPuppet.state == 'stand' then
        local okayToStartDancing = false

        if self.leader.danceAnimation:is_at_beginning() then
            okayToStartDancing = true
        end

        -- If the puppet is Khnum, and he hasn't summoned the golems yet
        if self.currentPuppet.name == 'khnum' and not self.spawnedGolems then
            okayToStartDancing = false
            if self.golemSpawnTimer:update() then
                self.credits:advance()

                -- Spawn the golems
                for _, golem in pairs(self.golems) do
                    golem:dance()
                    table.insert(self.outside.puppets, golem)
                end
                self.spawnedGolems = true
            end
        elseif self.currentPuppet.name == 'khnum' and self.spawnedGolems then
            if okayToStartDancing and
               self.golems[1].danceAnimation:is_stopped() then
                -- Change the golems' animation to the actual dance animation
                for _, golem in pairs(self.golems) do
                    golem.danceAnimation = golem.realDanceAnimation
                end
            else
                okayToStartDancing = false
            end
        end

        if okayToStartDancing then
            -- Make the puppet start dancing
            self.currentPuppet:dance()

            -- Reset the bow timer
            self.bowTimer:reset()
        end
    end

    if self.leader.danceAnimation:is_at_beginning() then
        -- Find the first non-leader puppet turn
        local danceLeader = self.outside.puppets[3]

        if danceLeader then
            danceLeader:turn_around()

            -- Make all the puppets except the player and danceLeader turn
            -- around
            for _, puppet in pairs(self.outside.puppets) do
                if puppet ~= self.leader and puppet ~= danceLeader and
                   puppet.name ~= 'golem' and puppet.state == 'dance' then
                    -- Set this puppet's direction to the same as the dance
                    -- leader
                    puppet.dir = danceLeader.dir
                end
            end
        end
    end

    self:update_camel()
end
