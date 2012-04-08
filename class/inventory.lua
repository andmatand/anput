-- An Inventory is a collection of Items
Inventory = class('Inventory')

function Inventory:init(owner)
	self.owner = owner

	self.items = {}
end

function Inventory:add(item)
	item.position = nil
	item.owner = self.owner
	table.insert(self.items, item)
end

function Inventory:get_item(itemType)
	for _, item in pairs(self.items) do
		if item.itemType == itemType then
			return item
		end
	end
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

function Inventory:remove(item)
	-- Search for the item in our items table
	for i, invItem in ipairs(self.items) do
		if invItem == item then
			-- Remove the item from our items table
			table.remove(self.items, i)
			break
		end
	end
end
