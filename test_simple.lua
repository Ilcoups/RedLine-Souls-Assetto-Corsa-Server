-- SUPER SIMPLE TEST
-- Just play audio after 3 seconds, no checks

local played = false
local time = 0

function script.update(dt)
    if played then return end
    time = time + dt
    
    if time > 3 then
        ui.playSound("content/sfx/RedLineSoulsIntro.ogg", 1.0)
        played = true
    end
end

