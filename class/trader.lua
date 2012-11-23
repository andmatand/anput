-- A Trader is a Character who can sell an item to another Character
Trader = class('Trader', Character)

function Trader:init(args)
    Character.init(self)
    self.magic = 100

    self.price = {currency = 'shinything',
                  quantity = 99}
    self.ware = args.ware
    self.paymentItems = {}

    -- If we have a ware
    if self.ware then
        -- Add the ware to our inventory
        self:pick_up(self.ware)
    end

    -- Create a mouth.  Speaking is important for commerce, man.
    self.mouth = Mouth({sprite = self})
    self.speech = {offer = '',  -- What we say to advertise what we're selling
                   enemy = '',  -- What we say to an enemy player
                   drop = '',   -- What we say upon droping our ware
                   enjoy = '',  -- What we say when the customer picks up ware
                   later = ''}  -- What we say when approached after the sale

    self.delay = 0
end

function Trader:can_trade()
    if self.ware.owner == self then
        return true
    else
        return false
    end
end

function Trader:drop_ware()
    -- Position the ware in a spot that is 
    self.ware.position = self:find_common_tile()
    self:drop_item(self.ware)
end

function Trader:find_customer()
    local player = self.room.game.player

    -- If the player is touching us
    if (player.room == self.room and not player.isDead and
        tiles_touching(self.position, player.position)) then
        if self:is_enemies_with(player) then
            self.mouth:set_speech(self.speech.enemy)
        else
            -- Consider him our customer
            self.customer = player
        end
    else
        self.customer = nil
    end

    if self.customer then
        -- Look at the customer
        self.dir = self:direction_to(self.customer:get_position())

        return true
    else
        return false
    end
end

-- Returns a position that is accessible to both us and the customer
function Trader:find_common_tile()
    -- Find our non-diagonal neighboring tiles
    local ourTiles = find_neighbor_tiles(self.position, self.room.bricks,
                                         {diagonals = false})

    -- Remove all tiles which are occupied with bricks
    local temp = {}
    for _, t in pairs(ourTiles) do
        if not t.occupied then
            table.insert(temp, t)
        end
    end
    ourTiles = temp

    -- Find the customer's non-diagonal neighboring tiles, marking those that
    -- overlap with ours
    local customerTiles = find_neighbor_tiles(self.customer.position, ourTiles)

    -- Find the first tile that overlaps
    for _, t in pairs(customerTiles) do
        if t.occupied then
            return t
        end
    end
end

function Trader:find_payment()
    if self.paymentPosition then
        -- Get the contents of the paymentPosition
        local contents = self.room:tile_contents(self.paymentPosition)

        -- Check if the full payment is there
        local quantity = 0
        for _, c in pairs(contents) do
            if c.itemType == self.price.currency then
                quantity = quantity + 1

                if quantity == self.price.quantity then
                    return true
                end
            end
        end
    end

    return false
end

function Trader:is_delaying()
    if self.delay > 0 then
        self.delay = self.delay - 1
        return true
    else
        return false
    end
end

-- Override the Character pick_up() method
function Trader:pick_up(item)
    local pickedUpItem = Character.pick_up(self, item)

    if pickedUpItem then
        -- If we are waiting to recieve payment
        if self.receivedPayment == false then
            self.paymentItems = self.inventory:get_items(self.price.currency,
                                                         self.price.quantity)

            -- Check if we have the full price
            if #self.paymentItems == self.price.quantity then
                self.receivedPayment = true
                self.paymentPosition = nil
            end
        end
    end

    return pickedUpItem
end

function Trader:pick_up_payment()
    self:step(self:direction_to(self.paymentPosition))
end

function Trader:ask_for_payment()
    self.receivedPayment = false

    -- Pick the position where the customer should drop his payment
    self.paymentPosition = self:find_common_tile()

    if self.paymentPosition then
        -- Make the customer drop his payment
        self.customer:drop_payment(self.price, self.paymentPosition)
    elseif self.customer.stepped then
        self.mouth:set_speech("THERE'S NO ROOM HERE")

        -- Dodge the customer
        self.ai:dodge(self.customer,
                      self.customer:direction_to(self:get_position()))

        self.mouth:speak(true)
    end
end

function Trader:update()
    if self:is_delaying() then
        return
    end

    -- If we are holding anything other than our ware or payment
    for _, item in pairs(self.inventory.items) do
        if item ~= self.ware and
           not value_in_table(item, self.paymentItems) then
            self:drop_items({item})
        end
    end

    -- If we can see a payment nearby
    if self:find_payment() then
        -- Stop talking
        self.mouth:shut()

        -- Go get it
        self:pick_up_payment()
        self.delay = 4

    -- If we got the payment, and we are holding our ware
    elseif self.receivedPayment and self.ware.owner == self then
        -- Give our ware to the customer
        self:drop_ware()

        -- Say our "here you go" line
        self.mouth:set_speech(self.speech.drop)
        self.mouth:speak(true)

    -- If we have a customer nearby
    elseif self:find_customer() then
        -- If we still have our ware
        if self:can_trade() then
            -- If the customer is both willing and able to trade
            if (self.customer:wants_to_trade() and
                self.customer:can_trade(self.price)) then
                -- Trade with him
                self:ask_for_payment()
                self.delay = 4
            elseif self.customer.moved then
                -- Give him our sales pitch
                self.mouth:set_speech(self.speech.offer)
                self.mouth:speak()
            end
        elseif self.customer.moved then
            if self.speech.enjoy then
                -- Say our "enjoy" line
                self.mouth:set_speech(self.speech.enjoy)
                self.mouth:speak(true)

                -- Don't say it again
                self.speech.enjoy = nil
            else
                -- From now on, say our "later" line
                self.mouth:set_speech(self.speech.later)
                self.mouth:speak()
            end
        end
    end

    Trader.super.update(self)
end
