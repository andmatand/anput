local wizard = Trader({ware = Weapon('firestaff')})

-- Appearance
wizard.name = 'WIZARD'
wizard.images = playerImg

-- AI
wizard.ai.choiceTimer.delay = .5
wizard.ai.level.aim = {dist = 4, prob = 10, delay = .1}
wizard.ai.level.attack = {dist = 10, prob = 10, delay = .25}
wizard.ai.level.dodge = {dist = 5, prob = 10, delay = 0}
wizard.ai.level.flee = {dist = 10, prob = 10, delay = .25}
wizard.ai.level.heal = {prob = 10, delay = .5}
--wizard.ai.level.dodge = {dist = 5, prob = 10, delay = 0}
wizard.ai.level.chase = {delay = .1}
--wizard.ai.level.loot = {dist = 20, prob = 10, delay = .1}
--wizard.ai.level.explore = {dist = 15, prob = 8, delay = 1}
--wizard.ai.level.shoot = {dist = 10, prob = 10, delay = .25}

-- Trader properties
wizard.price.quantity = 7
wizard.speech = {offer = 'I WOULD GIVE MY STAFF FOR 7 SHINY THINGS',
                 drop  = 'HERE YOU GO',
                 enjoy = 'ENJOY'}

local whichLine = math.random(1, 3)
if whichLine == 1 then
    wizard.speech.later = "NOW I CAN BUY THAT NEW DRESS I'VE BEEN WANTING"
elseif whichLine == 2 then
    wizard.speech.later = "I AM ENJOYING MY SHINY THINGS"
elseif whichLine == 3 then
    wizard.speech.later = "SHINY! SHINY! SHINY!"
end

return wizard
