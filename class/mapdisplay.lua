-- A MapDisplay draws a visual representation of the map
MapDisplay = class('MapDisplay')

function MapDisplay:init(nodes)
	self.nodes = nodes

	-- Place the display on the side of the screen
	self.nodeSize = 8
	self.x1 = (ROOM_W * TILE_W) + self.nodeSize
	self.y1 = (TILE_H * 12) + self.nodeSize
	self.x2 = (SCREEN_W * TILE_W) - 1 - self.nodeSize
	self.y2 = (SCREEN_H * TILE_H) - 1 - self.nodeSize
end

function MapDisplay:draw(currentRoom)
	if self.mapOffset == nil then
		self:find_map_offset()
	end

	love.graphics.push()
	love.graphics.translate(self.x1 + self.mapOffset.x,
	                        self.y1 + self.mapOffset.y)

	for _, n in pairs(self.nodes) do
		if n.room.visited then
			if n.room == currentRoom then
				love.graphics.setColor(255, 0, 255)
			elseif n.finalRoom then
				love.graphics.setColor(0, 255, 128)
			else
				love.graphics.setColor(255, 255, 255)
			end

			love.graphics.rectangle('fill',
			                        n.x * self.nodeSize, n.y * self.nodeSize,
			                        self.nodeSize, self.nodeSize)
		end
	end

	-- Undo the graphics translation
	love.graphics.pop()
end

-- Find offset necessary to center the map onscreen
function MapDisplay:find_map_offset()
	-- Find the furthest outside positions in the cardinal directions
	n = 0
	e = 0
	s = 0
	w = 0

	for _,j in pairs(self.nodes) do
		if j.y < n then
			n = j.y
		end
		if j.x > e then
			e = j.x
		end
		if j.y > s then
			s = j.y
		end
		if j.x < w then
			w = j.x
		end
	end

	width = ((e - w) + 1) * self.nodeSize
	height = ((s - n) + 1) * self.nodeSize

	displayW = self.x2 - self.x1 + 1
	displayH = self.y2 - self.y1 + 1

	self.mapOffset = {x = (displayW / 2) - (width / 2) - (w * self.nodeSize),
	                  y = (displayH / 2) - (height / 2) - (n * self.nodeSize)}
end
