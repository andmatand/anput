require('class.arrow')
require('class.fireball')

-- A weapon is an Item that can also hurt other Characters or shoot Projectiles
Weapon = class('Weapon', Item)

-- Weapon templates
Weapon.static.templates = {
    claws = {name = 'claws', meleeDamage = 15},
    sword = {name = 'sword', order = 1, meleeDamage = 15},
    bow = {name = 'bow', order = 2, ammoCost = 1, ammoItem = ITEM_TYPE.arrow,
           projectileClass = Arrow},
    staff = {name = 'staff', order = 3, isMagic = true, ammoCost = 10,
             meleeDamage = 5, projectileClass = Fireball}
    }

function Weapon:init(weaponType)
    Weapon.super.init(self, weaponType)

    -- Copy the weapon template for the specified type to create a new weapon
    for k, v in pairs(Weapon.static.templates[weaponType]) do
        self[k] = v
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

    if self.name == 'sword' then
        img = swordImg
    elseif self.name == 'bow' then
        img = bowImg
    elseif self.name == 'staff' then
        img = staffImg
    end

    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(img,
                       upscale_x(position.x), upscale_y(position.y),
                       0, SCALE_X, SCALE_Y)
end

function Weapon:is_effective_against(character)
    -- If we are not a magic weapon
    if not self.isMagic then
        if character.monsterType == MONSTER_TYPE.ghost then
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

function Weapon:set_projectile_class(c)
    self.projectileClass = c
end

function Weapon:shoot(dir)
    if self.owner then
        if self:get_ammo() >= self.ammoCost then
            self:use_ammo(self.ammoCost)

            return self.projectileClass(self.owner, dir)
        else
            sound.unable:play()
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
