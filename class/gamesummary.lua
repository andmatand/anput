GameSummary = class('GameSummary')

function GameSummary:init(game)
    self.game = game
end

function GameSummary:draw()
    self.x = 1
    self.y = 1

    local x = self.x
    local y = self.y

    local msg = "YOU WERE KILLED BY "
    cga_print(msg, x, y)
    x = x + msg:len()
    cga_print(" ", x, y)

    local obj = self.game.player.log.wasKilledBy

    if instanceOf(Spike, obj) then
        obj:draw({x = upscale_x(x), y = upscale_y(y)}, LIGHT)
    else
        obj:draw({x = upscale_x(x), y = upscale_y(y)})
    end

    if #self.game.player.log:get_kills() > 0 then
        x = 1
        y = y + 2
        local msg = "YOU KILLED "
        cga_print(msg, x, y)

        x = x + msg:len()
        for _, k in pairs(self.game.player.log:get_kills()) do
            k.flashTimer = 0

            cga_print(" ", x, y)
            --if k.draw then
            --    k:draw({x = upscale_x(x), y = upscale_y(y)})
            --end

            local ok, errorMessage = pcall(k.draw, k, {x = upscale_x(x),
                                                       y = upscale_y(y)})
            if not ok then
                print('error drawing ', k)
                print('  monsterType: ', k.monsterType)
                print('  currentImage: ', k.currentImage)
                print('  error message:' .. errorMessage)
            end

            x = x + 1
            if x == GRID_W - 1 then
                x = 1
                y = y + 1
            end
        end
    end

    self:draw_rooms_visited(y)
end

function GameSummary:draw_rooms_visited(y)
    local x = 1
    y = y + 2

    if not self.numRoomsVisited then
        self.numRoomsVisited = 0
        for _, room in pairs(self.game.rooms) do
            if room.isVisited then
                self.numRoomsVisited = self.numRoomsVisited + 1
            end
        end
    end

    local percent = round(self.numRoomsVisited / #self.game.rooms * 100, 2)
    cga_print("YOU EXPLORED " .. percent .. "% OF THE MAP", x, y)
end


function round(num, dp)
  return tonumber(string.format("%." .. (dp or 0) .. "f", num))
end
