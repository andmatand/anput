require('class.character')

Player = class('Player', Character)

function Player:init()
    Player.super.init(self)

    -- Remove AI in favor of just I
    self.ai = nil

    self.images = playerImg
    self.team = 1 -- Good guys
    self.magic = 100

    self.wantsToTrade = false
end

function Player:can_trade(price)
    if self:has_item(price.currency, price.quantity) then
        return true
    else
        return false
    end
end

function Player:die()
    Character.die(self)

    sound.playerDie:play()
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
    if self:is_standing_next_to(Trader) then
        return 'trade'
    end

    self.wantsToTrade = false

    return nil
end

function Player:get_artifact()
    for _, item in pairs(self.inventory.items) do
        if (item.itemType == ITEM_TYPE.ankh) then
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

function Player:is_standing_next_to(objectClass)
    for _, tile in pairs(adjacent_tiles(self.position)) do
        local contents = self.room:tile_contents(tile)
        if contents then
            for _, obj in pairs(contents) do
                if instanceOf(objectClass, obj) then
                    return true
                end
            end
        end
    end

    return false
end

function Player:keypressed(key)
    -- Get player input for trading
    if key == 'return' then
        if self.context == 'trade' then
            self.wantsToTrade = true
        end
    end
end

function Player:update()
    Player.super.update(self)

    self.context = self:find_context()
end

function Player:receive_damage(amount)
    Player.super.receive_damage(self, amount)

    if not self.dead then
        sound.playerCry:play()
    end
end

function Player:wants_to_trade()
    return self.wantsToTrade
end
