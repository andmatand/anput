Switch = class('Switch')

function Switch:init(door)
    self.door = door

    self.position = {}
    self.state = 1

    self.animation = Animation(images.switch)
    self.animation.loop = false
    self.animation.isStopped = true
end

function Switch:draw(alpha)
    love.graphics.setColor(WHITE[1], WHITE[2], WHITE[3], alpha)
    if not self.position.x or not self.position.y then
        return
    end
    love.graphics.draw(self.animation:get_drawable(),
                       upscale_x(self.position.x),
                       upscale_y(self.position.y),
                       0, SCALE_X, SCALE_Y)
end

function Switch:get_position()
    return self.position
end

function Switch:set_position(position)
    self.position = {x = position.x, y = position.y}
end

function Switch:update()
    self.animation:update()
end

function Switch:activate()
    self.isActivated = true
    self.animation.isStopped = false

    if self.door then
        self.door:open()
    end
end
