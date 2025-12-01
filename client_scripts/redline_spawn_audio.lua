-- ============================================================
-- RedLine Souls - Spawn Audio Player
-- ============================================================
-- Plays the server theme when you join RedLine Souls!
--
-- Installation:
--   Place this file in: Documents\Assetto Corsa\cfg\lua\online\
--
-- Or run the auto-installer:
--   irm https://red-line.live/install-audio | iex
--
-- Server: RedLine Souls | Shuto Cruise | Dynamic AI Traffic
-- Discord: https://discord.gg/YJJEGAhf
-- ============================================================

-- Configuration
local AUDIO_URL = "https://red-line.live/audio/RedLineSoulsIntro.ogg"
local SPAWN_DELAY = 2.0   -- Seconds to wait after spawn before playing
local AUDIO_VOLUME = 0.8  -- Volume (0.0 to 1.0)

-- State tracking
local hasPlayed = false
local spawnTimer = -1
local audioPlayer = nil
local isRedLineServer = false

-- Check if we're on a RedLine Souls server
local function checkServer()
    local sim = ac.getSim()
    if sim and sim.serverName then
        -- Check if server name contains "RedLine" (case insensitive)
        isRedLineServer = string.lower(sim.serverName):find("redline") ~= nil
        if isRedLineServer then
            ac.log("[RedLine Audio] Connected to RedLine Souls server!")
        end
    end
end

-- Chat message handler for spawn trigger
function script.chatMessage(message, senderCarIndex, senderSessionId)
    -- Check if this is our spawn audio trigger message
    -- Format: __SPAWN_AUDIO__|steamId|playerName (sent by server)
    if type(message) == "string" and message:find("__SPAWN_AUDIO__") then
        if not hasPlayed then
            ac.log("[RedLine Audio] Spawn audio trigger received!")
            spawnTimer = 0  -- Start countdown
        end
        
        -- Hide this message from chat (return true to consume)
        return true
    end
    
    return false  -- Show other messages normally
end

-- Play the spawn audio
local function playSpawnAudio()
    if hasPlayed then return end
    
    ac.log("[RedLine Audio] Playing spawn audio...")
    
    local played = false
    
    -- Method 1: Try ui.MediaPlayer (most reliable in recent CSP)
    if ui and ui.MediaPlayer then
        local success = pcall(function()
            local player = ui.MediaPlayer(AUDIO_URL)
            if player then
                player:setVolume(AUDIO_VOLUME)
                player:setAutoPlay(true)
                played = true
                ac.log("[RedLine Audio] Playing via ui.MediaPlayer")
            end
        end)
        if success and played then
            hasPlayed = true
            return
        end
    end
    
    -- Method 2: Try ac.AudioEvent
    if not played and ac.AudioEvent then
        pcall(function()
            local audio = ac.AudioEvent({
                source = AUDIO_URL,
                volume = AUDIO_VOLUME,
                use3D = false
            })
            if audio and audio.trigger then
                audio:trigger()
                played = true
                ac.log("[RedLine Audio] Playing via ac.AudioEvent")
            end
        end)
    end
    
    -- Method 3: Try web.loadRemoteAssets + ac.AudioEvent (for older CSP)
    if not played and web and web.loadRemoteAssets then
        pcall(function()
            web.loadRemoteAssets(AUDIO_URL, function(err, data)
                if not err and data then
                    ac.AudioEvent({
                        source = data,
                        volume = AUDIO_VOLUME,
                        use3D = false
                    }):trigger()
                    ac.log("[RedLine Audio] Playing via web.loadRemoteAssets")
                end
            end)
            played = true  -- Async, assume it will work
        end)
    end
    
    if played then
        hasPlayed = true
        ac.log("[RedLine Audio] Spawn audio playback initiated!")
    else
        ac.log("[RedLine Audio] Could not play audio - CSP version may not support required APIs")
        hasPlayed = true  -- Prevent retry spam
    end
end

-- Main update loop
function script.update(dt)
    -- Check server on first update
    if not isRedLineServer and not hasPlayed then
        checkServer()
    end
    
    -- Handle spawn delay countdown
    if spawnTimer >= 0 and not hasPlayed then
        spawnTimer = spawnTimer + dt
        
        -- Play audio when delay reaches threshold
        if spawnTimer >= SPAWN_DELAY then
            playSpawnAudio()
        end
    end
    
    -- Auto-trigger fallback: If on RedLine server and no trigger received after 10 seconds
    -- This handles cases where the server message was missed
    if isRedLineServer and not hasPlayed and spawnTimer < 0 then
        -- Start a fallback timer
        spawnTimer = -10  -- Will count up to -10 + SPAWN_DELAY
    end
    
    if spawnTimer < 0 and spawnTimer > -100 then
        spawnTimer = spawnTimer + dt
        if spawnTimer >= 0 and not hasPlayed then
            ac.log("[RedLine Audio] Fallback trigger - playing audio")
            playSpawnAudio()
        end
    end
end

-- Cleanup on unload
function script.dispose()
    if audioPlayer then
        pcall(function()
            if audioPlayer.stop then audioPlayer:stop() end
            if audioPlayer.dispose then audioPlayer:dispose() end
        end)
    end
end

-- Log initialization
ac.log("============================================================")
ac.log("[RedLine Audio] RedLine Souls Spawn Audio Script Loaded")
ac.log("[RedLine Audio] Version: 1.0.0")
ac.log("[RedLine Audio] Audio URL: " .. AUDIO_URL)
ac.log("[RedLine Audio] Discord: https://discord.gg/YJJEGAhf")
ac.log("============================================================")
