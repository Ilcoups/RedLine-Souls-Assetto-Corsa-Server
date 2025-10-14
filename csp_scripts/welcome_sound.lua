-- Welcome sound for RedLine Souls
local played = false
local timer = 0

function script.update(dt)
    if played then return end
    
    timer = timer + dt
    
    -- Play after 5 seconds
    if timer >= 5 then
        ui.playSound('/content/sfx/RedLine Souls Intro.m4a')
        played = true
    end
end
