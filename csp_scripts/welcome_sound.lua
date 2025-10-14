-- Welcome sound script for RedLine Souls
-- Plays intro sound 5 seconds after spawning in pits

local played = false
local spawnTime = 0
local inPits = false

function script.update(dt)
    -- Check if player is in pits
    local currentInPits = ac.isInPits()
    
    -- Detect spawn/join (first time in pits)
    if currentInPits and not inPits then
        spawnTime = os.clock()
    end
    
    inPits = currentInPits
    
    -- Play sound 5 seconds after spawn, only once per session
    if not played and inPits and spawnTime > 0 then
        local timeSinceSpawn = os.clock() - spawnTime
        
        if timeSinceSpawn >= 5 then
            -- Play the welcome sound
            ac.loadSoundEvent('content/sfx/RedLine Souls Intro.m4a'):play()
            played = true
            ac.log('RedLine Souls welcome sound played!')
        end
    end
end
