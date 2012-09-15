require('class.thunderbolt')
require('class.weapon')

ThunderStaff = class('ThunderStaff', Weapon)

function ThunderStaff:init()
    ThunderStaff.super.init(self, 'thunderstaff')

    self.damage = 4
    self.path = {}
end

function ThunderStaff:plot_path(src, dest)
    self.path.src = src
    self.path.dest = dest

    -- Plot a path from src to dest
    local pf = PathFinder(self.path.src, self.path.dest,
                          self.owner.room:get_obstacles())
    self.path.nodes = pf:plot()
end

function ThunderStaff:shoot()
    if self:get_ammo() < self.ammoCost then
        sound.unable:play()
        return
    end

    -- Find the closest enemy sprite
    local best = {sprite = nil, dist = 999}
    for _, s in pairs(self.owner.room.sprites) do
        if instanceOf(Character, s) and self.owner:is_enemies_with(s) then
            dist = manhattan_distance(s:get_position(), self.owner.position)

            -- If it's closer than the current closest
            if dist < best.dist then
                best.dist = dist
                best.sprite = s
            end
        end
    end

    -- If we found a target
    if best.sprite then
        self:use_ammo(self.ammoCost)

        local useOldPath = false

        -- If we have an old path
        if self.path.nodes then
            -- If the new src and dest are the in the same positions as those
            -- of the old path
            if tiles_overlap(self.owner:get_position(), self.path.src) and
               tiles_overlap(best.sprite:get_position(), self.path.dest) then
                useOldPath = true
            end
        end

        if not useOldPath then
            self:plot_path(self.owner:get_position(),
                           best.sprite:get_position())
        end

        -- Create a thunderbolt
        self.thunderbolt = Thunderbolt({staff = self, nodes = self.path.nodes})

        -- Add it to the room
        self.owner.room:add_object(self.thunderbolt)

        -- Damage everything in the path of the thunderbolt
        for i, n in pairs(self.path.nodes) do
            -- If this is not the tile where the owner is
            if i > 1 then
                for _, s in pairs(self.owner.room.sprites) do
                    if tiles_overlap(s:get_position(), n) then
                        -- If the sprite has a receive_damage function
                        if s.receive_damage then
                            s:receive_damage(self.damage)

                            if math.random(1, 3) ~= 1 then
                                s.isThundershocked = true
                            end
                        end
                    end
                end
            end
        end
    else
        sound.unable:play()
    end
end
