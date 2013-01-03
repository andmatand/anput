require('class.sprite')

Projectile = class('Projectile', Sprite) 

function Projectile:init(owner, dir)
    Sprite.init(self)

    self.owner = owner -- Who shot this projectile
    self.dir = dir -- Direction the projectile is facing

    if self.dir == 1 then
        self.velocity.y = -1
    elseif self.dir == 2 then
        self.velocity.x = 1
    elseif self.dir == 3 then
        self.velocity.y = 1
    elseif self.dir == 4 then
        self.velocity.x = -1
    end

    self.friction = 0 -- Projectiles keep going until they hit something
    self.new = true -- Projectile was created this frame and will not be drawn

    self.frame = 1
    self.animateTimer = 0
end

function Projectile:draw(manualPosition)
    if not self.images or not self.position.x or not self.position.y then
        return
    end
    local position = manualPosition or {x = upscale_x(self.position.x),
                                        y = upscale_y(self.position.y)}

    if self.new then
        return
    end

    -- Determine the rotation/flipping
    r = 0
    sx = SCALE_X
    sy = SCALE_Y
    if self.dir == 2 then
        r = math.rad(90)
    elseif self.dir == 3 then
        sy = -SCALE_Y
    elseif self.dir == 4 then
        r = math.rad(90)
        sy = -SCALE_Y
    end

    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(
        self.images[self.frame],
        position.x + (self.images[self.frame]:getWidth() * SCALE_X) / 2,
        position.y + (self.images[self.frame]:getHeight() * SCALE_Y) / 2,
        r, sx, sy,
        self.images[self.frame]:getWidth() / 2,
        self.images[self.frame]:getWidth() / 2)
end

function Projectile:physics()
    if self.new and self.owner then
        self.new = false
        -- Set position to current position of owner
        self.position = {x = self.owner.position.x, y = self.owner.position.y}
    end

    -- Do normal sprite physics
    Sprite.physics(self)
end

function Projectile:update()
    self.animateTimer = self.animateTimer + 1
    if self.animateTimer == 2 then
        self.animateTimer = 0

        self.frame = self.frame + 1
        if self.frame > #self.images  then
            self.frame = 1
        end
    end
end
