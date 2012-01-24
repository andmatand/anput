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
		if i <= wallNum then -- TEMP: draw one brick at a time
			b:draw()
		end
	end
end

function Room:generate()
	rb = RoomBuilder:new(self.exits)
	self.bricks = rb:build()
end
