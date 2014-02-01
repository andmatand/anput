Log = class('Log')

function Log:init()
    self.hits = {}
    self.kills = {}
    self.wasKilledBy = false
    self.projectileStats = {hits = 0, shots = 0}
end

function Log:add_shot()
    self.projectileStats.shots = self.projectileStats.shots + 1
end

function Log:add_hit(patient, agent)
    table.insert(self.hits, patient)
    if instanceOf(Projectile, agent) then
        self.projectileStats.hits = self.projectileStats.hits + 1
    end
end

function Log:add_kill(character)
    table.insert(self.kills, character)
end

function Log:get_hits()
    return self.hits
end

function Log:get_kills()
    return self.kills
end
