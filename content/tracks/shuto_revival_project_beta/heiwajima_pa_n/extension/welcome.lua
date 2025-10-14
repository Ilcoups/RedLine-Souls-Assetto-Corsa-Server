-- RedLine Souls Welcome Audio
-- Plays intro when player spawns for the first time

local played = false
local timer = 0

function update(dt)
    if played then return end
    
    timer = timer + dt
    
    -- Wait 5 seconds after track loads
    if timer > 5 then
        -- Play the audio from extension folder
        ac.loadSoundEvent('extension/RedLineSoulsIntro.ogg'):play()
        played = true
    end
end
