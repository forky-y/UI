-- ============================================================
--  Forky Server Monitor  |  Discord: @agil2
--  v2.0 — Galatama Edition
-- ============================================================

local HttpService        = game:GetService("HttpService")
local Players            = game:GetService("Players")
local TextChatService    = game:GetService("TextChatService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local CoreGui            = game:GetService("CoreGui")
local TweenService       = game:GetService("TweenService")

-- ============================================================
--  CONFIGURATION
-- ============================================================

local WEBHOOK_URL           = "https://discord.com/api/webhooks/1511291405929156678/ZUc6y6_x69taRIhzYodDG0VWeD43PJ6XGQBlxfpby_Cpmab75KPC55IKFIfbo7_zFsn6"
local WEBHOOK_STATS         = "https://discord.com/api/webhooks/1511289204481720452/xCFGbP5RxrZRbgWo7kaiGGvEuovSVtfrte1_J1qsJhxOZIq9B4CvuSCDEWogf185aXmu"
local WEBHOOK_LEADERBOARD   = "https://discord.com/api/webhooks/1511294906537213973/xEREYozKLsBqBOboIi13zNAhbNA-Yd3nkLEoGfRv4i_-fcSLuhJbJ41AcwSKHucowR5o"
local WEBHOOK_FISH          = "https://discord.com/api/webhooks/1511289254309920769/-atjZ426SzBz6XAlN-E4mrUCBpDxrsMjxW-y1pi4mpzSNb8u1wa7nDbLgNzJppV09bjj"
local WEBHOOK_CHAT          = "https://discord.com/api/webhooks/1511291170309800046/dvNnnqLqUL0XVeF240aHpIG1Vlye3lyXz3QtV8SG2gMZs8cEKSCXR5UjFcOcRBA5KtrS"
local WEBHOOK_GALATAMA      = "https://discord.com/api/webhooks/1512015161949425766/KJvYJHiRylTtrDislJB5SoRxu159RHRqtfccHqBIWI3Ea79UF523hAGvMVUqpzJMaII5"   -- isi lewat UI atau hardcode di sini
local DISCORD_ROLE_ID       = ""
local PROXY                 = "https://square-haze-a007.remediashop.workers.dev"
local WEBHOOK_NAME          = "ForkyHUB - Live Monitor"
local WEBHOOK_AVATAR        = "https://www.image2url.com/r2/default/images/1777666815405-eb5a3d95-9946-4914-b8aa-985e8f672557.png"
local SCRIPT_ACTIVE         = false

-- Galatama persist via Discord Bot
local BOT_TOKEN             = ""
local SAVE_CHANNEL_ID       = ""
local SAVE_STATE_TAG        = "FORKY_GALATAMA_SAVESTATE_V1"

local LEADERBOARD_INTERVAL   = 30    -- detik
local LIVE_MONITOR_INTERVAL  = 30    -- detik
local STATS_INTERVAL         = 1200  -- 20 menit

-- Live monitor state
local LiveMessageId          = nil
local LeaderboardMessageId   = nil
local StatsMessageId         = nil
local LastLeaderboardSnapshot = nil
local LastStatsSnapshot      = nil
local KnownUsers   = {}
local PreviousStatus = {}
local StatusHistory  = {}
local MAX_HISTORY    = 5

-- ============================================================
--  GALATAMA EVENT CONFIG
-- ============================================================

local GalatamaFishList = {
    "Blob Shark", "Skeleton Narwhal", "Ghost Shark", "Worm Fish", "Megalodon",
}

local GalatamaPoin = {
    ["Blob Shark"]       = 25,
    ["Skeleton Narwhal"] = 60,
    ["Ghost Shark"]      = 50,
    ["Worm Fish"]        = 300,
    ["Megalodon"]        = 400,
}

local GalatamaRarity = {
    ["Blob Shark"]       = "1 in 250K",
    ["Ghost Shark"]      = "1 in 500K",
    ["Skeleton Narwhal"] = "1 in 600K",
    ["Worm Fish"]        = "1 in 3M",
    ["Megalodon"]        = "1 in 4M",
}

local MutasiNoBonus         = { "big", "shiny" }
local GALATAMA_MUTASI_BONUS = 100

-- ============================================================
--  REQUEST HELPER
-- ============================================================

local function GetRequestFunc()
    if syn and type(syn.request) == "function" then return syn.request end
    if http and type(http.request) == "function" then return http.request end
    if type(http_request) == "function" then return http_request end
    if fluxus and type(fluxus.request) == "function" then return fluxus.request end
    if type(request) == "function" then return request end
    return nil
end

local function AddStatusHistory(event, username)
    local line = string.format("[%s] %-6s | %s", os.date("%H:%M:%S"), event, username)
    table.insert(StatusHistory, 1, line)
    if #StatusHistory > MAX_HISTORY then table.remove(StatusHistory) end
end

-- ============================================================
--  LIVE MONITOR (PATCH/POST)
-- ============================================================

local function UpdateLiveWebhook()
    if not SCRIPT_ACTIVE then return end

    local requestFunc = GetRequestFunc()
    if not requestFunc or type(requestFunc) ~= "function" then
        warn("[ LiveMonitor ] no HTTP request function available")
        return
    end

    local playerMap = {}
    for _, p in pairs(Players:GetPlayers()) do
        playerMap[p.Name] = p.DisplayName
        KnownUsers[p.Name] = p.DisplayName
    end

    local onlineText, offlineText = "", ""
    local onlineCount, offlineCount, totalUsers = 0, 0, 0

    for name, display in pairs(KnownUsers) do
        totalUsers = totalUsers + 1
        local isOnline  = playerMap[name] ~= nil
        local wasOnline = PreviousStatus[name]
        if isOnline and not wasOnline then AddStatusHistory("JOIN", name)
        elseif not isOnline and wasOnline then AddStatusHistory("LEAVE", name) end
        PreviousStatus[name] = isOnline

        if isOnline then
            onlineCount  = onlineCount + 1
            onlineText   = onlineText  .. string.format("<a:online:1511272522799124541> **%s** (@%s)\n", display, name)
        else
            offlineCount = offlineCount + 1
            offlineText  = offlineText .. string.format("<a:offline:1511272459830038598> **%s** — OFFLINE\n", name)
        end
    end

    local description = ""
    if onlineText  ~= "" then description = description .. "**<:online:1511272522799124541> ONLINE**\n"  .. onlineText  .. "\n" end
    if offlineText ~= "" then description = description .. "**<:offline:1511272459830038598> OFFLINE**\n" .. offlineText end

    local historyText = (#StatusHistory > 0)
        and ("```text\nTIME     EVENT  | USER\n---------------------------\n" .. table.concat(StatusHistory, "\n") .. "\n```")
        or "No activity yet"

    local color = (onlineCount == 0 and 0xE74C3C) or (offlineCount == 0 and 0x2ECC71) or 0x3498DB

    local fields = {
        { name = "📊 Server Status",  value = string.format("Online: **%d/%d**\nEmpty Slots: **%d**", onlineCount, Players.MaxPlayers, Players.MaxPlayers - onlineCount), inline = true },
        { name = "👥 User History",   value = string.format("Known Users: **%d**\nOffline (History): **%d**", totalUsers, offlineCount), inline = true },
        { name = "🧾 Activity Logs",  value = historyText, inline = false },
        { name = "🆔 Server ID",      value = "```" .. tostring(game.JobId or "Unknown") .. "```", inline = false },
    }

    if WEBHOOK_STATS == "" then return end

    local body = {
        embeds = {{ title = "LIVE Server Monitor", description = description, color = color, fields = fields,
            footer = { text = "LIVE Server Monitor | Last Update" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ") }}
    }

    local okEnc, encoded = pcall(function() return HttpService:JSONEncode(body) end)
    if not okEnc then warn("[ LiveMonitor ] JSONEncode failed:", encoded); return end

    local url    = LiveMessageId and (WEBHOOK_STATS .. "/messages/" .. LiveMessageId) or (WEBHOOK_STATS .. "?wait=true")
    local method = LiveMessageId and "PATCH" or "POST"

    local ok, res = pcall(requestFunc, { Url = url, Method = method, Headers = { ["Content-Type"] = "application/json" }, Body = encoded })

    if ok and not LiveMessageId and res and res.Body then
        local succ, decoded = pcall(function() return HttpService:JSONDecode(res.Body) end)
        if succ and decoded and decoded.id then LiveMessageId = decoded.id end
    elseif not ok then
        warn("[ LiveMonitor ] request failed:", res)
    elseif type(res) == "table" and res.StatusCode and res.StatusCode >= 400 then
        warn("[ LiveMonitor ] HTTP error:", res.StatusCode, res.Body or "")
        if res.StatusCode == 404 then LiveMessageId = nil end
    end
end

-- ============================================================
--  MEMBER LIST
-- ============================================================

local MemberList = {}

local function MergeMemberEntry(entry)
    if type(entry) ~= "table" then return end
    if not entry.username or not entry.id then return end
    table.insert(MemberList, { username = tostring(entry.username), display = tostring(entry.display or entry.username), id = tostring(entry.id) })
end

local function LoadMemberMapFromReplicatedStorage()
    local folder = ReplicatedStorage:FindFirstChild("MemberMap")
    if not folder or not folder:GetChildren() then return end
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("ModuleScript") then
            local ok, res = pcall(function() return require(child) end)
            if ok and type(res) == "table" then
                if #res > 0 then for _, e in ipairs(res) do MergeMemberEntry(e) end
                else MergeMemberEntry(res) end
            end
        elseif child:IsA("StringValue") then
            local v = child.Value
            local ok, decoded = pcall(function() return HttpService:JSONDecode(v) end)
            if ok and type(decoded) == "table" then MergeMemberEntry(decoded)
            else MergeMemberEntry({ username = child.Name, display = child.Name, id = v }) end
        end
    end
end

pcall(LoadMemberMapFromReplicatedStorage)

-- ============================================================
--  DATABASE (UPDATED)
-- ============================================================

local SecretFishList = {
    -- Common Secret
    "Crystal Crab", "Orca", "Zombie Shark", "Zombie Megalodon", "Dead Zombie Shark",
    "Blob Shark", "Ghost Shark", "Skeleton Narwhal", "Ghost Worm Fish", "Worm Fish",
    "Megalodon", "1x1x1x1 Comet Shark", "Bloodmoon Whale", "Lochness Monster",
    "Monster Shark", "Eerie Shark", "Great Whale", "Frostborn Shark", "Thin Armor Shark",
    "Scare", "Queen Crab", "King Crab", "Cryoshade Glider", "Panther Eel",
    "Giant Squid", "Depthseeker Ray", "Robot Kraken", "Mosasaur Shark", "King Jelly",
    "Bone Whale", "Elshark Gran Maja", "Elpirate Gran Maja", "Ancient Whale",
    "Gladiator Shark", "Ancient Lochness Monster", "Talon Serpent", "Hacker Shark",
    "ElRetro Gran Maja", "Strawberry Choc Megalodon", "Krampus Shark",
    "Emerald Winter Whale", "Winter Frost Shark", "Icebreaker Whale", "Leviathan",
    "Pirate Megalodon", "Viridis Lurker", "Cursed Kraken", "Ancient Magma Whale",
    "Rainbow Comet Shark", "Love Nessie", "Broken Heart Nessie",
    "Mutant Runic Koi", "Ketupat Whale", "Cosmic Mutant Shark", "Strawberry Orca",
    "Bonemaw Tyrant", "Deepsea Monster Axolotl", "Blocky Lochness Monster", "Aurelion",
    "Runic Enchant Stone", "Frogalloon", "Coral Whale", "Flame Tyrant", "Withering Core",
    -- Forgotten / Ultra Rare
    "Sea Eater", "Thunderzilla", "Iridesca", "Frostbite Leviathan", "Fluorivane", "Cerulean Dragon",
    -- New additions
    "Eggy Enchant Stone", "Ghost Worm Fish",
}

local ForgottenList = {
    "Sea Eater", "Thunderzilla", "Iridesca", "Frostbite Leviathan", "Fluorivane", "Cerulean Dragon",
}

local MutasiList = {
    "Noob", "Fairy Dust", "Holographic", "Gemstone", "Fire", "Color Burn", "Frozen",
    "Galaxy", "BloodMoon", "Binary", "Lightning", "Disco", "Festive", "Radioactive",
    "Moon Fragment", "Midnight",
}

local LegendaryCrystalList = {
    "Blue Sea Dragon", "Star Snail", "Cute Dumbo",
    "Blossom Jelly", "Bioluminescent Octopus",
}

local RubyList = { "Ruby" }

local FishChanceData = {
    ["Crystal Crab"]             = "1 in 750K",
    ["Orca"]                     = "1 in 1.5M",
    ["Zombie Shark"]             = "1 in 250K",
    ["Zombie Megalodon"]         = "1 in 4M",
    ["Dead Zombie Shark"]        = "1 in 500K",
    ["Blob Shark"]               = "1 in 250K",
    ["Ghost Shark"]              = "1 in 500K",
    ["Skeleton Narwhal"]         = "1 in 600K",
    ["Ghost Worm Fish"]          = "1 in 1M",
    ["Worm Fish"]                = "1 in 3M",
    ["Megalodon"]                = "1 in 4M",
    ["1x1x1x1 Comet Shark"]      = "1 in 4M",
    ["Bloodmoon Whale"]          = "1 in 5M",
    ["Lochness Monster"]         = "1 in 3M",
    ["Monster Shark"]            = "1 in 2.5M",
    ["Eerie Shark"]              = "1 in 250K",
    ["Great Whale"]              = "1 in 900K",
    ["Frostborn Shark"]          = "1 in 500K",
    ["Thin Armor Shark"]         = "1 in 300K",
    ["Scare"]                    = "1 in 3M",
    ["Queen Crab"]               = "1 in 800K",
    ["King Crab"]                = "1 in 1.2M",
    ["Cryoshade Glider"]         = "1 in 450K",
    ["Panther Eel"]              = "1 in 750K",
    ["Giant Squid"]              = "1 in 800K",
    ["Depthseeker Ray"]          = "1 in 1.2M",
    ["Robot Kraken"]             = "1 in 3.5M",
    ["Mosasaur Shark"]           = "1 in 800K",
    ["King Jelly"]               = "1 in 1.5M",
    ["Bone Whale"]               = "1 in 2M",
    ["Elshark Gran Maja"]        = "1 in 4M",
    ["Elpirate Gran Maja"]       = "1 in 4M",
    ["ElRetro Gran Maja"]        = "1 in 4M",
    ["Ancient Whale"]            = "1 in 2.75M",
    ["Gladiator Shark"]          = "1 in 1M",
    ["Ancient Lochness Monster"] = "1 in 3M",
    ["Talon Serpent"]            = "1 in 3M",
    ["Hacker Shark"]             = "1 in 2M",
    ["Strawberry Choc Megalodon"]= "1 in 4M",
    ["Krampus Shark"]            = "1 in 1M",
    ["Emerald Winter Whale"]     = "1 in 1.5M",
    ["Winter Frost Shark"]       = "1 in 3M",
    ["Icebreaker Whale"]         = "1 in 4M",
    ["Cursed Kraken"]            = "1 in 3M",
    ["Pirate Megalodon"]         = "1 in 4M",
    ["Leviathan"]                = "1 in 5M",
    ["Viridis Lurker"]           = "1 in 1.4M",
    ["Ancient Magma Whale"]      = "1 in 5M",
    ["Mutant Runic Koi"]         = "1 in ??",
    ["Cosmic Mutant Shark"]      = "1 in 2M",
    ["Strawberry Orca"]          = "1 in 3M",
    ["Bonemaw Tyrant"]           = "1 in 2.5M",
    ["Sea Eater"]                = "1 in 25M",
    ["Thunderzilla"]             = "1 in 30M",
    ["Iridesca"]                 = "1 in 25M",
    ["Eggy Enchant Stone"]       = "1 in 100K",
    ["Deepsea Monster Axolotl"]  = "1 in 2M",
    ["Blocky Lochness Monster"]  = "1 in 3M",
    ["Frostbite Leviathan"]      = "1 in 12M",
    ["Aurelion"]                 = "1 in 3M",
    ["Runic Enchant Stone"]      = "1 in 1.5M",
    ["Frogalloon"]               = "1 in 1.5M",
    ["Fluorivane"]               = "1 in 15M",
    ["Coral Whale"]              = "1 in 2M",
    ["Flame Tyrant"]             = "1 in 5M",
    ["Cerulean Dragon"]          = "1 in 25M",
    ["Withering Core"]           = "1 in ??",
    ["Love Nessie"]              = "1 in ??",
    ["Broken Heart Nessie"]      = "1 in ??",
    ["Ketupat Whale"]            = "1 in ??",
}

local FishImageURL = {
    ["Monster Shark"]            = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Monster%20Shark.png",
    ["Megalodon"]                = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Megalodon.png",
    ["Ancient Lochness Monster"] = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Ancient%20Lochness%20Monster.png",
    ["Ancient Magma Whale"]      = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Ancient%20Magma%20Whale.png",
    ["Ancient Whale"]            = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Ancient%20Whale.png",
    ["Bloodmoon Whale"]          = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Bloodmoon%20Whale.png",
    ["Blob Shark"]               = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Blob%20Shark.png",
    ["Bonemaw Tyrant"]           = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Bonemaw%20Tyrant.png",
    ["Bone Whale"]               = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Bone%20Whale.png",
    ["Cosmic Mutant Shark"]      = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Cosmic%20Mutant%20Shark.png",
    ["Cryoshade Glider"]         = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Cryoshade%20Glider.png",
    ["Crystal Crab"]             = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Crystal%20Crab.png",
    ["Cursed Kraken"]            = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Cursed%20Kraken.png",
    ["Depthseeker Ray"]          = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Depthseeker%20Ray.png",
    ["Eerie Shark"]              = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Eerie%20Shark.png",
    ["Elpirate Gran Maja"]       = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Elpirate%20Gran%20Maja.png",
    ["Elshark Gran Maja"]        = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Elshark%20Gran%20Maja.png",
    ["Frostborn Shark"]          = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Frostborn%20Shark.png",
    ["Ghost Shark"]              = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Ghost%20Shark.png",
    ["Giant Squid"]              = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Giant%20Squid.png",
    ["Gladiator Shark"]          = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Gladiator%20Shark.png",
    ["Great Whale"]              = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Great%20Whale.png",
    ["Ketupat Whale"]            = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Ketupat%20Whale.png",
    ["King Crab"]                = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/King%20Crab.png",
    ["King Jelly"]               = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/King%20Jelly.png",
    ["Leviathan"]                = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Leviathan.png",
    ["Lochness Monster"]         = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Lochness%20Monster.png",
    ["Mosasaur Shark"]           = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Mosasaur%20Shark.png",
    ["Orca"]                     = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Orca.png",
    ["Panther Eel"]              = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Panther%20Eel.png",
    ["Pirate Megalodon"]         = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Pirate%20Megalodon.png",
    ["Queen Crab"]               = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Queen%20Crab.png",
    ["Rainbow Comet Shark"]      = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Rainbow%20Comet%20Shark.png",
    ["Robot Kraken"]             = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Robot%20Kraken.png",
    ["Ruby"]                     = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Ruby%20Gemstone.png",
    ["Sea Eater"]                = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Sea%20Eater.png",
    ["Skeleton Narwhal"]         = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Skeleton%20Narwhal.png",
    ["Thin Armor Shark"]         = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Thin%20Armor%20Shark.png",
    ["Thunderzilla"]             = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Thunderzilla.png",
    ["Strawberry Orca"]          = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Strawberry%20Orca.png",
    ["Eggy Enchant Stone"]       = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Eggy%20Enchant%20Stone.png",
    ["Worm Fish"]                = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Worm%20Fish.png",
    ["Iridesca"]                 = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Iridesca.png",
    ["Deepsea Monster Axolotl"]  = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Deepsea%20Monster%20Axolotl.jpeg",
    ["Blocky Lochness Monster"]  = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Blocky%20Lochness%20Monster.jpeg",
    ["Frostbite Leviathan"]      = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Frostbite%20Leviathan.jpeg",
    ["Aurelion"]                 = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Aurelion.png",
    ["Frogalloon"]               = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Frogallon.png",
    ["Scare"]                    = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Scare.png",
    ["Viridis Lurker"]           = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Viridis%20Lurker.jpg",
    ["Fluorivane"]               = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Fluorivane.png",
    ["Coral Whale"]              = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Coral%20Whale.png",
    ["Runic Enchant Stone"]      = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Runic%20Enchant%20Stone.png",
    ["Flame Tyrant"]             = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Flame%20Tyrant.png",
    ["Cerulean Dragon"]          = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Cerulean%20Dragon.png",
    ["Withering Core"]           = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/Withering%20Core.png",
}

-- ============================================================
--  STATE / CACHE
-- ============================================================

local MentionCache    = {}
local FishImageCache  = {}
local AvatarCache     = {}
local LeaveTimers     = {}

local PlayerStats     = {}   -- [uid] = { catchCount, secretList, secretCount, forgottenCount, joinTime, lastFishTime, name }
local PlayerNameToId  = {}   -- [lowercase name] = uid
local UidToCanonicalName = {} -- [uid] = p.Name
local GalatamaStats   = {}   -- [uid] = { name, totalPoin, catches }
local NameStats       = {}   -- [lowercase name] = { name, secretList, totalPoin, catches } (fallback)

local ServerStats = {
    totalSecret    = 0,
    totalForgotten = 0,
    secretLog      = {},
    forgottenLog   = {},
    startTime      = 0,
}

-- Persistent message refs
local LeaderboardMsgRef = { nil }
local StatsMsgRef       = { nil }

-- ============================================================
--  UTILITY
-- ============================================================

local function GetServerInfo()
    local ok1, jobId   = pcall(function() return game.JobId end)
    local ok2, placeId = pcall(function() return tostring(game.PlaceId) end)
    local jobStr   = (ok1 and jobId ~= "") and jobId or "Unknown"
    local placeStr = ok2 and placeId or "Unknown"
    local rejoinLink = "roblox://experiences/start?placeId=" .. placeStr .. "&gameInstanceId=" .. jobStr
    return jobStr, placeStr, rejoinLink
end

local function StripTags(str)
    return string.gsub(str, "<[^>]+>", "")
end

local function Trim(s)
    return s:match("^%s*(.-)%s*$") or s
end

local function UptimeString(seconds)
    return math.floor(seconds / 3600) .. "h " .. math.floor((seconds % 3600) / 60) .. "m"
end

local function FindPlayer(name)
    local p = Players:FindFirstChild(name)
    if p then return p end
    local lower = string.lower(name)
    for _, player in ipairs(Players:GetPlayers()) do
        if string.lower(player.Name) == lower or string.lower(player.DisplayName) == lower then return player end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if string.find(string.lower(player.Name), lower, 1, true)
        or string.find(lower, string.lower(player.Name), 1, true) then
            return player
        end
    end
    return nil
end

-- ============================================================
--  REGISTER PLAYER (terpusat, cegah duplikat)
-- ============================================================

local function RegisterPlayer(player)
    local uid   = player.UserId
    local uname = player.Name
    local dname = player.DisplayName
    local ul    = uname:lower()
    local dl    = dname:lower()

    UidToCanonicalName[uid] = uname
    PlayerNameToId[ul]      = uid
    PlayerNameToId[dl]      = uid

    if not PlayerStats[uid] then
        PlayerStats[uid] = {
            name          = uname,
            catchCount    = 0,
            secretList    = {},
            secretCount   = 0,
            forgottenCount= 0,
            joinTime      = os.time(),
            lastFishTime  = nil,
        }
    end

    if not GalatamaStats[uid] then
        GalatamaStats[uid] = { name = uname, totalPoin = 0, catches = {} }
    end

    if not NameStats[ul] then
        NameStats[ul] = { name = uname, secretList = {}, secretCount = 0, forgottenCount = 0, totalPoin = 0, catches = {} }
    end

    -- Alias display name ke canonical entry
    if dl ~= ul then
        NameStats[dl] = NameStats[ul]
    end

    -- Build mention cache
    for _, member in ipairs(MemberList) do
        local mUl = string.lower(member.username)
        local mDl = string.lower(member.display)
        if ul == mUl or dl == mDl or ul == mDl or dl == mUl then
            MentionCache[ul] = member.id
            MentionCache[dl] = member.id
        end
    end
end

-- ============================================================
--  MENTION HELPERS
-- ============================================================

local function BuildMentionCache(rbxName, rbxDisplay)
    for _, member in ipairs(MemberList) do
        local uLower = string.lower(member.username)
        local dLower = string.lower(member.display)
        if string.lower(rbxName) == uLower    or string.lower(rbxDisplay) == dLower
        or string.lower(rbxName) == dLower    or string.lower(rbxDisplay) == uLower then
            MentionCache[string.lower(rbxName)]    = member.id
            MentionCache[string.lower(rbxDisplay)] = member.id
        end
    end
end

local function GetMention(robloxName)
    if not robloxName then return "" end
    local lower = string.lower(robloxName)
    if MentionCache[lower] then return "<@" .. MentionCache[lower] .. ">" end
    for _, member in ipairs(MemberList) do
        if string.lower(member.username) == lower or string.lower(member.display) == lower then
            return "<@" .. member.id .. ">"
        end
    end
    return ""
end

-- ============================================================
--  FISH DETECTION
-- ============================================================

local function FindSecretFish(fishName)
    local lower = string.lower(fishName)
    for _, baseName in ipairs(SecretFishList) do
        if lower == string.lower(baseName) then return baseName, nil end
    end
    local bestBase, bestLen, bestMutasi = nil, 0, nil
    for _, baseName in ipairs(SecretFishList) do
        local s = string.find(lower, string.lower(baseName), 1, true)
        if s then
            local mutasi = nil
            if s > 1 then
                mutasi = fishName:sub(1, s - 1):match("^%s*(.-)%s*$")
                if mutasi == "" then mutasi = nil end
            end
            if #baseName > bestLen then
                bestLen    = #baseName
                bestBase   = baseName
                bestMutasi = mutasi
            end
        end
    end
    return bestBase, bestMutasi
end

local function FindGalatamaFish(fishName)
    local lower = string.lower(fishName)
    for _, base in ipairs(GalatamaFishList) do
        if lower == base:lower() then return base end
    end
    local bestBase, bestLen = nil, 0
    for _, base in ipairs(GalatamaFishList) do
        if lower:find(base:lower(), 1, true) and #base > bestLen then
            bestLen  = #base
            bestBase = base
        end
    end
    return bestBase
end

local function FindMutasi(fishName)
    local lower = string.lower(fishName)
    for _, mutasiName in ipairs(MutasiList) do
        local mutasiLower = string.lower(mutasiName)
        local s = string.find(lower, mutasiLower, 1, true)
        if s then
            local before = s == 1 and " " or lower:sub(s - 1, s - 1)
            local after  = lower:sub(s + #mutasiLower, s + #mutasiLower)
            if (before == " " and after == " ")
            or (s == 1 and after == " ") then
                return mutasiName
            end
        end
    end
    return nil
end

local function FindRuby(fishName)
    local lower = string.lower(fishName)
    if string.find(lower, "ruby") and string.find(lower, "gemstone") then return "Ruby" end
    return nil
end

local function FindLegendaryCrystal(fishName)
    local lower = string.lower(fishName)
    if not string.find(lower, "crystalized") then return nil end
    for _, name in ipairs(LegendaryCrystalList) do
        if string.find(lower, string.lower(name), 1, true) then return name end
    end
    return nil
end

local function GetFishImageId(item)
    for _, desc in ipairs(item:GetDescendants()) do
        local ok, val = pcall(function()
            if desc:IsA("SpecialMesh")                               then return desc.TextureId
            elseif desc:IsA("Decal") or desc:IsA("Texture")         then return desc.Texture
            elseif desc:IsA("ImageLabel") or desc:IsA("ImageButton") then return desc.Image
            end
            return nil
        end)
        if ok and val and val ~= "" and val ~= "rbxasset://" then
            local id = tostring(val):match("%d+")
            if id then return id end
        end
    end
    return nil
end

-- ============================================================
--  GALATAMA MUTASI BONUS HELPER
-- ============================================================

local function CheckGalatamaMutasiBonus(mutasi)
    if not mutasi or mutasi == "" then return false, nil end
    local ml = mutasi:lower()
    for _, excluded in ipairs(MutasiNoBonus) do
        if ml == excluded:lower() then return false, mutasi end
    end
    return true, mutasi
end

-- ============================================================
--  WEBHOOK SENDERS
-- ============================================================

local function BuildEmbed(title, description, color, fields, imageUrl, thumbUrl, footerTag)
    local embed = {
        title       = title,
        description = description,
        color       = color,
        fields      = fields,
        footer      = { text = (footerTag or "Forky Webhook") .. " | " .. os.date("%X") },
        timestamp   = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    }
    if imageUrl then embed.image     = { url = imageUrl } end
    if thumbUrl then embed.thumbnail = { url = thumbUrl } end
    return embed
end

local function BuildFieldContent(emoji, label, value, inline)
    return { name = (emoji and (emoji .. " ") or "") .. label, value = value, inline = inline or false }
end

local function PostWebhook(url, body)
    local requestFunc = GetRequestFunc()
    if not requestFunc then warn("[ Webhook ] no request function available"); return end
    if url == "" or not url then warn("[ Webhook ] empty or nil URL"); return end

    local okEncode, encoded = pcall(function() return HttpService:JSONEncode(body) end)
    if not okEncode then warn("[ Webhook ] JSONEncode failed:", encoded); return end

    task.spawn(function()
        local ok, res = pcall(function()
            return requestFunc({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = encoded })
        end)
        if not ok then warn("[ Webhook ] request failed:", res); return end
        if not res then warn("[ Webhook ] request returned nil/false:", url); return end
        if type(res) == "table" and res.StatusCode and res.StatusCode >= 400 then
            warn("[ Webhook ] HTTP error:", res.StatusCode, res.Body or "")
        end
    end)
end

local function PatchOrPostWebhook(url, body, messageIdRef, onSuccess)
    local requestFunc = GetRequestFunc()
    if not requestFunc then warn("[ PatchPost ] no request function"); return end
    if not url or url == "" then return end

    local okEnc, encoded = pcall(function() return HttpService:JSONEncode(body) end)
    if not okEnc then warn("[ PatchPost ] JSONEncode failed:", encoded); return end

    local msgId  = messageIdRef[1]
    local target = msgId and (url .. "/messages/" .. msgId) or (url .. "?wait=true")
    local method = msgId and "PATCH" or "POST"

    local ok, res = pcall(requestFunc, { Url = target, Method = method, Headers = { ["Content-Type"] = "application/json" }, Body = encoded })

    if not ok then warn("[ PatchPost ] request failed:", res); return end
    if not res then warn("[ PatchPost ] nil response:", target); return end
    if type(res) == "table" then
        if res.StatusCode and res.StatusCode >= 400 then
            warn("[ PatchPost ] HTTP error:", res.StatusCode, res.Body or "")
            if res.StatusCode == 404 then messageIdRef[1] = nil end
            return
        end
        if not messageIdRef[1] and res.Body then
            local succ, decoded = pcall(function() return HttpService:JSONDecode(res.Body) end)
            if succ and decoded and decoded.id then
                messageIdRef[1] = decoded.id
                if onSuccess then onSuccess(decoded.id) end
            end
        end
    end
end

local function BuildContent(mention, captionType)
    if not mention or mention == "" then return nil end
    local m = Trim(mention)
    if captionType == "secret" or captionType == "forgotten" then return "Ingfokan spot pliss " .. m
    elseif captionType == "leave"   then return "ke disconect ya? " .. m
    elseif captionType == "join"    then return "alhamdulilah kembali " .. m
    elseif captionType == "notback" then return "lah kok ngilang " .. m
    end
    return m
end

local function SendWebhook(title, description, color, fields, imageUrl, thumbUrl, mention, captionType)
    local f = {}; for _, v in ipairs(fields) do table.insert(f, v) end
    local content = BuildContent(mention, captionType)
    PostWebhook(WEBHOOK_URL, {
        username   = WEBHOOK_NAME,
        avatar_url = WEBHOOK_AVATAR,
        content    = content,
        embeds     = { BuildEmbed(title, description, color, f, imageUrl, thumbUrl) },
    })
end

local function SendFishWebhook(title, description, color, fields, imageUrl, thumbUrl, mention, captionType)
    local url = (WEBHOOK_FISH ~= "") and WEBHOOK_FISH or WEBHOOK_URL
    if url == "" then return end
    local f = {}; for _, v in ipairs(fields) do table.insert(f, v) end
    local content = BuildContent(mention, captionType)
    PostWebhook(url, {
        username   = WEBHOOK_NAME,
        avatar_url = WEBHOOK_AVATAR,
        content    = content,
        embeds     = { BuildEmbed(title, description, color, f, imageUrl, thumbUrl) },
    })
end

-- ============================================================
--  GALATAMA — SAVE & RESTORE STATE
-- ============================================================

local function SaveGalatamaState()
    local requestFunc = GetRequestFunc()
    if not requestFunc or BOT_TOKEN == "" or SAVE_CHANNEL_ID == "" then return end

    local saveData = {}

    for uid, gs in pairs(GalatamaStats) do
        if gs.totalPoin > 0 then
            saveData[gs.name] = { totalPoin = gs.totalPoin, catches = gs.catches }
        end
    end

    for lname, ns in pairs(NameStats) do
        if (ns.totalPoin or 0) > 0 and not saveData[ns.name] then
            local uid = PlayerNameToId[lname]
            if not (uid and GalatamaStats[uid] and GalatamaStats[uid].totalPoin > 0) then
                saveData[ns.name] = { totalPoin = ns.totalPoin, catches = ns.catches }
            end
        end
    end

    if next(saveData) == nil then return end

    local ok, jsonStr = pcall(function() return HttpService:JSONEncode(saveData) end)
    if not ok then return end

    pcall(function()
        requestFunc({
            Url     = "https://discord.com/api/v10/channels/" .. SAVE_CHANNEL_ID .. "/messages",
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json", ["Authorization"] = "Bot " .. BOT_TOKEN },
            Body    = HttpService:JSONEncode({ content = SAVE_STATE_TAG .. "\n```json\n" .. jsonStr .. "\n```" }),
        })
    end)
end

local function RestoreGalatamaState()
    local requestFunc = GetRequestFunc()
    if not requestFunc or BOT_TOKEN == "" or SAVE_CHANNEL_ID == "" then return end

    local ok, response = pcall(function()
        return requestFunc({
            Url     = "https://discord.com/api/v10/channels/" .. SAVE_CHANNEL_ID .. "/messages?limit=50",
            Method  = "GET",
            Headers = { ["Authorization"] = "Bot " .. BOT_TOKEN },
        })
    end)
    if not ok or not response or not response.Body then return end

    local okParse, messages = pcall(function() return HttpService:JSONDecode(response.Body) end)
    if not okParse or type(messages) ~= "table" then return end

    for _, msg in ipairs(messages) do
        local content = msg.content or ""
        if content:find(SAVE_STATE_TAG, 1, true) then
            local jsonStr = content:match("```json\n(.+)\n```")
            if not jsonStr then break end

            local okJson, saveData = pcall(function() return HttpService:JSONDecode(jsonStr) end)
            if not okJson or type(saveData) ~= "table" then break end

            local restoredCount = 0
            for playerName, data in pairs(saveData) do
                local lname = playerName:lower()
                if not NameStats[lname] then
                    NameStats[lname] = { name = playerName, secretList = {}, secretCount = 0, forgottenCount = 0, totalPoin = 0, catches = {} }
                end
                if (data.totalPoin or 0) > (NameStats[lname].totalPoin or 0) then
                    NameStats[lname].totalPoin = data.totalPoin or 0
                    NameStats[lname].catches   = data.catches   or {}
                    restoredCount = restoredCount + 1
                end
                local uid = PlayerNameToId[lname]
                if uid then
                    if not GalatamaStats[uid] then
                        GalatamaStats[uid] = { name = playerName, totalPoin = 0, catches = {} }
                    end
                    if (data.totalPoin or 0) > GalatamaStats[uid].totalPoin then
                        GalatamaStats[uid].totalPoin = data.totalPoin or 0
                        GalatamaStats[uid].catches   = data.catches   or {}
                    end
                end
            end

            if restoredCount > 0 then
                local url = (WEBHOOK_GALATAMA ~= "") and WEBHOOK_GALATAMA or WEBHOOK_URL
                PostWebhook(url, {
                    username   = WEBHOOK_NAME,
                    avatar_url = WEBHOOK_AVATAR,
                    embeds = { BuildEmbed(
                        "♻️ DATA GALATAMA DIPULIHKAN",
                        "Point **" .. restoredCount .. "** pemain berhasil di-restore dari sesi sebelumnya.",
                        3066993, {}, nil, nil, "Forky Galatama"
                    )},
                })
            end
            break
        end
    end
end

-- ============================================================
--  LEADERBOARD SECRET FISH (PATCH/POST persistent)
-- ============================================================

local function SendLeaderboard(isFinal)
    local merged = {}

    -- Primary: PlayerStats by UserId
    for uid, stats in pairs(PlayerStats) do
        local key = tostring(uid)
        if not merged[key] then
            merged[key] = { name = stats.name, total = 0, secret = 0, forgotten = 0, fishList = {} }
        end
        for fishName, count in pairs(stats.secretList) do
            merged[key].total = merged[key].total + count
            table.insert(merged[key].fishList, fishName .. " x" .. count)
        end
        merged[key].secret   = stats.secretCount   or 0
        merged[key].forgotten = stats.forgottenCount or 0
    end

    local function isForgottenFish(name)
        for _, value in ipairs(ForgottenList) do
            if string.lower(value) == string.lower(name) then
                return true
            end
        end
        return false
    end

    local leaderData = {}
    local seenNameStats = {}

    -- Include offline / fallback name-based stats
    for lname, ns in pairs(NameStats) do
        if type(ns) == "table" and not seenNameStats[ns] then
            seenNameStats[ns] = true
            local linkedUid = PlayerNameToId[lname]
            if not (linkedUid and merged[tostring(linkedUid)]) then
                local secretCount = ns.secretCount
                local forgottenCount = ns.forgottenCount
                local needsCount = (secretCount == nil or forgottenCount == nil)
                if secretCount == nil then secretCount = 0 end
                if forgottenCount == nil then forgottenCount = 0 end
                if needsCount then
                    for fishName, count in pairs(ns.secretList or {}) do
                        if isForgottenFish(fishName) then
                            forgottenCount = forgottenCount + count
                        else
                            secretCount = secretCount + count
                        end
                    end
                end
                if (secretCount + forgottenCount) > 0 then
                    local entry = { name = ns.name or lname, total = secretCount + forgottenCount, secret = secretCount, forgotten = forgottenCount, fishList = {} }
                    for fishName, count in pairs(ns.secretList or {}) do
                        table.insert(entry.fishList, fishName .. " x" .. count)
                    end
                    merged["name_" .. lname] = entry
                end
            end
        end
    end

    for _, entry in pairs(merged) do
        if (entry.secret + entry.forgotten) > 0 then
            table.sort(entry.fishList)
            table.insert(leaderData, entry)
        end
    end

    table.sort(leaderData, function(a, b)
        if a.secret ~= b.secret then return a.secret > b.secret end
        if a.forgotten ~= b.forgotten then return a.forgotten > b.forgotten end
        return a.total > b.total
    end)

    local description = "Belum ada secret fish tercatat saat ini."
    local lines = {}
    if #leaderData > 0 then
        local medals = { "🥇", "🥈", "🥉" }
        for i, entry in ipairs(leaderData) do
            if i > 10 then break end
            local medal = medals[i] or ("**#" .. i .. "**")
            local line = medal .. " **" .. entry.name .. "**"
                .. " — Secret: **" .. entry.secret .. "**"
                .. ", Forgotten: **" .. entry.forgotten .. "**"
                .. "\n↳ " .. (#entry.fishList > 0 and table.concat(entry.fishList, ", ") or "-")
            table.insert(lines, line)
        end
        description = table.concat(lines, "\n\n")
    end

    local uptime = os.time() - ServerStats.startTime
    local fields = {
        BuildFieldContent("⏱️", "Uptime",          UptimeString(uptime),                                         true),
        BuildFieldContent("🎣", "Total Secret",    "**" .. tostring(ServerStats.totalSecret)   .. "** ekor",     true),
        BuildFieldContent("⚜️", "Total Forgotten", "**" .. tostring(ServerStats.totalForgotten) .. "** ekor",    true),
    }

    local snapshot = description .. HttpService:JSONEncode(fields)
    if not isFinal and snapshot == LastLeaderboardSnapshot then return end
    LastLeaderboardSnapshot = snapshot

    local url = (WEBHOOK_LEADERBOARD ~= "") and WEBHOOK_LEADERBOARD or WEBHOOK_STATS
    if url == "" then return end

    local title   = isFinal and "🏆 LEADERBOARD FINAL SECRET FISH" or "🏆 LEADERBOARD SECRET FISH"
    local roleMent = DISCORD_ROLE_ID ~= "" and ("<@&" .. DISCORD_ROLE_ID .. ">") or nil
    local contentMsg = isFinal and (roleMent and roleMent .. " 📢 **Leaderboard Final! Monitor disconnect.**") or nil

    local body = {
        username   = WEBHOOK_NAME,
        avatar_url = WEBHOOK_AVATAR,
        content    = contentMsg,
        embeds     = { BuildEmbed(title, description, 16766720, fields, nil, nil, "Forky Leaderboard") },
    }

    if isFinal then
        PostWebhook(url, body)
    else
        PatchOrPostWebhook(url, body, LeaderboardMsgRef, nil)
    end
end

-- ============================================================
--  GALATAMA LEADERBOARD
-- ============================================================

local function SendGalatamaLeaderboard(isFinal)
    local merged = {}

    -- Primary: GalatamaStats by UserId
    for uid, gs in pairs(GalatamaStats) do
        if gs.totalPoin > 0 then
            merged[tostring(uid)] = { name = gs.name, totalPoin = gs.totalPoin, catches = gs.catches }
        end
    end

    -- Fallback: NameStats untuk player yang sudah disconnect
    for lname, ns in pairs(NameStats) do
        if (ns.totalPoin or 0) > 0 and ns.name:lower() == lname then
            local uid = PlayerNameToId[lname]
            if uid and merged[tostring(uid)] then
                if (ns.totalPoin or 0) > merged[tostring(uid)].totalPoin then
                    merged[tostring(uid)].totalPoin = ns.totalPoin
                    merged[tostring(uid)].catches   = ns.catches
                end
            else
                local key = uid and tostring(uid) or ("name_" .. lname)
                if not merged[key] then
                    merged[key] = { name = ns.name, totalPoin = ns.totalPoin or 0, catches = ns.catches }
                end
            end
        end
    end

    local leaderData = {}
    for _, gs in pairs(merged) do
        local catchLines = {}
        for fishName, count in pairs(gs.catches) do
            local pts = (GalatamaPoin[fishName] or 0) * count
            table.insert(catchLines, fishName .. " x" .. count .. " (+" .. pts .. "pts)")
        end
        table.insert(leaderData, {
            name      = gs.name,
            totalPoin = gs.totalPoin,
            catchStr  = #catchLines > 0 and table.concat(catchLines, "\n") or "-",
        })
    end

    if #leaderData == 0 then return end
    table.sort(leaderData, function(a, b) return a.totalPoin > b.totalPoin end)

    local medals    = { "🥇", "🥈", "🥉" }
    local uptime    = os.time() - ServerStats.startTime
    local roleMent  = DISCORD_ROLE_ID ~= "" and ("<@&" .. DISCORD_ROLE_ID .. ">") or ""
    local title     = isFinal and "🏆 LEADERBOARD FINAL GALATAMA" or "🏆 LEADERBOARD GALATAMA — UPDATE"
    local contentMsg = isFinal
        and (roleMent ~= "" and roleMent .. " 📢 **Hasil Akhir Galatama! Monitor disconnect.**" or nil)
        or  (roleMent ~= "" and roleMent .. " 📊 **Update Leaderboard Galatama!**" or nil)

    local fields = {}
    for i, entry in ipairs(leaderData) do
        if i > 10 then break end
        local medal = medals[i] or ("#" .. i)
        table.insert(fields, {
            name   = medal .. " " .. entry.name .. " — 🏅 " .. entry.totalPoin .. " pts",
            value  = entry.catchStr,
            inline = false,
        })
    end
    table.insert(fields, { name = "🎪 Event",          value = "**Galatama**",                                        inline = true })
    table.insert(fields, { name = "⏱️ Uptime",          value = UptimeString(uptime),                                  inline = true })
    table.insert(fields, { name = "🦕 Total Secret",    value = "**" .. ServerStats.totalSecret .. "** ekor",          inline = true })
    table.insert(fields, { name = "⚜️ Total Forgotten", value = "**" .. ServerStats.totalForgotten .. "** ekor",       inline = true })

    local url = (WEBHOOK_GALATAMA ~= "") and WEBHOOK_GALATAMA or WEBHOOK_STATS
    if url == "" then return end

    PostWebhook(url, {
        username   = WEBHOOK_NAME,
        avatar_url = WEBHOOK_AVATAR,
        content    = contentMsg,
        embeds     = { BuildEmbed(title,
            "```\nBlob Shark=25 | Ghost Shark=50 | Skeleton Narwhal=60 | Worm Fish=300 | Megalodon=400\nBonus Mutasi (kecuali Big & Shiny): +100pts\n```",
            16766720, fields, nil, nil, "Forky Galatama") },
    })
end

local function SendFinalLeaderboard()
    SaveGalatamaState()
    SendLeaderboard(true)
    SendGalatamaLeaderboard(true)
end

-- ============================================================
--  SERVER STATS  (PATCH/POST persistent)
-- ============================================================

local function SendServerStats()
    if not SCRIPT_ACTIVE then return end

    local uptime = os.time() - ServerStats.startTime

    local recentSecret, recentForgotten = {}, {}
    for i = math.max(1, #ServerStats.secretLog - 4), #ServerStats.secretLog do
        local e = ServerStats.secretLog[i]
        table.insert(recentSecret, e.fish .. " (" .. e.player .. ")")
    end
    for i = math.max(1, #ServerStats.forgottenLog - 4), #ServerStats.forgottenLog do
        local e = ServerStats.forgottenLog[i]
        table.insert(recentForgotten, e.fish .. " (" .. e.player .. ")")
    end

    local fields = {
        BuildFieldContent("⏱️", "Uptime Monitor",    UptimeString(uptime),                                                    true),
        BuildFieldContent("🎣", "Total Secret Fish", "**" .. tostring(ServerStats.totalSecret)   .. "** ekor",               true),
        BuildFieldContent("⚜️", "Total Forgotten",   "**" .. tostring(ServerStats.totalForgotten) .. "** ekor",              true),
        BuildFieldContent("🕐", "Secret Terakhir",   #recentSecret   > 0 and table.concat(recentSecret,   "\n") or "-",      false),
        BuildFieldContent("👑", "Forgotten Terakhir",#recentForgotten > 0 and table.concat(recentForgotten, "\n") or "-",    false),
    }

    local snapshot = HttpService:JSONEncode(fields)
    if snapshot == LastStatsSnapshot then return end
    LastStatsSnapshot = snapshot

    local body = {
        username   = WEBHOOK_NAME,
        avatar_url = WEBHOOK_AVATAR,
        embeds     = { BuildEmbed("🌐 SERVER STATS", nil, 3447003, fields, nil, nil, "Forky Stats") },
    }

    PatchOrPostWebhook(WEBHOOK_STATS, body, StatsMsgRef, nil)
end

-- ============================================================
--  CHAT LOG
-- ============================================================

local function GetAvatarUrl(player)
    return player and (PROXY .. "/avatar/" .. tostring(player.UserId) .. "?t=" .. tostring(os.time())) or nil
end

local function SendChatLog(senderName, message)
    if not SCRIPT_ACTIVE or not message or message == "" then return end
    local url = (WEBHOOK_CHAT ~= "") and WEBHOOK_CHAT or WEBHOOK_URL
    if url == "" then return end
    local player   = FindPlayer(senderName)
    local thumbUrl = player and (AvatarCache[player.UserId] or GetAvatarUrl(player)) or nil
    local displaySender = senderName
    if player and UidToCanonicalName[player.UserId] then
        displaySender = UidToCanonicalName[player.UserId]
    end

    PostWebhook(url, {
        username   = WEBHOOK_NAME,
        avatar_url = WEBHOOK_AVATAR,
        embeds = { BuildEmbed("💬 CHAT LOG", nil, 5793266, {
            BuildFieldContent("👤", "Player",  "**" .. displaySender .. "**", true),
            BuildFieldContent("💬", "Message", message,                        false),
        }, nil, thumbUrl, "Forky Chat Log") },
    })
end

-- ============================================================
--  CHAT PARSING & DETECTION
-- ============================================================

local function ParseChat(rawMsg)
    local msg = StripTags(rawMsg)
    msg = string.gsub(msg, "^%[Server%]:%s*", "")
    local playerName, fishFull, weight = string.match(msg, "^(.-) obtained an? (.-) %(([%d%.%a]+ ?kg)%)")
    if not playerName then
        playerName, fishFull = string.match(msg, "^(.-) obtained an? (.+)")
        weight = "N/A"
    end
    if not playerName or not fishFull then return nil end
    playerName = playerName:match("%[%a+%]:%s*(.+)") or playerName
    playerName = Trim(playerName)
    weight     = weight and Trim(weight) or "N/A"
    fishFull   = fishFull:match("^(.-)%s+with a 1 in") or fishFull
    fishFull   = fishFull:match("^(.-)%s*[!%.]?$")     or fishFull
    fishFull   = Trim(fishFull)
    return { player = playerName, fish = fishFull, weight = weight }
end

local function CheckAndSend(rawMsg)
    if not SCRIPT_ACTIVE then return end
    if not string.find(string.lower(rawMsg), "obtained") then return end

    local data = ParseChat(rawMsg)
    if not data then return end

    local targetPlayer = FindPlayer(data.player)
    local avatarUrl    = GetAvatarUrl(targetPlayer)
    local uid = targetPlayer and targetPlayer.UserId or PlayerNameToId[string.lower(data.player)]

    -- Canonical name resolution
    local canonicalName = data.player
    if uid and UidToCanonicalName[uid] then
        canonicalName = UidToCanonicalName[uid]
    elseif targetPlayer then
        canonicalName = targetPlayer.Name
    end
    local lname = canonicalName:lower()

    -- Init stats
    if uid then
        if not PlayerStats[uid] then
            PlayerStats[uid] = {
                name          = canonicalName,
                catchCount    = 0,
                secretList    = {},
                secretCount   = 0,
                forgottenCount= 0,
                joinTime      = os.time(),
                lastFishTime  = nil,
            }
        end
        PlayerStats[uid].catchCount   = PlayerStats[uid].catchCount + 1
        PlayerStats[uid].lastFishTime = os.time()

        if not GalatamaStats[uid] then
            GalatamaStats[uid] = { name = canonicalName, totalPoin = 0, catches = {} }
        end
    end

    if not NameStats[lname] then
        NameStats[lname] = { name = canonicalName, secretList = {}, secretCount = 0, forgottenCount = 0, totalPoin = 0, catches = {} }
    end

    -- 1. Crystalized Legendary
    local legendaryBase = FindLegendaryCrystal(data.fish)
    if legendaryBase then
        local imageUrl = FishImageURL[legendaryBase]
            or (FishImageCache[legendaryBase] and (PROXY .. "/asset/" .. FishImageCache[legendaryBase]))
        SendFishWebhook("☄️ CRYSTALIZED LEGENDARY!", nil, 3407871, {
            BuildFieldContent("👤", "Player",  "**" .. canonicalName .. "**",  true),
            BuildFieldContent("🦐", "Item",    "**" .. data.fish .. "**",      true),
            BuildFieldContent("✨", "Type",    "Crystalized Legendary",         true),
            BuildFieldContent("⚖️", "Weight",  data.weight,                    true),
        }, imageUrl, avatarUrl, GetMention(canonicalName), "secret")
        return
    end

    -- 2. Ruby Gemstone
    local rubyBase = FindRuby(data.fish)
    if rubyBase then
        local imageUrl = FishImageURL[rubyBase]
            or (FishImageCache[rubyBase] and (PROXY .. "/asset/" .. FishImageCache[rubyBase]))
        SendFishWebhook("💎 RUBY GEMSTONE!", nil, 16753920, {
            BuildFieldContent("👤", "Player", "**" .. canonicalName .. "**", true),
            BuildFieldContent("💎", "Item",   "**" .. data.fish .. "**",     true),
            BuildFieldContent("⚖️", "Weight", data.weight,                   true),
        }, imageUrl, avatarUrl, GetMention(canonicalName), "secret")
        return
    end

    -- 3. Secret / Forgotten Fish
    local baseName, mutasi = FindSecretFish(data.fish)
    if baseName then
        local imageUrl = FishImageURL[baseName]
            or (FishImageCache[baseName] and (PROXY .. "/asset/" .. FishImageCache[baseName]))

        local isForgotten = false
        for _, name in ipairs(ForgottenList) do
            if string.lower(baseName) == string.lower(name) then isForgotten = true; break end
        end

        -- Update secretList
        if uid and PlayerStats[uid] then
            PlayerStats[uid].secretList[baseName] = (PlayerStats[uid].secretList[baseName] or 0) + 1
        end
        NameStats[lname].secretList[baseName] = (NameStats[lname].secretList[baseName] or 0) + 1
        if isForgotten then
            NameStats[lname].forgottenCount = (NameStats[lname].forgottenCount or 0) + 1
        else
            NameStats[lname].secretCount = (NameStats[lname].secretCount or 0) + 1
        end

        -- Galatama points
        local galBase  = FindGalatamaFish(data.fish)
        local galPoint = galBase and (GalatamaPoin[galBase] or 0) or 0

        local galMutasiBonus   = 0
        local mutasiBonusLabel = nil
        if galBase and galPoint > 0 then
            local eligible, label = CheckGalatamaMutasiBonus(mutasi)
            if eligible then
                galMutasiBonus   = GALATAMA_MUTASI_BONUS
                mutasiBonusLabel = label
            end
        end
        local galPointTotal = galPoint + galMutasiBonus

        if galBase and galPointTotal > 0 then
            if uid and GalatamaStats[uid] then
                GalatamaStats[uid].catches[galBase] = (GalatamaStats[uid].catches[galBase] or 0) + 1
                GalatamaStats[uid].totalPoin        = GalatamaStats[uid].totalPoin + galPointTotal
            end
            NameStats[lname].catches[galBase] = (NameStats[lname].catches[galBase] or 0) + 1
            NameStats[lname].totalPoin        = (NameStats[lname].totalPoin or 0) + galPointTotal
        end

        -- Total poin player saat ini
        local totalPoinNow = 0
        if uid and GalatamaStats[uid] then
            totalPoinNow = GalatamaStats[uid].totalPoin
        elseif NameStats[lname] then
            totalPoinNow = NameStats[lname].totalPoin or 0
        end

        local chanceInfo  = FishChanceData[baseName] or "Unknown"
        local mutasiField = mutasi and ("*" .. mutasi .. "*") or "-"

        local fields = {
            BuildFieldContent("👤", "Player",  "**" .. canonicalName .. "**", true),
            BuildFieldContent("🎣", "Fish",    "**" .. data.fish .. "**",     true),
            BuildFieldContent("🌀", "Variant", mutasiField,                    true),
            BuildFieldContent("⚖️", "Weight",  data.weight,                   true),
            BuildFieldContent("🎲", "Chance",  chanceInfo,                     true),
        }

        -- Tambahkan field galatama jika ada poin
        if galBase and galPointTotal > 0 then
            local galDesc
            if galMutasiBonus > 0 then
                galDesc = "**+" .. galPointTotal .. " pts**"
                    .. " (" .. galPoint .. " base + " .. galMutasiBonus .. " bonus mutasi 🌀 *" .. (mutasiBonusLabel or mutasi) .. "*)"
                    .. "\ntotal: **" .. totalPoinNow .. " pts**"
            else
                galDesc = "**+" .. galPointTotal .. " pts**"
                if mutasi then
                    galDesc = galDesc .. " *(mutasi " .. mutasi .. " — no bonus)*"
                end
                galDesc = galDesc .. "\ntotal: **" .. totalPoinNow .. " pts**"
            end
            table.insert(fields, BuildFieldContent("🏅", "Galatama", galDesc, false))
        end

        if isForgotten then
            if uid and PlayerStats[uid] then
                PlayerStats[uid].forgottenCount = (PlayerStats[uid].forgottenCount or 0) + 1
            end
            ServerStats.totalForgotten = ServerStats.totalForgotten + 1
            table.insert(ServerStats.forgottenLog, { fish = baseName, player = canonicalName, time = os.time() })
            SendFishWebhook("⚜️ FORGOTTEN TIER DETECTED!", nil, 16777215, fields, imageUrl, avatarUrl, GetMention(canonicalName), "forgotten")
        else
            if uid and PlayerStats[uid] then
                PlayerStats[uid].secretCount = (PlayerStats[uid].secretCount or 0) + 1
            end
            ServerStats.totalSecret = ServerStats.totalSecret + 1
            table.insert(ServerStats.secretLog, { fish = baseName, player = canonicalName, time = os.time() })
            SendFishWebhook("🎣 SECRET FISH DETECTED!", nil, 1752220, fields, imageUrl, avatarUrl, GetMention(canonicalName), "secret")
        end

        SendLeaderboard(false)
        return
    end

    -- 4. Mutasi non-secret
    local mutasiDetected = FindMutasi(data.fish)
    if mutasiDetected then
        SendFishWebhook("✨ MUTASI DETECTED!", nil, 16776960, {
            BuildFieldContent("👤", "Player",  "**" .. canonicalName .. "**", true),
            BuildFieldContent("🎣", "Fish",    "**" .. data.fish .. "**",     true),
            BuildFieldContent("🌀", "Variant", mutasiDetected,                 true),
            BuildFieldContent("⚖️", "Weight",  data.weight,                   true),
        }, nil, avatarUrl, nil, nil)
    end
end

-- ============================================================
--  BACKPACK MONITOR
-- ============================================================

local function WatchBackpack(bp)
    bp.ChildAdded:Connect(function(item)
        task.wait(0.1)
        local baseName = FindSecretFish(item.Name)
        if baseName and not FishImageURL[baseName] and not FishImageCache[baseName] then
            local imgId = GetFishImageId(item)
            if imgId then FishImageCache[baseName] = imgId end
        end
    end)
end

local function WatchForFish(player)
    local bp = player:FindFirstChild("Backpack")
    if bp then WatchBackpack(bp) end
    player.CharacterAdded:Connect(function()
        local newBp = player:WaitForChild("Backpack", 15)
        if newBp then WatchBackpack(newBp) end
    end)
end

-- ============================================================
--  HOOK CHAT
-- ============================================================

local function HookChat()
    if TextChatService then
        TextChatService.MessageReceived:Connect(function(msg)
            local text = msg.Text or ""
            if msg.TextSource == nil then
                CheckAndSend(text)
            else
                local senderName = msg.TextSource and msg.TextSource.Name or "Unknown"
                SendChatLog(senderName, StripTags(text))
            end
        end)
    end

    local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if chatEvents then
        local onMessage = chatEvents:FindFirstChild("OnMessageDoneFiltering")
        if onMessage then
            onMessage.OnClientEvent:Connect(function(d)
                if not (d and d.Message) then return end
                local lowerMsg = string.lower(d.Message)
                local isServer = string.find(lowerMsg, "%[server%]") or string.find(lowerMsg, "obtained")
                if isServer then
                    CheckAndSend(d.Message)
                else
                    local sender = d.FromSpeaker or d.SpeakerName or "Unknown"
                    SendChatLog(sender, StripTags(d.Message))
                end
            end)
        end
    end
end

-- ============================================================
--  START MONITORING
-- ============================================================

local function StartMonitoring()
    ServerStats.startTime = os.time()

    warn("[ Monitor ] Starting with:")
    warn("  - JOIN/LEAVE:  " .. (WEBHOOK_URL         ~= "" and "✓ SET" or "✗ EMPTY"))
    warn("  - LEADERBOARD: " .. (WEBHOOK_LEADERBOARD  ~= "" and "✓ SET" or "✗ EMPTY"))
    warn("  - FISH:        " .. (WEBHOOK_FISH         ~= "" and "✓ SET" or "✗ EMPTY"))
    warn("  - STATS:       " .. (WEBHOOK_STATS        ~= "" and "✓ SET" or "✗ EMPTY"))
    warn("  - CHAT:        " .. (WEBHOOK_CHAT         ~= "" and "✓ SET" or "✗ EMPTY"))
    warn("  - GALATAMA:    " .. (WEBHOOK_GALATAMA     ~= "" and "✓ SET" or "✗ EMPTY"))

    local allPlayers = Players:GetPlayers()
    for _, p in ipairs(allPlayers) do
        AvatarCache[p.UserId] = GetAvatarUrl(p)
        RegisterPlayer(p)
        KnownUsers[p.Name] = p.DisplayName
        WatchForFish(p)
    end

    -- Restore galatama state dari Discord setelah 3 detik
    task.spawn(function()
        task.wait(3)
        if SCRIPT_ACTIVE then RestoreGalatamaState() end
    end)

    -- Live monitor loop
    task.spawn(function()
        if SCRIPT_ACTIVE then UpdateLiveWebhook() end
        while SCRIPT_ACTIVE do
            task.wait(LIVE_MONITOR_INTERVAL)
            if SCRIPT_ACTIVE then UpdateLiveWebhook() end
        end
    end)

    HookChat()
    SendLeaderboard(false)

    -- Leaderboard loop
    task.spawn(function()
        while SCRIPT_ACTIVE do
            task.wait(LEADERBOARD_INTERVAL)
            if SCRIPT_ACTIVE then
                SendLeaderboard(false)
                if WEBHOOK_GALATAMA ~= "" then SendGalatamaLeaderboard(false) end
            end
        end
    end)

    -- Server Stats loop
    task.spawn(function()
        while SCRIPT_ACTIVE do
            task.wait(STATS_INTERVAL)
            if SCRIPT_ACTIVE then SendServerStats() end
        end
    end)

    Players.PlayerAdded:Connect(function(player)
        if not SCRIPT_ACTIVE then return end
        LeaveTimers[player.UserId] = nil
        RegisterPlayer(player)
        KnownUsers[player.Name] = player.DisplayName
        task.spawn(function()
            task.wait(1)
            AvatarCache[player.UserId] = GetAvatarUrl(player)
            SendWebhook("✅ PLAYER JOINED SERVER", nil, 65280, {
                BuildFieldContent("👤", "Player",     "**" .. player.Name .. "**",                         true),
                BuildFieldContent("👥", "Online Now", "**" .. tostring(#Players:GetPlayers()) .. "**",     true),
            }, nil, AvatarCache[player.UserId], GetMention(player.Name), "join")
        end)
        WatchForFish(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        if not SCRIPT_ACTIVE then return end

        local pName     = player.Name
        local pId       = player.UserId
        local avatarUrl = AvatarCache[pId] or GetAvatarUrl(player)
        local totalNow  = #Players:GetPlayers() - 1
        local mentionStr = GetMention(pName)

        AvatarCache[pId]                           = nil
        PlayerNameToId[pName:lower()]              = nil
        PlayerNameToId[player.DisplayName:lower()] = nil
        MentionCache[pName:lower()]                = nil
        MentionCache[player.DisplayName:lower()]   = nil
        UidToCanonicalName[pId]                    = nil

        SendWebhook("👋 PLAYER LEFT SERVER", nil, 16729344, {
            BuildFieldContent("👤", "Player",     "**" .. pName .. "**",              true),
            BuildFieldContent("👥", "Online Now", "**" .. tostring(totalNow) .. "**", true),
        }, nil, avatarUrl, mentionStr, "leave")

        LeaveTimers[pId] = true
        task.spawn(function()
            task.wait(600)
            if LeaveTimers[pId] then
                LeaveTimers[pId] = nil
                local notBackContent = BuildContent(mentionStr, "notback")
                PostWebhook(WEBHOOK_URL, {
                    username   = WEBHOOK_NAME,
                    avatar_url = WEBHOOK_AVATAR,
                    content    = notBackContent,
                    embeds = { BuildEmbed("⏰ PLAYER TIDAK KEMBALI", nil, 16711680, {
                        BuildFieldContent("👤", "Player",    "**" .. pName .. "**",           true),
                        BuildFieldContent("⏱️", "Duration", "Tidak kembali **10 menit**",    true),
                    }, nil, nil) },
                })
            end
        end)
    end)

    -- Final leaderboard saat local player disconnect
    local finalSent = false
    local function TrySendFinal()
        if finalSent or not SCRIPT_ACTIVE then return end
        finalSent = true
        SendFinalLeaderboard()
    end

    Players.LocalPlayer.AncestryChanged:Connect(function(_, parent)
        if parent == nil then TrySendFinal() end
    end)

    Players.LocalPlayer.CharacterRemoving:Connect(function()
        task.spawn(function()
            task.wait(2)
            if not Players.LocalPlayer.Parent then TrySendFinal() end
        end)
    end)
end

-- ============================================================
--  UI
-- ============================================================

local function CreateUI()
    local gui = Instance.new("ScreenGui")
    gui.Name         = "BloxGankUI"
    gui.ResetOnSpawn = false
    gui.Parent       = (gethui and gethui()) or CoreGui

    local frame = Instance.new("Frame")
    frame.Name              = "Main"
    frame.Size              = UDim2.new(0, 310, 0, 440)
    frame.Position          = UDim2.new(0.5, -155, 0.5, -220)
    frame.BackgroundColor3  = Color3.fromRGB(20, 20, 20)
    frame.BorderSizePixel   = 0
    frame.Parent            = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke")
    stroke.Color     = Color3.fromRGB(50, 50, 50)
    stroke.Thickness = 1
    stroke.Parent    = frame

    -- Top bar
    local topBar = Instance.new("Frame")
    topBar.Size             = UDim2.new(1, 0, 0, 36)
    topBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    topBar.BorderSizePixel  = 0
    topBar.Parent           = frame
    Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 8)

    local topBarFix = Instance.new("Frame")
    topBarFix.Size             = UDim2.new(1, 0, 0, 8)
    topBarFix.Position         = UDim2.new(0, 0, 1, -8)
    topBarFix.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    topBarFix.BorderSizePixel  = 0
    topBarFix.Parent           = topBar

    local title = Instance.new("TextLabel")
    title.Text                   = "🎣 Forky Monitor — Galatama"
    title.Size                   = UDim2.new(1, -80, 1, 0)
    title.Position               = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.TextColor3             = Color3.fromRGB(255, 255, 255)
    title.Font                   = Enum.Font.GothamBold
    title.TextSize               = 12
    title.TextXAlignment         = Enum.TextXAlignment.Left
    title.Parent                 = topBar

    local function MakeWinBtn(text, xOffset, bgColor)
        local btn = Instance.new("TextButton")
        btn.Text             = text
        btn.Size             = UDim2.new(0, 28, 0, 22)
        btn.Position         = UDim2.new(1, xOffset, 0.5, -11)
        btn.BackgroundColor3 = bgColor
        btn.TextColor3       = Color3.fromRGB(255, 255, 255)
        btn.Font             = Enum.Font.GothamBold
        btn.TextSize         = 12
        btn.BorderSizePixel  = 0
        btn.Parent           = topBar
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        return btn
    end

    local minBtn   = MakeWinBtn("—", -58, Color3.fromRGB(60, 60, 60))
    local closeBtn = MakeWinBtn("✕", -28, Color3.fromRGB(200, 50, 50))

    local isMinimized = false
    local fullSize    = UDim2.new(0, 310, 0, 440)
    local miniSize    = UDim2.new(0, 310, 0, 36)

    local function HoverTween(btn, hoverColor, baseColor)
        btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = hoverColor}):Play() end)
        btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = baseColor}):Play()  end)
    end

    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        TweenService:Create(frame, TweenInfo.new(0.2), {
            Size = isMinimized and miniSize or fullSize
        }):Play()
        minBtn.Text = isMinimized and "□" or "—"
    end)

    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(frame, TweenInfo.new(0.15), {
            Size = UDim2.new(0, 310, 0, 0), BackgroundTransparency = 1
        }):Play()
        task.wait(0.2); gui:Destroy()
    end)

    HoverTween(minBtn,   Color3.fromRGB(80, 80, 80),  Color3.fromRGB(60, 60, 60))
    HoverTween(closeBtn, Color3.fromRGB(230, 70, 70), Color3.fromRGB(200, 50, 50))

    -- Drag
    local dragging, dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)
    topBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Status dot & label
    local statusDot = Instance.new("Frame")
    statusDot.Size             = UDim2.new(0, 8, 0, 8)
    statusDot.Position         = UDim2.new(0, 16, 0, 46)
    statusDot.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    statusDot.BorderSizePixel  = 0
    statusDot.Parent           = frame
    Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Text                   = "Tidak Aktif"
    statusLabel.Size                   = UDim2.new(1, -40, 0, 20)
    statusLabel.Position               = UDim2.new(0, 30, 0, 38)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3             = Color3.fromRGB(180, 180, 180)
    statusLabel.Font                   = Enum.Font.Gotham
    statusLabel.TextSize               = 11
    statusLabel.TextXAlignment         = Enum.TextXAlignment.Left
    statusLabel.Parent                 = frame

    local function MakeLabel(text, yPos)
        local lbl = Instance.new("TextLabel")
        lbl.Text                   = text
        lbl.Size                   = UDim2.new(1, -24, 0, 14)
        lbl.Position               = UDim2.new(0, 12, 0, yPos)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3             = Color3.fromRGB(130, 130, 130)
        lbl.Font                   = Enum.Font.Gotham
        lbl.TextSize               = 10
        lbl.TextXAlignment         = Enum.TextXAlignment.Left
        lbl.Parent                 = frame
        return lbl
    end

    local function MakeInput(placeholder, yPos)
        local box = Instance.new("TextBox")
        box.PlaceholderText   = placeholder
        box.Size              = UDim2.new(1, -24, 0, 28)
        box.Position          = UDim2.new(0, 12, 0, yPos)
        box.BackgroundColor3  = Color3.fromRGB(35, 35, 35)
        box.TextColor3        = Color3.fromRGB(220, 220, 220)
        box.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
        box.Font              = Enum.Font.Gotham
        box.TextSize          = 10
        box.ClearTextOnFocus  = false
        box.BorderSizePixel   = 0
        box.Text              = ""
        box.TextXAlignment    = Enum.TextXAlignment.Left
        box.ClipsDescendants  = true
        box.Parent            = frame
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
        local pad = Instance.new("UIPadding", box)
        pad.PaddingLeft  = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)
        return box
    end

    local function MakeButton(text, yPos, w, xPos, bg)
        local btn = Instance.new("TextButton")
        btn.Text             = text
        btn.Size             = w or UDim2.new(1, -24, 0, 32)
        btn.Position         = xPos or UDim2.new(0, 12, 0, yPos)
        btn.BackgroundColor3 = bg or Color3.fromRGB(0, 180, 100)
        btn.TextColor3       = Color3.fromRGB(255, 255, 255)
        btn.Font             = Enum.Font.GothamBold
        btn.TextSize         = 11
        btn.BorderSizePixel  = 0
        btn.Parent           = frame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        return btn
    end

    -- Inputs
    MakeLabel("✅ Webhook dari script (sudah diset)", 62)
    local infoBox = Instance.new("TextLabel")
    infoBox.Text                   = "Webhook utama sudah terpasang di dalam skrip."
    infoBox.Size                   = UDim2.new(1, -24, 0, 28)
    infoBox.Position               = UDim2.new(0, 12, 0, 76)
    infoBox.BackgroundTransparency = 1
    infoBox.TextColor3             = Color3.fromRGB(160, 160, 160)
    infoBox.Font                   = Enum.Font.Gotham
    infoBox.TextSize               = 10
    infoBox.TextWrapped            = true
    infoBox.TextXAlignment         = Enum.TextXAlignment.Left
    infoBox.Parent                 = frame

    MakeLabel("🏅 Webhook Galatama (opsional)", 110)
    local inputGalatama = MakeInput("Paste webhook khusus Galatama...", 124)

    MakeLabel("🤖 Bot Token (untuk restore point)", 160)
    local inputToken = MakeInput("Paste Bot Token...", 174)

    MakeLabel("📌 Channel ID Galatama (save/restore)", 208)
    local inputChannel = MakeInput("Paste Channel ID...", 222)

    MakeLabel("🔔 Discord Role ID (opsional)", 256)
    local inputRole = MakeInput("Masukkan Role ID...", 270)

    -- START button
    local startBtn = MakeButton("START MONITORING", 308, nil, nil, Color3.fromRGB(0, 180, 100))
    HoverTween(startBtn, Color3.fromRGB(0, 210, 120), Color3.fromRGB(0, 180, 100))

    -- Post-start buttons (awalnya hidden)
    local editBtn = MakeButton(
        "✏️ EDIT WEBHOOK",
        352,
        UDim2.new(0.5, -14, 0, 28),
        UDim2.new(0, 12, 0, 352),
        Color3.fromRGB(60, 100, 180)
    )
    editBtn.TextSize = 10
    editBtn.Visible  = false
    HoverTween(editBtn, Color3.fromRGB(80, 130, 210), Color3.fromRGB(60, 100, 180))

    local galaBtn = MakeButton(
        "🏅 LB GALATAMA",
        352,
        UDim2.new(0.5, -14, 0, 28),
        UDim2.new(0.5, 2, 0, 352),
        Color3.fromRGB(160, 100, 0)
    )
    galaBtn.TextSize = 10
    galaBtn.Visible  = false
    HoverTween(galaBtn, Color3.fromRGB(200, 130, 0), Color3.fromRGB(160, 100, 0))

    local lbBtn = MakeButton(
        "📊 LB SECRET",
        388,
        UDim2.new(1, -24, 0, 28),
        UDim2.new(0, 12, 0, 388),
        Color3.fromRGB(50, 120, 60)
    )
    lbBtn.TextSize = 10
    lbBtn.Visible  = false
    HoverTween(lbBtn, Color3.fromRGB(70, 160, 80), Color3.fromRGB(50, 120, 60))

    -- Galatama LB button
    galaBtn.MouseButton1Click:Connect(function()
        if not SCRIPT_ACTIVE then return end
        galaBtn.Text = "⏳ Mengirim..."
        SendGalatamaLeaderboard(false)
        task.wait(2)
        galaBtn.Text = "🏅 LB GALATAMA"
    end)

    -- Secret LB button
    lbBtn.MouseButton1Click:Connect(function()
        if not SCRIPT_ACTIVE then return end
        lbBtn.Text = "⏳ Mengirim..."
        SendLeaderboard(false)
        task.wait(2)
        lbBtn.Text = "📊 LB SECRET"
    end)

    -- Edit webhook toggle
    local isEditing = false
    local allInputs = { inputGalatama, inputToken, inputChannel, inputRole }

    editBtn.MouseButton1Click:Connect(function()
        if not SCRIPT_ACTIVE then return end
        isEditing = not isEditing
        if isEditing then
            for _, box in ipairs(allInputs) do
                box.TextEditable     = true
                box.BackgroundColor3 = Color3.fromRGB(50, 50, 30)
            end
            editBtn.Text             = "💾 SIMPAN"
            editBtn.BackgroundColor3 = Color3.fromRGB(180, 140, 0)
        else
            if inputGalatama.Text ~= "" and inputGalatama.Text:find("discord.com/api/webhooks") then
                WEBHOOK_GALATAMA = inputGalatama.Text
            end
            if inputToken.Text   ~= "" then BOT_TOKEN       = inputToken.Text   end
            if inputChannel.Text ~= "" then SAVE_CHANNEL_ID = inputChannel.Text end
            if inputRole.Text    ~= "" then DISCORD_ROLE_ID = inputRole.Text    end
            for _, box in ipairs(allInputs) do
                box.TextEditable     = false
                box.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            end
            editBtn.Text             = "✏️ EDIT WEBHOOK"
            editBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 180)
            PostWebhook(WEBHOOK_URL ~= "" and WEBHOOK_URL or WEBHOOK_STATS, {
                username   = WEBHOOK_NAME,
                avatar_url = WEBHOOK_AVATAR,
                embeds = { BuildEmbed("⚙️ KONFIGURASI DIPERBARUI", nil, 16776960, {
                    BuildFieldContent("ℹ️", "Info", "Webhook & config berhasil diubah.", false),
                }, nil, nil) },
            })
        end
    end)

    -- START button
    startBtn.MouseButton1Click:Connect(function()
        if SCRIPT_ACTIVE then return end

        if not WEBHOOK_URL or not WEBHOOK_URL:find("discord.com/api/webhooks") then
            startBtn.Text             = "❌ WEBHOOK SCRIPT INVALID!"
            startBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            task.wait(2)
            startBtn.Text             = "START MONITORING"
            startBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
            return
        end

        if inputGalatama.Text ~= "" and inputGalatama.Text:find("discord.com/api/webhooks") then
            WEBHOOK_GALATAMA = inputGalatama.Text
        end
        if inputToken.Text   ~= "" then BOT_TOKEN       = inputToken.Text   end
        if inputChannel.Text ~= "" then SAVE_CHANNEL_ID = inputChannel.Text end
        if inputRole.Text    ~= "" then DISCORD_ROLE_ID = inputRole.Text    end

        SCRIPT_ACTIVE = true
        statusDot.BackgroundColor3  = Color3.fromRGB(0, 220, 100)
        statusLabel.Text            = "Aktif — Monitoring Galatama..."
        statusLabel.TextColor3      = Color3.fromRGB(0, 220, 100)
        startBtn.Text               = "✅ MONITORING AKTIF"
        startBtn.BackgroundColor3   = Color3.fromRGB(30, 30, 30)

        for _, box in ipairs(allInputs) do box.TextEditable = false end
        editBtn.Visible = true
        galaBtn.Visible = true
        lbBtn.Visible   = true

        StartMonitoring()
    end)
end

-- ============================================================
--  INIT
-- ============================================================

CreateUI()
