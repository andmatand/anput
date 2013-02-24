require('class.character')
require('class.monster')

Wizard = class('Wizard', Trader)

function Wizard:init()
    Wizard.super.init(self, {ware = Weapon('firestaff')})

    self.name = 'WIZARD'
    self.images = images.npc.wizard
    self.magic = 100

    -- See monsters as enemies
    self:add_enemy_class(Monster)

    -- AI
    self.ai.choiceTimer.delay = .25
    self.ai.level.aim = {dist = 4, prob = 10, delay = .1}
    self.ai.level.attack = {dist = 10, prob = 10, delay = .1}
    self.ai.level.avoid = {prob = 10, delay = 0}
    self.ai.level.dodge = {dist = 7, prob = 10, delay = 0}
    self.ai.level.flee = {dist = 10, prob = 10, delay = .25}
    self.ai.level.heal = {prob = 10, delay = .5}
    self.ai.level.chase = {delay = .1}

    -- Trader properties
    self.price.quantity = 7
    self.speech = {offer = {'I WOULD GIVE MY STAFF FOR 7 SHINY THINGS',
                            'I LIKE SHINY THINGS'},
                   enemy = {'YOU PROBABLY WANT TO RUN AWAY',
                            "DUDE, I'M SHOOTING AT YOU"},
                   drop  = 'HERE YOU GO',
                   enjoy = 'ENJOY',
                   later = {"NOW I CAN BUY THAT NEW DRESS I'VE BEEN WANTING",
                            'I AM ENJOYING MY SHINY THINGS',
                            'SHINY! SHINY! SHINY!'}}
end

function Wizard:forgive()
    self.mouth:set_speech({'HEY NOT COOL',
                           "OKAY DON'T DO THAT AGAIN"})
    self.mouth:speak(true)

    -- Avenge next time
    self.ai.reactions.avenge = true
end

function Wizard:avenge()
    self.mouth:set_speech({'MAN, NOW I HAVE TO KILL YOU',
    'ALL I WANTED WAS SOME SHINY THINGS'})
    self.mouth:speak(true)

    -- Be more agressive
    self.ai.level.aim.dist = 10
end
