require('class.character')
require('class.switch')

Player = class('Player', Character)

function Player:init()
    Player.super.init(self)

    self:add_enemy_class(Monster)
    self:add_enemy_class(Khnum)

    -- Remove AI in favor of just I
    self.ai = nil

    self.images = playerImg
    self.color = WHITE
    self.magic = 100
    self.mouth = Mouth({sprite = self})

    self.wantsToTrade = false
end

function Player:can_trade(price)
    if self:has_item(price.currency, price.quantity) then
        return true
    else
        return false
    end
end

-- Drops the payment when paying a Trader
function Player:drop_payment(price, position)
    -- Create a table of items that are acting as payment
    local munnies = {}
    for _, item in pairs(self.inventory.items) do
        if item.itemType == price.currency then
            table.insert(munnies, item)
            if #munnies == price.quantity then
                break
            end
        end
    end

    -- Drop each item (must be done in a separate loop because drop_item alters
    -- the inventory table)
    for _, m in pairs(munnies) do
        m.position = position
        self:drop_item(m)
    end
end

function Player:find_context()
    for _, pos in pairs(adjacent_tiles(self.position)) do
        local tile = self.room.tileCache:get_tile(pos)
        for _, obj in pairs(tile.contents) do
            if instanceOf(Switch, obj) then
                if not obj.isActivated then
                    return obj
                end
            end
        end

        for _, s in pairs(self.room.sprites) do
            if tiles_overlap(pos, s:get_position()) then
                if instanceOf(Trader, s) then
                    -- If the trade has something to trade, and we have enough
                    -- to buy his ware
                    if s:can_trade() and self:can_trade(s.price) then
                        return 'trade'
                    end
                elseif instanceOf(Camel, s) and not s.isCaught then
                    return 'grab'
                end
            end
        end
    end

    return nil
end

function Player:get_artifact()
    for _, item in pairs(self.inventory.items) do
        if (item.itemType == 'ankh') then
            return item
        end
    end
end

function Player:hit(patient)
    -- Ignore screen edge
    if patient == nil then
        return false
    end

    return Player.super.hit(self, patient)
end

function Player:key_held(key)
    -- Get input for walking
    local dir
    if key == KEYS.WALK.NORTH then
        dir = 1
    elseif key == KEYS.WALK.EAST then
        dir = 2
    elseif key == KEYS.WALK.SOUTH then
        dir = 3
    elseif key == KEYS.WALK.WEST then
        dir = 4
    end
    if dir then
        self:step(dir)
        return
    end

    -- If we are wielding the thunderstaff
    if self.armory:get_current_weapon_type() == 'thunderstaff' then
        -- If the key is one of the shoot keys
        if value_in_table(key, KEYS.SHOOT) then
            self.shootDir = 1
        end
    end
end

function Player:key_pressed(key)
    if not key then
        return
    end

    -- Get input for switching weapons
    if key >= KEYS.WEAPON_SLOT_1 and key <= KEYS.WEAPON_SLOT_5 then
        -- Switch to specified weapon number, based on display order
        self.armory:switch_to_weapon_number(key - KEYS.WEAPON_SLOT_1 + 1)
    end
    if key == KEYS.SWITCH_WEAPON then
        -- Switch to the next weapon
        self.armory:switch_to_next_weapon()
    end

    -- Get input for using items
    if key == KEYS.ELIXIR then
        -- Take an elixir
        if self:has_item('elixir') then
            self.inventory:get_item('elixir'):use()
        end
    elseif key == KEYS.POTION then
        -- Take a potion
        if self:has_item('potion') then
            self.inventory:get_item('potion'):use()
        end
    end

    -- If the game is paused
    if self.room.game.paused then
        -- Don't allow input below here
        return
    end


    -- If the key is one of the walk keys
    if value_in_table(key, KEYS.WALK) then
        self:key_held(key)
    end

    -- Get input for the context button
    if key == KEYS.CONTEXT then
        if self.context == 'trade' then
            self.wantsToTrade = true
        elseif self.context == 'grab' then
            self.isGrabbing = true
        elseif instanceOf(Switch, self.context) then
            self.context:activate()
        end
    end

    -- Get input for shooting
    if key == KEYS.SHOOT.NORTH then
        self.shootDir = 1
    elseif key == KEYS.SHOOT.EAST then
        self.shootDir = 2
    elseif key == KEYS.SHOOT.SOUTH then
        self.shootDir = 3
    elseif key == KEYS.SHOOT.WEST then
        self.shootDir = 4
    end
end

function Player:shoot(dir)
    Player.super.shoot(self, dir)

    self.room.game.tutorial.playerShot = true
end

function Player:update()
    Player.super.update(self)

    self.context = self:find_context()

    -- Show a context messages in the status bar
    local contextAction
    if self.context == 'trade' then
        contextAction = 'TRADE'
    elseif self.context == 'grab' then
        contextAction = 'GRAB'
    elseif instanceOf(Switch, self.context) then
        contextAction = 'ACTIVATE'
    end
    if contextAction then
        self.room.game.statusBar:show_context_message({'enter'}, contextAction)
    end
end

function Player:wants_to_trade()
    return self.wantsToTrade
end
