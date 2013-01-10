-- An Inventory is a collection of Items
Inventory = class('Inventory')

function Inventory:init(owner)
    self.owner = owner

    self.items = {}

    self.numItemSlots = 9
end

function Inventory:add(item)
    item.position = nil
    item.owner = self.owner

    -- Find the index of an existing item of the same type
    local index
    for i, it in pairs(self.items) do
        if it.itemType == item.itemType then
            index = i
            break
        end
    end

    if index then
        -- Insert the new item after the found index
        table.insert(self.items, index + 1, item)
    else
        table.insert(self.items, item)
    end

    -- Save a pointer to the most recently added item
    self.newestItem = item
end

function Inventory:can_pick_up(item)
    -- If the item is a weapon
    if instanceOf(Weapon, item) then
        -- If it contains ammo
        if item.ammo and item.ammo > 0 then
            return true
        end

        -- If we already have this type of weapon
        if self:has_item(item.itemType) then
            return false
        end
    end

    if self:has_room_for(item) then
        return true
    end
end

-- This function returns one item of the specified type
function Inventory:get_item(itemType)
    for _, item in pairs(self.items) do
        if item.itemType == itemType then
            return item
        end
    end
end

-- This function returns a specified quantity of items of the specified type,
-- or all of them if no quantity is given
function Inventory:get_items(itemType, quantity)
    local items = {}

    for _, item in pairs(self.items) do
        if item.itemType == itemType then
            table.insert(items, item)

            if quantity and #items >= quantity then
                return items
            end
        end
    end

    return items
end

function Inventory:get_non_weapons()
    local temp = {}
    for _, item in pairs(self.items) do
        if not instanceOf(Weapon, item) then
            table.insert(temp, item)
        end
    end

    return temp
end

function Inventory:get_unique_items()
    local items = {}
    local usedItemTypes = {}

    for _, item in pairs(self.items) do
        if not usedItemTypes[item.itemType] then
            usedItemTypes[item.itemType] = true
            table.insert(items, item)
        end
    end

    return items
end

function Inventory:has_item(itemType, quantity)
    local quantity = quantity or 1
    local num = 0

    for _, i in pairs(self.items) do
        if i.itemType == itemType then
            num = num + 1

            if num == quantity then
                return true
            end
        end
    end

    return false
end

function Inventory:has_room_for(item)
    local num = #self:get_unique_items()

    -- If we have less items than there are slots
    if num < self.numItemSlots then
        return true
    elseif num == self.numItemSlots then
        -- If the new item is of the same type as one of our current ones
        if self:get_item(item.itemType) ~= nil then
            return true
        end
    end

    return false
end

function Inventory:remove(item)
    -- Search for the item in our items table
    for i, invItem in ipairs(self.items) do
        if invItem == item then
            -- Remove ourself as owner
            invItem.owner = nil

            -- Remove the item from our items table
            table.remove(self.items, i)

            -- If this is our most recently added item
            if item == self.newestItem then
                -- Clear the pointer to the most recently added item
                self.newestItem = nil
            end
            break
        end
    end
end
