-- RedLine Souls Welcome Sound
-- This should be loaded automatically by the server

local played = false
local timer = 0

function script.update(dt)
    if played then return end
    
    timer = timer + dt
    
    -- Play after 3 seconds
    if timer >= 3 then
        -- Try the audio file
        ui.playSound('content/sfx/RedLineSoulsIntro.ogg', 1.0)
        played = true
    end
end
