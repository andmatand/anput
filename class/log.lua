Log = class('Log')

function Log:init()
    self.kills = {}
end

function Log:add_kill(character)
    table.insert(self.kills, character)
end

function Log:get_kills()
    return self.kills
end
