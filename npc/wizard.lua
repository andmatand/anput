local wizard = Trader({ware = Weapon('firestaff')})

-- Appearance
wizard.name = 'WIZARD'
wizard.images = playerImg

-- See monsters as enemies
wizard:add_enemy_class(Monster)

-- AI
wizard.ai.choiceTimer.delay = .25
wizard.ai.level.aim = {dist = 4, prob = 10, delay = .1}
wizard.ai.level.attack = {dist = 10, prob = 10, delay = .1}
wizard.ai.level.dodge = {dist = 7, prob = 10, delay = 0}
wizard.ai.level.flee = {dist = 10, prob = 10, delay = .25}
wizard.ai.level.heal = {prob = 10, delay = .5}
wizard.ai.level.chase = {delay = .1}

-- Trader properties
wizard.price.quantity = 7
wizard.speech = {offer = {'I WOULD GIVE MY STAFF FOR 7 SHINY THINGS',
                          'I LIKE SHINY THINGS'},
                 enemy = {'YOU PROBABLY WANT TO RUN AWAY',
                          "DUDE, I'M SHOOTING AT YOU"},
                 drop  = 'HERE YOU GO',
                 enjoy = 'ENJOY',
                 later = {"NOW I CAN BUY THAT NEW DRESS I'VE BEEN WANTING",
                          'I AM ENJOYING MY SHINY THINGS',
                          'SHINY! SHINY! SHINY!'}}

wizard.forgive = 
    function(self)
        self.mouth:set_speech({'HEY NOT COOL',
                               "OKAY DON'T DO THAT AGAIN"})
        self.mouth:speak(true)

        -- Avenge next time
        self.ai.reactions.avenge = true
    end

wizard.avenge = 
    function(self)
        self.mouth:set_speech({'MAN, NOW I HAVE TO KILL YOU',
                               'ALL I WANTED WAS SOME SHINY THINGS'})
        self.mouth:speak(true)

        -- Be more agressive
        wizard.ai.level.aim.dist = 10
    end

return wizard
