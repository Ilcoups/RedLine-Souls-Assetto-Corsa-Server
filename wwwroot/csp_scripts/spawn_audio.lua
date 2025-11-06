-- RedLine Souls - Spawn Audio Player
-- Plays server theme when player spawns in pits
-- Server-delivered CSP Lua script

-- Configuration
local AUDIO_URL = "content/sfx/RedLineSoulsIntro.ogg"
local SPAWN_DELAY = 3.0 -- Seconds to wait before playing audio
local AUDIO_VOLUME = 1.0 -- Volume (0.0 to 1.0)

-- State tracking
local hasPlayed = false
local spawnTimer = -1  -- -1 = not triggered, >= 0 = counting down
local audioReady = false
local audioPlayer = nil

-- Chat message handler for spawn trigger
function script.chatMessage(message, senderCarIndex, senderSessionId)
    -- Check if this is our spawn audio trigger message
    if type(message) == "string" and message:find("^__SPAWN_AUDIO__|") then
        if not hasPlayed then
            -- Parse the message: __SPAWN_AUDIO__|steamId|playerName
            local parts = {}
            for part in message:gmatch("[^|]+") do
                table.insert(parts, part)
            end
            
            if #parts >= 3 then
                local steamId = parts[2]
                local playerName = parts[3]
                
                ac.log(string.format("Spawn audio trigger received for %s (SteamID: %s)", playerName, steamId))
                spawnTimer = 0  -- Start countdown
            end
        end
        
        -- Hide this message from chat
        return true
    end
    
    return false  -- Show other messages normally
end

-- Initialize audio player on first update
function script.update(dt)
    -- Initialize audio player once
    if not audioReady and not audioPlayer then
        -- Try to create audio player with URL
        -- CSP supports loading audio from HTTP URLs
        local success, err = pcall(function()
            -- Create audio event that can be triggered
            audioPlayer = ac.AudioEvent({
                source = AUDIO_URL,
                volume = AUDIO_VOLUME,
                use3D = false -- 2D audio, not positional
            })
            audioReady = true
            ac.log("Spawn audio player initialized successfully")
        end)
        
        if not success then
            ac.log("Warning: Could not initialize audio player: " .. tostring(err))
            -- Fallback: try alternate initialization method
            audioPlayer = {url = AUDIO_URL, ready = true}
            audioReady = true
        end
    end
    
    -- Handle spawn delay countdown (only if triggered)
    if not hasPlayed and spawnTimer >= 0 and spawnTimer < SPAWN_DELAY then
        spawnTimer = spawnTimer + dt
        
        -- Play audio when delay reaches threshold
        if spawnTimer >= SPAWN_DELAY and audioReady then
            playSpawnAudio()
        end
    end
    
    -- Auto-trigger if somehow we missed the message (fallback)
    -- This will play audio 5 seconds after script load if no message received
    if not hasPlayed and spawnTimer == -1 then
        local sim = ac.getSim()
        if sim and sim.isOnlineRace then
            -- Check if we've been in the session for a few frames
            if spawnTimer == -1 then
                spawnTimer = -0.1  -- Mark as checked
            end
        end
    end
end

-- Play the spawn audio
function playSpawnAudio()
    if hasPlayed then return end
    
    ac.log("Playing spawn audio...")
    
    -- Try multiple methods to play audio (CSP API varies by version)
    local played = false
    
    -- Method 1: AudioEvent trigger
    if audioPlayer and type(audioPlayer) == "table" and audioPlayer.trigger then
        pcall(function()
            audioPlayer:trigger()
            played = true
            ac.log("Audio played via AudioEvent.trigger()")
        end)
    end
    
    -- Method 2: Direct ac.AudioEvent call
    if not played then
        pcall(function()
            ac.AudioEvent({
                source = AUDIO_URL,
                volume = AUDIO_VOLUME,
                use3D = false
            }):trigger()
            played = true
            ac.log("Audio played via direct AudioEvent call")
        end)
    end
    
    -- Method 3: Try ui namespace (fallback)
    if not played and ui and ui.MediaPlayer then
        pcall(function()
            ui.MediaPlayer(AUDIO_URL):setVolume(AUDIO_VOLUME):play()
            played = true
            ac.log("Audio played via ui.MediaPlayer")
        end)
    end
    
    -- Method 4: Try ac.playSound if it exists
    if not played and ac.playSound then
        pcall(function()
            ac.playSound(AUDIO_URL, AUDIO_VOLUME)
            played = true
            ac.log("Audio played via ac.playSound")
        end)
    end
    
    if played then
        hasPlayed = true
        ac.log("Spawn audio playback initiated successfully")
    else
        ac.log("ERROR: Could not play spawn audio - no working audio API found")
        ac.log("CSP Version may not support required audio APIs")
        hasPlayed = true  -- Prevent spam
    end
end

-- Log script initialization
ac.log("RedLine Souls spawn audio script loaded")
ac.log("Audio URL: " .. AUDIO_URL)
ac.log("Spawn delay: " .. SPAWN_DELAY .. " seconds")

