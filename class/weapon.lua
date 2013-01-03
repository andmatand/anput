require('class.arrow')
require('class.fireball')
require('class.item')

-- A weapon is an Item that can also hurt other Characters or shoot Projectiles
Weapon = class('Weapon', Item)

-- Weapon templates
WEAPON_TYPE = {
    claws        = {meleeDamage = 15},

    sword        = {order = 1,
                    meleeDamage = 15},

    bow          = {order = 2,
                    ammoCost = 1,
                    ammoItem = 'arrow',
                    projectileClass = Arrow},

    firestaff    = {order = 3,
                    meleeDamage = 5,
                    isMagic = true,
                    ammoCost = 10,
                    projectileClass = Fireball},

    thunderstaff = {order = 4,
                    meleeDamage = 5,
                    isMagic = true,
                    ammoCost = 4},

    horn         = {order = 5,
                    meleeDamage = 5,
                    isMagic = true,
                    ammoCost = 10}
    }

function Weapon:init(weaponType)
    Weapon.super.init(self, weaponType)

    -- Save a reference to the weapon name
    self.weaponType = weaponType

    -- Copy the weapon template for the specified type to create a new weapon
    for k, v in pairs(WEAPON_TYPE[weaponType]) do
        self[k] = v
    end

    -- Assign the image of the same name
    if images.items[self.weaponType] then
        self.image = images.items[self.weaponType]
    end

    self.isUsable = true
end

function Weapon:add_ammo(amount)
    if self.ammoItem and self.owner then
        for i = 1, amount do
            local item = Item(self.ammoItem)

            self.owner:pick_up(item)
        end
    end

    return false
end

function Weapon:draw(position)
    position = position or self.position

    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(self.image,
                       upscale_x(position.x), upscale_y(position.y),
                       0, SCALE_X, SCALE_Y)
end

function Weapon:is_effective_against(character)
    -- If we are not a magic weapon
    if not self.isMagic then
        if character.monsterType == 'ghost' then
            return false
        end
    end

    return true
end

function Weapon:get_ammo()
    if not self.owner then
        return false
    end

    if self.isMagic then
        if self.owner.magic then
            return self.owner.magic
        else
            return 0
        end
    elseif self.ammoItem then
        return #self.owner.inventory:get_items(self.ammoItem)
    end
end

function Weapon:shoot(dir)
    if self.owner and self.ammoCost then
        if self:get_ammo() >= self.ammoCost then
            self:use_ammo(self.ammoCost)

            if self.projectileClass then
                -- Create a new projectile
                local newProjectile = self.projectileClass(self.owner, dir)

                -- Add it to the room
                self.owner.room:add_object(newProjectile)
                return true
            end
        elseif instanceOf(Player, self.owner) then
            sounds.unable:play()
        end
    end

    return false
end

function Weapon:use()
    if self.owner then
        -- Make this weapon the owner's current weapon
        self.owner.armory:set_current_weapon(self)

        return true
    else
        return false
    end
end

function Weapon:use_ammo(amount)
    if not self.owner then
        return
    end

    if self.ammoItem then
        for i = 1, amount do
            local item = self.owner.inventory:get_item(self.ammoItem)

            -- Remove the item from the owner's inventory
            self.owner.inventory:remove(item)
        end
    elseif self.isMagic then
        self.owner:add_magic(-amount)
    end
end
