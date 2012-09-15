-- An Item is an object that can exist in either a room (it has no physics) and
-- a Character's inventory
Item = class('Item')

             
ITEM_NAME = {
    -- Normal items
    elixir = 'ELIXIR',
    arrow = 'ARROW',
    shinything = 'SHINY THING',

    -- Weapons
    sword = 'SWORD',
    bow = 'BOW',
    firestaff = 'FIRE STAFF',
    thunderstaff = 'THUNDER STAFF',

    -- Artifacts
    ankh = 'ANKH',
    eye = 'EYE OF HORUS',
    feather = 'FEATHER OF MA\'AT'}


function Item:init(itemType)
    self.itemType = itemType

    self.isMovable = true

    if self.itemType == 'elixir' then
        self.isUsable = true
    end

    if self.itemType == 'shinything' then
        self.frames = {
            {image = image.shinything[1], delay = 8},
            {image = image.shinything[2], delay = 2},
            {image = image.shinything[3], delay = 2},
            {image = image.shinything[2], delay = 2},
            {image = image.shinything[3], delay = 2}}
    elseif image[self.itemType] then
        self.frames = {{image = image[self.itemType]}}
    else
        self.frames = nil
    end

    self.currentFrame = 1
    self.animateTimer = 0
    self.animationEnabled = true

    self.name = ITEM_NAME[self.itemType]
    self.owner = nil
    self.position = {}
end

function Item:animate()
    -- If there's nothing to animate
    if (self.frames == nil or #self.frames < 2 or
        self.animationEnabled == false) then
        -- Go away
        return
    end

    self.animateTimer = self.animateTimer + 1

    if self.animateTimer >= self.frames[self.currentFrame].delay then
        self.animateTimer = 0
        self.currentFrame = self.currentFrame + 1

        -- Loop back around to the first frame
        if self.currentFrame > #self.frames then
            self.currentFrame = 1
        end
    end
end

function Item:draw(manualPosition)
    local position = manualPosition or {x = upscale_x(self.position.x),
                                        y = upscale_y(self.position.y)}
    if self.frames then
        love.graphics.setColor(255, 255, 255)
        love.graphics.draw(self.frames[self.currentFrame].image,
                           position.x, position.y,
                           0, SCALE_X, SCALE_Y)
    end
end

function Item:get_position()
    if self.position then
        return {x = self.position.x, y = self.position.y}
    end
end

function Item:set_position(position)
    self.position = {x = position.x, y = position.y}
end

function Item:update()
    self:animate()
end

function Item:use()
    if self.owner then
        if self:use_on(self.owner) then
            self.owner.inventory:remove(self)
            return true
        else
            return false
        end
    end

    return false
end

function Item:use_on(patient)
    if self.itemType == 'elixir' then
        -- Health elixir
        if patient:add_health(20) then
            print('used elixir')

            -- Play sound depending on who got health
            if instanceOf(Player, patient) then
                sound.playerGetHP:play()
            elseif patient:is_audible() then
                sound.monsterGetHP:play()
            end
            
            return true
        else
            sound.unable:play()
            return false
        end
    elseif self.itemType == 'arrow' then
        -- Arrows
        -- If the patient has a bow
        if patient.armory.weapons.bow then
            patient.armory.weapons.bow:add_ammo(1)
            return true
        end
    end

    return false
end
