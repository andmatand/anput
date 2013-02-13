Tile = class('Tile')

function Tile:init()
    self.position = {}
end

function Tile:get_position()
    return {x = self.position.x, y = self.position.y}
end

function Tile:set_position(pos)
    self.position.x = pos.x
    self.position.y = pos.y
end
