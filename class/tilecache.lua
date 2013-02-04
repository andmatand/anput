-- A TileCache holds cached information about the contents of tiles in a room
TileCache = class('TileCache')

local contains_class_function =
    function (self, class)
        for _, obj in pairs(self.contents) do
            if instanceOf(class, obj) then
                return true
            end
        end
        return false
    end

function TileCache:init()
    self.tiles = {}
end

function TileCache:add(position, object, extraTileProperties)
    local tile = self:get_tile(position)

    if object then
        if self.room and not object.is_collidable then
            object.is_collidable = function() return false end
        end
        table.insert(tile.contents, object)
    end

    if extraTileProperties then
        for k, v in pairs(extraTileProperties) do
            tile[k] = v
        end
    end

    tile.isPartOfRoom = true
end

function TileCache:get_tile(position)
    local index = ((ROOM_W + 2) * (position.y + 1)) + (position.x + 1) + 1

    -- If no tile exists at this index
    if not self.tiles[index] then
        -- Add a new empty tile
        local newTile = {contents = {}, isPartOfRoom = false}

        if self.room then
            newTile.contains_class = contains_class_function
        end

        self.tiles[index] = newTile
    end

    return self.tiles[index], index
end

function TileCache:remove(position, object)
    local tile = self:get_tile(position)

    for i, obj in pairs(tile.contents) do
        if obj == object then
            table.remove(tile.contents, i)
            return true
        end
    end

    return false
end

function TileCache:clear(position)
    local _, index = self:get_tile(position)

    self.tiles[index] = nil
end
