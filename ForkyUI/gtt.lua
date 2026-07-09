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
local SCRIPT_ACTIVE         = false

-- Per-webhook identity (nama + avatar masing-masing)
local WH_IDENTITY = {
    url       = { name = "ForkyHUB — Join/Leave",    avatar = "https://www.image2url.com/r2/default/images/1777666815405-eb5a3d95-9946-4914-b8aa-985e8f672557.png" },
    stats     = { name = "ForkyHUB — Server Stats",  avatar = "https://www.image2url.com/r2/default/images/1777666815405-eb5a3d95-9946-4914-b8aa-985e8f672557.png" },
    lb        = { name = "ForkyHUB — Leaderboard",   avatar = "https://www.image2url.com/r2/default/images/1777666815405-eb5a3d95-9946-4914-b8aa-985e8f672557.png" },
    fish      = { name = "ForkyHUB — Secret Fish",   avatar = "https://www.image2url.com/r2/default/images/1777666815405-eb5a3d95-9946-4914-b8aa-985e8f672557.png" },
    chat      = { name = "ForkyHUB — Chat Log",      avatar = "https://www.image2url.com/r2/default/images/1777666815405-eb5a3d95-9946-4914-b8aa-985e8f672557.png" },
    galatama  = { name = "ForkyHUB — Galatama",      avatar = "https://www.image2url.com/r2/default/images/1777666815405-eb5a3d95-9946-4914-b8aa-985e8f672557.png" },
    event     = { name = "ForkyHUB — Event Hunt",    avatar = "https://www.image2url.com/r2/default/images/1777666815405-eb5a3d95-9946-4914-b8aa-985e8f672557.png" },
}

-- Alias compat (masih dipakai di beberapa tempat)
local WEBHOOK_NAME   = WH_IDENTITY.url.name
local WEBHOOK_AVATAR = WH_IDENTITY.url.avatar

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
--  EVENT HUNT DATABASE
-- ============================================================

local EVENT_COOLDOWN_SECONDS = 120

local EventHuntData = {
    {
        textTriggers = { "treasure hunt" },
        title        = "💰 Treasure Hunt Dimulai!",
        description  = "katakan Peta 🗺️",
        color        = 16766720,
        emoji        = "💰",
    },
    {
        textTriggers = { "dark megalodon hunt", "dark megalodon" },
        title        = "🌑 Dark Megalodon Hunt Dimulai!",
        description  = "Dark Mega guys 🦈",
        color        = 2303786,
        emoji        = "🌑",
    },
    {
        textTriggers = { "megalodon hunt" },
        title        = "🦈 Megalodon Hunt Dimulai!",
        description  = "Mega guys 🎣",
        color        = 3447003,
        emoji        = "🦈",
    },
    {
        textTriggers = { "thunderzilla hunt", "thunderzilla" },
        title        = "⚡ Thunderzilla Hunt Dimulai!",
        description  = "zilla oi ⚡",
        color        = 16776960,
        emoji        = "⚡",
    },
    {
        textTriggers = { "crystals have spawned", "crystals have", "crystal" },
        title        = "💎 Crystal Event Dimulai!",
        description  = "Crystal muncul gas nambang 💎",
        color        = 1146986,
        emoji        = "💎",
    },
    {
        textTriggers = { "aurora borealis", "aurora event" },
        title        = "💫 Aurora Borealis!",
        description  = "cantiknyooo 💫",
        color        = 9055202,
        emoji        = "💫",
    },
}

local EventCooldown = {}

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
        username   = WH_IDENTITY.stats.name,
        avatar_url = WH_IDENTITY.stats.avatar,
        embeds = {{ title = "📡 ForkyHUB — Live Server Monitor", description = description, color = color, fields = fields,
            footer = { text = "ForkyHUB — Server Stats | Last Update" },
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
    "Sea Eater", "Thunderzilla", "Iridesca", "Frostbite Leviathan", "Fluorivane",
    "Cerulean Dragon", "Machodon", "Scorching Veinmaw", "Crystalline Behemoth",
    "Frostmoon Whale", "Crystal Goliath", "Eggy Enchant Stone", "Dark Megalodon", "Elemental Tempestray",
}

local ForgottenList = {
    "Sea Eater", "Thunderzilla", "Iridesca", "Frostbite Leviathan", "Fluorivane", "Cerulean Dragon","Crystalline Behemoth",
}

local MutasiList = {
    "Noob", "Fairy Dust", "Holographic", "Gemstone", "Fire", "Color Burn", "Frozen",
    "Galaxy", "BloodMoon", "Binary", "Lightning", "Disco", "Festive", "Radioactive", "Moon Fragment",
}

local LegendaryCrystalList = {
    "Blue Sea Dragon", "Star Snail", "Cute Dumbo", "Blossom Jelly", "Bioluminescent Octopus",
}

local FishChanceData = {
    ["Crystal Crab"]              = "1 in 750K",
    ["Orca"]                      = "1 in 1.5M",
    ["Zombie Shark"]              = "1 in 250K",
    ["Zombie Megalodon"]          = "1 in 4M",
    ["Dead Zombie Shark"]         = "1 in 500K",
    ["Blob Shark"]                = "1 in 250K",
    ["Ghost Shark"]               = "1 in 500K",
    ["Skeleton Narwhal"]          = "1 in 600K",
    ["Ghost Worm Fish"]           = "1 in 1M",
    ["Worm Fish"]                 = "1 in 3M",
    ["Megalodon"]                 = "1 in 4M",
    ["1x1x1x1 Comet Shark"]       = "1 in 4M",
    ["Bloodmoon Whale"]           = "1 in 5M",
    ["Lochness Monster"]          = "1 in 3M",
    ["Monster Shark"]             = "1 in 2.5M",
    ["Eerie Shark"]               = "1 in 250K",
    ["Great Whale"]               = "1 in 900K",
    ["Frostborn Shark"]           = "1 in 500K",
    ["Thin Armor Shark"]          = "1 in 300K",
    ["Scare"]                     = "1 in 3M",
    ["Queen Crab"]                = "1 in 800K",
    ["King Crab"]                 = "1 in 1.2M",
    ["Cryoshade Glider"]          = "1 in 450K",
    ["Panther Eel"]               = "1 in 750K",
    ["Giant Squid"]               = "1 in 800K",
    ["Depthseeker Ray"]           = "1 in 1.2M",
    ["Robot Kraken"]              = "1 in 3.5M",
    ["Mosasaur Shark"]            = "1 in 800K",
    ["King Jelly"]                = "1 in 1.5M",
    ["Bone Whale"]                = "1 in 2M",
    ["Elshark Gran Maja"]         = "1 in 4M",
    ["Elpirate Gran Maja"]        = "1 in 4M",
    ["ElRetro Gran Maja"]         = "1 in 4M",
    ["Ancient Whale"]             = "1 in 2.75M",
    ["Gladiator Shark"]           = "1 in 1M",
    ["Ancient Lochness Monster"]  = "1 in 3M",
    ["Talon Serpent"]             = "1 in 3M",
    ["Hacker Shark"]              = "1 in 2M",
    ["Strawberry Choc Megalodon"] = "1 in 4M",
    ["Krampus Shark"]             = "1 in 1M",
    ["Emerald Winter Whale"]      = "1 in 1.5M",
    ["Winter Frost Shark"]        = "1 in 3M",
    ["Icebreaker Whale"]          = "1 in 4M",
    ["Cursed Kraken"]             = "1 in 3M",
    ["Pirate Megalodon"]          = "1 in 4M",
    ["Leviathan"]                 = "1 in 5M",
    ["Viridis Lurker"]            = "1 in 1.4M",
    ["Ancient Magma Whale"]       = "1 in 5M",
    ["Mutant Runic Koi"]          = "1 in ??",
    ["Cosmic Mutant Shark"]       = "1 in 2M",
    ["Strawberry Orca"]           = "1 in 3M",
    ["Bonemaw Tyrant"]            = "1 in 2.5M",
    ["Rainbow Comet Shark"]       = "1 in ??",
    ["Love Nessie"]               = "1 in ??",
    ["Broken Heart Nessie"]       = "1 in ??",
    ["Sea Eater"]                 = "1 in 25M",
    ["Thunderzilla"]              = "1 in 30M",
    ["Iridesca"]                  = "1 in 25M",
    ["Eggy Enchant Stone"]        = "1 in 100K",
    ["Deepsea Monster Axolotl"]   = "1 in 2M",
    ["Blocky Lochness Monster"]   = "1 in 3M",
    ["Frostbite Leviathan"]       = "1 in 12M",
    ["Aurelion"]                  = "1 in 3M",
    ["Runic Enchant Stone"]       = "1 in 1.5M",
    ["Frogalloon"]                = "1 in 1.5M",
    ["Fluorivane"]                = "1 in 15M",
    ["Coral Whale"]               = "1 in 2M",
    ["Flame Tyrant"]              = "1 in 5M",
    ["Cerulean Dragon"]           = "1 in 25M",
    ["Withering Core"]            = "1 in 3M",
    ["Machodon"]                  = "1 in 10M",
    ["Crystalline Behemoth"]      = "1 in 20M",
    ["Frostmoon Whale"]           = "1 in 5M",
    ["Crystal Goliath"]           = "1 in 3M",
    ["Ketupat Whale"]             = "1 in ??",
    ["Scorching Veinmaw"]         = "1 in 5M",
    [""]                          = "1 in 3M",
    ["Elemental Tempestray"]      = "1 in 1M",
    ["Dark Megalodon"]            = "1 in 8M",
    
}

local NP = "https://raw.githubusercontent.com/revkatomy-max/new-pisit-image/main/"
local AI = "https://raw.githubusercontent.com/revkatomy-max/asset-id/main/"
local PI = "https://raw.githubusercontent.com/revkatomy-max/pisit-image/main/"

local FishImageURL = {
    -- new-pisit-image repo (kualitas lebih baik)
    ["Frostborn Shark"]          = NP .. "9.png",
    ["Crystalline Behemoth"]     = NP .. "10.png",
    ["Crystal Goliath"]          = NP .. "11.png",
    ["Elemental Tempestray"]     = NP .. "13.png",
    ["Dark Megalodon"]           = NP .. "14.png",
    ["Withering Core"]           = NP .. "16.png",
    ["Flame Tyrant"]             = NP .. "17.png",
    ["Scorching Veinmaw"]        = NP .. "18.png",
    ["Cerulean Dragon"]          = NP .. "19.png",
    ["King Crab"]                = NP .. "21.png",
    ["Queen Crab"]               = NP .. "22.png",
    ["Panther Eel"]              = NP .. "23.png",
    ["Cryoshade Glider"]         = NP .. "24.png",
    ["Giant Squid"]              = NP .. "25.png",
    ["Depthseeker Ray"]          = NP .. "26.png",
    ["Robot Kraken"]             = NP .. "27.png",
    ["Ghost Shark"]              = NP .. "29.png",
    ["Skeleton Narwhal"]         = NP .. "30.png",
    ["Blob Shark"]               = NP .. "31.png",
    ["Worm Fish"]                = NP .. "32.png",
    ["Cosmic Mutant Shark"]      = NP .. "33.png",
    ["Megalodon"]                = NP .. "34.png",
    ["Bloodmoon Whale"]          = NP .. "36.png",
    ["Frostmoon Whale"]          = NP .. "37.png",
    ["Thunderzilla"]             = NP .. "38.png",
    ["Thin Armor Shark"]         = NP .. "40.png",
    ["Scare"]                    = NP .. "41.png",
    ["Lochness Monster"]         = NP .. "43.png",
    ["Ancient Magma Whale"]      = NP .. "44.png",
    ["Crystal Crab"]             = NP .. "46.png",
    ["Orca"]                     = NP .. "47.png",
    ["Eerie Shark"]              = NP .. "49.png",
    ["Monster Shark"]            = NP .. "50.png",
    ["Eggy Enchant Stone"]       = NP .. "52.png",
    ["Strawberry Orca"]          = NP .. "53.png",
    ["Iridesca"]                 = NP .. "54.png",
    ["Frogalloon"]               = NP .. "56.png",
    ["Blocky Lochness Monster"]  = NP .. "57.png",
    ["Aurelion"]                 = NP .. "58.png",
    ["Frostbite Leviathan"]      = NP .. "59.png",
    ["Runic Enchant Stone"]      = NP .. "61.png",
    ["Bonemaw Tyrant"]           = NP .. "00.png",
    ["Mutant Runic Koi"]         = NP .. "62.png",
    ["Deepsea Monster Axolotl"]  = NP .. "63.png",
    ["Fluorivane"]               = NP .. "64.png",
    ["Sea Eater"]                = NP .. "65.png",
    ["Pirate Megalodon"]         = NP .. "67.png",
    ["Elpirate Gran Maja"]       = NP .. "68.png",
    ["Cursed Kraken"]            = NP .. "69.png",
    ["Mosasaur Shark"]           = NP .. "71.png",
    ["King Jelly"]               = NP .. "72.png",
    ["Gladiator Shark"]          = NP .. "75.png",
    ["Ancient Lochness Monster"] = NP .. "76.png",
    ["Elshark Gran Maja"]        = NP .. "77.png",
    ["Viridis Lurker"]           = NP .. "78.png",
    ["Bone Whale"]               = NP .. "79.png",
    ["Ancient Whale"]            = NP .. "80.png",
    ["Great Whale"]              = NP .. "82.png",
    ["Coral Whale"]              = NP .. "83.png",
    ["Love Nessie"]              = NP .. "85.png",
    ["Broken Heart Nessie"]      = NP .. "86.png",
    ["Ketupat Whale"]            = AI .. "Ketupat%20Whale.png",
    ["Leviathan"]                = AI .. "Leviathan.png",
    ["Rainbow Comet Shark"]      = AI .. "Rainbow%20Comet%20Shark.png",
    ["Ruby"]                     = PI .. "1.png",
    ["Glacial Serpent"]          = AI .. "SC%20baru.png",
    ["Machodon"]                 = PI .. "42.png",
    ["Crystal"]                  = NP .. "crystal.png",
    ["treasure hunt"]            = NP .. "treasure.png",
    ["Caustic Maw"]              = NP .. "97.png",
    ["Aurora"]                   = NP .. "99.png",
    ["Coral Reaper"]             = NP .. "Coral%20Reaper.png",
    ["Trench Warden"]            = NP .. "Trench%20Warden.png",
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
local GalatamaMsgRef    = { nil }

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
        footer      = { text = (footerTag or "ForkyHUB") .. " | " .. os.date("%X") },
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
        username   = WH_IDENTITY.url.name,
        avatar_url = WH_IDENTITY.url.avatar,
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
        username   = WH_IDENTITY.fish.name,
        avatar_url = WH_IDENTITY.fish.avatar,
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
                    username   = WH_IDENTITY.galatama.name,
                    avatar_url = WH_IDENTITY.galatama.avatar,
                    embeds = { BuildEmbed(
                        "♻️ DATA GALATAMA DIPULIHKAN",
                        "Point **" .. restoredCount .. "** pemain berhasil di-restore dari sesi sebelumnya.",
                        3066993, {}, nil, nil, "ForkyHUB — Galatama"
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
        username   = WH_IDENTITY.lb.name,
        avatar_url = WH_IDENTITY.lb.avatar,
        content    = contentMsg,
        embeds     = { BuildEmbed(title, description, 16766720, fields, nil, nil, "ForkyHUB — Leaderboard") },
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

    local body = {
        username   = WH_IDENTITY.galatama.name,
        avatar_url = WH_IDENTITY.galatama.avatar,
        content    = contentMsg,
        embeds     = { BuildEmbed(title,
            "```\nBlob Shark=25 | Ghost Shark=50 | Skeleton Narwhal=60 | Worm Fish=300 | Megalodon=400\nBonus Mutasi (kecuali Big & Shiny): +100pts\n```",
            16766720, fields, nil, nil, "ForkyHUB — Galatama") },
    }

    if isFinal then
        -- Final: kirim pesan baru (bukan edit) biar ada mention role
        PostWebhook(url, body)
        GalatamaMsgRef[1] = nil  -- reset supaya sesi berikutnya mulai fresh
    else
        -- Update: edit pesan yang sama, tidak spam
        PatchOrPostWebhook(url, body, GalatamaMsgRef, nil)
    end
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
        username   = WH_IDENTITY.stats.name,
        avatar_url = WH_IDENTITY.stats.avatar,
        embeds     = { BuildEmbed("📊 SERVER STATS", nil, 3447003, fields, nil, nil, "ForkyHUB — Server Stats") },
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
        username   = WH_IDENTITY.chat.name,
        avatar_url = WH_IDENTITY.chat.avatar,
        embeds = { BuildEmbed("💬 CHAT LOG", nil, 5793266, {
            BuildFieldContent("👤", "Player",  "**" .. displaySender .. "**", true),
            BuildFieldContent("💬", "Message", message,                        false),
        }, nil, thumbUrl, "ForkyHUB — Chat Log") },
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
--  EVENT HUNT DETECTION
-- ============================================================

local function SendEventWebhook(eventData)
    local url = (WEBHOOK_URL ~= "") and WEBHOOK_URL or ""
    if url == "" then return end
    local roleMent = DISCORD_ROLE_ID ~= "" and ("<@&" .. DISCORD_ROLE_ID .. ">") or nil
    PostWebhook(url, {
        username   = WH_IDENTITY.event.name,
        avatar_url = WH_IDENTITY.event.avatar,
        content    = roleMent and (roleMent .. " 📢 **Event dimulai!**") or nil,
        embeds = { BuildEmbed(
            eventData.title,
            eventData.description,
            eventData.color,
            {
                BuildFieldContent("🎣", "Host Server",   "**" .. Players.LocalPlayer.Name .. "**",              true),
                BuildFieldContent("👥", "Total Player",  "**" .. tostring(#Players:GetPlayers()) .. "** orang", true),
                BuildFieldContent("🕐", "Waktu Mulai",   os.date("%H:%M:%S"),                                   true),
            },
            nil, nil, "ForkyHUB — Event Hunt"
        )},
    })
end

local function ProcessEventText(text)
    if not SCRIPT_ACTIVE then return end
    if not text or text == "" then return end
    local lower = text:lower()

    local isRelevant = lower:find("hunt") or lower:find("started") or lower:find("crystal")
        or lower:find("spawned") or lower:find("aurora")
    if not isRelevant then return end

    for _, evData in ipairs(EventHuntData) do
        for _, trigger in ipairs(evData.textTriggers) do
            if lower:find(trigger, 1, true) then
                local now = os.time()
                if (now - (EventCooldown[evData.title] or 0)) >= EVENT_COOLDOWN_SECONDS then
                    EventCooldown[evData.title] = now
                    SendEventWebhook(evData)
                end
                return
            end
        end
    end
end

local _hookedLabels = {}

local function HookLabel(label)
    if _hookedLabels[label] then return end
    _hookedLabels[label] = true
    ProcessEventText(label.Text)
    label:GetPropertyChangedSignal("Text"):Connect(function()
        ProcessEventText(label.Text)
    end)
end

local function StartEventMonitor()
    task.spawn(function()
        local pg = Players.LocalPlayer:WaitForChild("PlayerGui", 30)
        if not pg then return end
        for _, v in ipairs(pg:GetDescendants()) do
            if v:IsA("TextLabel") or v:IsA("TextButton") then HookLabel(v) end
        end
        pg.DescendantAdded:Connect(function(v)
            if v:IsA("TextLabel") or v:IsA("TextButton") then
                task.wait(0)
                HookLabel(v)
            end
        end)
    end)
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
    StartEventMonitor()
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
                    username   = WH_IDENTITY.url.name,
                    avatar_url = WH_IDENTITY.url.avatar,
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
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent       = (gethui and gethui()) or CoreGui

    -- ── Helpers ────────────────────────────────────────────────
    local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
    local function corner(p,r) Instance.new("UICorner",p).CornerRadius = UDim.new(0,r) end
    local function stroke(p,c,t) local s=Instance.new("UIStroke",p); s.Color=c; s.Thickness=t; return s end
    local function pad(p,l,r,t,b)
        local u=Instance.new("UIPadding",p)
        u.PaddingLeft=UDim.new(0,l); u.PaddingRight=UDim.new(0,r)
        u.PaddingTop=UDim.new(0,t);  u.PaddingBottom=UDim.new(0,b)
    end
    local function grad(p,c0,c1,r)
        local g=Instance.new("UIGradient",p)
        g.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,c0),ColorSequenceKeypoint.new(1,c1)}
        g.Rotation=r or 90
    end

    -- Palette
    local C = {
        bg       = rgb(8,12,18),
        panel    = rgb(13,20,30),
        surface  = rgb(18,28,42),
        border   = rgb(30,50,70),
        accent   = rgb(0,200,180),
        accentDim= rgb(0,140,120),
        green    = rgb(0,210,110),
        red      = rgb(220,60,60),
        amber    = rgb(220,160,0),
        blue     = rgb(60,130,220),
        text     = rgb(220,235,245),
        subtext  = rgb(120,155,180),
        dim      = rgb(70,100,130),
        input    = rgb(12,22,35),
    }

    -- ── Shadow (outer glow) ────────────────────────────────────
    local shadow = Instance.new("Frame")
    shadow.Size              = UDim2.new(0, 336, 0, 472)
    shadow.Position          = UDim2.new(0.5, -168, 0.5, -236)
    shadow.BackgroundColor3  = rgb(0,180,160)
    shadow.BackgroundTransparency = 0.88
    shadow.BorderSizePixel   = 0
    shadow.ZIndex            = 0
    shadow.Parent            = gui
    corner(shadow, 14)

    -- ── Main frame ─────────────────────────────────────────────
    local frame = Instance.new("Frame")
    frame.Name              = "Main"
    frame.Size              = UDim2.new(0, 330, 0, 462)
    frame.Position          = UDim2.new(0.5, -165, 0.5, -231)
    frame.BackgroundColor3  = C.bg
    frame.BorderSizePixel   = 0
    frame.ZIndex            = 1
    frame.Parent            = gui
    corner(frame, 12)
    stroke(frame, C.border, 1)

    -- subtle top accent line
    local accentLine = Instance.new("Frame")
    accentLine.Size             = UDim2.new(0.6, 0, 0, 2)
    accentLine.Position         = UDim2.new(0.2, 0, 0, 0)
    accentLine.BackgroundColor3 = C.accent
    accentLine.BorderSizePixel  = 0
    accentLine.ZIndex           = 2
    accentLine.Parent           = frame
    corner(accentLine, 2)
    grad(accentLine, rgb(0,0,0), C.accent, 0)

    -- ── Top bar ────────────────────────────────────────────────
    local topBar = Instance.new("Frame")
    topBar.Size             = UDim2.new(1, 0, 0, 42)
    topBar.BackgroundColor3 = C.panel
    topBar.BorderSizePixel  = 0
    topBar.ZIndex           = 2
    topBar.Parent           = frame
    corner(topBar, 12)

    local topBarFix = Instance.new("Frame")
    topBarFix.Size             = UDim2.new(1, 0, 0, 12)
    topBarFix.Position         = UDim2.new(0, 0, 1, -12)
    topBarFix.BackgroundColor3 = C.panel
    topBarFix.BorderSizePixel  = 0
    topBarFix.ZIndex           = 2
    topBarFix.Parent           = topBar

    -- logo dot
    local logoDot = Instance.new("Frame")
    logoDot.Size             = UDim2.new(0, 8, 0, 8)
    logoDot.Position         = UDim2.new(0, 14, 0.5, -4)
    logoDot.BackgroundColor3 = C.accent
    logoDot.BorderSizePixel  = 0
    logoDot.ZIndex           = 3
    logoDot.Parent           = topBar
    corner(logoDot, 99)

    local title = Instance.new("TextLabel")
    title.Text                   = "ForkyHUB  ·  Galatama Monitor"
    title.Size                   = UDim2.new(1, -100, 1, 0)
    title.Position               = UDim2.new(0, 28, 0, 0)
    title.BackgroundTransparency = 1
    title.TextColor3             = C.text
    title.Font                   = Enum.Font.GothamBold
    title.TextSize               = 11
    title.TextXAlignment         = Enum.TextXAlignment.Left
    title.ZIndex                 = 3
    title.Parent                 = topBar

    local function MakeWinBtn(sym, xOff, bg, hov)
        local b = Instance.new("TextButton")
        b.Text             = sym
        b.Size             = UDim2.new(0, 26, 0, 20)
        b.Position         = UDim2.new(1, xOff, 0.5, -10)
        b.BackgroundColor3 = bg
        b.TextColor3       = C.text
        b.Font             = Enum.Font.GothamBold
        b.TextSize         = 11
        b.BorderSizePixel  = 0
        b.ZIndex           = 3
        b.Parent           = topBar
        corner(b, 5)
        b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.12),{BackgroundColor3=hov}):Play() end)
        b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.12),{BackgroundColor3=bg}):Play() end)
        return b
    end

    local minBtn   = MakeWinBtn("—", -60, rgb(28,42,58), rgb(45,65,85))
    local closeBtn = MakeWinBtn("✕", -30, rgb(28,42,58), rgb(200,55,55))

    local isMinimized = false
    local fullSize    = UDim2.new(0, 330, 0, 462)
    local miniSize    = UDim2.new(0, 330, 0, 42)

    minBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        TweenService:Create(frame, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {
            Size = isMinimized and miniSize or fullSize
        }):Play()
        TweenService:Create(shadow, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {
            Size = isMinimized and UDim2.new(0,336,0,52) or UDim2.new(0,336,0,472)
        }):Play()
        minBtn.Text = isMinimized and "□" or "—"
    end)

    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(frame, TweenInfo.new(0.18), {Size=UDim2.new(0,330,0,0), BackgroundTransparency=1}):Play()
        TweenService:Create(shadow, TweenInfo.new(0.18), {BackgroundTransparency=1}):Play()
        task.wait(0.2); gui:Destroy()
    end)

    -- Drag
    local dragging, dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging=true; dragStart=input.Position; startPos=frame.Position
        end
    end)
    topBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging=false end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
            shadow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X-3, startPos.Y.Scale, startPos.Y.Offset+d.Y-3)
        end
    end)

    -- ── Status pill ────────────────────────────────────────────
    local statusPill = Instance.new("Frame")
    statusPill.Size             = UDim2.new(1, -24, 0, 30)
    statusPill.Position         = UDim2.new(0, 12, 0, 50)
    statusPill.BackgroundColor3 = C.surface
    statusPill.BorderSizePixel  = 0
    statusPill.ZIndex           = 2
    statusPill.Parent           = frame
    corner(statusPill, 8)
    stroke(statusPill, C.border, 1)

    local statusDot = Instance.new("Frame")
    statusDot.Size             = UDim2.new(0, 7, 0, 7)
    statusDot.Position         = UDim2.new(0, 12, 0.5, -3)
    statusDot.BackgroundColor3 = C.red
    statusDot.BorderSizePixel  = 0
    statusDot.ZIndex           = 3
    statusDot.Parent           = statusPill
    corner(statusDot, 99)

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Text                   = "Tidak Aktif"
    statusLabel.Size                   = UDim2.new(1, -30, 1, 0)
    statusLabel.Position               = UDim2.new(0, 26, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3             = C.subtext
    statusLabel.Font                   = Enum.Font.Gotham
    statusLabel.TextSize               = 10
    statusLabel.TextXAlignment         = Enum.TextXAlignment.Left
    statusLabel.ZIndex                 = 3
    statusLabel.Parent                 = statusPill

    -- ── Input helper ───────────────────────────────────────────
    local function MakeSection(labelText, yPos)
        local lbl = Instance.new("TextLabel")
        lbl.Text                   = labelText
        lbl.Size                   = UDim2.new(1, -24, 0, 13)
        lbl.Position               = UDim2.new(0, 12, 0, yPos)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3             = C.dim
        lbl.Font                   = Enum.Font.GothamBold
        lbl.TextSize               = 9
        lbl.TextXAlignment         = Enum.TextXAlignment.Left
        lbl.ZIndex                 = 2
        lbl.Parent                 = frame
    end

    local function MakeInput(placeholder, yPos)
        local box = Instance.new("TextBox")
        box.PlaceholderText   = placeholder
        box.Size              = UDim2.new(1, -24, 0, 30)
        box.Position          = UDim2.new(0, 12, 0, yPos)
        box.BackgroundColor3  = C.input
        box.TextColor3        = C.text
        box.PlaceholderColor3 = C.dim
        box.Font              = Enum.Font.Gotham
        box.TextSize          = 10
        box.ClearTextOnFocus  = false
        box.BorderSizePixel   = 0
        box.Text              = ""
        box.TextXAlignment    = Enum.TextXAlignment.Left
        box.ClipsDescendants  = true
        box.ZIndex            = 2
        box.Parent            = frame
        corner(box, 7)
        stroke(box, C.border, 1)
        pad(box, 10, 10, 0, 0)
        -- focus glow
        box.Focused:Connect(function()
            TweenService:Create(box,TweenInfo.new(0.15),{BackgroundColor3=rgb(16,30,46)}):Play()
        end)
        box.FocusLost:Connect(function()
            TweenService:Create(box,TweenInfo.new(0.15),{BackgroundColor3=C.input}):Play()
        end)
        return box
    end

    local function MakeBtn(text, yPos, sz, xp, bg, hov)
        local b = Instance.new("TextButton")
        b.Text             = text
        b.Size             = sz  or UDim2.new(1,-24,0,34)
        b.Position         = xp  or UDim2.new(0,12,0,yPos)
        b.BackgroundColor3 = bg  or C.green
        b.TextColor3       = rgb(240,255,250)
        b.Font             = Enum.Font.GothamBold
        b.TextSize         = 11
        b.BorderSizePixel  = 0
        b.ZIndex           = 2
        b.Parent           = frame
        corner(b, 8)
        local hc = hov or rgb(
            math.min(bg.R*255+20,255),
            math.min(bg.G*255+20,255),
            math.min(bg.B*255+20,255)
        )
        b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.12),{BackgroundColor3=hc}):Play() end)
        b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.12),{BackgroundColor3=bg}):Play() end)
        return b
    end

    -- ── Divider ────────────────────────────────────────────────
    local function MakeDivider(yPos)
        local d = Instance.new("Frame")
        d.Size             = UDim2.new(1,-24,0,1)
        d.Position         = UDim2.new(0,12,0,yPos)
        d.BackgroundColor3 = C.border
        d.BorderSizePixel  = 0
        d.ZIndex           = 2
        d.Parent           = frame
    end

    -- ── Info row ───────────────────────────────────────────────
    local infoRow = Instance.new("Frame")
    infoRow.Size             = UDim2.new(1,-24,0,28)
    infoRow.Position         = UDim2.new(0,12,0,89)
    infoRow.BackgroundColor3 = rgb(10,30,20)
    infoRow.BorderSizePixel  = 0
    infoRow.ZIndex           = 2
    infoRow.Parent           = frame
    corner(infoRow, 7)
    stroke(infoRow, rgb(0,80,50), 1)
    local infoLbl = Instance.new("TextLabel", infoRow)
    infoLbl.Text                   = "✅  Webhook utama sudah terpasang di dalam skrip."
    infoLbl.Size                   = UDim2.new(1,-10,1,0)
    infoLbl.Position               = UDim2.new(0,8,0,0)
    infoLbl.BackgroundTransparency = 1
    infoLbl.TextColor3             = rgb(80,210,140)
    infoLbl.Font                   = Enum.Font.Gotham
    infoLbl.TextSize               = 9
    infoLbl.TextXAlignment         = Enum.TextXAlignment.Left
    infoLbl.TextWrapped            = true
    infoLbl.ZIndex                 = 3

    -- ── Inputs ─────────────────────────────────────────────────
    MakeSection("WEBHOOK GALATAMA  (opsional)", 125)
    local inputGalatama = MakeInput("https://discord.com/api/webhooks/...", 139)

    MakeSection("BOT TOKEN  (untuk restore point)", 178)
    local inputToken = MakeInput("Bot token...", 192)

    MakeSection("CHANNEL ID GALATAMA", 230)
    local inputChannel = MakeInput("ID channel Discord...", 244)

    MakeSection("DISCORD ROLE ID  (opsional)", 282)
    local inputRole = MakeInput("Role ID...", 296)

    MakeDivider(336)

    -- ── START button ───────────────────────────────────────────
    local startBtn = MakeBtn(
        "▶   START MONITORING",
        344, nil, nil,
        rgb(0,155,90), rgb(0,185,110)
    )

    -- ── Post-start buttons ─────────────────────────────────────
    local editBtn = MakeBtn(
        "✏️  EDIT",
        386,
        UDim2.new(0.33,-8,0,28),
        UDim2.new(0,12,0,386),
        rgb(40,80,170), rgb(60,110,210)
    )
    editBtn.TextSize = 10; editBtn.Visible = false

    local galaBtn = MakeBtn(
        "🏅  GALATAMA",
        386,
        UDim2.new(0.34,-4,0,28),
        UDim2.new(0.33,4,0,386),
        rgb(140,90,0), rgb(185,120,0)
    )
    galaBtn.TextSize = 10; galaBtn.Visible = false

    local lbBtn = MakeBtn(
        "📊  LB SECRET",
        386,
        UDim2.new(0.33,-8,0,28),
        UDim2.new(0.67,4,0,386),
        rgb(40,110,55), rgb(55,150,75)
    )
    lbBtn.TextSize = 10; lbBtn.Visible = false

    -- ── Version tag ────────────────────────────────────────────
    local verLbl = Instance.new("TextLabel")
    verLbl.Text                   = "ForkyHUB v2  ·  GTT Edition"
    verLbl.Size                   = UDim2.new(1,-24,0,14)
    verLbl.Position               = UDim2.new(0,12,1,-18)
    verLbl.BackgroundTransparency = 1
    verLbl.TextColor3             = C.dim
    verLbl.Font                   = Enum.Font.Gotham
    verLbl.TextSize               = 8
    verLbl.TextXAlignment         = Enum.TextXAlignment.Center
    verLbl.ZIndex                 = 2
    verLbl.Parent                 = frame

    -- ── Logic (sama persis dengan sebelumnya) ──────────────────
    galaBtn.MouseButton1Click:Connect(function()
        if not SCRIPT_ACTIVE then return end
        galaBtn.Text = "⏳ Mengirim..."
        SendGalatamaLeaderboard(false)
        task.wait(2)
        galaBtn.Text = "🏅  GALATAMA"
    end)

    lbBtn.MouseButton1Click:Connect(function()
        if not SCRIPT_ACTIVE then return end
        lbBtn.Text = "⏳ Mengirim..."
        SendLeaderboard(false)
        task.wait(2)
        lbBtn.Text = "📊  LB SECRET"
    end)

    local isEditing = false
    local allInputs = { inputGalatama, inputToken, inputChannel, inputRole }

    editBtn.MouseButton1Click:Connect(function()
        if not SCRIPT_ACTIVE then return end
        isEditing = not isEditing
        if isEditing then
            for _, box in ipairs(allInputs) do
                box.TextEditable     = true
                box.BackgroundColor3 = rgb(22,32,16)
            end
            editBtn.Text             = "💾 SIMPAN"
            editBtn.BackgroundColor3 = rgb(160,120,0)
        else
            if inputGalatama.Text ~= "" and inputGalatama.Text:find("discord.com/api/webhooks") then
                WEBHOOK_GALATAMA = inputGalatama.Text
            end
            if inputToken.Text   ~= "" then BOT_TOKEN       = inputToken.Text   end
            if inputChannel.Text ~= "" then SAVE_CHANNEL_ID = inputChannel.Text end
            if inputRole.Text    ~= "" then DISCORD_ROLE_ID = inputRole.Text    end
            for _, box in ipairs(allInputs) do
                box.TextEditable     = false
                box.BackgroundColor3 = C.input
            end
            editBtn.Text             = "✏️  EDIT"
            editBtn.BackgroundColor3 = rgb(40,80,170)
            PostWebhook(WEBHOOK_URL ~= "" and WEBHOOK_URL or WEBHOOK_STATS, {
                username   = WH_IDENTITY.stats.name,
                avatar_url = WH_IDENTITY.stats.avatar,
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
            startBtn.BackgroundColor3 = C.red
            task.wait(2)
            startBtn.Text             = "▶   START MONITORING"
            startBtn.BackgroundColor3 = rgb(0,155,90)
            return
        end

        if inputGalatama.Text ~= "" and inputGalatama.Text:find("discord.com/api/webhooks") then
            WEBHOOK_GALATAMA = inputGalatama.Text
        end
        if inputToken.Text   ~= "" then BOT_TOKEN       = inputToken.Text   end
        if inputChannel.Text ~= "" then SAVE_CHANNEL_ID = inputChannel.Text end
        if inputRole.Text    ~= "" then DISCORD_ROLE_ID = inputRole.Text    end

        SCRIPT_ACTIVE = true

        -- animate status
        TweenService:Create(statusDot, TweenInfo.new(0.3), {BackgroundColor3=C.green}):Play()
        TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextColor3=C.green}):Play()
        statusLabel.Text             = "Aktif — Monitoring berjalan..."
        startBtn.Text                = "✅  MONITORING AKTIF"
        startBtn.BackgroundColor3    = rgb(20,35,25)
        startBtn.TextColor3          = C.dim

        -- pulse accent line
        task.spawn(function()
            while SCRIPT_ACTIVE do
                TweenService:Create(accentLine,TweenInfo.new(1.2,Enum.EasingStyle.Sine),{BackgroundTransparency=0.4}):Play()
                task.wait(1.2)
                TweenService:Create(accentLine,TweenInfo.new(1.2,Enum.EasingStyle.Sine),{BackgroundTransparency=0}):Play()
                task.wait(1.2)
            end
        end)

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
