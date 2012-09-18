local wizard = Trader({ware = Weapon('firestaff')})

-- Appearance
wizard.name = 'WIZARD'
wizard.images = playerImg

-- See monsters as enemies
wizard:add_enemy_class(Monster)

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

wizard.receive_damage =
    function(self, amount, agent)
        if wizard.class.super.receive_damage(self, amount, agent) then
            local perpetrator = get_ultimate_owner(agent)

            -- If the dude that hit us is not currently an enemy
            if not self:is_enemies_with(perpetrator) then
                -- Make him an enemy
                self:add_enemy(perpetrator)
            end

            return true
        else
            return false
        end
    end

return wizard
