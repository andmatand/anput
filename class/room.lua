require 'class/roombuilder.lua'

Room = {}
Room.__index = Room

function Room:new(exits)
	local o = {}
	setmetatable(o, self)

	o.exits = exits

	return o
end

function Room:draw()
	for i,b in pairs(self.bricks) do
		--if i <= wallNum then -- TEMP: draw one brick at a time
			b:draw()
		--end
	end
end

function Room:generate()
	rb = RoomBuilder:new(self.exits)
	rbResults = rb:build()
	self.bricks = rbResults.bricks
	self.freeTiles = rbResults.freeTiles
end

function Room:get_exit(position)
	for i,e in pairs(self.exits) do
		if e.x == position.x or e.y == position.y then
			return e
		end
	end
end
