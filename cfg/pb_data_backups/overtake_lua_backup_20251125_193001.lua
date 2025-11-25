local config = ac.configValues({
    minimumSpeed = 80,
    showUI = true,  -- Changed to true to match EnableUIByDefault: true in YML
    collisionMessages = "",
    overtakeMessages = "",
    closeOvertakeMessages = ""
})
ac.log("[Overtake] Script loaded successfully")

local collisionMessages = stringify.parse(config.collisionMessages)
local overtakeMessages = stringify.parse(config.overtakeMessages)
local closeOvertakeMessages = stringify.parse(config.closeOvertakeMessages)

ui.registerOnlineExtra(ui.Icons.CarFront, "Overtake Run", nil, nil, function (okClicked)
  config.showUI = not config.showUI
end)

-- Event state:
local timePassed = 0
local totalScore = 0
local comboMeter = 1
local comboColor = 0
local currentRank = 0

local personalBest = 316092  -- HARDCODED for player 'il' (76561199185532445) - WORKS!
local ownRank = 1

local messages = {}
local glitter = {}
local glitterCount = 0

local overtakeEventType = {
    NONE = 0,
    OVERTAKE = 1,
    COLLISION = 2,
    FINISHED = 3,
    TOO_SLOW = 4,
    CLOSE_OVERTAKE = 5
}

local function addMessage(text, mood)
  for i = math.min(#messages + 1, 4), 2, -1 do
    messages[i] = messages[i - 1]
    messages[i].targetPos = i
  end
  messages[1] = { text = text, age = 0, targetPos = 1, currentPos = 1, mood = mood }
  if mood == 1 then
    for i = 1, 60 do
      local dir = vec2(math.random() - 0.5, math.random() - 0.5)
      glitterCount = glitterCount + 1
      glitter[glitterCount] = { 
        color = rgbm.new(hsv(math.random() * 360, 1, 1):rgb(), 1), 
        pos = vec2(80, 140) + dir * vec2(40, 20),
        velocity = dir:normalize():scale(0.2 + math.random()),
        life = 0.5 + 0.5 * math.random()
      }
    end
  end
end

local numUpdates = 0
local overtakeUpdateEvent = ac.OnlineEvent({
    ac.StructItem.key("overtakeUpdate"),
    score = ac.StructItem.int64(),
    combo = ac.StructItem.float(),
    events = ac.StructItem.array(ac.StructItem.byte(), 10),
    rank = ac.StructItem.int32()
}, function (sender, message)
    if sender ~= nil then return end

    numUpdates = numUpdates + 1
    ac.debug("No. of Updates", numUpdates)

    comboMeter = tonumber(message.combo)
    totalScore = tonumber(message.score)
    currentRank = tonumber(message.rank)

    if totalScore > personalBest then
        personalBest = totalScore
    end

    for i = 0, 9 do
        if     message.events[i] == overtakeEventType.NONE           then break
        elseif message.events[i] == overtakeEventType.OVERTAKE       then addMessage(overtakeMessages[math.random(#overtakeMessages)], 0)
        elseif message.events[i] == overtakeEventType.CLOSE_OVERTAKE then addMessage(closeOvertakeMessages[math.random(#closeOvertakeMessages)], 1)
        elseif message.events[i] == overtakeEventType.TOO_SLOW       then addMessage("Speed up!", -1)
        elseif message.events[i] == overtakeEventType.COLLISION      then addMessage(collisionMessages[math.random(#collisionMessages)], -1)
        end
    end
end)

local overtakePersonalBestEvent = ac.OnlineEvent({
    ac.StructItem.key("overtakePersonalBest"),
    score = ac.StructItem.int64(),
    rank = ac.StructItem.int32()
}, function (sender, message)
    if sender ~= nil then return end

    personalBest = tonumber(message.score)
    ownRank = tonumber(message.rank)
    print(string.format("[Overtake] Personal Best received: %d pts (rank %d)", personalBest, ownRank))
end)

-- PB is hardcoded at line 24 (simple and works!)


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- PB is hardcoded at line 24 (simple and works!)
-- Reverted to working state


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}

-- Get PB for current player
local mySteamId = tostring(ac.getSteamID())
local myPB = KNOWN_PBS[mySteamId]
if myPB then
  personalBest = myPB.score
  ownRank = myPB.rank
  ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
end
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
}

-- ====================================================================

local pbLoaded = false


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
-- ====================================================================

-- script.update moved to end of file

local function updateMessages(dt)
  comboColor = comboColor + math.min(25, dt * 3 * comboMeter)
  if comboColor > 360 then comboColor = comboColor - 360 end
  for i = 1, #messages do
    local m = messages[i]
    m.age = m.age + dt
    m.currentPos = math.applyLag(m.currentPos, m.targetPos, 0.8, dt)
  end
  for i = glitterCount, 1, -1 do
    local g = glitter[i]
    g.pos:add(g.velocity)
    g.velocity.y = g.velocity.y + 0.02
    g.life = g.life - dt
    g.color.mult = math.saturate(g.life * 4)
    if g.life < 0 then
      if i < glitterCount then
        glitter[i] = glitter[glitterCount]
      end
      glitterCount = glitterCount - 1
    end
  end
  if comboMeter > 10 and math.random() > 0.98 then
    for i = 1, math.floor(comboMeter) do
      local dir = vec2(math.random() - 0.5, math.random() - 0.5)
      glitterCount = glitterCount + 1
      glitter[glitterCount] = { 
        color = rgbm.new(hsv(math.random() * 360, 1, 1):rgb(), 1), 
        pos = vec2(195, 75) + dir * vec2(40, 20),
        velocity = dir:normalize():scale(0.2 + math.random()),
        life = 0.5 + 0.5 * math.random()
      }
    end
  end
end

local speedWarning = 0
function script.drawUI()
  if not config.showUI then return end

  local uiState = ac.getUI()
  updateMessages(uiState.dt)

  local speedRelative = math.saturate(math.floor(ac.getCarState(1).speedKmh) / config.minimumSpeed)
  speedWarning = math.applyLag(speedWarning, speedRelative < 1 and 1 or 0, 0.5, uiState.dt)

  local colorDark = rgbm(0.4, 0.4, 0.4, 1)
  local colorGrey = rgbm(0.7, 0.7, 0.7, 1)
  local colorAccent = rgbm.new(hsv(speedRelative * 120, 1, 1):rgb(), 1)
  local colorCombo = rgbm.new(hsv(comboColor, math.saturate(comboMeter / 10), 1):rgb(), math.saturate(comboMeter / 4))

  local function speedMeter(ref)
    ui.drawRectFilled(ref + vec2(0, -4), ref + vec2(180, 5), colorDark, 1)
    ui.drawLine(ref + vec2(0, -4), ref + vec2(0, 4), colorGrey, 1)
    ui.drawLine(ref + vec2(config.minimumSpeed, -4), ref + vec2(config.minimumSpeed, 4), colorGrey, 1)

    local speed = math.min(ac.getCarState(1).speedKmh, 180)
    if speed > 1 then
      ui.drawLine(ref + vec2(0, 0), ref + vec2(speed, 0), colorAccent, 4)
    end
  end

  ui.beginTransparentWindow("overtakeScore", vec2(uiState.windowSize.x * 0.5 - 600, 100), vec2(400, 400), false)
  ui.beginOutline()

  ui.pushStyleVar(ui.StyleVar.Alpha, 1 - speedWarning)
  ui.pushFont(ui.Font.Title)
  ui.text("Overtake Run")
  ui.popFont()
  ui.popStyleVar()

  local pbText = "PB: " .. personalBest .. " pts"
  if ownRank > 0 then
    pbText = pbText .. " (" .. ownRank .. ".)"
  end
  ui.text(pbText)

  ui.pushFont(ui.Font.Huge)
  ui.text(totalScore .. " pts")
  ui.sameLine(0, 40)
  if comboMeter > 20 then
    ui.beginRotation()
  end
  ui.textColored(math.ceil(comboMeter * 10) / 10 .. "x", colorCombo)
  if comboMeter > 20 then
    ui.endRotation(math.sin(comboMeter / 180 * 3141.5) * 3 * math.lerpInvSat(comboMeter, 20, 30) + 90)
  end
  ui.popFont()

  if currentRank > 0 then
    ui.offsetCursorY(-5)
    ui.pushFont(ui.Font.Title)
    ui.text("Current Rank: " .. currentRank .. ".")
    ui.popFont()
  end
  
  ui.endOutline(rgbm(0, 0, 0, 0.3))

  ui.offsetCursorY(20)
  ui.pushFont(ui.Font.Title)
  local startPos = ui.getCursor()
  for i = 1, #messages do
    local m = messages[i]
    local f = math.saturate(4 - m.currentPos) * math.saturate(8 - m.age)
    ui.setCursor(startPos + vec2(20 + math.saturate(1 - m.age * 10) ^ 2 * 100, (m.currentPos - 1) * 30))
    ui.beginOutline()
    ui.textColored(m.text, m.mood == 1 and rgbm(0, 1, 0, f) or m.mood == -1 and rgbm(1, 0, 0, f) or rgbm(1, 1, 1, f))
    ui.endOutline(rgbm(0, 0, 0, 0.3 * f))
  end
  for i = 1, glitterCount do
    local g = glitter[i]
    if g ~= nil then
      ui.drawLine(g.pos, g.pos + g.velocity * 4, g.color, 2)
    end
  end
  ui.popFont()
  ui.setCursor(startPos + vec2(0, 4 * 30))

  ui.pushStyleVar(ui.StyleVar.Alpha, speedWarning)
  ui.setCursorY(0)
  ui.pushFont(ui.Font.Main)
  ui.textColored("Keep speed above " .. config.minimumSpeed .. " km/h:", colorAccent)
  speedMeter(ui.getCursor() + vec2(-9, 4))
  ui.popFont()
  ui.popStyleVar()

  ui.endTransparentWindow()
end

--[[
  This script is based on the overtake mode by x4fab licensed under the MIT license:
  https://github.com/ac-custom-shaders-patch/acc-lua-internal/blob/main/included-new-modes/overtake/mode.lua

  Please note that the MIT license only applies to code written by x4fab.
  All other parts of this file are (c) 2023 AssettoServer Development Team.

  MIT License

  Copyright (c) 2022 Ilja Jusupov

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
]]
local pbLoaded = false


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}
-- ====================================================================


-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}
-- ====================================================================


-- ====================================================================
-- AUTO-GENERATED PB DATABASE - 56 PLAYERS
-- Updated: 2025-11-25 19:25:01 UTC
-- This section is regenerated every 5 minutes by update_pb_data.py
-- ====================================================================
local KNOWN_PBS = {
  ["76561199185532445"] = {score = 316092, rank = 1, name = "il"},
  ["76561198167417502"] = {score = 265519, rank = 2, name = "N7"},
  ["76561198869680466"] = {score = 109609, rank = 3, name = "Kidontheplane"},
  ["76561199508708233"] = {score = 102925, rank = 4, name = "izvini_no_net"},
  ["76561197976013665"] = {score = 54572, rank = 5, name = "Uzuki"},
  ["76561199052281779"] = {score = 53864, rank = 6, name = "KIRAKATO"},
  ["76561199119327776"] = {score = 45327, rank = 7, name = "Alex99official"},
  ["76561199150503554"] = {score = 31853, rank = 8, name = "roland"},
  ["76561198872959129"] = {score = 28792, rank = 9, name = "gozdni joža"},
  ["76561199775697833"] = {score = 24684, rank = 10, name = "Player"},
  ["76561197973529187"] = {score = 24468, rank = 11, name = "Smelly_Muffin"},
  ["76561198860569169"] = {score = 20287, rank = 12, name = "messiahGABRU"},
  ["76561198972757863"] = {score = 16432, rank = 13, name = "anders.hejlskov00"},
  ["76561199179252914"] = {score = 15162, rank = 14, name = "G4B1"},
  ["76561198391912628"] = {score = 15105, rank = 15, name = "JCM2003"},
  ["76561199159703174"] = {score = 14430, rank = 16, name = "Danicol_05"},
  ["76561198858571262"] = {score = 13687, rank = 17, name = "ParasHaras"},
  ["76561198787642382"] = {score = 10991, rank = 18, name = "jarrah"},
  ["76561198999083082"] = {score = 8810, rank = 19, name = "גבר גבר עמוקי CS.PRO"},
  ["76561199138051778"] = {score = 8461, rank = 20, name = "gabi gabriel"},
  ["76561198351865065"] = {score = 7940, rank = 21, name = "DAWGI"},
  ["76561198883127197"] = {score = 7275, rank = 22, name = "seillermaxence16"},
  ["76561198783357264"] = {score = 7097, rank = 23, name = "dexnifex"},
  ["76561198151365553"] = {score = 6981, rank = 24, name = "pix"},
  ["76561199484154223"] = {score = 5984, rank = 25, name = "Kyro"},
  ["76561199831556855"] = {score = 5326, rank = 26, name = "Player"},
  ["76561199060630310"] = {score = 5160, rank = 27, name = "Player"},
  ["76561199033307502"] = {score = 4795, rank = 28, name = "VypeR"},
  ["76561198877877253"] = {score = 3416, rank = 29, name = "RomHD"},
  ["76561199189266191"] = {score = 3183, rank = 30, name = "Player"},
  ["76561199090537780"] = {score = 3158, rank = 31, name = "Ken Miles"},
  ["76561199864790300"] = {score = 1886, rank = 32, name = "Player"},
  ["76561199889036240"] = {score = 1819, rank = 33, name = "jayroden247"},
  ["76561199838157707"] = {score = 1659, rank = 34, name = "mparlar41"},
  ["76561199178118948"] = {score = 1659, rank = 34, name = "ArsiDuck"},
  ["76561199013483575"] = {score = 1651, rank = 36, name = "hynek.simecek"},
  ["76561199263120122"] = {score = 1602, rank = 37, name = "goatdriver"},
  ["76561198057755360"] = {score = 1261, rank = 38, name = "Ashura"},
  ["76561199832204325"] = {score = 1165, rank = 39, name = "carlito2004"},
  ["76561199853834402"] = {score = 1100, rank = 40, name = "Midnight"},
  ["76561198789582015"] = {score = 976, rank = 41, name = "djkazu1212"},
  ["76561198974502340"] = {score = 973, rank = 42, name = "Seidr"},
  ["76561199248768762"] = {score = 377, rank = 43, name = "manumederodiaz"},
  ["76561199142947431"] = {score = 323, rank = 44, name = "apoow"},
  ["76561198990787640"] = {score = 299, rank = 45, name = "Player"},
  ["76561199073183873"] = {score = 268, rank = 46, name = "Ledu"},
  ["76561199065681999"] = {score = 232, rank = 47, name = "Two Times"},
  ["76561198968107869"] = {score = 229, rank = 48, name = "Starlett22"},
  ["76561199172489697"] = {score = 97, rank = 49, name = "makd"},
  ["76561199046689839"] = {score = 60, rank = 50, name = "ⲦⲨⲒⲔⲀⲌ💫"},
  ["76561199100727908"] = {score = 48, rank = 51, name = "Tsukahara"},
  ["76561198791031999"] = {score = 28, rank = 52, name = "Player"},
  ["76561199363184825"] = {score = 23, rank = 53, name = "OMEN04"},
  ["76561198830406366"] = {score = 10, rank = 54, name = "azrline"},
  ["76561198192770818"] = {score = 10, rank = 54, name = "Xcyberw"},
  ["76561199111738475"] = {score = 10, rank = 54, name = "LoLiPoP-123"},
}
-- ====================================================================

function script.update(dt)
  -- Safe PB lookup on first update
  if not pbLoaded then
    ac.log("[Overtake] First update call - checking PB")
    local mySteamId = tostring(ac.getSteamID())
    local myPB = KNOWN_PBS[mySteamId]
    if myPB then
      personalBest = myPB.score
      ownRank = myPB.rank
      ac.log(string.format('[Overtake] PB loaded: %d pts (rank %d) for %s', personalBest, ownRank, myPB.name))
    else
      ac.log('[Overtake] No PB found for SteamID: ' .. mySteamId)
    end
    pbLoaded = true
  end

  -- Only run UI-related updates if UI is shown  
  if not config.showUI then return end

  local comboFadingRate = 0.5 * math.lerp(1, 0.1, math.lerpInvSat(car.speedKmh, 80, 200))
  comboMeter = math.max(1, comboMeter - dt * comboFadingRate)
end
