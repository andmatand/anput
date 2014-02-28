function get_direction_input(key)
    if key == KEYS.WALK.NORTH or key == KEYS.SHOOT.NORTH then
        return 1
    elseif key == KEYS.WALK.EAST or key == KEYS.SHOOT.EAST then
        return 2
    elseif key == KEYS.WALK.SOUTH or key == KEYS.SHOOT.SOUTH then
        return 3
    elseif key == KEYS.WALK.WEST or key == KEYS.SHOOT.WEST then
        return 4
    end
end
