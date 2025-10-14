-- RedLine Souls Welcome Audio - DEBUG VERSION
-- Plays intro when player spawns for the first time

local played = false
local timer = 0

function update(dt)
    if played then return end
    
    timer = timer + dt
    
    -- Debug: Show chat message every second
    if math.floor(timer) ~= math.floor(timer - dt) then
        ac.debug('Timer', string.format('Waiting... %.1f seconds', timer))
    end
    
    -- Wait 5 seconds after track loads
    if timer > 5 then
        ac.debug('Audio', 'Attempting to play audio...')
        
        -- Try multiple path variations
        local sound = ac.loadSoundEvent('extension/RedLineSoulsIntro.ogg')
        if sound then
            ac.debug('Audio', 'Sound loaded successfully!')
            sound:play()
        else
            ac.debug('Audio', 'Failed to load sound!')
        end
        
        played = true
    end
end
