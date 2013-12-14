GameSummary = class('GameSummary')

function GameSummary:init(game)
    self.game = game

    self.paragraphTimer = Timer(8)
    self.numParagraphs = 0
end

function GameSummary:draw()
    self.y = 1

    if self.numParagraphs >= 1 then
        self:draw_killer()
        self.y = self.y + 2
    end

    if self.numParagraphs >= 2 then
        -- If any kills were drawn
        if self:draw_kills() then
            self.y = self.y + 2
        else
            if self.numParagraphs == 2 then
                -- Advance to the next paragraph
                self.numParagraphs = self.numParagraphs + 1
            end
        end
    end

    if self.numParagraphs >= 3 then
        -- If there are projectile stats
        if self:draw_projectile_stats() then
            self.y = self.y + 3
        else
            if self.numParagraphs == 3 then
                -- Advance to the next paragraph
                self.numParagraphs = self.numParagraphs + 1
            end
        end
    end

    if self.numParagraphs >= 4 then
        self:draw_rooms_visited()
    end

    if self.numParagraphs >= 8 then
        self.game.player.statusBar:show_context_message({'enter'}, 'NEW GAME')
    end
end

function GameSummary:draw_killer()
    local x = 1

    local msg = 'YOU WERE KILLED BY '
    cga_print(msg, x, self.y)

    -- Draw a black background for the tile on which the killer will be
    x = x + msg:len()
    cga_print(' ', x, self.y)

    local killer = self.game.player.log.wasKilledBy

    -- Draw the killer
    if instanceOf(Spike, killer) then
        killer:draw({x = upscale_x(x), y = upscale_y(self.y)}, LIGHT)
    else
        killer:draw({x = upscale_x(x), y = upscale_y(self.y)})
    end
end

function GameSummary:draw_kills()
    if #self.game.player.log:get_kills() == 0 then
        return false
    end

    local x = 1
    local msg = 'YOU KILLED '
    cga_print(msg, x, self.y)

    x = x + msg:len()
    for _, k in pairs(self.game.player.log:get_kills()) do
        k.flashTimer = 0

        -- Draw the black background this tile would have if it was a
        -- text character
        cga_print(' ', x, self.y)

        -- Draw the dead monster
        --if k.draw then
        --    k:draw({x = upscale_x(x), y = upscale_y(y)})
        --end
        local ok, errorMessage = pcall(k.draw, k, {x = upscale_x(x),
                                                   y = upscale_y(self.y)})
        if not ok then
            print('error drawing ', k)
            print('  monsterType: ', k.monsterType)
            print('  currentImage: ', k.currentImage)
            print('  error message:' .. errorMessage)
        end

        x = x + 1
        if x == GRID_W - 1 then
            x = 1
            self.y = self.y + 1
        end
    end

    return true
end

function GameSummary:draw_rooms_visited()
    if not self.numRoomsVisited then
        self.numRoomsVisited = 0
        for _, room in pairs(self.game.rooms) do
            if room.isVisited then
                self.numRoomsVisited = self.numRoomsVisited + 1
            end
        end
    end

    local percent = round((self.numRoomsVisited / #self.game.rooms) * 100, 2)
    cga_print('YOU EXPLORED ' .. percent .. '% OF THE TEMPLE', 1, self.y)
end

function GameSummary:draw_projectile_stats()
    -- If the player has no projectile shots
    if self.game.player.log.projectileStats.shots == 0 then
        return false
    end

    local percent = round((self.game.player.log.projectileStats.hits /
                           self.game.player.log.projectileStats.shots) * 100, 2)
    cga_print('YOU SHOT ' .. self.game.player.log.projectileStats.shots ..
              ' PROJECTILES\nWITH ' .. percent .. '% ACCURACY', 1, self.y)

    return true
end

function GameSummary:update()
    if self.paragraphTimer:update() then
        self.paragraphTimer:reset()
        if self.numParagraphs < 8 then
            self.numParagraphs = self.numParagraphs + 1
        end
    end
end

function round(num, dp)
  return tonumber(string.format("%." .. (dp or 0) .. "f", num))
end
