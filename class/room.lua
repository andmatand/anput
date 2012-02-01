require 'class/roombuilder.lua'

Room = {}
Room.__index = Room

function Room:new(exits, index)
	local o = {}
	setmetatable(o, self)

	o.exits = exits
	o.index = index
	o.generated = false
	o.sprites = {}

	return o
end

function Room:draw()
	for i,b in pairs(self.bricks) do
		b:draw()
	end

	if #self.sprites > 0 then
		for i,s in pairs(self.sprites) do
			s:draw()
		end
	end
end

function Room:generate()
	rb = RoomBuilder:new(self.exits)
	rbResults = rb:build()
	self.bricks = rbResults.bricks
	self.freeTiles = rbResults.freeTiles
	self.midPoint = rbResults.midPoint

	self.generated = true
end

function Room:get_exit(search)
	for i,e in pairs(self.exits) do
		if (e.x ~= nil and e.x == search.x) or
		   (e.y ~= nil and e.y == search.y) or
		   (e.roomIndex ~= nil and e.roomIndex == search.roomIndex) then
			return e
		end
	end
end

function Room:update()
	for i,s in pairs(self.sprites) do
		s:physics(self.bricks, self.sprites)
	end
	for i,s in pairs(self.sprites) do
		s:post_physics()
	end
end
