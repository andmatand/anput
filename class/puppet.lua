require('class.animation')
require('class.tile')

-- A Puppet is an actor for the Outside scenes
Puppet = class('Puppet', Tile)

DANCE_DELAY = 7

function Puppet:init(args)
    Puppet.super.init(self)

    self.image = args.image
    self.danceAnimation = args.danceAnimation
    self.walkAnimation = args.walkAnimation
    self.color = args.color
    if args.position then
        self:set_position(args.position)
    end

    self.enabled = true
    self.state = 'stand'
    self.dir = 2
    self.walkState = {dir = 1, distance = 0, timer = nil}
end

function Puppet:draw(customPosition)
    if not self.enabled then return end

    local drawable = self:get_drawable()

    if drawable then
        local x, y
        local sx, sy = SCALE_X, SCALE_Y

        if customPosition then
            x, y = customPosition.x, customPosition.y
        else
            x, y = upscale_x(self.position.x), upscale_y(self.position.y)
        end

        if self.dir == 2 then
            self.mirrored = false
        elseif self.dir == 4 then
            self.mirrored = true
        end

        if self.mirrored then 
            x = x + (drawable:getWidth() * SCALE_X)
            sx = -sx
        end

        love.graphics.setColor(self.color or WHITE)
        love.graphics.draw(drawable, x, y, 0, sx, sy)
    end
end

function Puppet:get_drawable()
    if self.state == 'walk' then
        -- If we have a walk animation
        if self.walkAnimation then
            return self.walkAnimation:get_drawable()
        end
    elseif self.state == 'dance' then
        -- If we have a dance animation
        if self.danceAnimation then
            return self.danceAnimation:get_drawable()
        end
    end

    return self.image
end

function Puppet:dance()
    self.state = 'dance'
end

function Puppet:turn_around()
    if self.dir == 4 then
        self.dir = 2
    else
        self.dir = 4
    end
end

function Puppet:update()
    if not self.enabled then return end

    if self.state == 'walk' then
        -- If we need to walk farther
        if self.walkState.distance > 0 then
            -- If we have a walk animation
            if self.walkAnimation then
                -- Update our walk animation
                self.walkAnimation:update()
            end

            if self.walkState.timer:update() then
                self.walkState.timer:reset()

                -- Face the direction in which we are walking
                self.dir = self.walkState.dir

                -- Move the direction in which we are walking
                self.position = add_direction(self.position, self.walkState.dir)

                -- Decrement the remaining distance we need to walk
                self.walkState.distance = self.walkState.distance - 1
            end
        else
            self.state = 'stand'
        end
    elseif self.state == 'dance' then
        -- If we have a dance animation
        if self.danceAnimation then
            -- Update our dance animation
            self.danceAnimation:update()
        end
    end
end

function Puppet:walk(dir, distance, delay)
    distance = distance or 1
    delay = delay or 0

    self.walkState = {dir = dir, distance = distance}
    self.walkState.timer = Timer(delay)
    self.state = 'walk'
end
