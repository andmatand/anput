-- An Item is an object that can exist in either a room (it has no physics) and
-- a Character's inventory
Item = class('Item')

ITEM_TYPE = {elixir = 1,
             arrow = 2,
             shinything = 3,
             sword = 4,
             bow = 5,
             staff = 6,
             ankh = 7}
ITEM_NAME = {'ELIXIR',
             'ARROW',
             'SHINY THING',
             'SWORD',
             'BOW',
             'STAFF',
             'ANKH'}

function Item:init(itemType)
    if type(itemType) == 'number' then
        self.itemType = itemType
    elseif type(itemType) == 'string' then
        self.itemType = ITEM_TYPE[itemType]
    end

    self.isUsable = false

    if self.itemType == ITEM_TYPE.elixir then
        self.frames = {{image = elixirImg}}
        self.isUsable = true
    elseif self.itemType == ITEM_TYPE.arrow then
        self.frames = {{image = arrowImg}}
        --self.frames = {{image = projectileImg.arrow}}
    elseif self.itemType == ITEM_TYPE.shinything then
        self.frames = {
            {image = shinyThingImg[1], delay = 8},
            {image = shinyThingImg[2], delay = 2},
            {image = shinyThingImg[3], delay = 2},
            {image = shinyThingImg[2], delay = 2},
            {image = shinyThingImg[3], delay = 2}}
    elseif self.itemType == ITEM_TYPE.ankh then
        self.frames = {{image = ankhImg}}
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
    return {x = self.position.x, y = self.position.y}
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
    if self.itemType == ITEM_TYPE.elixir then
        -- Health elixir
        if patient:add_health(20) then
            self.isUsed = true
            print('used elixir')

            -- Play sound depending on who got health
            if instanceOf(Player, patient) then
                sound.playerGetHP:play()
            elseif instanceOf(Monster, patient) then
                sound.monsterGetHP:play()
            end
            
            return true
        else
            sound.unable:play()
            return false
        end
    elseif self.itemType == ITEM_TYPE.arrow then
        -- Arrows
        -- If the patient has a bow
        if patient.armory.weapons.bow then
            patient.armory.weapons.bow:add_ammo(1)
            self.isUsed = true
            return true
        end
    end

    return false
end
