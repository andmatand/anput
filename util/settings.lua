local function set_all_sound_volumes_in_table(sounds, volume)
    for _, sound in pairs(sounds) do
        if instanceOf(Sound, sound) then
            sound.source:setVolume(volume)
        elseif type(sound) == 'table' then
            set_all_sound_volumes_in_table(sound, volume)
        end
    end
end

function apply_sound_setting()
    local volume

    if settings.sound then
        -- Set the volume pretty low to prevent hearing ugly artifacts of
        -- DOSBox's fake PC speaker sounds
        volume = .2
    else
        volume = 0
    end

    -- If the global table of sounds is loaded
    if sounds then
        -- Ensure all playing sounds are set to the master volume
        set_all_sound_volumes_in_table(sounds, volume)
    end
end

function load_default_keys()
    KEYS = {CONTEXT = 1,
            ELIXIR = 2,
            EXIT = 3,
            INVENTORY = 5,
            PAUSE = 6,
            POTION = 7,
            SKIP_CUTSCENE = 8,
            SKIP_DIALOGUE = 9,
            SWITCH_WEAPON = 11,
            SHOOT = {NORTH = 12,
                     EAST = 13,
                     SOUTH = 14,
                     WEST = 15},
            WALK = {NORTH = 16,
                    EAST = 17,
                    SOUTH = 18,
                    WEST = 19},
            WEAPON_SLOT_1 = 20,
            WEAPON_SLOT_2 = 21,
            WEAPON_SLOT_3 = 22,
            WEAPON_SLOT_4 = 23,
            WEAPON_SLOT_5 = 24}
end

function load_default_settings()
    settings = {fullscreen = true,
                sound = true}
end

function load_settings()
    load_default_keys()

    local ok
    ok, settings = pcall(love.filesystem.load('settings'))

    if not ok then
        print('error loading settings; using defaults')
        load_default_settings()
    end
end

function save_settings()
    local contents = 'return ' .. serialize_table(settings)

    love.filesystem.write('settings', contents)
end
