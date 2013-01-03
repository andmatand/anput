require('class.golem')
require('class.weapon')

Horn = class('Horn', Weapon)

function Horn:init()
    Horn.super.init(self, 'horn')
end

function Horn:shoot(dir)
    if self:get_ammo() < self.ammoCost then
        if instanceOf(Player, self.owner) then
            sounds.unable:play()
        end
        return false
    end

    -- Find positioins
    local positions = {}
    --for dir = 1, 4 do
    --    table.insert(positions,
    --                 add_direction(self.owner:get_position(), dir, 2))
    --end
    table.insert(positions, add_direction(self.owner:get_position(), dir, 2))

    local spawnedGolem = false
    for _, pos in pairs(positions) do
        if self.owner.room:tile_walkable(pos) then
            local golem = Golem(self.owner)
            golem:set_position(pos)
            self.owner.room:add_object(golem)

            -- Use one unit of ammo for each golem
            self:use_ammo(self.ammoCost)
            spawnedGolem = true
        end
    end

    if spawnedGolem then
        return true
    else
        if instanceOf(Player, self.owner) then
            sounds.unable:play()
        end
        return false
    end
end
