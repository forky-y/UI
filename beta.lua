local cloneref = (cloneref or clonereference or function(instance) return instance end)
local HttpService = game:GetService("HttpService")
local CoreGui = cloneref(game:GetService("CoreGui"))
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local keepAliveUser = nil
local MarketplaceService = cloneref(game:GetService("MarketplaceService"))
local TweenService = game:GetService("TweenService")

local PLACE_ID = game.PlaceId
local Player   = Players.LocalPlayer
local JSON_URL = "https://app.forkyhub.my.id/storage/track/vip.json"
local ForkyHUB_RECORD_VIP_URL = "https://app.forkyhub.my.id/storage/recorder.lua"

-- ══════════════════════════════════════════════════════════════
-- NO FALL DAMAGE FEATURE (ALWAYS ON)
-- ══════════════════════════════════════════════════════════════
local function ApplyNoFall(char)
    if not char then return end
    task.spawn(function()
        local fall = char:WaitForChild("Client_Fall_Damage", 5)
        if fall then
            fall.Disabled = true
        end
    end)
end

if Player.Character then
    ApplyNoFall(Player.Character)
end
Player.CharacterAdded:Connect(ApplyNoFall)

-- ══════════════════════════════════════════════════════════════
-- WINDUI LOADER
-- ══════════════════════════════════════════════════════════════
local PlayerGui = Player:WaitForChild("PlayerGui")

local function showLoadingScreen()
    local loadingGui = Instance.new("ScreenGui")
    loadingGui.Name = "ForkyHUB_Loading"
    loadingGui.ResetOnSpawn = false
    loadingGui.IgnoreGuiInset = true
    loadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    loadingGui.Parent = CoreGui or PlayerGui

    local background = Instance.new("Frame", loadingGui)
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(8, 8, 18)
    background.BorderSizePixel = 0

    local grad = Instance.new("UIGradient", background)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 10, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 15)),
    })
    grad.Rotation = 135

    local logo = Instance.new("ImageLabel", background)
    logo.Size = UDim2.new(0, 100, 0, 100)
    logo.Position = UDim2.new(0.5, -50, 0.42, -50)
    logo.BackgroundTransparency = 1
    logo.Image = "rbxassetid://110496326502383"
    logo.ScaleType = Enum.ScaleType.Fit
    Instance.new("UICorner", logo).CornerRadius = UDim.new(0, 16)

    local title = Instance.new("TextLabel", background)
    title.Size = UDim2.new(0, 320, 0, 30)
    title.Position = UDim2.new(0.5, -160, 0.6, -10)
    title.BackgroundTransparency = 1
    title.Text = "ForkyHUB Loading..."
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(0, 225, 255)
    title.TextXAlignment = Enum.TextXAlignment.Center

    local status = Instance.new("TextLabel", background)
    status.Size = UDim2.new(0, 320, 0, 24)
    status.Position = UDim2.new(0.5, -160, 0.68, 10)
    status.BackgroundTransparency = 1
    status.Text = "Preparing..."
    status.Font = Enum.Font.Gotham
    status.TextSize = 14
    status.TextColor3 = Color3.fromRGB(170, 170, 255)
    status.TextXAlignment = Enum.TextXAlignment.Center

    local barBack = Instance.new("Frame", background)
    barBack.Size = UDim2.new(0, 300, 0, 6)
    barBack.Position = UDim2.new(0.5, -150, 0.74, 0)
    barBack.BackgroundColor3 = Color3.fromRGB(30, 20, 60)
    barBack.BorderSizePixel = 0
    Instance.new("UICorner", barBack).CornerRadius = UDim.new(0, 4)

    local barFill = Instance.new("Frame", barBack)
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    barFill.BorderSizePixel = 0
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 4)

    TweenService:Create(barFill, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 1, 0)
    }):Play()

    local function setText(text)
        if status and status.Parent then
            status.Text = tostring(text)
        end
    end

    local function hide()
        if loadingGui and loadingGui.Parent then
            pcall(function() loadingGui:Destroy() end)
        end
    end

    return setText, hide
end

local setLoadingText, hideLoading = showLoadingScreen()
setLoadingText("Loading WindUI...")

local WindUI = nil
pcall(function()
    WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not WindUI then
    task.wait(1)
    pcall(function()
        WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
    end)
end
if not WindUI then
    hideLoading()
    warn("[ForkyHUB] Gagal load WindUI, cek koneksi atau executor.")
    return
end
setLoadingText("Building UI...")


-- ══════════════════════════════════════════════════════════════
-- CLICK SOUND
-- ══════════════════════════════════════════════════════════════
local SoundService = game:GetService("SoundService")
local ClickSound = Instance.new("Sound")
ClickSound.SoundId = "rbxassetid://140039147129195"
ClickSound.Volume  = 1
ClickSound.Parent  = SoundService

local function PlayClick()
    local s = ClickSound:Clone()
    s.Parent = SoundService
    s:Play()
    game:GetService("Debris"):AddItem(s, 2)
end

-- ══════════════════════════════════════════════════════════════
-- FETCH TITLES
-- ══════════════════════════════════════════════════════════════
local WORKER_URL = "https://app.forkyhub.my.id/api"
local Titles = {
    windowTitle    = "ForkyHUB",
    windowSubtitle = "AutoWalk V1.5.0",
    openBtnTitle   = "Forky Hub",
    discordUrl     = "https://dsc.gg/forky",
    tag1           = "Premium Version",
    tag2           = "",
}

local function httpGet(url)
    -- Method 1: executor http request functions
    local requestFn = (syn and syn.request)
        or (http and http.request)
        or http_request
        or request
    if requestFn then
        local ok, res = pcall(requestFn, {Url = url, Method = "GET"})
        if ok and res and res.Body and res.Body ~= "" then
            return res.Body
        end
    end
    -- Method 2: game:HttpGet (paling kompatibel di semua executor)
    local ok2, body = pcall(function() return game:HttpGet(url, true) end)
    if ok2 and body and body ~= "" then
        return body
    end
    -- Method 3: HttpService:GetAsync
    local ok3, body3 = pcall(function() return HttpService:GetAsync(url, true) end)
    if ok3 and body3 and body3 ~= "" then
        return body3
    end
    return nil
end

local ok_fetch, body = pcall(httpGet, WORKER_URL .. "/public.php")
if ok_fetch and body then
    local ok_parse, data = pcall(HttpService.JSONDecode, HttpService, body)
    if ok_parse and data and data.titles then
        local t = data.titles
        local function pick(...) for i = 1, select('#', ...) do local v = select(i, ...) if v ~= nil and v ~= '' then return v end end return nil end
        local windowTitle    = pick(t.windowTitle,    t.window_title)
        local windowSubtitle = pick(t.windowSubtitle, t.window_subtitle)
        local openBtnTitle   = pick(t.openBtnTitle,   t.open_btn_title)
        local discordUrl     = pick(t.discordUrl,     t.discord_url)
        if windowTitle    then Titles.windowTitle    = windowTitle    end
        if windowSubtitle then Titles.windowSubtitle = windowSubtitle end
        if openBtnTitle   then Titles.openBtnTitle   = openBtnTitle   end
        if discordUrl     then Titles.discordUrl     = discordUrl     end
        if t.tag1           and t.tag1           ~= '' then Titles.tag1           = t.tag1           end
        if t.tag2 ~= nil then Titles.tag2 = t.tag2 end
    end
end

local function gradient(text, startColor, endColor)
    local result = ""
    for i = 1, #text do
        local pct = (i-1) / math.max(#text-1, 1)
        local r = math.floor((startColor.R + (endColor.R - startColor.R) * pct) * 255)
        local g = math.floor((startColor.G + (endColor.G - startColor.G) * pct) * 255)
        local b = math.floor((startColor.B + (endColor.B - startColor.B) * pct) * 255)
        result = result .. '<font color="rgb(' .. r .. ',' .. g .. ',' .. b .. ')">' .. text:sub(i,i) .. '</font>'
    end
    return result
end

local cyan = Color3.fromRGB(0, 225, 255)
local blue = Color3.fromRGB(0, 150, 255)

local Window = WindUI:CreateWindow({
    Title         = gradient(Titles.windowTitle, cyan, blue),
    Author        = gradient(Titles.windowSubtitle, cyan, blue),
    Folder        = "Forky",
    Icon          = "rbxassetid://110496326502383",
    Transparent   = true,
    Resizable     = true,
    HideSearchBar = false,
})

pcall(function()
    Window:EditOpenButton({
        Title           = gradient(Titles.openBtnTitle, cyan, blue),
        Icon            = "rbxassetid://110496326502383",
        CornerRadius    = UDim.new(0, 16),
        StrokeThickness = 2,
        Color           = ColorSequence.new(cyan, blue),
        OnlyMobile      = false,
        Enabled         = true,
        Draggable       = true,
    })
end)

local tagColor = Color3.fromHex("#0a2a3d")
Window:Tag({ Title=gradient(Titles.discordUrl,cyan,blue), Icon="geist:logo-discord", Color=tagColor, Radius=13 })
if Titles.tag1 and Titles.tag1 ~= "" then
    Window:Tag({ Title=gradient(Titles.tag1,cyan,blue), Icon="geist:star", Color=tagColor, Radius=13 })
end
if Titles.tag2 and Titles.tag2 ~= "" then
    Window:Tag({ Title=gradient(Titles.tag2,cyan,blue), Icon="lucide:badge-check", Color=tagColor, Radius=13 })
end
_G.ForkyTitles = Titles
hideLoading()

-- ══════════════════════════════════════════════════════════════
-- DATA STATE
-- ══════════════════════════════════════════════════════════════
local SelectedTrackData    = {}
local AutoWalkActive       = false
local WalkConnection       = nil
local FlipState            = false
local TrackStartTime       = 0
local TrackIndex           = {}
local PlayStopBtn          = nil
local CurrentTrackDuration = 0
local ResumeTrackTime      = 0
local TrackFinished        = false
local AutoRespawnEnabled   = false
local AutoLoopEnabled      = false
local IsLooping            = false
local lastJumpSent = 0

local HotkeyConfig = {
    play = "P",
    stop = "X",
}

local function normalizeHotkeyString(value)
    if type(value) ~= "string" then
        return nil
    end
    local text = value:upper():gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", "")
    if text == "" then
        return nil
    end
    if Enum.KeyCode[text] then
        return text
    end
    if #text == 1 and text:match("[A-Z0-9]") then
        local numericMap = {
            ["0"] = "Zero", ["1"] = "One", ["2"] = "Two", ["3"] = "Three", ["4"] = "Four",
            ["5"] = "Five", ["6"] = "Six", ["7"] = "Seven", ["8"] = "Eight", ["9"] = "Nine",
        }
        return numericMap[text] or text
    end
    return nil
end

local function getHotkeyKeyCode(action)
    local keyName = nil
    if action == "play" then
        keyName = normalizeHotkeyString(HotkeyConfig.play) or "P"
    elseif action == "stop" then
        keyName = normalizeHotkeyString(HotkeyConfig.stop) or "X"
    end
    if action == "stop" then
        return Enum.KeyCode[keyName] or Enum.KeyCode.X
    end
    return Enum.KeyCode[keyName] or Enum.KeyCode.P
end

local function setHotkey(action, value)
    local keyName = normalizeHotkeyString(value)
    if not keyName then
        WindUI:Notify({Title="Hotkey", Content="Invalid hotkey: "..tostring(value), Duration=2})
        return false
    end
    if action == "play" then
        HotkeyConfig.play = keyName
    elseif action == "stop" then
        HotkeyConfig.stop = keyName
    end
    WindUI:Notify({Title="Hotkey", Content=(action == "play" and "Play/Pause" or "Stop") .. " hotkey diset ke " .. keyName, Duration=2})
    return true
end
local loadedRouteInfo      = {} -- Info tentang route yang di-load (source, frames, duration, speed, loadedAt)
local lastKnownPosition    = nil
local lastKnownPlaybackTime = 0
local customStatusParagraph = nil
local refreshCustomLoadStatus
local StopWalk, StopLoop

-- BITWISE SETTINGS
-- SAVED CHARACTER STATE
local savedWalkSpeed         = 16

-- ══════════════════════════════════════════════════════════════
-- LIVE SPEED SYSTEM (ported dari FreeWALKADARECORDER.lua)
-- Cara kerja:  speed diubah → timeMultiplier berubah → waktu playback
-- maju lebih cepat → lebih banyak frame di-skip per detik →
-- avatar benar-benar bergerak lebih cepat (bukan cuma velocity lebih besar).
-- ══════════════════════════════════════════════════════════════
local playbackRuntimeSpeed   = 16    -- nilai live yg dibaca tiap Heartbeat
local recordedBaseSpeed      = 16    -- base speed track yg di-load (auto-detect)
local MIN_PB_SPEED           = 8
local MAX_PB_SPEED           = 500
local LOOP_MULT_MIN          = 0.1
local LOOP_MULT_MAX          = 50

local savedJumpPower         = 50
local savedJumpHeight        = 7.2
local savedUseJumpPower      = true
local savedAutoRotate        = true

-- CLIMB ANIMATION
local activeClimbTrack       = nil
local activeClimbHumanoid    = nil

-- JUMP TRACKING
local lastJumpIdx            = 0

-- SMOOTH STATE THROTTLE (ported dari FreeWALKADARECORDER.lua)
-- Pakai _G supaya tidak makan slot local register (Lua 5.1 limit 200)
_G.ForkyBeta_LastState      = nil
_G.ForkyBeta_LastStateClock = 0

function changeStateSoft(hum, stateName, force)
    if not hum then return end
    local stateEnum
    if     stateName == "Running"     then stateEnum = Enum.HumanoidStateType.Running
    elseif stateName == "Standing"    then stateEnum = Enum.HumanoidStateType.Standing
    elseif stateName == "Jumping"     then stateEnum = Enum.HumanoidStateType.Jumping
    elseif stateName == "Freefall"    then stateEnum = Enum.HumanoidStateType.Freefall
    elseif stateName == "FallingDown" then stateEnum = Enum.HumanoidStateType.FallingDown
    elseif stateName == "Climbing"    then stateEnum = Enum.HumanoidStateType.Climbing
    elseif stateName == "Swimming"    then stateEnum = Enum.HumanoidStateType.Swimming
    end
    if not stateEnum then return end
    local now = os.clock()
    if force == true
       or tostring(_G.ForkyBeta_LastState or "") ~= stateName
       or (now - (_G.ForkyBeta_LastStateClock or 0)) >= 0.12 then
        _G.ForkyBeta_LastState      = stateName
        _G.ForkyBeta_LastStateClock = now
        pcall(function() hum:ChangeState(stateEnum) end)
    end
end

-- ══════════════════════════════════════════════════════════════
-- SPEEDOMETER (dari FreeAutoWalk.lua)
-- State disimpan di _G supaya tidak menambah top-level local registers
-- ══════════════════════════════════════════════════════════════
if not _G.ForkySpeedometer then
    _G.ForkySpeedometer = { active=false, conn=nil, speed=0, gui=nil, val=nil, stat=nil, inputConns={} }
end

local function getVelocity(hrp)
    if not hrp then return 0 end
    local ok, vel = pcall(function() return hrp.AssemblyLinearVelocity end)
    if not ok or typeof(vel) ~= "Vector3" then return 0 end
    local flat = Vector3.new(vel.X, 0, vel.Z)
    return flat.Magnitude
end

local function createSpeedometerOverlay()
    local sg = Instance.new("ScreenGui")
    sg.Name = "UI" .. math.random(10000, 99999); sg.ResetOnSpawn = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = Player:WaitForChild("PlayerGui")

    local f = Instance.new("Frame", sg)
    f.Size = UDim2.new(0,130,0,60); f.Position = UDim2.new(0.82,0,0.02,0)
    f.BackgroundColor3 = Color3.fromRGB(0,0,0); f.BackgroundTransparency = 0.15; f.ZIndex = 100
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,16)

    local g = Instance.new("UIGradient", f)
    g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(100,50,180)),ColorSequenceKeypoint.new(1,Color3.fromRGB(60,30,120))})
    g.Rotation = 135

    local sk = Instance.new("UIStroke", f)
    sk.Color = Color3.fromRGB(200,150,255); sk.Thickness = 2; sk.Transparency = 0.3

    local t1 = Instance.new("TextLabel", f)
    t1.Size = UDim2.new(1,0,0,26); t1.Position = UDim2.new(0,0,0,6)
    t1.BackgroundTransparency=1; t1.Text="⚡ SPEED"
    t1.Font=Enum.Font.GothamBold; t1.TextSize=12; t1.TextColor3=Color3.fromRGB(200,150,255)

    local vl = Instance.new("TextLabel", f)
    vl.Size = UDim2.new(1,0,0,26); vl.Position = UDim2.new(0,0,0,32)
    vl.BackgroundTransparency=1; vl.Text="0.0"
    vl.Font=Enum.Font.GothamBold; vl.TextSize=38; vl.TextColor3=Color3.fromRGB(255,255,255)

    local sl = Instance.new("TextLabel", f)
    sl.Size = UDim2.new(1,0,0,18); sl.Position = UDim2.new(0,0,1,-46)
    sl.BackgroundTransparency=1; sl.Text="NORMAL SPEED"
    sl.Font=Enum.Font.GothamBold; sl.TextSize=10; sl.TextColor3=Color3.fromRGB(100,255,100)

    local dragging,dragStart,startPos = false,Vector2.new(),f.Position
    local sp = _G.ForkySpeedometer
    
    local conn1 = f.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=inp.Position; startPos=f.Position
        end
    end)
    table.insert(sp.inputConns, conn1)
    
    local conn2 = f.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    table.insert(sp.inputConns, conn2)
    
    local conn3 = UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d = inp.Position-dragStart
            f.Position = UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
    table.insert(sp.inputConns, conn3)
    
    return f, vl, sl
end

local function updateSpeedometerDisplay(speed)
    local vl = _G.ForkySpeedometer.val
    local sl = _G.ForkySpeedometer.stat
    if not vl then return end
    speed = tonumber(speed) or 0; if speed < 0 then speed = 0 end
    _G.ForkySpeedometer.speed = speed
    vl.Text = string.format("%.1f", speed)
    if speed < 16 then
        vl.TextColor3=Color3.fromRGB(100,255,100)
        if sl then sl.Text="NORMAL SPEED"; sl.TextColor3=Color3.fromRGB(100,255,100) end
    elseif speed < 50 then
        vl.TextColor3=Color3.fromRGB(255,200,100)
        if sl then sl.Text="FAST"; sl.TextColor3=Color3.fromRGB(255,200,100) end
    elseif speed < 100 then
        vl.TextColor3=Color3.fromRGB(255,100,100)
        if sl then sl.Text="VERY FAST"; sl.TextColor3=Color3.fromRGB(255,100,100) end
    else
        vl.TextColor3=Color3.fromRGB(255,50,50)
        if sl then sl.Text="⚡ EXTREME ⚡"; sl.TextColor3=Color3.fromRGB(255,50,50) end
    end
end

local function toggleSpeedometer()
    local sp = _G.ForkySpeedometer
    if sp.active then
        if sp.conn then sp.conn:Disconnect(); sp.conn=nil end
        if sp.gui then pcall(function() sp.gui:Destroy() end); sp.gui=nil end
        for _, conn in ipairs(sp.inputConns) do
            if conn then pcall(function() conn:Disconnect() end) end
        end
        sp.inputConns = {}
        sp.active=false; sp.val=nil; sp.stat=nil
        WindUI:Notify({Title="Speedometer", Content="Speedometer: OFF", Duration=1})
    else
        local f,vl,sl = createSpeedometerOverlay()
        sp.gui=f; sp.val=vl; sp.stat=sl; sp.active=true
        local acc=0
        sp.conn = RunService.Heartbeat:Connect(function(dt)
            acc=acc+(dt or 0.016)
            if acc>=0.15 then
                acc=0
                local char=Player.Character
                local hrp=char and char:FindFirstChild("HumanoidRootPart")
                if hrp then updateSpeedometerDisplay(getVelocity(hrp)) end
            end
        end)
        WindUI:Notify({Title="Speedometer", Content="Speedometer: ON (Drag to move)", Duration=2})
    end
end

-- ══════════════════════════════════════════════════════════════
-- AUTO RUN TO ROUTE PATCH CONFIG (dari FreeAutoWalk.lua)
-- Saat posisi jauh dari jalur, avatar lari dulu ke titik route terdekat
-- pakai speed map/recording, lalu playback langsung lanjut tanpa TP start.
-- ══════════════════════════════════════════════════════════════
local function isFiniteNumber(value)
    local n = tonumber(value)
    return type(n) == "number"
        and n == n
        and n ~= math.huge
        and n ~= -math.huge
        and math.abs(n) < 1000000000
end

local function safeNumber(value, fallback)
    local n = tonumber(value)
    if isFiniteNumber(n) then
        return n
    end

    local f = tonumber(fallback)
    if isFiniteNumber(f) then
        return f
    end

    return 0
end

local findNearestTrackFrameToPosition

_G.ForkyAutoRunActive = false
AUTO_RUN_TO_ROUTE_ENABLED = true
AUTO_RUN_TO_ROUTE_STOP_DISTANCE = 3.5
AUTO_RUN_TO_ROUTE_MAX_TIME = 12
AUTO_RUN_TO_ROUTE_LOOKAHEAD_FRAMES = 8
AUTO_RUN_TO_ROUTE_ACCEPT_MULTIPLIER = 1.65
AUTO_RUN_TO_ROUTE_OVERSHOOT_MULTIPLIER = 2.4
AUTO_RUN_TO_ROUTE_STUCK_SECONDS = 0.85
AUTO_RUN_TO_ROUTE_STUCK_MIN_MOVE = 0.75
AUTO_RUN_TO_ROUTE_RETARGET_SECONDS = 0.35
AUTO_RUN_TO_ROUTE_MIN_SPEED = 16
AUTO_RUN_TO_ROUTE_MAX_SPEED = 500

local function runToRoutePointBeforePlaybackFree(hum, hrp, targetFrame, recordedBaseSpeed)
    if not AUTO_RUN_TO_ROUTE_ENABLED then return true end
    if not hum or not hrp or not targetFrame then return true end

    local frames = SelectedTrackData or {}
    if #frames == 0 then return true end

    -- Cari index frame target
    local targetIndex = 1
    for i = 1, #frames do
        if frames[i] == targetFrame then targetIndex = i; break end
    end

    -- Lookahead: ambil titik sedikit lebih maju dari terdekat
    local maxIdx = math.max(1, #frames - 1)
    local tIdx = math.clamp(targetIndex + math.max(0, AUTO_RUN_TO_ROUTE_LOOKAHEAD_FRAMES), 1, maxIdx)
    local targetPos = (frames[tIdx] and frames[tIdx].pos) or (targetFrame and targetFrame.pos)
    if typeof(targetPos) ~= "Vector3" then return true end

    local runSpeed = safeNumber(recordedBaseSpeed, 0)
    if runSpeed <= 2 then runSpeed = safeNumber(hum.WalkSpeed, 0) end
    if runSpeed <= 2 then runSpeed = safeNumber(savedWalkSpeed, 16) end
    runSpeed = math.clamp(runSpeed, AUTO_RUN_TO_ROUTE_MIN_SPEED, AUTO_RUN_TO_ROUTE_MAX_SPEED)

    local startDelta = Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z) - hrp.Position
    local maxRunTime = math.max(AUTO_RUN_TO_ROUTE_MAX_TIME, (startDelta.Magnitude / math.max(runSpeed,1)) + 4)
    local stopDist = AUTO_RUN_TO_ROUTE_STOP_DISTANCE
    local acceptDist = math.max(stopDist, stopDist * AUTO_RUN_TO_ROUTE_ACCEPT_MULTIPLIER)
    local overshootDist = math.max(acceptDist + 1, stopDist * AUTO_RUN_TO_ROUTE_OVERSHOOT_MULTIPLIER)

    local bestDist = math.huge
    local lastProgPos = hrp.Position
    local lastProgClock = tick()
    local lastRetarget = 0
    local lastDir = nil
    local startClock = tick()

    _G.ForkyAutoRunActive = true

    pcall(function()
        hum.AutoRotate = true; hum.PlatformStand = false
        hum.Sit = false; hum.Jump = false; hum.WalkSpeed = runSpeed
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end)

    WindUI:Notify({Title="Smart Resume", Content="Lari ke jalur terdekat... Speed: "..math.floor(runSpeed), Duration=1})

    while AutoWalkActive do
        local char2 = Player.Character
        local hum2 = char2 and char2:FindFirstChildOfClass("Humanoid")
        local hrp2 = char2 and char2:FindFirstChild("HumanoidRootPart")
        if not hum2 or not hrp2 then _G.ForkyAutoRunActive=false; return false end

        local curPos = hrp2.Position

        -- Retarget berkala
        if #frames > 1 and tick()-lastRetarget >= AUTO_RUN_TO_ROUTE_RETARGET_SECONDS then
            lastRetarget = tick()
            local nIdx, nDist = findNearestTrackFrameToPosition(curPos, frames)
            nIdx = math.clamp(nIdx or tIdx, 1, maxIdx)
            if nDist and nDist <= acceptDist then
                pcall(function() hum2:Move(Vector3.new(0,0,0),false); hrp2.AssemblyLinearVelocity=Vector3.new(0,hrp2.AssemblyLinearVelocity.Y,0) end)
                _G.ForkyAutoRunActive=false; return true
            end
            if nIdx >= tIdx or (nDist and nDist+2 < bestDist) then
                tIdx = math.clamp(nIdx + AUTO_RUN_TO_ROUTE_LOOKAHEAD_FRAMES, 1, maxIdx)
                targetPos = (frames[tIdx] and frames[tIdx].pos) or targetPos
            end
        end

        local flatTarget = Vector3.new(targetPos.X, curPos.Y, targetPos.Z)
        local delta = flatTarget - curPos
        local dist = delta.Magnitude

        if dist < bestDist then bestDist=dist; lastProgPos=curPos; lastProgClock=tick() end

        if dist <= acceptDist then
            pcall(function() hum2:Move(Vector3.new(0,0,0),false); hrp2.AssemblyLinearVelocity=Vector3.new(0,hrp2.AssemblyLinearVelocity.Y,0) end)
            _G.ForkyAutoRunActive=false; return true
        end

        -- Overshoot check
        if lastDir and delta.Magnitude > 0.01 then
            if lastDir:Dot(delta.Unit) < -0.15 and bestDist <= overshootDist then
                pcall(function() hum2:Move(Vector3.new(0,0,0),false); hrp2.AssemblyLinearVelocity=Vector3.new(0,hrp2.AssemblyLinearVelocity.Y,0) end)
                _G.ForkyAutoRunActive=false; return true
            end
        end
        if bestDist <= overshootDist and dist > bestDist+1.25 then
            pcall(function() hum2:Move(Vector3.new(0,0,0),false); hrp2.AssemblyLinearVelocity=Vector3.new(0,hrp2.AssemblyLinearVelocity.Y,0) end)
            _G.ForkyAutoRunActive=false; return true
        end

        -- Stuck check
        if tick()-lastProgClock >= AUTO_RUN_TO_ROUTE_STUCK_SECONDS then
            if (curPos-lastProgPos).Magnitude <= AUTO_RUN_TO_ROUTE_STUCK_MIN_MOVE or bestDist <= overshootDist*1.75 then
                pcall(function() hum2:Move(Vector3.new(0,0,0),false); hrp2.AssemblyLinearVelocity=Vector3.new(0,hrp2.AssemblyLinearVelocity.Y,0) end)
                _G.ForkyAutoRunActive=false; return true
            end
            lastProgPos=curPos; lastProgClock=tick()
        end

        if tick()-startClock > maxRunTime then
            _G.ForkyAutoRunActive=false
            WindUI:Notify({Title="Smart Resume", Content="Lanjut dari titik terdekat.", Duration=1})
            return true
        end

        local dir = delta.Magnitude > 0 and delta.Unit or Vector3.new(0,0,0)
        lastDir = dir

        pcall(function()
            hum2.AutoRotate=true; hum2.PlatformStand=false; hum2.Sit=false
            hum2.WalkSpeed=runSpeed; hum2:Move(dir, false)
            hrp2.AssemblyLinearVelocity = Vector3.new(dir.X*runSpeed, hrp2.AssemblyLinearVelocity.Y, dir.Z*runSpeed)
            if dir.Magnitude > 0.01 then
                hrp2.CFrame = CFrame.lookAt(hrp2.Position, hrp2.Position+Vector3.new(dir.X,0,dir.Z))
            end
            hum2.Jump = (targetPos.Y - curPos.Y > 2.75 and dist > stopDist)
        end)

        RunService.Heartbeat:Wait()
    end

    _G.ForkyAutoRunActive=false
    return true
end

-- SHIFTLOCK STATE
local ShiftLockActive        = false
local UserMouseInput         = nil

-- ══════════════════════════════════════════════════════════════
-- SMART AI SPEED SYSTEM
-- ══════════════════════════════════════════════════════════════
local SmartAISpeed = {
    enabled              = false,
    detectionRadius      = 200,
    maxSpeedSafeArea     = 1.5,
    slowSpeedNearPlayer  = 1,
    ignoreClosePlayers   = false,
    closePlayerDistance  = 10,
    statusText           = "❌ DISABLED",
    lastPlayerCount      = 0,
    statusUpdateTime     = 0,
}

local function getPlayersInRadius()
    local char = Player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end
    
    local nearbyPlayers = {}
    local myPos = hrp.Position
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= Player then
            local plrChar = plr.Character
            local plrHrp  = plrChar and plrChar:FindFirstChild("HumanoidRootPart")
            if plrHrp then
                local dist = (plrHrp.Position - myPos).Magnitude
                if dist <= SmartAISpeed.detectionRadius then
                    table.insert(nearbyPlayers, {player = plr, distance = dist, hrp = plrHrp})
                end
            end
        end
    end
    
    return nearbyPlayers
end

local function updateSmartAIStatus()
    if not SmartAISpeed.enabled then
        SmartAISpeed.statusText = "❌ DISABLED"
        SmartAISpeed.lastPlayerCount = 0
        return
    end
    
    local nearbyPlayers = getPlayersInRadius()
    local playerCount = #nearbyPlayers
    
    -- Update status text based on player detection
    if playerCount == 0 then
        SmartAISpeed.statusText = "✅ ACTIVE - Area Aman (Speed: " .. string.format("%.1f", SmartAISpeed.maxSpeedSafeArea) .. "x)"
    elseif playerCount == 1 then
        local closestDist = nearbyPlayers[1].distance
        SmartAISpeed.statusText = "⚠️ ACTIVE - 1 Player Terdeteksi (" .. math.floor(closestDist) .. "m) - Speed: " .. string.format("%.1f", SmartAISpeed.slowSpeedNearPlayer) .. "x"
    else
        local closestDist = nearbyPlayers[1].distance
        SmartAISpeed.statusText = "🚨 ACTIVE - " .. playerCount .. " Players Terdeteksi (" .. math.floor(closestDist) .. "m) - Speed: " .. string.format("%.1f", SmartAISpeed.slowSpeedNearPlayer) .. "x"
    end
    
    -- Notify when player count changes
    if playerCount ~= SmartAISpeed.lastPlayerCount then
        local now = tick()
        if now - SmartAISpeed.statusUpdateTime > 2 then -- Prevent spam notifications
            if playerCount > SmartAISpeed.lastPlayerCount then
                WindUI:Notify({
                    Title="🚨 Player Detected",
                    Content="Ada " .. playerCount .. " player terdeteksi! Speed dikurangi.",
                    Duration=2
                })
            elseif playerCount < SmartAISpeed.lastPlayerCount then
                WindUI:Notify({
                    Title="✅ Area Clear",
                    Content="Player berkurang! Speed dinaikkan.",
                    Duration=2
                })
            end
            SmartAISpeed.statusUpdateTime = now
        end
    end
    
    SmartAISpeed.lastPlayerCount = playerCount
end

local function calculateSmartSpeed(baseSpeed)
    if not SmartAISpeed.enabled then return baseSpeed end
    
    local nearbyPlayers = getPlayersInRadius()
    if #nearbyPlayers == 0 then
        return baseSpeed * SmartAISpeed.maxSpeedSafeArea
    end
    
    local closestPlayer = nearbyPlayers[1]
    for _, p in ipairs(nearbyPlayers) do
        if p.distance < closestPlayer.distance then
            closestPlayer = p
        end
    end
    
    -- If ignore close players is enabled and player is too close, slow down
    if SmartAISpeed.ignoreClosePlayers and closestPlayer.distance <= SmartAISpeed.closePlayerDistance then
        return baseSpeed * SmartAISpeed.slowSpeedNearPlayer
    end
    
    -- Smooth speed transition based on distance
    local speedFactor = math.clamp(
        closestPlayer.distance / SmartAISpeed.detectionRadius,
        SmartAISpeed.slowSpeedNearPlayer,
        SmartAISpeed.maxSpeedSafeArea
    )
    
    return baseSpeed * speedFactor
end

-- ══════════════════════════════════════════════════════════════
-- ESP PATH SYSTEM
-- ══════════════════════════════════════════════════════════════
local ESP = {
    enabled       = false,
    parts         = {},
    folder        = nil,
    lineThickness = 0.15,
    dotSize       = 0.4,
    stepEvery     = 5,
    colorMode     = "gradient",
    solidColor    = Color3.fromRGB(0, 200, 255),
}

local function ensureESPFolder()
    if ESP.folder and ESP.folder.Parent then return ESP.folder end
    local f = Instance.new("Folder")
    f.Name   = "ForkyESP_Track"
    f.Parent = workspace
    ESP.folder = f
    return f
end

local function makeSegment(p0, p1, color)
    local dist = (p1 - p0).Magnitude
    if dist < 0.05 then return nil end
    local seg = Instance.new("Part")
    seg.Name         = "ESPSeg"
    seg.Anchored     = true
    seg.CanCollide   = false
    seg.CanTouch     = false
    seg.CanQuery     = false
    seg.CastShadow   = false
    seg.Material     = Enum.Material.Neon
    seg.Size         = Vector3.new(ESP.lineThickness, ESP.lineThickness, dist)
    seg.Color        = color
    seg.Transparency = 0.2
    seg.CFrame       = CFrame.lookAt((p0+p1)/2, p1)
    seg.Parent       = ensureESPFolder()
    table.insert(ESP.parts, seg)
    return seg
end

local function makeDot(pos, color, size)
    local d = Instance.new("Part")
    d.Name         = "ESPDot"
    d.Anchored     = true
    d.CanCollide   = false
    d.CanTouch     = false
    d.CanQuery     = false
    d.CastShadow   = false
    d.Shape        = Enum.PartType.Ball
    d.Material     = Enum.Material.Neon
    d.Size         = Vector3.new(size, size, size)
    d.Color        = color
    d.Transparency = 0.0
    d.CFrame       = CFrame.new(pos)
    d.Parent       = ensureESPFolder()
    table.insert(ESP.parts, d)
    return d
end

local function getESPColor(pct)
    if ESP.colorMode == "solid" then
        return ESP.solidColor
    elseif ESP.colorMode == "rainbow" then
        return Color3.fromHSV(pct, 1, 1)
    else
        if pct < 0.5 then
            local t = pct * 2
            return Color3.fromRGB(0, math.floor(150 + t*75), 255)
        else
            local t = (pct - 0.5) * 2
            return Color3.fromRGB(math.floor(t*60), math.floor(225 + t*30), math.floor(255 - t*150))
        end
    end
end

local function clearESP()
    for _, p in ipairs(ESP.parts) do pcall(function() p:Destroy() end) end
    ESP.parts = {}
    if ESP.folder then pcall(function() ESP.folder:Destroy() end); ESP.folder = nil end
end

local function drawTrackPath(trackData)
    clearESP()
    if not ESP.enabled then return end
    if not trackData or #trackData < 2 then
        WindUI:Notify({Title="⚠️ ESP", Content="Track belum diload!", Duration=2})
        return
    end
    ensureESPFolder()
    local total = #trackData
    local step  = math.max(1, ESP.stepEvery)
    for i = 1, total - step, step do
        local a   = trackData[i]
        local b   = trackData[math.min(i+step, total)]
        local pct = (i-1) / (total-1)
        makeSegment(a.pos, b.pos, getESPColor(pct))
    end
    local lastDrawn = math.floor((total-1)/step)*step + 1
    if lastDrawn < total then
        makeSegment(trackData[lastDrawn].pos, trackData[total].pos, getESPColor(1))
    end
    makeDot(trackData[1].pos,     Color3.fromRGB(0, 255, 80),  ESP.dotSize * 1.5)
    makeDot(trackData[total].pos, Color3.fromRGB(255, 50, 50), ESP.dotSize * 1.5)
    local wpStep = math.max(1, math.floor(total/10))
    for i = wpStep, total-wpStep, wpStep do
        makeDot(trackData[i].pos, getESPColor((i-1)/(total-1)), ESP.dotSize)
    end
    WindUI:Notify({Title="ESP Line", Content="Path ditampilkan ("..total.." frames, step "..step..")", Duration=2})
end

-- ══════════════════════════════════════════════════════════════
-- HELPERS (BITWISE STYLE)
-- ══════════════════════════════════════════════════════════════
local function SafeJsonDecode(jsonStr)
    local ok, r = pcall(HttpService.JSONDecode, HttpService, jsonStr)
    return ok and r or nil
end

-- ══════════════════════════════════════════════════════════════
-- CUSTOM LOAD JSON / URL INPUT SYSTEM
-- ══════════════════════════════════════════════════════════════
-- Variables untuk menyimpan input manual JSON/URL
local manualJsonInputText = ""
local manualUrlInputText = ""

-- Baca text dari clipboard
local function readClipboardText()
    local data = nil
    pcall(function() data = readclipboard() end)
    if not data then pcall(function() data = clipboard.get() end) end
    if not data then pcall(function() data = getclipboard() end) end
    return data
end

local function trim(text)
    return tostring(text or ""):match("^%s*(.-)%s*$") or ""
end

-- Cek apakah text terlihat seperti URL
local function looksLikeUrl(text)
    text = trim(text)
    return text:find("^https?://") ~= nil
end

local function parseFrameVector3(value)
    if type(value) ~= "table" then return Vector3.zero end
    local x = tonumber(value.x or value.X or value[1]) or 0
    local y = tonumber(value.y or value.Y or value[2]) or 0
    local z = tonumber(value.z or value.Z or value[3]) or 0
    return Vector3.new(x, y, z)
end

local function parseFrameState(f)
    local state = f.state or f.states or ""
    if type(state) == "table" then
        state = state.state or state.name or table.concat(state, ",")
    end
    state = tostring(state or "")
    if state:lower():find("jump") then return "Jumping" end
    if state:lower():find("freefal") then return "Freefall" end
    if state:lower():find("climb") then return "Climbing" end
    if state:lower():find("swim") then return "Swimming" end
    return state ~= "" and state or "Running"
end

local function parseFrameTime(f, index)
    return tonumber(f.time or f.times or f.t) or (index * 0.033)
end

local function parseFrameRotation(f)
    return tonumber(f.rotation or f.rot or f.yaw or 0) or 0
end

local function parseFrameHipHeight(f)
    return tonumber(f.hipHeight or f.hipheight or f.hip or 3.5) or 3.5
end
local function extractRouteSpeed(data, track)
    if type(data) ~= "table" then
        return nil
    end

    local speed = safeNumber(data.speed or data.walkSpeed or data.ws or data.originalWalkSpeed or data.Speed or data.WalkSpeed or data.Walkspeed, 0)
    if speed > 2 then
        return speed
    end

    if type(track) == "table" and #track > 0 then
        local total, count = 0, 0
        for _, frame in ipairs(track) do
            local frameSpeed = safeNumber(frame.walkSpeed or frame.speed or frame.ws or frame.originalWalkSpeed, 0)
            if frameSpeed > 2 then
                total = total + frameSpeed
                count = count + 1
            end
        end
        if count > 0 then
            return total / count
        end
        
        -- Jika semua frame speed 0, cek first frame atau use default
        local firstFrameSpeed = safeNumber(track[1].walkSpeed or track[1].speed or track[1].ws, 0)
        if firstFrameSpeed > 0 then
            return firstFrameSpeed
        end
    end

    return nil
end

local function lerpAngle(a, b, t)
    a = tonumber(a) or 0
    b = tonumber(b) or a
    t = math.clamp(t or 0, 0, 1)
    local diff = ((b - a + math.pi) % (2 * math.pi)) - math.pi
    return a + diff * t
end

local function getRecordedYaw(f, nextFrame, alpha)
    local startYaw = tonumber(f.rotation or f.rot or f.yaw) or 0
    local endYaw = nextFrame and tonumber(nextFrame.rotation or nextFrame.rot or nextFrame.yaw)
    if endYaw == nil then endYaw = startYaw end
    if ReverseMode then
        startYaw = startYaw + math.pi
        endYaw = endYaw + math.pi
    end
    return lerpAngle(startYaw, endYaw, alpha)
end

local function ConvertReplayToTrack(data)
    local track  = {}
    local frames = type(data) == "table" and data or {}
    if type(data) == "table" and data.Frames then frames = data.Frames end

    for i = 1, math.min(#frames, 200000) do
        local f = frames[i]
        if type(f) == "table" then
            local pos
            if f.position then
                pos = parseFrameVector3(f.position)
            elseif f.px and f.py and f.pz then
                pos = Vector3.new(tonumber(f.px) or 0, tonumber(f.py) or 0, tonumber(f.pz) or 0)
            end

            if pos then
                table.insert(track, {
                    pos       = pos,
                    rotation  = parseFrameRotation(f),
                    vel       = (f.velocity and type(f.velocity) == "table") and Vector3.new(tonumber(f.velocity.x) or 0, tonumber(f.velocity.y) or 0, tonumber(f.velocity.z) or 0) or Vector3.zero,
                    walkSpeed = safeNumber(f.walkSpeed or f.ws or f.speed or f.originalWalkSpeed, 0),
                    jump      = (f.jump == true) or parseFrameState(f) == "Jumping",
                    time      = parseFrameTime(f, i),
                    state     = parseFrameState(f),
                    climbing  = parseFrameState(f) == "Climbing",
                    freefall  = parseFrameState(f) == "Freefall",
                    swimming  = parseFrameState(f) == "Swimming",
                    hipHeight = parseFrameHipHeight(f),
                })
            end
        end
    end

    table.sort(track, function(a,b) return a.time < b.time end)

    if #track > 0 then
        local unique = {track[1]}
        for i = 2, #track do
            if (track[i].pos - unique[#unique].pos).Magnitude > 0.1 then
                table.insert(unique, track[i])
            end
        end
        track = unique
    end

    CurrentTrackDuration = #track > 0 and track[#track].time + 0.5 or 0
    print("🎯", #track, "frames loaded")
    return track
end

local function buildReversedTrack(track)
    if not track or #track == 0 then
        return {}
    end

    local duration = safeNumber(track[#track].time, 0)
    local reversed = {}

    for i = #track, 1, -1 do
        local frame = track[i]
        local revFrame = {}
        for k, v in pairs(frame) do
            revFrame[k] = v
        end
        revFrame.time = duration - safeNumber(frame.time, 0)
        table.insert(reversed, revFrame)
    end

    return reversed
end

-- Load dari file picker atau clipboard
local function loadFromFilePicker()
    local text = tostring(manualJsonInputText or "")
    if text == "" then
        text = tostring(readClipboardText() or "")
    end

    if text == "" then
        WindUI:Notify({
            Title = "Load",
            Content = "❌ Isi JSON/URL di Textarea atau copy JSON ke clipboard",
            Duration = 2
        })
        return
    end

    -- Kalau user menaruh URL, langsung fetch
    if looksLikeUrl(text) then
        manualUrlInputText = text
        fetchManualJsonUrl()
        return
    end

    -- Load sebagai JSON langsung
    local ok, data = pcall(function() return HttpService:JSONDecode(text) end)
    if not ok or not data then
        WindUI:Notify({
            Title = "Load",
            Content = "❌ Format JSON tidak valid",
            Duration = 2
        })
        return
    end

    local okTrack, trackOrErr = pcall(function() return ConvertReplayToTrack(data) end)
    if not okTrack then
        WindUI:Notify({Title = "❌ Load", Content = "Convert error: " .. tostring(trackOrErr), Duration = 3})
        return
    end
    local track = trackOrErr
    if track and #track > 0 then
        if AutoLoopEnabled then StopLoop() end
        StopWalk()
        ResumeTrackTime = 0
        TrackFinished = false
        SelectedTrackData = track
        ReversedTrackData = buildReversedTrack(SelectedTrackData)
        CurrentTrackDuration = (track[#track] and track[#track].time) or (#track * 0.033)

                        local extractedSpeed = extractRouteSpeed(data, track)
                        local finalSpeed = safeNumber(extractedSpeed, 20)
                        if finalSpeed <= 2 then finalSpeed = 20 end
                        local est = ForkyEstimateBaseSpeed(track)
                        local useSpeed = safeNumber(est, finalSpeed)
                        
                        recordedBaseSpeed = useSpeed
                        playbackRuntimeSpeed = useSpeed
                        loadedRouteInfo = {
                            source = "Custom JSON",
                            frames = #track,
                            duration = CurrentTrackDuration,
                            speed = useSpeed,
                            loadedAt = os.date("%H:%M:%S")
                        }

        if PlayStopBtn then PlayStopBtn.Text = "PLAY" end
        if ESP.enabled then drawTrackPath(SelectedTrackData) end
        if refreshCustomLoadStatus then refreshCustomLoadStatus() end
        WindUI:Notify({
            Title = "✅ Load JSON",
            Content = "Track loaded (" .. #track .. " frames)",
            Duration = 2
        })
    else
        WindUI:Notify({
            Title = "❌ Load",
            Content = "Gagal convert JSON ke track data",
            Duration = 2
        })
    end
end

-- Fetch URL JSON langsung
local function fetchManualJsonUrl()
    local url = trim(manualUrlInputText)
    if url == "" then
        url = trim(manualJsonInputText)
    end

    if url == "" then
        WindUI:Notify({
            Title = "Load",
            Content = "❌ Masukkan URL di input field",
            Duration = 2
        })
        return
    end

    if not looksLikeUrl(url) then
        WindUI:Notify({
            Title = "Load",
            Content = "❌ Input bukan URL. Gunakan format https://...",
            Duration = 2
        })
        return
    end

    WindUI:Notify({
        Title = "Load",
        Content = "🌐 Fetching URL...",
        Duration = 1
    })

    task.spawn(function()
        local ok, result = pcall(function()
            return httpGet(url)
        end)

        if ok and result and result ~= "" then
            local okJson, data = pcall(function()
                return HttpService:JSONDecode(result)
            end)

            if okJson and data then
                local okTrack, trackOrErr = pcall(function() return ConvertReplayToTrack(data) end)
                if not okTrack then
                    WindUI:Notify({Title = "❌ Load", Content = "Convert error: " .. tostring(trackOrErr), Duration = 3})
                else
                    local track = trackOrErr
                    if track and #track > 0 then
                        if AutoLoopEnabled then StopLoop() end
                        StopWalk()
                        ResumeTrackTime = 0
                        TrackFinished = false
                        SelectedTrackData = track
                        ReversedTrackData = buildReversedTrack(SelectedTrackData)
                        CurrentTrackDuration = (track[#track] and track[#track].time) or (#track * 0.033)

                        local extractedSpeed = extractRouteSpeed(data, track)
                        local finalSpeed = safeNumber(extractedSpeed, 20)
                        if finalSpeed <= 2 then finalSpeed = 20 end
                        local est = ForkyEstimateBaseSpeed(track)
                        local useSpeed = safeNumber(est, finalSpeed)
                        
                        recordedBaseSpeed = useSpeed
                        playbackRuntimeSpeed = useSpeed
                        loadedRouteInfo = {
                            source = url,
                            frames = #track,
                            duration = CurrentTrackDuration,
                            speed = useSpeed,
                            loadedAt = os.date("%H:%M:%S")
                        }
                        
                        if PlayStopBtn then PlayStopBtn.Text = "PLAY" end
                        if ESP.enabled then drawTrackPath(SelectedTrackData) end
                        if refreshCustomLoadStatus then refreshCustomLoadStatus() end
                        WindUI:Notify({
                            Title = "✅ Fetch URL",
                            Content = "Track loaded (" .. #track .. " frames)",
                            Duration = 3
                        })
                    else
                        WindUI:Notify({
                            Title = "❌ Load",
                            Content = "URL valid tapi data tidak bisa dikonversi",
                            Duration = 3
                        })
                        if refreshCustomLoadStatus then refreshCustomLoadStatus() end
                    end
                end
            else
                WindUI:Notify({
                    Title = "❌ Load",
                    Content = "URL mengembalikan data yang bukan JSON",
                    Duration = 3
                })
                if refreshCustomLoadStatus then refreshCustomLoadStatus() end
            end
        else
            WindUI:Notify({
                Title = "❌ Load",
                Content = "Gagal fetch URL. Cek internet atau URL salah.",
                Duration = 3
            })
            if refreshCustomLoadStatus then refreshCustomLoadStatus() end
        end
    end)
end

-- Clear semua loaded track
local function clearLoadedRouteResult()
    if WalkConnection then
        StopWalk()
        task.wait(0.1)
    end

    SelectedTrackData = {}
    ReversedTrackData = {}
    ResumeTrackTime = 0
    TrackFinished = false
    CurrentTrackDuration = 0
    manualJsonInputText = ""
    manualUrlInputText = ""
    loadedRouteInfo = {}

    clearESP()
    if PlayStopBtn then PlayStopBtn.Text = "PLAY" end

    if refreshCustomLoadStatus then refreshCustomLoadStatus() end
    WindUI:Notify({
        Title = "✅ Clear",
        Content = "Track sudah dihapus. Route sekarang kosong.",
        Duration = 2
    })
end

local function FetchIndex()
    local ok_http, body = pcall(function() return httpGet(JSON_URL) end)
    if not ok_http then
        print("[Forky] HttpGet gagal:", body)
        return false
    end
    
    local ok_json, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok_json or not data then
        print("[Forky] JSON decode gagal:", data or "empty")
        return false
    end
    
    TrackIndex = data
    print("[Forky] Index loaded OK")
    return true
end

local function safeVector3(vec, fallback)
    fallback = fallback or Vector3.new(0, 0, 0)
    if typeof(vec) ~= "Vector3" then
        return fallback
    end

    local x = safeNumber(vec.X, fallback.X)
    local y = safeNumber(vec.Y, fallback.Y)
    local z = safeNumber(vec.Z, fallback.Z)

    return Vector3.new(x, y, z)
end

local function safeMagnitude(vec)
    if typeof(vec) ~= "Vector3" then
        return 0
    end

    local clean = safeVector3(vec)
    local mag = clean.Magnitude
    if not isFiniteNumber(mag) then
        return 0
    end
    return mag
end

-- ══════════════════════════════════════════════════════════════
-- TIME FORMATTING FUNCTIONS
-- ══════════════════════════════════════════════════════════════
local function timeFmt(seconds)
    if not seconds or seconds < 0 then seconds = 0 end
    local minutes = math.floor(seconds / 60)
    local secs    = math.floor(seconds % 60)
    local millis  = math.floor((seconds % 1) * 100)
    return string.format("%02d:%02d.%02d", minutes, secs, millis)
end

local function timeFmtSimple(seconds)
    if not seconds or seconds < 0 then seconds = 0 end
    local minutes = math.floor(seconds / 60)
    local secs    = math.floor(seconds % 60)
    return string.format("%02d:%02d", minutes, secs)
end

-- ══════════════════════════════════════════════════════════════
-- RECORDING STATUS TEXT DISPLAY
-- ══════════════════════════════════════════════════════════════
local function getRecordingStatusText(currentTime)
    local DEFAULT_PLAYBACK_SPEED = 16
    
    local mode = "IDLE"
    if AutoWalkActive then
        mode = "PLAYING"
    elseif #SelectedTrackData > 0 then
        mode = "READY"
    end

    local routeState = (#SelectedTrackData > 0) and "LOADED" or "EMPTY"
    local info = loadedRouteInfo or {}
    local sourceText = tostring(info.source or "Belum ada")
    
    -- Shorten URL for display
    if sourceText:match("^https?://") then
        local domain = sourceText:match("^https?://([^/]+)") or sourceText
        local path = sourceText:match("^https?://[^/]+(.*)") or ""
        if path:len() > 30 then
            sourceText = domain .. path:sub(1, 27) .. "..."
        elseif path == "" then
            sourceText = domain
        else
            sourceText = domain .. path
        end
    end
    
    local frameCount = tonumber(info.frames) or #SelectedTrackData
    local duration = tonumber(info.duration) or CurrentTrackDuration or 0
    local speed = safeNumber(info.speed, safeNumber(savedWalkSpeed, DEFAULT_PLAYBACK_SPEED))
    local timeNow = tonumber(currentTime) or tonumber(ResumeTrackTime) or 0

    if #SelectedTrackData <= 0 then
        return "Status   : EMPTY" ..
            "\nRoute    : Belum ada hasil load" ..
            "\nSource   : -" ..
            "\nTime     : 00:00.00" ..
            "\nDuration : 00:00" ..
            "\nSpeed    : " .. string.format("%.1f stud/s", speed) ..
            "\nFrames   : 0" ..
            "\nAction   : Load JSON/URL atau pilih Gunung dari menu"
    end

    return "Status   : " .. mode ..
        "\nRoute    : " .. routeState ..
        "\nSource   : " .. sourceText ..
        "\nLoaded   : " .. tostring(info.loadedAt or "-") ..
        "\nTime     : " .. timeFmt(timeNow) ..
        "\nDuration : " .. timeFmtSimple(duration) ..
        "\nSpeed    : " .. string.format("%.1f stud/s", speed) ..
        "\nFrames   : " .. tostring(frameCount) ..
        "\nReverse  : " .. (ReverseMode and "ON" or "OFF")
end

refreshCustomLoadStatus = function()
    if customStatusParagraph then
        pcall(function()
            if customStatusParagraph.SetDesc then
                customStatusParagraph:SetDesc(getRecordingStatusText())
            end
        end)
    end
end

local function isAirborne(hum)
    if not hum then return false end
    local s = hum:GetState()
    return s == Enum.HumanoidStateType.Jumping
        or s == Enum.HumanoidStateType.Freefall
        or s == Enum.HumanoidStateType.GettingUp
        or s == Enum.HumanoidStateType.FallingDown
end

local function extractCFrameFromFrame(f, posX, posY, posZ)
    -- Try to extract CFrame from frame data
    if f and f.cframe then
        local cf = f.cframe
        if typeof(cf) == "CFrame" then
            return cf
        elseif type(cf) == "table" then
            return CFrame.new(
                tonumber(cf.x or cf.X or cf[1]) or posX,
                tonumber(cf.y or cf.Y or cf[2]) or posY,
                tonumber(cf.z or cf.Z or cf[3]) or posZ,
                tonumber(cf.r00 or cf[4]) or 1,
                tonumber(cf.r01 or cf[5]) or 0,
                tonumber(cf.r02 or cf[6]) or 0,
                tonumber(cf.r10 or cf[7]) or 0,
                tonumber(cf.r11 or cf[8]) or 1,
                tonumber(cf.r12 or cf[9]) or 0,
                tonumber(cf.r20 or cf[10]) or 0,
                tonumber(cf.r21 or cf[11]) or 0,
                tonumber(cf.r22 or cf[12]) or 1
            )
        end
    end
    
    -- Try rotation matrix format
    if f and f.r00 ~= nil then
        return CFrame.new(
            posX, posY, posZ,
            tonumber(f.r00) or 1, tonumber(f.r01) or 0, tonumber(f.r02) or 0,
            tonumber(f.r10) or 0, tonumber(f.r11) or 1, tonumber(f.r12) or 0,
            tonumber(f.r20) or 0, tonumber(f.r21) or 0, tonumber(f.r22) or 1
        )
    end
    
    -- Try yaw/rotation field
    local yaw = tonumber(f and (f.rotation or f.rot or f.yaw))
    if yaw then
        return CFrame.new(posX, posY, posZ) * CFrame.Angles(0, yaw, 0)
    end
    
    return CFrame.new(posX, posY, posZ)
end

local function GetNearestTrackTime()
    local char = Player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or #SelectedTrackData==0 then return 0 end
    local nearestTime, minDist = 0, math.huge
    for _, frame in ipairs(SelectedTrackData) do
        local dist = (frame.pos - hrp.Position).Magnitude
        if dist < minDist then minDist=dist; nearestTime=frame.time end
    end
    -- Always return nearest track time, no distance limit
    return nearestTime
end

local AUTO_RUN_TO_ROUTE_ENABLED = true
local AUTO_RUN_TO_ROUTE_STOP_DISTANCE = 3.5
local AUTO_RUN_TO_ROUTE_SEARCH_STEPS = 500

-- Smart resume / finish detection thresholds (FreeWALK-adapted)
local AUTO_RUN_TO_ROUTE_FAR_PATH_START_DISTANCE = 200
local PLAY_FINISH_RESTART_DISTANCE = 6
local PLAY_FINISH_RESTART_TIME_WINDOW = 4

findNearestTrackFrameToPosition = function(position, track)
    if not track or #track == 0 then return 1, 0 end
    local closestIndex = 1
    local closestDistance = (track[1].pos - position).Magnitude
    local step = math.max(1, math.floor(#track / AUTO_RUN_TO_ROUTE_SEARCH_STEPS))
    for i = 1, #track, step do
        local dist = (track[i].pos - position).Magnitude
        if dist < closestDistance then
            closestDistance = dist
            closestIndex = i
        end
    end
    local searchRadius = math.min(step, 50)
    for i = math.max(1, closestIndex - searchRadius), math.min(#track, closestIndex + searchRadius) do
        local dist = (track[i].pos - position).Magnitude
        if dist < closestDistance then
            closestDistance = dist
            closestIndex = i
        end
    end
    return closestIndex, closestDistance
end

local AUTO_RUN_TO_ROUTE_LOOKAHEAD_FRAMES = 18
local AUTO_RUN_TO_ROUTE_MAX_TIME = 12
local AUTO_RUN_TO_ROUTE_ACCEPT_MULTIPLIER = 1.65
local AUTO_RUN_TO_ROUTE_OVERSHOOT_MULTIPLIER = 2.4
local AUTO_RUN_TO_ROUTE_STUCK_SECONDS = 0.85
local AUTO_RUN_TO_ROUTE_STUCK_MIN_MOVE = 0.75
local AUTO_RUN_TO_ROUTE_RETARGET_SECONDS = 0.35
local AUTO_RUN_TO_ROUTE_MIN_SPEED = 18
local AUTO_RUN_TO_ROUTE_MAX_SPEED = 500

local function getAutoRouteRunSpeed(recordedBaseSpeed, hum)
    -- Pakai speed route yang di-load jika tersedia, lalu fallback ke kondisi current humanoid / saved speed.
    local recordedSpeed = safeNumber(recordedBaseSpeed, 0)
    if recordedSpeed > 0 then
        return math.clamp(recordedSpeed, AUTO_RUN_TO_ROUTE_MIN_SPEED, AUTO_RUN_TO_ROUTE_MAX_SPEED)
    end

    local speed = 0
    if hum then
        speed = safeNumber(hum.WalkSpeed, 0)
    end

    if speed <= 2 then
        speed = safeNumber(savedWalkSpeed, 0)
    end

    if speed <= 2 then
        speed = 16
    end

    -- Clamp to configured min/max to avoid absurd values
    speed = math.clamp(speed, AUTO_RUN_TO_ROUTE_MIN_SPEED, AUTO_RUN_TO_ROUTE_MAX_SPEED)
    return speed
end

local function getRouteLoadedSpeed(track)
    local routeSpeed = safeNumber(loadedRouteInfo.speed, 0)
    if routeSpeed > 2 then
        return routeSpeed
    end

    if type(track) == "table" and #track > 0 then
        -- Try to estimate from actual frame distances/times first
        local est = ForkyEstimateBaseSpeed and ForkyEstimateBaseSpeed(track)
        if est and est > 2 then
            return est
        end
        routeSpeed = safeNumber(track[1].walkSpeed, 0)
        if routeSpeed > 2 then
            return routeSpeed
        end
        
        local avgSpeed = 0
        local count = 0
        for i = 1, math.min(100, #track) do
            local frameSpeed = safeNumber(track[i].walkSpeed or track[i].speed or track[i].ws, 0)
            if frameSpeed > 2 then
                avgSpeed = avgSpeed + frameSpeed
                count = count + 1
            end
        end
        if count > 0 then
            return avgSpeed / count
        end
    end

    return 20
end

-- Estimate base speed by sampling frame distances / time deltas (robust median)
function ForkyEstimateBaseSpeed(frames)
    if type(frames) ~= "table" or #frames < 2 then return nil end
    local speeds = {}
    for i = 1, #frames-1 do
        local a = frames[i]
        local b = frames[i+1]
        if a and b and a.pos and b.pos and a.time and b.time then
            local dt = (b.time - a.time)
            if dt and dt > 0.001 then
                local dist = Vector3.new(b.pos.X - a.pos.X, 0, b.pos.Z - a.pos.Z).Magnitude
                local sp = dist / dt
                if sp > 0 and sp < 1000 then
                    table.insert(speeds, sp)
                end
            end
        end
        if #speeds >= 2000 then break end
    end
    if #speeds == 0 then return nil end
    table.sort(speeds)
    local n = #speeds
    if n % 2 == 1 then
        return speeds[math.floor(n/2)+1]
    else
        return (speeds[n/2] + speeds[n/2 + 1]) / 2
    end
end

local function ForkyHUBAutoRunFramePos(frame, fallback)
    fallback = fallback or Vector3.new(0, 0, 0)
    if type(frame) ~= "table" then return fallback end
    if typeof(frame.pos) == "Vector3" then return frame.pos end
    if typeof(frame.position) == "Vector3" then return frame.position end
    return vec3FromTable(frame.position) or vec3FromTable(frame.pos) or fallback
end

local function ForkyHUBAutoRunFindFrameIndex(frames, targetFrame)
    if type(frames) ~= "table" or #frames <= 0 then return 1 end
    if type(targetFrame) ~= "table" then return 1 end
    for i = 1, #frames do
        if frames[i] == targetFrame then
            return i
        end
    end
    return 1
end

local function ForkyHUBAutoRunPickTarget(frames, baseIndex, currentPos)
    if type(frames) ~= "table" or #frames <= 0 then
        return nil, 1
    end
    local lookAhead = math.max(0, math.floor(AUTO_RUN_TO_ROUTE_LOOKAHEAD_FRAMES))
    local maxIndex  = math.max(1, #frames - 1)
    local idx = math.clamp(baseIndex or 1, 1, maxIndex)
    local targetIndex = math.clamp(idx + lookAhead, 1, maxIndex)
    local targetPos = ForkyHUBAutoRunFramePos(frames[targetIndex], currentPos)
    if typeof(targetPos) ~= "Vector3" then
        targetIndex = idx
        targetPos = ForkyHUBAutoRunFramePos(frames[targetIndex], currentPos)
    end
    return targetPos, targetIndex
end

local function runToRoutePointBeforePlayback(hum, hrp, targetFrame, recordedBaseSpeed)
    if not AUTO_RUN_TO_ROUTE_ENABLED then return true end
    if not hum or not hrp or not targetFrame then return true end

    local track = SelectedTrackData or {}
    if #track == 0 then return true end

    local targetIndex = ForkyHUBAutoRunFindFrameIndex(track, targetFrame)
    local targetPos = nil
    if #track > 1 then
        targetPos, targetIndex = ForkyHUBAutoRunPickTarget(track, targetIndex, hrp.Position)
    else
        targetPos = ForkyHUBAutoRunFramePos(targetFrame, hrp.Position)
    end

    if typeof(targetPos) ~= "Vector3" then return true end

    local runSpeed = getAutoRouteRunSpeed(recordedBaseSpeed, hum)
    local startDelta = Vector3.new(targetPos.X, hrp.Position.Y, targetPos.Z) - hrp.Position
    local maxRunTime = math.max(AUTO_RUN_TO_ROUTE_MAX_TIME, (startDelta.Magnitude / math.max(runSpeed, 1)) + 4)
    local stopDistance = AUTO_RUN_TO_ROUTE_STOP_DISTANCE
    local acceptDistance = math.max(stopDistance, stopDistance * AUTO_RUN_TO_ROUTE_ACCEPT_MULTIPLIER)
    local overshootDistance = math.max(acceptDistance + 1, stopDistance * AUTO_RUN_TO_ROUTE_OVERSHOOT_MULTIPLIER)
    local stuckSeconds = AUTO_RUN_TO_ROUTE_STUCK_SECONDS
    local stuckMinMove = AUTO_RUN_TO_ROUTE_STUCK_MIN_MOVE
    local retargetEvery = AUTO_RUN_TO_ROUTE_RETARGET_SECONDS

    local bestDist = math.huge
    local lastProgressPos = hrp.Position
    local lastProgressClock = tick()
    local lastRetargetClock = 0
    local lastDir = nil

    -- Debug toggle: set true to print run details to output every 0.5s
    local DEBUG_AUTO_RUN = false
    local lastDebugClock = 0

    pcall(function()
        hum.AutoRotate = true
        hum.PlatformStand = false
        hum.Sit = false
        hum.Jump = false
        hum:ChangeState(Enum.HumanoidStateType.Running)
        hum.WalkSpeed = runSpeed
    end)

    local startClock = tick()
    while AutoWalkActive do
        if not Player.Character then
            return false
        end

        local char = Player.Character
        local hum2  = char:FindFirstChildOfClass("Humanoid")
        local hrp2  = char:FindFirstChild("HumanoidRootPart")
        if not hum2 or not hrp2 then
            return false
        end

        local currentPos = hrp2.Position
        local targetPosFlat = Vector3.new(targetPos.X, currentPos.Y, targetPos.Z)
        local delta = targetPosFlat - currentPos
        local dist = delta.Magnitude

        if dist < bestDist then
            bestDist = dist
            lastProgressPos = currentPos
            lastProgressClock = tick()
        end

        if dist <= acceptDistance then
            pcall(function()
                hum2:Move(Vector3.new(0, 0, 0), false)
                hrp2.AssemblyLinearVelocity = Vector3.new(0, hrp2.AssemblyLinearVelocity.Y, 0)
            end)
            return true
        end

        if #track > 1 and tick() - lastRetargetClock >= retargetEvery then
            lastRetargetClock = tick()
            local nearestIndex, nearestDist = findNearestTrackFrameToPosition(currentPos, track)
            nearestIndex = math.clamp(nearestIndex or targetIndex, 1, math.max(1, #track - 1))
            if nearestDist and nearestDist <= acceptDistance then
                pcall(function()
                    hum2:Move(Vector3.new(0, 0, 0), false)
                    hrp2.AssemblyLinearVelocity = Vector3.new(0, hrp2.AssemblyLinearVelocity.Y, 0)
                end)
                return true
            end
            if nearestIndex >= targetIndex or (nearestDist and nearestDist + 2 < bestDist) then
                targetPos, targetIndex = ForkyHUBAutoRunPickTarget(track, nearestIndex, currentPos)
            end
        end

        if lastDir and delta.Magnitude > 0.01 then
            local nowDir = delta.Unit
            if lastDir:Dot(nowDir) < -0.15 and bestDist <= overshootDistance then
                pcall(function()
                    hum2:Move(Vector3.new(0, 0, 0), false)
                    hrp2.AssemblyLinearVelocity = Vector3.new(0, hrp2.AssemblyLinearVelocity.Y, 0)
                end)
                return true
            end
        end

        if bestDist <= overshootDistance and dist > bestDist + 1.25 then
            pcall(function()
                hum2:Move(Vector3.new(0, 0, 0), false)
                hrp2.AssemblyLinearVelocity = Vector3.new(0, hrp2.AssemblyLinearVelocity.Y, 0)
            end)
            return true
        end

        if tick() - lastProgressClock >= stuckSeconds then
            local moved = (currentPos - lastProgressPos).Magnitude
            if moved <= stuckMinMove or bestDist <= overshootDistance * 1.75 then
                pcall(function()
                    hum2:Move(Vector3.new(0, 0, 0), false)
                    hrp2.AssemblyLinearVelocity = Vector3.new(0, hrp2.AssemblyLinearVelocity.Y, 0)
                end)
                return true
            end
            lastProgressPos = currentPos
            lastProgressClock = tick()
        end

        if tick() - startClock > maxRunTime then
            pcall(function()
                hum2:Move(Vector3.new(0, 0, 0), false)
                hrp2.AssemblyLinearVelocity = Vector3.new(0, hrp2.AssemblyLinearVelocity.Y, 0)
            end)
            return true
        end

        local dir = delta.Magnitude > 0 and delta.Unit or Vector3.new(0, 0, 0)
        lastDir = dir

        pcall(function()
            hum2.AutoRotate = true
            hum2.PlatformStand = false
            hum2.Sit = false
            hum2.WalkSpeed = runSpeed
            hum2:Move(dir, false)
            hrp2.AssemblyLinearVelocity = Vector3.new(
                dir.X * runSpeed,
                hrp2.AssemblyLinearVelocity.Y,
                dir.Z * runSpeed
            )

            if dir.Magnitude > 0.01 then
                hrp2.CFrame = CFrame.lookAt(hrp2.Position, hrp2.Position + Vector3.new(dir.X, 0, dir.Z))
            end

            if targetPos.Y - currentPos.Y > 2.75 and dist > stopDistance then
                hum2.Jump = true
            else
                hum2.Jump = false
            end
        end)

        if DEBUG_AUTO_RUN and tick() - lastDebugClock >= 0.5 then
            lastDebugClock = tick()
            pcall(function()
                print(string.format("[AutoRun Debug] recordedBaseSpeed=%.2f runSpeed=%.2f humWalkSpeed=%.2f dist=%.2f bestDist=%.2f vel=%.2f", 
                    safeNumber(recordedBaseSpeed,0), runSpeed, safeNumber(hum2.WalkSpeed,0), dist, bestDist, hrp2.AssemblyLinearVelocity.Magnitude))
            end)
        end

        RunService.Heartbeat:Wait()
    end

    return AutoWalkActive
end

-- Smart resume position finder (adapted from FreeWALKADARECORDER.lua)
local function ForkyHUBPlaybackFindStart(frames)
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not frames or #frames < 2 then return 1, 0, 0 end

    local firstT = safeNumber(frames[1].time, 0)
    local lastT = safeNumber(frames[#frames].time, firstT)
    local finishLimit = math.max(lastT - PLAY_FINISH_RESTART_TIME_WINDOW, firstT)
    local finishPos = (frames[#frames] and frames[#frames].pos) or Vector3.new(0,0,0)
    local distanceToFinish = (finishPos - hrp.Position).Magnitude

    local closestIndex, distanceTo = findNearestTrackFrameToPosition(hrp.Position, frames)
    closestIndex = math.clamp(closestIndex, 1, math.max(1, #frames - 1))
    local targetTime = safeNumber(frames[closestIndex] and frames[closestIndex].time, firstT)

    if TrackFinished == true and distanceToFinish <= PLAY_FINISH_RESTART_DISTANCE and targetTime >= finishLimit then
        lastKnownPosition = nil
        lastKnownPlaybackTime = 0
        WindUI:Notify({Title="Smart Resume", Content="Masih di FINISH, balik ke START", Duration=1})
        return 1, firstT, distanceToFinish
    end

    if distanceTo > AUTO_RUN_TO_ROUTE_FAR_PATH_START_DISTANCE then
        WindUI:Notify({Title="Smart Resume", Content="Jauh dari path, cari titik track terdekat", Duration=1})
        return closestIndex, targetTime, distanceTo
    end

    if targetTime >= finishLimit then
        WindUI:Notify({Title="Smart Resume", Content="Dekat akhir, lanjut dari titik terdekat", Duration=1})
        return closestIndex, targetTime, distanceTo
    end

    WindUI:Notify({Title="Smart Resume", Content="Mulai dari titik terdekat", Duration=1})
    return closestIndex, targetTime, distanceTo
end

StopWalk = function()
    AutoWalkActive = false
    if WalkConnection then WalkConnection:Disconnect(); WalkConnection=nil end
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0) end
    if PlayStopBtn then PlayStopBtn.Text = "PLAY" end
end

local function DoRespawn()
    local char = Player.Character
    if char then
        pcall(function() char:BreakJoints() end)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function() hum.Health = 0 end)
        end
        local head = char:FindFirstChild("Head")
        if head then
            pcall(function() head:Destroy() end)
        end
    end
    local deadline = tick() + 10
    repeat task.wait(0.1)
    until (Player.Character and Player.Character ~= char
        and Player.Character:FindFirstChild("HumanoidRootPart")
        and Player.Character:FindFirstChild("Humanoid")
        and Player.Character.Humanoid.Health > 0)
        or tick() > deadline
    task.wait(0.3)
end

-- ══════════════════════════════════════════════════════════════
-- CLIMB ANIMATION HELPER (BITWISE)
-- ══════════════════════════════════════════════════════════════
local function stopClimbAnimation()
    pcall(function()
        if activeClimbTrack then
            activeClimbTrack:Stop(0.15)
            activeClimbTrack:Destroy()
        end
    end)

    activeClimbTrack = nil
    activeClimbHumanoid = nil
end

local function getClimbAnimationId(character)
    local animate = character and character:FindFirstChild("Animate")
    if animate then
        local climbFolder = animate:FindFirstChild("climb")
        if climbFolder then
            local climbAnim = climbFolder:FindFirstChild("ClimbAnim")
            if climbAnim and climbAnim:IsA("Animation") and climbAnim.AnimationId ~= "" then
                return climbAnim.AnimationId
            end
        end
    end
    return "rbxassetid://180436334"
end

local function playClimbAnimation(character, humanoid, climbSpeed)
    if not character or not humanoid then return end

    pcall(function()
        if activeClimbHumanoid ~= humanoid then
            stopClimbAnimation()

            local animator = humanoid:FindFirstChildOfClass("Animator")
            if not animator then
                animator = Instance.new("Animator")
                animator.Parent = humanoid
            end

            local anim = Instance.new("Animation")
            anim.AnimationId = getClimbAnimationId(character)

            activeClimbTrack = animator:LoadAnimation(anim)
            activeClimbTrack.Priority = Enum.AnimationPriority.Movement
            activeClimbTrack.Looped = true
            activeClimbHumanoid = humanoid
        end

        if activeClimbTrack and not activeClimbTrack.IsPlaying then
            activeClimbTrack:Play(0.1, 1, 1)
        end

        if activeClimbTrack then
            local animSpeed = math.clamp(math.abs(climbSpeed or 8) / 8, 0.6, 2.5)
            activeClimbTrack:AdjustSpeed(animSpeed)
        end
    end)
end

local function oniumSafeVelocity(vec, maxH, maxY)
    if typeof(vec) ~= "Vector3" then
        return Vector3.new(0, 0, 0)
    end

    maxH = safeNumber(maxH, 120)
    maxY = safeNumber(maxY, 80)

    vec = safeVector3(vec)
    local h = Vector3.new(vec.X, 0, vec.Z)
    local hMag = safeMagnitude(h)

    if hMag > maxH and hMag > 0 then
        h = h.Unit * maxH
    end

    return Vector3.new(
        safeNumber(h.X, 0),
        math.clamp(vec.Y, -maxY, maxY),
        safeNumber(h.Z, 0)
    )
end

-- SHIFTLOCK HANDLER
local ShiftLockConnection = nil
local savedAutoRotateForShiftLock = false

-- Function to check if native Roblox Shift Lock or our custom one is active
local function IsShiftLockActive()
    if ShiftLockActive then return true end
    -- Check for native Shift Lock (Mouse is locked to center)
    return UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
end

local function enableShiftLockListener()
    if ShiftLockConnection then return end
    
    ShiftLockConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        
        -- CUSTOM: Middle mouse button toggle
        if input.UserInputType == Enum.UserInputType.MouseButton3 then
            ShiftLockActive = not ShiftLockActive
            hum.AutoRotate = ShiftLockActive
            
            if ShiftLockActive then
                WindUI:Notify({Title="🎥", Content="ShiftLock: ON", Duration=1})
            else
                WindUI:Notify({Title="🎥", Content="ShiftLock: OFF", Duration=1})
            end
        end
    end)
end

local function disableShiftLockListener()
    if ShiftLockConnection then
        ShiftLockConnection:Disconnect()
        ShiftLockConnection = nil
    end
    ShiftLockActive = false
end

-- Helper to set CFrame while respecting ShiftLock
local function setCFrameWithShiftLock(part, newPos, newRot)
    local char = part.Parent
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    
    if IsShiftLockActive() then
        -- Ensure AutoRotate is ON so the engine/camera can rotate the body
        if hum and not hum.AutoRotate then
            hum.AutoRotate = true
        end
        -- When ShiftLock active, only update position, keep current rotation (camera-controlled)
        local currentRot = (part.CFrame - part.Position)
        part.CFrame = CFrame.new(newPos) * currentRot
    else
        -- Normal: set both position and rotation (path-controlled)
        part.CFrame = CFrame.new(newPos) * newRot
    end
end

-- ══════════════════════════════════════════════════════════════
-- MOVEMENT CORE — TIME-MULTIPLIER SYSTEM
-- Ported dari FreeWALKADARECORDER.lua:
-- currentPlaybackTime += realDt * timeMultiplier
-- timeMultiplier = playbackRuntimeSpeed / recordedBaseSpeed
-- → waktu maju lebih cepat → lebih banyak frame di-skip → benar-benar lebih cepat
-- Mengubah speed via input langsung berpengaruh LIVE tanpa Stop/Play ulang.
-- ══════════════════════════════════════════════════════════════
local function StartAutoPlay(onFinished)
    if WalkConnection then WalkConnection:Disconnect() end

    local trackData = ReverseMode and ReversedTrackData or SelectedTrackData
    local trackLen  = #trackData

    -- SAVE CHARACTER STATE
    local c = Player.Character
    local hum = c and c:FindFirstChild("Humanoid")
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    
    if hum then
        -- savedWalkSpeed = speed asli map/coil, untuk di-restore setelah stop
        savedWalkSpeed = safeNumber(hum.WalkSpeed, 16)
        if savedWalkSpeed <= 0 then savedWalkSpeed = 16 end
        
        savedJumpPower = safeNumber(hum.JumpPower, 50)
        if savedJumpPower <= 0 then savedJumpPower = 50 end
        
        savedJumpHeight = safeNumber(hum.JumpHeight, 7.2)
        if savedJumpHeight <= 0 then savedJumpHeight = 7.2 end
        
        local okUseJumpPower, useJumpPowerValue = pcall(function() return hum.UseJumpPower end)
        if okUseJumpPower then savedUseJumpPower = useJumpPowerValue end
        
        savedAutoRotate = hum.AutoRotate
        hum.AutoRotate = IsShiftLockActive()
    end

    -- Hitung base speed dari recording (sekali saat play dimulai)
    recordedBaseSpeed = math.max(safeNumber(getRouteLoadedSpeed(trackData), 16), 1)

    -- FIX: Jangan reset playbackRuntimeSpeed kalau user sudah set manual.
    -- Reset hanya kalau benar-benar 0 / belum pernah di-set.
    if playbackRuntimeSpeed <= 0 then
        playbackRuntimeSpeed = recordedBaseSpeed
    end
    playbackRuntimeSpeed = math.clamp(playbackRuntimeSpeed, MIN_PB_SPEED, MAX_PB_SPEED)

    -- Smart resume
    local nearestIndex, nearestDistance = 1, 0
    if hrp and trackLen > 0 then
        local idx, timeVal, dist = ForkyHUBPlaybackFindStart(trackData)
        nearestIndex = math.clamp(idx or 1, 1, math.max(1, trackLen - 1))
        ResumeTrackTime = safeNumber(timeVal, (trackData[nearestIndex] and trackData[nearestIndex].time) or 0)
        nearestDistance = safeNumber(dist, 0)
    else
        ResumeTrackTime = 0
    end

    AutoWalkActive = true
    if hrp and trackLen > 0 and AUTO_RUN_TO_ROUTE_ENABLED and nearestDistance > AUTO_RUN_TO_ROUTE_STOP_DISTANCE then
        local runOk = runToRoutePointBeforePlaybackFree(hum, hrp, trackData[nearestIndex], recordedBaseSpeed)
        if not runOk then
            AutoWalkActive = false
            StopWalk()
            return
        end
        pcall(function()
            hum.WalkSpeed = savedWalkSpeed
            hum.AutoRotate = IsShiftLockActive()
        end)
        nearestIndex, nearestDistance = findNearestTrackFrameToPosition(hrp.Position, trackData)
        ResumeTrackTime = trackData[nearestIndex].time
    end

    -- Inisialisasi sistem waktu baru (TIME-MULTIPLIER style)
    local currentPlaybackTime = ResumeTrackTime
    local lastClock = tick()
    local firstT = safeNumber(trackData[1] and trackData[1].time, 0)
    local lastT  = safeNumber(trackData[trackLen] and trackData[trackLen].time, 0)

    TrackStartTime  = tick()
    lastJumpIdx     = 0
    TrackFinished   = false
    _G.ForkyBeta_LastState      = nil
    _G.ForkyBeta_LastStateClock = 0
    if PlayStopBtn then PlayStopBtn.Text = "STOP" end

    WalkConnection = RunService.Heartbeat:Connect(function(dt)
        local char = Player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not (hrp and hum and trackLen > 0) then return end

        -- ══════════════════════════════════════════════
        -- LIVE SPEED TIME MULTIPLIER (inti dari FreeWALKADARECORDER)
        -- ══════════════════════════════════════════════
        local now    = tick()
        local realDt = now - lastClock
        lastClock    = now
        if realDt <= 0 then realDt = 0.016
        elseif realDt > 0.2 then realDt = 0.1 end

        -- Baca ulang playbackRuntimeSpeed setiap frame (live update)
        local liveSpeed = math.clamp(playbackRuntimeSpeed, MIN_PB_SPEED, MAX_PB_SPEED)
        local timeMultiplier = math.clamp(liveSpeed / recordedBaseSpeed, LOOP_MULT_MIN, LOOP_MULT_MAX)

        -- Maju waktu dengan multiplier → lebih cepat = skip lebih banyak frame
        currentPlaybackTime = currentPlaybackTime + (realDt * timeMultiplier)

        local trackTime = currentPlaybackTime

        if trackTime > CurrentTrackDuration then
            StopWalk(); TrackFinished = true
            if onFinished then onFinished() end
            return
        end

        -- BINARY SEARCH frame
        local lo, hi, fi = 1, trackLen, 1
        while lo <= hi do
            local mid = math.floor((lo+hi)/2)
            if trackData[mid].time <= trackTime then fi=mid; lo=mid+1 else hi=mid-1 end
        end

        local cf = trackData[fi]
        local nf = trackData[fi+1]
        if not cf then return end

        local targetPos
        if nf and nf.time > cf.time then
            local t = (trackTime-cf.time)/(nf.time-cf.time)
            targetPos = cf.pos:Lerp(nf.pos, math.clamp(t,0,1))
        else
            targetPos = cf.pos
        end

        local hrpPos = hrp.Position
        local dx = targetPos.X - hrpPos.X
        local dz = targetPos.Z - hrpPos.Z
        local dist = math.sqrt(dx*dx + dz*dz)

        local alpha = 0
        if nf and nf.time > cf.time then
            alpha = math.clamp((trackTime - cf.time)/(nf.time - cf.time), 0, 1)
        end

        local yaw = getRecordedYaw(cf, nf, alpha)
        if FlipState then yaw = yaw + math.pi end
        local targetRot = CFrame.Angles(0, yaw, 0)

        local hasRecordedRotation = tonumber(cf.rotation or cf.rot or cf.yaw) ~= nil
            or (nf and tonumber(nf.rotation or nf.rot or nf.yaw) ~= nil)

        if not hasRecordedRotation then
            local movementDir = nil
            if nf then movementDir = nf.pos - cf.pos end
            if not movementDir or movementDir.Magnitude < 0.05 then
                movementDir = Vector3.new(dx, 0, dz)
            else
                movementDir = Vector3.new(movementDir.X, 0, movementDir.Z)
            end
            if movementDir.Magnitude > 0.05 then
                local targetLookPos = hrpPos + movementDir.Unit
                targetRot = (CFrame.new(hrpPos, targetLookPos) - hrpPos)
                if FlipState then targetRot = targetRot * CFrame.Angles(0, math.pi, 0) end
            end
        end

        local targetCF = CFrame.new(targetPos) * targetRot

        local stateText = tostring(cf.state or "")
        local isClimbing = cf.climbing == true or stateText == "Climbing"
        local isSwimming = cf.swimming == true or stateText == "Swimming"
        local isJumping  = cf.jump == true or stateText == "Jumping"
        local isFreefall = cf.freefall == true or stateText == "Freefall"
        local airborne   = isJumping or isFreefall or isSwimming

        -- ══════════════════════════════════════════════
        -- VELOCITY berbasis frame delta × timeMultiplier
        -- Ini yang membuat fisik avatar ikut lebih cepat
        -- ══════════════════════════════════════════════
        local mapVel = Vector3.zero
        if nf and nf.time > cf.time then
            local posDiff  = nf.pos - cf.pos
            local timeDiff = math.max(nf.time - cf.time, 0.001)
            -- kalkulasi velocity dari delta posisi × multiplier (sama seperti FreeWALKADARECORDER)
            mapVel = (posDiff / timeDiff) * timeMultiplier
        elseif cf.vel and cf.vel.Magnitude > 0 then
            mapVel = cf.vel * timeMultiplier
        end

        -- CLIMBING
        if isClimbing then
            hrp.CFrame = targetCF
            local climbVel = Vector3.new(
                math.clamp(mapVel.X * 0.25, -80, 80),
                math.clamp(mapVel.Y, -45, 45),
                math.clamp(mapVel.Z * 0.25, -80, 80)
            )
            hum.Sit = false
            hum.PlatformStand = false
            hum.WalkSpeed = math.max(liveSpeed, 16)
            changeStateSoft(hum, "Climbing", false)
            hrp.AssemblyLinearVelocity = climbVel
            playClimbAnimation(char, hum, mapVel.Y)

        -- AIRBORNE / JUMPING / FREEFALL
        elseif airborne then
            local currentRot = (hrp.CFrame - hrp.Position)
            local lerpedRot  = currentRot:Lerp(targetRot, 0.2)
            setCFrameWithShiftLock(hrp, targetCF.Position, lerpedRot)

            local hVel = Vector3.new(mapVel.X, 0, mapVel.Z)
            local maxH = math.max(liveSpeed * 1.5, 100)
            if hVel.Magnitude > maxH and hVel.Magnitude > 0 then
                hVel = hVel.Unit * maxH
            end
            local yVel = math.clamp(mapVel.Y, -220, 170)

            hrp.AssemblyLinearVelocity = Vector3.new(hVel.X, yVel, hVel.Z)
            hum.Sit = false
            hum.PlatformStand = false
            hum.WalkSpeed = liveSpeed

            if isFreefall then
                hum.Jump = false
                changeStateSoft(hum, "Freefall", false)
            else
                changeStateSoft(hum, "Jumping", false)
            end

        -- RUNNING / GROUND
        else
            stopClimbAnimation()

            -- Y correction hipHeight
            local recHipHeight = cf.hipHeight or 3.5
            local curHipHeight = hum.HipHeight or 3.5
            if recHipHeight > 0 and curHipHeight > 0 then
                local yFix = curHipHeight - recHipHeight
                if math.abs(yFix) <= 8 then
                    targetPos = Vector3.new(targetPos.X, targetPos.Y + yFix, targetPos.Z)
                end
            end

            -- Set WalkSpeed ke liveSpeed agar animasi lari ikut speed baru
            hum.WalkSpeed = liveSpeed

            -- Velocity horizontal dari delta posisi × multiplier (bukan velocity dummy)
            local hVel = Vector3.new(mapVel.X, 0, mapVel.Z)
            local maxH = math.max(liveSpeed * 1.5, 60)
            if hVel.Magnitude > maxH and hVel.Magnitude > 0 then
                hVel = hVel.Unit * maxH
            end
            local yVel = math.clamp(mapVel.Y, -80, 80)

            -- Apply Smart AI Speed multiplier ke horizontal velocity
            local smartFactor = 1
            if SmartAISpeed.enabled then
                local smartTarget = calculateSmartSpeed(liveSpeed)
                smartFactor = smartTarget / math.max(liveSpeed, 1)
            end

            hrp.AssemblyLinearVelocity = Vector3.new(
                hVel.X * smartFactor,
                hrp.AssemblyLinearVelocity.Y,
                hVel.Z * smartFactor
            )

            -- CFrame ikut posisi target langsung (seperti FreeWALKADARECORDER)
            local currentRot = (hrp.CFrame - hrp.Position)
            local lerpedRot  = currentRot:Lerp(targetRot, 0.15)
            if dist > 0.5 then
                local correctedPos = hrpPos:Lerp(targetPos, 0.12)
                setCFrameWithShiftLock(hrp, correctedPos, lerpedRot)
            else
                setCFrameWithShiftLock(hrp, hrp.Position, lerpedRot)
            end

            local yDiff = targetPos.Y - hrpPos.Y
            if math.abs(yDiff) > 0.5 then
                local pos = hrp.CFrame.Position + Vector3.new(0, yDiff * 0.25, 0)
                setCFrameWithShiftLock(hrp, pos, (hrp.CFrame - hrp.CFrame.Position))
            end

            hum.Sit = false
            hum.PlatformStand = false
            changeStateSoft(hum, "Running", false)
        end

        -- Jump trigger: hanya saat pertama kali masuk frame jump (bukan tiap heartbeat)
        local nowT = tick()
        if fi > lastJumpIdx
           and isJumping
           and math.abs(trackTime - cf.time) <= 0.08
           and (nowT - lastJumpSent) >= 0.3
           and not isAirborne(hum) then
            hum.Jump = true
            -- Force state change saat awal jump supaya tidak tertahan
            _G.ForkyBeta_LastState = nil
            changeStateSoft(hum, "Jumping", true)
            lastJumpIdx  = fi
            lastJumpSent = nowT
        end
    end)
    
    -- RESTORE AFTER FINISH
    task.spawn(function()
        while AutoWalkActive do
            task.wait(0.5)
        end
        
        -- RESTORE CHARACTER STATE
        task.wait(0.1)
        local c, hum, hrp = Player.Character, nil, nil
        if c then
            hum = c:FindFirstChild("Humanoid")
            hrp = c:FindFirstChild("HumanoidRootPart")
        end
        
        if hum then
            pcall(function()
                hum.AutoRotate = savedAutoRotate
                hum.PlatformStand = false
                hum.Sit = false
                hum.Jump = false
                hum.WalkSpeed = savedWalkSpeed
                hum.JumpPower = savedJumpPower
                hum.JumpHeight = savedJumpHeight
                hum.UseJumpPower = savedUseJumpPower
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end
        
        if hrp then
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)
        end
        
        stopClimbAnimation()
    end)
end

-- ══════════════════════════════════════════════════════════════
-- AUTO LOOP
-- ══════════════════════════════════════════════════════════════
StopLoop = function()
    AutoLoopEnabled = false
    IsLooping       = false
    StopWalk()
    WindUI:Notify({Title="🔁 Loop", Content="Auto Loop dimatikan.", Duration=2})
end

local function StartLoop()
    if IsLooping then return end
    if #SelectedTrackData == 0 then
        WindUI:Notify({Title="❌", Content="Load track dulu!", Duration=2}); return
    end
    IsLooping = true; AutoLoopEnabled = true

    task.spawn(function()
        while AutoLoopEnabled and IsLooping do
            ResumeTrackTime = 0
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp and #SelectedTrackData > 0 then
                hrp.CFrame = CFrame.new(SelectedTrackData[1].pos)
                task.wait(0.2)
            end

            local finished = false
            StartAutoPlay(function() finished = true end)
            repeat task.wait(0.2) until finished or not AutoLoopEnabled
            if not AutoLoopEnabled then break end

            WindUI:Notify({Title="🔁 Loop", Content="Putaran selesai!", Duration=1.5})

            if AutoRespawnEnabled then
                task.wait(5) -- Delay 5 seconds
                WindUI:Notify({Title="💀 Respawn", Content="Auto respawn...", Duration=2})
                DoRespawn()
            else
                task.wait(0.5)
            end

            local deadline = tick() + 10
            repeat task.wait(0.1)
            until (Player.Character
                and Player.Character:FindFirstChild("HumanoidRootPart")
                and Player.Character:FindFirstChild("Humanoid")
                and Player.Character.Humanoid.Health > 0)
                or tick() > deadline
            task.wait(0.3)
        end
        IsLooping = false
        if PlayStopBtn then PlayStopBtn.Text = "PLAY" end
    end)
end

-- ══════════════════════════════════════════════════════════════
-- SERVER HOP
-- ══════════════════════════════════════════════════════════════
local function hopToEmptyServer()
    WindUI:Notify({Title="🔍", Content="Searching for empty server...", Duration=3})
    local ok, servers = pcall(function()
        return HttpService:JSONDecode(httpGet(
            "https://games.roblox.com/v1/games/"..PLACE_ID.."/servers/Public?sortOrder=Asc&limit=100"
        ))
    end)
    if ok and servers and servers.data then
        local list = {}
        for _, s in pairs(servers.data) do
            if s.playing < 10 and s.id ~= game.JobId then table.insert(list, s.id) end
        end
        if #list > 0 then
            WindUI:Notify({Title="🚀", Content="Joining ("..#list.." available)", Duration=2})
            task.wait(1)
            TeleportService:TeleportToPlaceInstance(PLACE_ID, list[math.random(1,#list)], Player)
        else
            WindUI:Notify({Title="❌", Content="No empty servers found!", Duration=3})
        end
    else
        WindUI:Notify({Title="❌", Content="Failed to fetch servers!", Duration=3})
    end
end

-- ══════════════════════════════════════════════════════════════
-- ANTI AFK
-- ══════════════════════════════════════════════════════════════
local AntiAFKConn = nil; local AntiAFKEnabled = true

local function enableAntiAFK()
    AntiAFKEnabled = true
    if AntiAFKConn then return end
    if not keepAliveUser then
        return
    end
    AntiAFKConn = RunService.Heartbeat:Connect(function()
        if not AntiAFKEnabled then return end
        keepAliveUser:CaptureController(); keepAliveUser:ClickButton2(Vector2.new())
    end)
end

local function disableAntiAFK()
    AntiAFKEnabled = false
    if AntiAFKConn then AntiAFKConn:Disconnect(); AntiAFKConn=nil end
end

-- ══════════════════════════════════════════════════════════════
-- PREMIUM BUTTONS
-- ══════════════════════════════════════════════════════════════
local function CreatePremiumButtons()
    if CoreGui:FindFirstChild("ForkyPremiumButtons") then
        CoreGui:FindFirstChild("ForkyPremiumButtons"):Destroy()
    end
    local SG = Instance.new("ScreenGui", CoreGui)
    SG.Name = "ForkyPremiumButtons"
    SG.Enabled = false
    SG.ResetOnSpawn = false
    SG.IgnoreGuiInset = true
    SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- ── PALETTE ─────────────────────────────────────────────────
    local cBg        = Color3.fromRGB(13, 14, 20)
    local cBgTop     = Color3.fromRGB(24, 26, 38)
    local cCyan      = Color3.fromRGB(0, 210, 255)
    local cBlue      = Color3.fromRGB(90, 120, 255)
    local cGreen     = Color3.fromRGB(70, 230, 150)
    local cGreenDark = Color3.fromRGB(20, 140, 90)
    local cRed       = Color3.fromRGB(255, 90, 100)
    local cRedDark   = Color3.fromRGB(170, 40, 55)
    local cPurple    = Color3.fromRGB(185, 110, 255)
    local cPurpleDk  = Color3.fromRGB(110, 55, 190)
    local cIdleBar   = Color3.fromRGB(60, 64, 84)
    local cIdleBg    = Color3.fromRGB(24, 26, 36)
    local cIdleText  = Color3.fromRGB(150, 156, 178)

    -- ══════════════════════════════════════════════════════════
    -- MAIN FRAME
    -- ══════════════════════════════════════════════════════════
    local MainFrame = Instance.new("Frame", SG)
    MainFrame.Name             = "Controller"
    MainFrame.AnchorPoint      = Vector2.new(0.5, 1)
    MainFrame.Position         = UDim2.new(0.5, 0, 1, -28)
    MainFrame.Size             = UDim2.new(0, 336, 0, 112)
    MainFrame.BackgroundColor3 = cBg
    MainFrame.BorderSizePixel  = 0
    MainFrame.ClipsDescendants = false
    MainFrame.Active           = true

    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 20)

    local MainGradient = Instance.new("UIGradient", MainFrame)
    MainGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, cBgTop),
        ColorSequenceKeypoint.new(1, cBg),
    })
    MainGradient.Rotation = 90

    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.Color        = Color3.fromRGB(50, 54, 72)
    MainStroke.Thickness    = 1
    MainStroke.Transparency = 0.2

    -- Animated glowing border accent (rotating gradient ring effect)
    local GlowStroke = Instance.new("UIStroke", MainFrame)
    GlowStroke.Thickness    = 1.5
    GlowStroke.Transparency = 0.35
    GlowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local GlowGradient = Instance.new("UIGradient", GlowStroke)
    GlowGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,    cCyan),
        ColorSequenceKeypoint.new(0.35, cBlue),
        ColorSequenceKeypoint.new(0.65, cPurple),
        ColorSequenceKeypoint.new(1,    cCyan),
    })

    task.spawn(function()
        local rot = 0
        while SG and SG.Parent do
            rot = (rot + 1.2) % 360
            GlowGradient.Rotation = rot
            task.wait(0.03)
        end
    end)

    -- ══════════════════════════════════════════════════════════
    -- TOP DRAG HANDLE
    -- ══════════════════════════════════════════════════════════
    local TopHandle = Instance.new("TextButton", MainFrame)
    TopHandle.Name                   = "DragHandle"
    TopHandle.Size                   = UDim2.new(1, 0, 0, 24)
    TopHandle.Position               = UDim2.new(0, 0, 0, 0)
    TopHandle.BackgroundTransparency = 1
    TopHandle.Text                   = ""
    TopHandle.AutoButtonColor         = false
    TopHandle.Active                  = true
    TopHandle.ZIndex                  = 5

    local TitleLbl = Instance.new("TextLabel", TopHandle)
    TitleLbl.AnchorPoint = Vector2.new(0, 0.5)
    TitleLbl.Position    = UDim2.new(0, 16, 0.5, 0)
    TitleLbl.Size        = UDim2.new(0, 140, 0, 16)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Text        = "FORKYHUB"
    TitleLbl.Font        = Enum.Font.GothamBold
    TitleLbl.TextSize    = 11
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.TextColor3  = Color3.fromRGB(125, 132, 158)

    local TitleGrad = Instance.new("UIGradient", TitleLbl)
    TitleGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, cCyan),
        ColorSequenceKeypoint.new(1, cBlue),
    })

    -- center grip dots
    local DotHolder = Instance.new("Frame", TopHandle)
    DotHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    DotHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
    DotHolder.Size = UDim2.new(0, 36, 0, 4)
    DotHolder.BackgroundTransparency = 1

    local DotLayout = Instance.new("UIListLayout", DotHolder)
    DotLayout.FillDirection = Enum.FillDirection.Horizontal
    DotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    DotLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    DotLayout.Padding = UDim.new(0, 5)

    for i = 1, 5 do
        local dot = Instance.new("Frame", DotHolder)
        dot.Size = UDim2.new(0, 4, 0, 4)
        dot.BackgroundColor3 = cCyan
        dot.BackgroundTransparency = 0.45
        dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    end

    -- ══════════════════════════════════════════════════════════
    -- BOTTOM RESIZE HANDLE
    -- ══════════════════════════════════════════════════════════
    local BottomHandle = Instance.new("TextButton", MainFrame)
    BottomHandle.Name                   = "ResizeHandle"
    BottomHandle.Size                   = UDim2.new(1, 0, 0, 20)
    BottomHandle.AnchorPoint            = Vector2.new(0, 1)
    BottomHandle.Position               = UDim2.new(0, 0, 1, 0)
    BottomHandle.BackgroundTransparency = 1
    BottomHandle.Text                   = ""
    BottomHandle.AutoButtonColor          = false
    BottomHandle.Active                   = true
    BottomHandle.ZIndex                   = 5

    local ResizeBars = Instance.new("Frame", BottomHandle)
    ResizeBars.AnchorPoint = Vector2.new(1, 0.5)
    ResizeBars.Position = UDim2.new(1, -14, 0.5, 0)
    ResizeBars.Size = UDim2.new(0, 18, 0, 12)
    ResizeBars.BackgroundTransparency = 1

    -- diagonal resize grip: three staggered bars
    local barSizes = {{6,16},{10,12},{14,8}}
    for i, dims in ipairs(barSizes) do
        local bar = Instance.new("Frame", ResizeBars)
        bar.AnchorPoint = Vector2.new(1, 1)
        bar.Position = UDim2.new(1, 0, 1, -((i-1)*0))
        bar.Size = UDim2.new(0, dims[1], 0, 2)
        bar.BackgroundColor3 = cCyan
        bar.BackgroundTransparency = 0.4
        bar.BorderSizePixel = 0
        bar.Rotation = -45
        bar.Position = UDim2.new(1, -((i-1)*5), 1, -((i-1)*5))
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1,0)
    end

    local CenterGrip = Instance.new("Frame", BottomHandle)
    CenterGrip.AnchorPoint = Vector2.new(0.5, 0.5)
    CenterGrip.Position = UDim2.new(0.5, 0, 0.5, 0)
    CenterGrip.Size = UDim2.new(0, 36, 0, 4)
    CenterGrip.BackgroundColor3 = cCyan
    CenterGrip.BackgroundTransparency = 0.5
    CenterGrip.BorderSizePixel = 0
    Instance.new("UICorner", CenterGrip).CornerRadius = UDim.new(1, 0)

    -- ══════════════════════════════════════════════════════════
    -- DRAG + RESIZE LOGIC — Mouse (PC) & Touch (Mobile)
    -- ══════════════════════════════════════════════════════════
    local MIN_W, MAX_W = 240, 540
    local MIN_H, MAX_H = 96, 250

    local function isPointerInput(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
    end
    local function isMoveInput(input)
        return input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
    end

    local function setupDragOrResize(handle, mode)
        local active = false
        local startInputPos = Vector2.new()
        local startFramePos, startFrameSize

        handle.InputBegan:Connect(function(input)
            if not isPointerInput(input) then return end
            active = true
            startInputPos  = Vector2.new(input.Position.X, input.Position.Y)
            startFramePos  = MainFrame.Position
            startFrameSize = MainFrame.Size
            TweenService:Create(MainStroke, TweenInfo.new(0.12), {Transparency = 0, Color = cCyan}):Play()
        end)

        handle.InputEnded:Connect(function(input)
            if not isPointerInput(input) then return end
            active = false
            TweenService:Create(MainStroke, TweenInfo.new(0.25), {Transparency = 0.2, Color = Color3.fromRGB(50,54,72)}):Play()
        end)

        UserInputService.InputChanged:Connect(function(input)
            if not active then return end
            if not isMoveInput(input) then return end

            local delta = Vector2.new(input.Position.X, input.Position.Y) - startInputPos

            if mode == "drag" then
                MainFrame.Position = UDim2.new(
                    startFramePos.X.Scale, startFramePos.X.Offset + delta.X,
                    startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y
                )
            else -- resize
                local newW = math.clamp(startFrameSize.X.Offset + delta.X, MIN_W, MAX_W)
                local newH = math.clamp(startFrameSize.Y.Offset + delta.Y, MIN_H, MAX_H)
                MainFrame.Size = UDim2.new(startFrameSize.X.Scale, newW, startFrameSize.Y.Scale, newH)
            end
        end)
    end

    setupDragOrResize(TopHandle, "drag")
    setupDragOrResize(BottomHandle, "resize")

    -- ══════════════════════════════════════════════════════════
    -- BUTTON CONTAINER
    -- ══════════════════════════════════════════════════════════
    local Container = Instance.new("Frame", MainFrame)
    Container.Size                   = UDim2.new(1, -28, 1, -56)
    Container.Position               = UDim2.new(0, 14, 0, 28)
    Container.BackgroundTransparency = 1

    local Layout = Instance.new("UIListLayout", Container)
    Layout.FillDirection       = Enum.FillDirection.Horizontal
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Layout.VerticalAlignment   = Enum.VerticalAlignment.Center
    Layout.Padding             = UDim.new(0, 10)
    Layout.SortOrder           = Enum.SortOrder.LayoutOrder

    -- ══════════════════════════════════════════════════════════
    -- BUTTON FACTORY (no emojis — clean geometric accent bar + label)
    -- ══════════════════════════════════════════════════════════
    local function MakeButton(label, sublabel)
        local btn = Instance.new("TextButton", Container)
        btn.Size             = UDim2.new(0.333, -7, 1, 0)
        btn.BackgroundColor3 = cIdleBg
        btn.AutoButtonColor  = false
        btn.Text             = ""
        btn.BorderSizePixel  = 0
        btn.ClipsDescendants = true

        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 14)

        local stroke = Instance.new("UIStroke", btn)
        stroke.Color       = Color3.fromRGB(46, 50, 68)
        stroke.Thickness   = 1
        stroke.Transparency = 0.25

        local grad = Instance.new("UIGradient", btn)
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, cIdleBg),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 17, 25)),
        })
        grad.Rotation = 90
        grad.Enabled = false

        -- top accent bar (replaces emoji icon)
        local accent = Instance.new("Frame", btn)
        accent.Size = UDim2.new(1, 0, 0, 3)
        accent.Position = UDim2.new(0, 0, 0, 0)
        accent.BackgroundColor3 = cIdleBar
        accent.BorderSizePixel = 0
        Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)

        local inner = Instance.new("Frame", btn)
        inner.BackgroundTransparency = 1
        inner.Size = UDim2.new(1, 0, 1, -3)
        inner.Position = UDim2.new(0, 0, 0, 3)

        local ilayout = Instance.new("UIListLayout", inner)
        ilayout.FillDirection       = Enum.FillDirection.Vertical
        ilayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        ilayout.VerticalAlignment   = Enum.VerticalAlignment.Center
        ilayout.Padding             = UDim.new(0, 2)

        local mainLbl = Instance.new("TextLabel", inner)
        mainLbl.BackgroundTransparency = 1
        mainLbl.Size      = UDim2.new(1, 0, 0, 20)
        mainLbl.Text      = label
        mainLbl.Font      = Enum.Font.GothamBold
        mainLbl.TextSize  = 15
        mainLbl.TextColor3 = Color3.fromRGB(225, 228, 240)

        local subLbl = Instance.new("TextLabel", inner)
        subLbl.BackgroundTransparency = 1
        subLbl.Size      = UDim2.new(1, 0, 0, 12)
        subLbl.Text      = sublabel or ""
        subLbl.Font      = Enum.Font.Gotham
        subLbl.TextSize  = 9
        subLbl.TextColor3 = cIdleText
        subLbl.TextTransparency = 0.15

        -- press feedback
        btn.MouseButton1Down:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundTransparency = 0.2}):Play()
        end)
        btn.MouseButton1Up:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundTransparency = 0}):Play()
        end)

        return {
            btn = btn, accent = accent, stroke = stroke, grad = grad,
            main = mainLbl, sub = subLbl,
        }
    end

    -- Set a button to "active/highlighted" or "idle" visual state
    local function setButtonState(p, isActive, colorA, colorB, activeSub)
        if isActive then
            p.grad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, colorA),
                ColorSequenceKeypoint.new(1, colorB),
            })
            p.grad.Enabled = true
            TweenService:Create(p.btn, TweenInfo.new(0.18), {BackgroundColor3 = colorA}):Play()
            TweenService:Create(p.accent, TweenInfo.new(0.18), {BackgroundColor3 = colorA, BackgroundTransparency = 0}):Play()
            TweenService:Create(p.stroke, TweenInfo.new(0.18), {Color = colorA, Transparency = 0}):Play()
            TweenService:Create(p.sub, TweenInfo.new(0.18), {TextColor3 = Color3.fromRGB(255,255,255), TextTransparency = 0.05}):Play()
            if activeSub then p.sub.Text = activeSub end
        else
            p.grad.Enabled = false
            TweenService:Create(p.btn, TweenInfo.new(0.18), {BackgroundColor3 = cIdleBg}):Play()
            TweenService:Create(p.accent, TweenInfo.new(0.18), {BackgroundColor3 = cIdleBar, BackgroundTransparency = 0.5}):Play()
            TweenService:Create(p.stroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(46,50,68), Transparency = 0.25}):Play()
            TweenService:Create(p.sub, TweenInfo.new(0.18), {TextColor3 = cIdleText, TextTransparency = 0.15}):Play()
        end
    end

    -- ══════════════════════════════════════════════════════════
    -- PLAYBACK LOGIC
    -- ══════════════════════════════════════════════════════════
    local function StartPlaybackWithFinishNotify()
        if #SelectedTrackData == 0 then
            WindUI:Notify({Title="No Track",Content="Load track first!",Duration=2})
            return
        end
        if AutoLoopEnabled then
            StopLoop()
            return
        end
        if AutoWalkActive then
            StopWalk()
            WindUI:Notify({Title="Paused",Content="Press PLAY to continue.",Duration=2})
            return
        end

        if TrackFinished then
            TrackFinished = false
            ResumeTrackTime = 0
            WindUI:Notify({Title="Playback",Content="Starting from beginning.",Duration=1.5})
        else
            WindUI:Notify({Title="Playback",Content="Continuing from current position.",Duration=1.5})
        end

        StartAutoPlay(function()
            TrackFinished = true
            WindUI:Notify({Title="Finished",Content="Track complete. Press PLAY to repeat.",Duration=3})
            if AutoRespawnEnabled then
                task.spawn(function()
                    task.wait(5)
                    if not AutoWalkActive and not AutoLoopEnabled then
                        WindUI:Notify({Title="Respawn", Content="Auto respawn triggered.", Duration=2})
                        DoRespawn()
                    end
                end)
            end
        end)
    end

    local function StopPlaybackWithNotify()
        if AutoLoopEnabled then
            StopLoop()
        end
        if AutoWalkActive then
            StopWalk()
            WindUI:Notify({Title="Stopped",Content="Playback stopped.",Duration=1.5})
        else
            WindUI:Notify({Title="Idle",Content="Already stopped.",Duration=1})
        end
    end

    local function IsTypingText()
        return UserInputService:GetFocusedTextBox() ~= nil
    end

    -- ══════════════════════════════════════════════════════════
    -- BUTTONS: PLAY/STOP — REV — FLIP
    -- ══════════════════════════════════════════════════════════
    local playP = MakeButton("PLAY", "Tap to start")
    local revP  = MakeButton("REV",  "Reverse")
    local flipP = MakeButton("FLIP", "Flip turn")

    -- PlayStopBtn kept as global reference so other parts of the script
    -- (which set .Text = "PLAY"/"STOP") keep working as before.
    PlayStopBtn = playP.main

    playP.btn.MouseButton1Click:Connect(function()
        StartPlaybackWithFinishNotify()
    end)

    revP.btn.MouseButton1Click:Connect(function()
        if AutoLoopEnabled then StopLoop() end
        StopWalk()
        ReverseMode = not ReverseMode
        TrackFinished = false
        ResumeTrackTime = 0
        WindUI:Notify({Title="Reverse",Content="Reverse mode " .. (ReverseMode and "enabled" or "disabled"),Duration=1.5})
    end)

    flipP.btn.MouseButton1Click:Connect(function()
        FlipState = not FlipState
        WindUI:Notify({Title="Flip",Content="Flip turn " .. (FlipState and "enabled" or "disabled"),Duration=1.5})
    end)

    -- ══════════════════════════════════════════════════════════
    -- LIVE STATE SYNC — keeps labels/colors in sync with logic state
    -- ══════════════════════════════════════════════════════════
    task.spawn(function()
        while SG and SG.Parent do
            local ok = pcall(function()
                local playing = AutoWalkActive or AutoLoopEnabled

                if playing then
                    playP.main.Text = "STOP"
                    setButtonState(playP, true, cRed, cRedDark, "Tap to stop")
                else
                    playP.main.Text = "PLAY"
                    setButtonState(playP, true, cGreen, cGreenDark, "Tap to start")
                end

                setButtonState(revP, ReverseMode == true, cCyan, cBlue, ReverseMode and "Active" or "Reverse")
                if ReverseMode ~= true then revP.sub.Text = "Reverse" end

                setButtonState(flipP, FlipState == true, cPurple, cPurpleDk, FlipState and "Active" or "Flip turn")
                if FlipState ~= true then flipP.sub.Text = "Flip turn" end
            end)
            if not ok then break end
            task.wait(0.2)
        end
    end)

    -- ══════════════════════════════════════════════════════════
    -- HOTKEYS: Play/Pause & Stop (custom configurable)
    -- ══════════════════════════════════════════════════════════
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if IsTypingText() then return end

        if input.KeyCode == getHotkeyKeyCode("play") then
            StartPlaybackWithFinishNotify()
        elseif input.KeyCode == getHotkeyKeyCode("stop") then
            StopPlaybackWithNotify()
        end
    end)

    return SG
end

local PremiumButtons = CreatePremiumButtons()

-- ══════════════════════════════════════════════════════════════
-- AUTO EXPEDITION SYSTEM
-- ══════════════════════════════════════════════════════════════
local Lighting = cloneref(game:GetService("Lighting"))
local VUser = cloneref(game:GetService("VirtualUser"))

local ExpLocations = {
    {Name="Spawn",     CFrame=CFrame.new(-6438.5,-156.6,-53.6)},
    {Name="Camp 1",    CFrame=CFrame.new(-3718.6,227.4,235.6)},
    {Name="Camp 2",    CFrame=CFrame.new(1789.7,107.8,-137)},
    {Name="Camp 3",    CFrame=CFrame.new(5892.1,323.4,-20.3)},
    {Name="Camp 4",    CFrame=CFrame.new(8992.2,598,102.6)},
    {Name="South Pole",CFrame=CFrame.new(11001.9,551.5,103.8)}
}

_G.ExpConfig = {
    Enabled         = false,
    CurrentIdx      = 2,
    TargetLoops     = 0,
    CompletedLoops  = 0,
    JumpPause       = 3,
    JumpResume      = 5,
    SpawnWait       = 100,
    FinishMode      = "Reset",
    IsTeleporting   = false,
    Countdown       = 0,
    CurrentCampName = "Spawn",
    NextCampName    = "Camp 1",
    Status          = "Idle"
}

local AutoJumpTask = nil

local function SetExpeditionStatus(currentName, nextName, status)
    _G.ExpConfig.CurrentCampName = currentName or _G.ExpConfig.CurrentCampName or "Unknown"
    _G.ExpConfig.NextCampName    = nextName    or _G.ExpConfig.NextCampName    or "None"
    _G.ExpConfig.Status          = status      or _G.ExpConfig.Status          or "Idle"
end

local function ExpExecuteTeleport(targetCF)
    _G.ExpConfig.IsTeleporting = true
    local char = Player.Character or Player.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart")
    task.wait(_G.ExpConfig.JumpPause)
    if hrp then
        hrp.Anchored  = true
        hrp.Velocity  = Vector3.zero
        hrp.CFrame    = targetCF
        task.wait(0.1)
        hrp.Anchored  = false
    end
    task.wait(_G.ExpConfig.JumpResume)
    _G.ExpConfig.IsTeleporting = false
end

local function IsNearExpSpawn(position)
    return (position - ExpLocations[1].CFrame.Position).Magnitude <= 100
end

local function IsOnGround(character)
    if not character then return false end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {Player.Character}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -4, 0), params)
    return ray and ray.Instance ~= nil
end

local function TryAutoJump()
    if not _G.ExpConfig.Enabled or _G.ExpConfig.IsTeleporting then return end
    local char = Player.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hum and hrp and hum.Health > 0 and IsOnGround(char) and not IsNearExpSpawn(hrp.Position) then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

local function StartAutoJumpLoop()
    if AutoJumpTask then return end
    AutoJumpTask = task.spawn(function()
        while _G.ExpConfig.Enabled do
            TryAutoJump()
            task.wait(2)
        end
        AutoJumpTask = nil
    end)
end

local function StopAutoJumpLoop()
    if AutoJumpTask then
        task.cancel(AutoJumpTask)
        AutoJumpTask = nil
    end
end

local function StopExpedition()
    _G.ExpConfig.Enabled        = false
    _G.ExpConfig.IsTeleporting  = false
    _G.ExpConfig.Countdown      = 0
    SetExpeditionStatus("Stopped", "None", "Stopped")
    StopAutoJumpLoop()
end

local function StartExpedition()
    _G.ExpConfig.Enabled        = true
    _G.ExpConfig.CurrentIdx     = 2
    _G.ExpConfig.CompletedLoops = 0
    _G.ExpConfig.Countdown      = 0
    _G.ExpConfig.IsTeleporting  = false
    SetExpeditionStatus("Spawn", ExpLocations[2].Name, "Teleporting to "..ExpLocations[2].Name)
    WindUI:Notify({Title="System", Content="Starting at Camp 1 | Pause:".. _G.ExpConfig.JumpPause .."s Resume:".. _G.ExpConfig.JumpResume .."s", Duration=5})
    StartAutoJumpLoop()
    ExpExecuteTeleport(ExpLocations[2].CFrame)
end

-- Idled anti-afk untuk VUser
Player.Idled:Connect(function()
    local state = 0
    while true do
        if state == 1 then
            VUser:Button2Up(Vector2.zero, workspace.CurrentCamera.CFrame)
            break
        end
        if state == 0 then
            VUser:Button2Down(Vector2.zero, workspace.CurrentCamera.CFrame)
            task.wait(1)
            state = 1
        end
    end
end)

-- Detector: cek TextLabel "You have made it to" di PlayerGui
task.spawn(function()
    while true do
        task.wait(0.5)
        if _G.ExpConfig.Enabled and not _G.ExpConfig.IsTeleporting then
            local pGui = Player:FindFirstChild("PlayerGui")
            if pGui then
                for _, v in pairs(pGui:GetDescendants()) do
                    if v:IsA("TextLabel") and v.Visible and v.Text:find("You have made it to") then
                        local target = ExpLocations[_G.ExpConfig.CurrentIdx]
                        if target and v.Text:find(target.Name) then
                            _G.ExpConfig.IsTeleporting = true
                            if target.Name == "South Pole" then
                                task.spawn(function()
                                    _G.ExpConfig.CompletedLoops = _G.ExpConfig.CompletedLoops + 1
                                    SetExpeditionStatus("South Pole", "Spawn", "Completed loop. Respawning...")
                                    WindUI:Notify({Title="Success", Content="Completed Loop: ".._G.ExpConfig.CompletedLoops, Duration=5})
                                    if _G.ExpConfig.TargetLoops > 0 and _G.ExpConfig.CompletedLoops >= _G.ExpConfig.TargetLoops then
                                        WindUI:Notify({Title="System", Content="Completed ".._G.ExpConfig.CompletedLoops.." loops.", Duration=5})
                                        StopExpedition()
                                        return
                                    end
                                    task.wait(5)
                                    if _G.ExpConfig.FinishMode == "Reset" then
                                        if Player.Character then Player.Character:BreakJoints() end
                                    end
                                    task.wait(2)
                                    SetExpeditionStatus("Spawn", ExpLocations[2].Name, "Waiting at Spawn for ".._G.ExpConfig.SpawnWait.."s")
                                    WindUI:Notify({Title="Waiting", Content="Waiting ".._G.ExpConfig.SpawnWait.."s at Spawn", Duration=5})
                                    task.wait(_G.ExpConfig.SpawnWait)
                                    if _G.ExpConfig.Enabled then
                                        _G.ExpConfig.CurrentIdx = 2
                                        SetExpeditionStatus("Spawn", ExpLocations[2].Name, "Teleporting to "..ExpLocations[2].Name)
                                        ExpExecuteTeleport(ExpLocations[2].CFrame)
                                    else
                                        _G.ExpConfig.IsTeleporting = false
                                    end
                                end)
                            elseif target.Name == "Camp 4" then
                                task.spawn(function()
                                    SetExpeditionStatus("Camp 4", "South Pole", "Waiting at Camp 4 for 100s")
                                    WindUI:Notify({Title="Waiting", Content="Waiting at Camp 4 for 1m 40s before South Pole", Duration=5})
                                    _G.ExpConfig.Countdown = 100
                                    while _G.ExpConfig.Countdown > 0 and _G.ExpConfig.Enabled do
                                        task.wait(1)
                                        _G.ExpConfig.Countdown = _G.ExpConfig.Countdown - 1
                                    end
                                    _G.ExpConfig.Countdown = 0
                                    if _G.ExpConfig.Enabled then
                                        _G.ExpConfig.CurrentIdx = _G.ExpConfig.CurrentIdx + 1
                                        SetExpeditionStatus("Camp 4", "South Pole", "Teleporting to South Pole")
                                        ExpExecuteTeleport(ExpLocations[_G.ExpConfig.CurrentIdx].CFrame)
                                    else
                                        _G.ExpConfig.IsTeleporting = false
                                    end
                                end)
                            else
                                task.spawn(function()
                                    local nextIdx  = _G.ExpConfig.CurrentIdx + 1
                                    local nextName = ExpLocations[nextIdx] and ExpLocations[nextIdx].Name or "None"
                                    SetExpeditionStatus(target.Name, nextName, "Teleporting to "..nextName)
                                    _G.ExpConfig.CurrentIdx = nextIdx
                                    ExpExecuteTeleport(ExpLocations[_G.ExpConfig.CurrentIdx].CFrame)
                                end)
                            end
                            break
                        end
                    end
                end
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════
-- TABS
-- ══════════════════════════════════════════════════════════════
local TabInfo = Window:Tab({ Title="Information", Icon="lucide:info", IconColor=Color3.fromRGB(0,225,255) })
local GameName = "Unknown"
local s2,res2 = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId).Name end)
if s2 then GameName=res2 end

local InfoSec = TabInfo:Section({ Title="User & Game Status", Opened=true })
InfoSec:Paragraph({
    Title="User Profile",
    Desc="👤 Name: "..Player.DisplayName.." (@"..Player.Name..")\n🆔 User ID: "..Player.UserId
})
InfoSec:Paragraph({
    Title="Current Session",
    Desc="🎮 Playing: "..GameName.."\n📍 Place ID: "..game.PlaceId
        .."\n⏱️ Server Age: "..math.floor(workspace.DistributedGameTime/60).." Minutes"
})

local ScriptSec = TabInfo:Section({ Title="Script Status", Opened=true })
local keyData=_G.ForkyHUB or {}; local keyType=keyData.type or "unknown"
local expiresAt=keyData.expiresAt
local function fmtExpiry(ms)
    if not ms or ms==0 then return "Permanen" end
    local rem=math.max(0,ms-os.time()*1000); if rem<=0 then return "Expired" end
    local h=math.floor(rem/3600000); local m=math.floor((rem%3600000)/60000)
    if h>=24 then return math.floor(h/24).."d "..(h%24).."h" end
    return h.."h "..m.."m"
end
local typeLabel=({premium="👑 Premium",trial="🎁 Trial"})[keyType] or "❓ Unknown"
ScriptSec:Paragraph({
    Title="Subscription",
    Desc="🔑 Key Status: Verified ("..typeLabel..")\n⏰ Expires: "..fmtExpiry(expiresAt)
        .."\n🛡️ Anti-Cheat: Bypassed\n🚀 Version: 1.5.0"
})
TabInfo:Section({Title="Socials & Links",Opened=true}):Button({
    Title="Copy Discord Link",
    Callback=function()
        setclipboard("https://dsc.gg/forky")
        WindUI:Notify({Title="Success",Content="Discord link copied!",Duration=3})
    end
})

-- TAB: AUTO WALK
local TabController = Window:Tab({ Title="Auto Walk", Icon="lucide:gamepad-2", IconColor=Color3.fromRGB(0,150,255) })

local ControllerSection = TabController:Section({ Title="Controller AutoWalk", Opened=true })
ControllerSection:Toggle({
    Title="Show Controller", Icon="lucide:gamepad", Value=false,
    Callback=function(v) PremiumButtons.Enabled=v end
})
ControllerSection:Toggle({
    Title="Auto Respawn", Icon="lucide:refresh-ccw", Value=false,
    Callback=function(v)
        AutoRespawnEnabled=v
        WindUI:Notify({Title="Auto Respawn",Content=v and "ON" or "OFF",Duration=2})
    end
})
ControllerSection:Toggle({
    Title="Auto Loop", Icon="lucide:repeat", Value=false,
    Callback=function(v)
        if v then
            if #SelectedTrackData==0 then
                WindUI:Notify({Title="❌",Content="Load track dulu!",Duration=2}); return
            end
            AutoLoopEnabled=true; StartLoop()
            WindUI:Notify({Title="Auto Loop",Content="ON",Duration=2})
        else
            StopLoop()
        end
    end
})

-- ═══════════════════════════════════════════════════════
-- TYPE SPEED MANUALLY (logic dari FreeWALKADARECORDER.lua)
-- Update playbackRuntimeSpeed → timeMultiplier berubah live di Heartbeat
-- ═══════════════════════════════════════════════════════
ControllerSection:Input({
    Title = "Type Speed Manually",
    Icon = "lucide:pencil",
    Desc = "Ketik speed (stud/s). Berlaku LIVE tanpa Stop/Play ulang.",
    Placeholder = "Contoh: 50 atau 200 (base track auto-detect)",
    Callback = function(Text)
        local speed = tonumber(Text)
        if speed and speed > 0 then
            speed = math.clamp(speed, MIN_PB_SPEED, MAX_PB_SPEED)
            -- LIVE SPEED: update playbackRuntimeSpeed → dibaca Heartbeat loop tiap frame
            playbackRuntimeSpeed = speed
            -- Apply ke hum langsung juga biar animasi lari ikut berubah
            local char = Player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum.WalkSpeed = speed end) end
            if AutoWalkActive then
                WindUI:Notify({Title="⚡ LIVE Speed", Content=string.format("%.1f stud/s (multiplier: %.2fx)", speed, speed / math.max(recordedBaseSpeed, 1)), Duration=2})
            else
                WindUI:Notify({Title="Speed Set", Content=string.format("%.1f stud/s — berlaku saat Play", speed), Duration=2})
            end
            if refreshCustomLoadStatus then refreshCustomLoadStatus() end
        else
            WindUI:Notify({Title="Speed", Content="❌ Input tidak valid. Masukkan angka.", Duration=2})
        end
    end
})

-- ═══════════════════════════════════════════════════════
-- SPEEDOMETER (Free & VIP) (dari FreeAutoWalk.lua)
-- ═══════════════════════════════════════════════════════
ControllerSection:Toggle({
    Title = "Speedometer",
    Icon = "lucide:gauge",
    Desc = "Overlay speed real-time di luar UI, bisa di-drag",
    Value = false,
    Callback = function(v)
        PlayClick()
        if (v==true) ~= _G.ForkySpeedometer.active then
            toggleSpeedometer()
        end
    end
})

local TrackSection = TabController:Section({ Title="AutoWalk Track", Opened=true })
local TrackList = {}
local trackLoaded = false
local ActiveDropdown = nil

local function LoadTrack(name)
    if not trackLoaded then
        WindUI:Notify({Title="⏳",Content="Masih loading...",Duration=1.5}); return
    end
    local url = TrackIndex[name]
    if not url then return end
    WindUI:Notify({Title="⏳",Content="Loading "..name.."...",Duration=2})
    task.spawn(function()
        local ok, result = pcall(function()
            local content = httpGet(url)
            local data    = HttpService:JSONDecode(content)
            if not data then error("Invalid JSON") end
            return ConvertReplayToTrack(data)
        end)
        if ok and result and #result > 0 then
            if AutoLoopEnabled then StopLoop() end
            StopWalk()
            ResumeTrackTime=0; TrackFinished=false
            SelectedTrackData=result
            ReversedTrackData = buildReversedTrack(SelectedTrackData)
            CurrentTrackDuration = (result[#result] and result[#result].time) or (#result * 0.033)
            
            -- Set loaded route info
            -- FIX: pakai ForkyEstimateBaseSpeed (actual track speed), bukan savedWalkSpeed (map speed).
            -- Kalau pakai savedWalkSpeed maka recordedBaseSpeed salah → speed 28 jadi 78+.
            local detectedTrackSpeed = ForkyEstimateBaseSpeed(result) or extractRouteSpeed(data, result) or 16
            loadedRouteInfo = {
                source = "Gunung: " .. name,
                frames = #result,
                duration = CurrentTrackDuration,
                speed = detectedTrackSpeed,
                loadedAt = os.date("%H:%M:%S")
            }
            
            -- FIX SPEED: Reset playbackRuntimeSpeed ke track speed setiap kali track baru di-load.
            -- Tanpa ini, kalau track speed 78 dan user set 28 sebelumnya,
            -- multiplier = 28/78 = 0.36x → jalannya hanya 0.36× track speed.
            -- Dengan ini, speed slider selalu relatif ke track yang aktif.
            playbackRuntimeSpeed = detectedTrackSpeed
            recordedBaseSpeed    = detectedTrackSpeed
            
            if PlayStopBtn then PlayStopBtn.Text="PLAY" end
            if ESP.enabled then drawTrackPath(SelectedTrackData) end
            WindUI:Notify({Title="✅",Content=name.." ("..#result.." frames)",Duration=3})
        else
            WindUI:Notify({Title="❌",Content="Gagal load: "..name,Duration=3})
        end
    end)
end

TrackSection:Input({
    Title="Search Track", Placeholder="Ketik nama track...",
    Callback=function(query)
        if not trackLoaded then
            WindUI:Notify({Title="⏳",Content="Belum siap!",Duration=1.5}); return
        end
        query=query:lower():gsub("%s+","")
        local filtered=query=="" and TrackList or (function()
            local t={}
            for _,n in ipairs(TrackList) do
                if n:lower():gsub("%s+",""):find(query,1,true) then table.insert(t,n) end
            end
            return t
        end)()
        if #filtered==0 then
            WindUI:Notify({Title="❌",Content="Tidak ada: "..query,Duration=2}); return
        end
        pcall(function() ActiveDropdown:Destroy() end)
        ActiveDropdown=TrackSection:Dropdown({
            Title="Select Track ("..#filtered..")", Values=filtered, Callback=LoadTrack
        })
        WindUI:Notify({Title="🔍",Content=#filtered.." ditemukan",Duration=1.5})
    end
})

ActiveDropdown = TrackSection:Dropdown({
    Title="Select Track (Loading...)", Values={"Memuat..."},
    Callback=function(name) if name~="Memuat..." then LoadTrack(name) end end
})

task.spawn(function()
    print("[Forky] Mulai fetch track index...")
    local fetch_ok = FetchIndex()
    task.wait(0.5)
    
    if not fetch_ok then
        print("[Forky] FetchIndex returned false!")
        WindUI:Notify({Title="❌",Content="Gagal fetch index dari URL!",Duration=3})
        return
    end
    
    print("[Forky] TrackIndex type:", type(TrackIndex))
    for name in pairs(TrackIndex) do 
        table.insert(TrackList, name)
    end
    table.sort(TrackList)
    print("[Forky] Total tracks loaded:", #TrackList)
    
    if #TrackList==0 then
        print("[Forky] TrackList kosong!")
        WindUI:Notify({Title="❌",Content="Track list kosong! Cek URL: "..JSON_URL,Duration=4}); return
    end
    
    trackLoaded=true
    pcall(function() ActiveDropdown:Destroy() end)
    ActiveDropdown=TrackSection:Dropdown({
        Title="Select Track ("..#TrackList..")", Values=TrackList, Callback=LoadTrack
    })
    WindUI:Notify({Title="✅",Content=#TrackList.." tracks tersedia",Duration=2})
end)

-- TAB: SMART AI SPEED
local TabSmartAI = Window:Tab({ Title="Smart AI Speed", Icon="lucide:zap", IconColor=Color3.fromRGB(0,255,150) })

local SmartAIInfoSec = TabSmartAI:Section({ Title="Info", Opened=true })
SmartAIInfoSec:Paragraph({
    Title="Smart AI Speed System",
    Desc="Sepi? Gas!\nAda player? Pelan!\nOtomatis, tanpa setting manual.",
    Icon="lucide:cpu"
})

-- STATUS DISPLAY SECTION
local SmartAIStatusSec = TabSmartAI:Section({ Title="Status Monitor", Opened=true })
local StatusParagraph = SmartAIStatusSec:Paragraph({
    Title="Current Status",
    Desc=SmartAISpeed.statusText
})

local SmartAIControlSec = TabSmartAI:Section({ Title="Main Control", Opened=true })
SmartAIControlSec:Toggle({
    Title="Adaptive Speed (Smart AI)",
    Icon="lucide:zap",
    Value=false,
    Callback=function(v)
        SmartAISpeed.enabled=v
        updateSmartAIStatus()
        StatusParagraph:SetDesc(SmartAISpeed.statusText)
        WindUI:Notify({
            Title="Smart AI",
            Content=v and "✅ ENABLED - Auto ngebut saat sepi, auto pelan saat ada player" or "❌ DISABLED",
            Duration=2
        })
    end
})

local SmartAISettingsSec = TabSmartAI:Section({ Title="Detection Settings", Opened=true })
SmartAISettingsSec:Slider({
    Title="Jarak Deteksi Player",
    Value={Min=50,Max=500,Default=200},
    Callback=function(v)
        SmartAISpeed.detectionRadius=v
        updateSmartAIStatus()
        StatusParagraph:SetDesc(SmartAISpeed.statusText)
        WindUI:Notify({Title="📍",Content="Detection radius: "..math.floor(v).." studs",Duration=1.5})
    end
})

local SmartAISpeedSec = TabSmartAI:Section({ Title="Speed Control", Opened=true })
SmartAISpeedSec:Slider({
    Title="Max Speed (Area Aman)",
    Value={Min=0.5,Max=2.5,Default=1.5},
    Callback=function(v)
        SmartAISpeed.maxSpeedSafeArea=v
        updateSmartAIStatus()
        StatusParagraph:SetDesc(SmartAISpeed.statusText)
        WindUI:Notify({Title="⚡",Content="Max speed: "..string.format("%.1f",v).."x",Duration=1})
    end
})

SmartAISpeedSec:Slider({
    Title="Slow Speed Near Player",
    Value={Min=0.1,Max=1,Default=0.5},
    Callback=function(v)
        SmartAISpeed.slowSpeedNearPlayer=v
        updateSmartAIStatus()
        StatusParagraph:SetDesc(SmartAISpeed.statusText)
        WindUI:Notify({Title="🐢",Content="Slow speed: "..string.format("%.1f",v).."x",Duration=1})
    end
})

local SmartAIAdvancedSec = TabSmartAI:Section({ Title="Advanced", Opened=false })
SmartAIAdvancedSec:Toggle({
    Title="Ignore Close Players",
    Icon="lucide:eye-off",
    Value=false,
    Callback=function(v)
        SmartAISpeed.ignoreClosePlayers=v
        updateSmartAIStatus()
        StatusParagraph:SetDesc(SmartAISpeed.statusText)
        WindUI:Notify({
            Title="Close Player Detection",
            Content=v and "✅ ENABLED - Extra safety saat ada yang super deket" or "❌ DISABLED",
            Duration=2
        })
    end
})

SmartAIAdvancedSec:Slider({
    Title="Close Player Distance",
    Value={Min=1,Max=50,Default=10},
    Callback=function(v)
        SmartAISpeed.closePlayerDistance=v
        updateSmartAIStatus()
        StatusParagraph:SetDesc(SmartAISpeed.statusText)
        WindUI:Notify({Title="🔴",Content="Close distance: "..math.floor(v).." studs",Duration=1})
    end
})

-- ══════════════════════════════════════════════════════════════
-- SMART AI STATUS UPDATE LOOP
-- ══════════════════════════════════════════════════════════════
task.spawn(function()
    while task.wait(1) do -- Update every second
        if SmartAISpeed.enabled then
            updateSmartAIStatus()
            StatusParagraph:SetDesc(SmartAISpeed.statusText)
        end
    end
end)

-- TAB: ESP LINE
local TabESP = Window:Tab({ Title="ESP Line", Icon="lucide:map", IconColor=Color3.fromRGB(0,220,255) })

local ESPInfoSec = TabESP:Section({ Title="Info", Opened=true })
ESPInfoSec:Paragraph({
    Title = "Cara Pakai",
    Desc  = "1. Load track di tab Auto Walk dulu\n"
         .. "2. Aktifkan toggle di bawah\n"
         .. "3. Path langsung muncul di dunia game\n\n"
         .. "Start dot = titik START\n"
         .. "End dot = titik END\n"
         .. "Small dot = waypoint tiap 10%",
    Icon = "lucide:info"
})

local ESPControlSec = TabESP:Section({ Title="Controls", Opened=true })

ESPControlSec:Toggle({
    Title = "Tampilkan Track Path",
    Icon = "lucide:map",
    Value = false,
    Callback = function(v)
        ESP.enabled = v
        if v then
            if #SelectedTrackData==0 then
                ESP.enabled=false
                WindUI:Notify({Title="ESP",Content="Load track dulu!",Duration=2})
                return
            end
            drawTrackPath(SelectedTrackData)
        else
            clearESP()
            WindUI:Notify({Title="ESP",Content="Path disembunyikan.",Duration=1.5})
        end
    end
})

local ESPStyleSec = TabESP:Section({ Title="Gaya Line", Opened=true })

ESPStyleSec:Dropdown({
    Title="Warna Line", Values={"gradient","solid","rainbow"}, Value="gradient",
    Callback=function(v)
        ESP.colorMode=v
        if ESP.enabled and #SelectedTrackData>0 then drawTrackPath(SelectedTrackData) end
    end
})

local colorOptions = {
    Cyan=Color3.fromRGB(0,220,255), Merah=Color3.fromRGB(255,60,60),
    Hijau=Color3.fromRGB(60,255,100), Kuning=Color3.fromRGB(255,220,0),
    Putih=Color3.fromRGB(255,255,255), Ungu=Color3.fromRGB(180,60,255),
    Orange=Color3.fromRGB(255,140,0),
}
ESPStyleSec:Dropdown({
    Title="Warna Solid (jika mode Solid)",
    Values={"Cyan","Merah","Hijau","Kuning","Putih","Ungu","Orange"}, Value="Cyan",
    Callback=function(v)
        ESP.solidColor=colorOptions[v] or Color3.fromRGB(0,220,255)
        if ESP.enabled and ESP.colorMode=="solid" and #SelectedTrackData>0 then
            drawTrackPath(SelectedTrackData)
        end
    end
})

ESPStyleSec:Dropdown({
    Title="Ketebalan Line",
    Values={"Tipis (0.08)","Normal (0.15)","Tebal (0.25)","Super Tebal (0.4)"},
    Value="Normal (0.15)",
    Callback=function(v)
        local map={["Tipis (0.08)"]=0.08,["Normal (0.15)"]=0.15,["Tebal (0.25)"]=0.25,["Super Tebal (0.4)"]=0.40}
        ESP.lineThickness=map[v] or 0.15
        if ESP.enabled and #SelectedTrackData>0 then drawTrackPath(SelectedTrackData) end
    end
})

ESPStyleSec:Dropdown({
    Title="Detail Line",
    Values={"Sangat Detail (step 2)","Detail (step 5)","Normal (step 10)","Ringan (step 20)"},
    Value="Detail (step 5)",
    Callback=function(v)
        local map={["Sangat Detail (step 2)"]=2,["Detail (step 5)"]=5,["Normal (step 10)"]=10,["Ringan (step 20)"]=20}
        ESP.stepEvery=map[v] or 5
        if ESP.enabled and #SelectedTrackData>0 then drawTrackPath(SelectedTrackData) end
    end
})

local ESPActionSec = TabESP:Section({ Title="Aksi", Opened=true })
ESPActionSec:Button({
    Title="Redraw Path",
    Icon="lucide:refresh-cw",
    Callback=function()
        if #SelectedTrackData==0 then
            WindUI:Notify({Title="❌",Content="Load track dulu!",Duration=2}); return
        end
        ESP.enabled=true
        drawTrackPath(SelectedTrackData)
    end
})
ESPActionSec:Button({
    Title="Clear ESP",
    Icon="lucide:trash-2",
    Callback=function()
        clearESP(); ESP.enabled=false
        WindUI:Notify({Title="ESP",Content="Path dihapus.",Duration=2})
    end
})

-- TAB: TELEPORT
local TabTP = Window:Tab({Title="Teleport", Icon="lucide:map-pin", IconColor=Color3.fromRGB(65,105,225)})
local TPSec = TabTP:Section({Title="Lokasi Camp", Opened=true})
TPSec:Paragraph({Title="Info",Desc="Teleport instan ke lokasi-lokasi di Expedition Antarctica."})
for _, loc in pairs({
    {Name="Spawn",     CF=CFrame.new(-6438.5,-156.6,-53.6)},
    {Name="Camp 1",    CF=CFrame.new(-3718.6,227.4,235.6)},
    {Name="Camp 2",    CF=CFrame.new(1789.7,107.8,-137)},
    {Name="Camp 3",    CF=CFrame.new(5892.1,323.4,-20.3)},
    {Name="Camp 4",    CF=CFrame.new(8992.2,598,102.6)},
    {Name="South Pole",CF=CFrame.new(11001.9,551.5,103.8)},
}) do
    local locCopy = loc
    TPSec:Button({
        Title = locCopy.Name,
        Icon  = "lucide:map-pin",
        Callback = function()
            PlayClick()
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = locCopy.CF
                WindUI:Notify({Title="Teleport", Content="Teleported to "..locCopy.Name, Duration=2})
            end
        end
    })
end

-- TAB: PLAYER MOVEMENT
local TabMove = Window:Tab({Title="Player Movement", Icon="lucide:chess-queen", IconColor=Color3.fromRGB(0,192,225)})

local MoveSec = TabMove:Section({Title="Movement", Opened=true})
local MoveWalkSpeed = 16
local MoveJumpPower = 50

MoveSec:Slider({
    Title="Walk Speed",
    Value={Min=16, Max=200, Default=16},
    Callback=function(v)
        MoveWalkSpeed = v
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
})

MoveSec:Slider({
    Title="Jump Power",
    Value={Min=50, Max=200, Default=50},
    Callback=function(v)
        MoveJumpPower = v
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end
})

Player.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = MoveWalkSpeed
        hum.JumpPower = MoveJumpPower
    end
end)

local JumpSec = TabMove:Section({Title="Jump", Opened=true})
local InfJumpPC     = false
local InfJumpMobile = false

JumpSec:Toggle({Title="Infinite Jump (PC)",     Callback=function(v) InfJumpPC = v end})
JumpSec:Toggle({Title="Infinite Jump (Mobile)", Callback=function(v) InfJumpMobile = v end})

local MoveMouseConn = Player:GetMouse()
MoveMouseConn.KeyDown:Connect(function(k)
    if InfJumpPC and k == " " then
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState("Jumping") end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if InfJumpMobile then
        local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

local CharSec = TabMove:Section({Title="Character", Opened=true})
local NoclipEnabled = false

CharSec:Toggle({
    Title="NoClip",
    Callback=function(v) NoclipEnabled = v end
})

RunService.Stepped:Connect(function()
    if NoclipEnabled and Player.Character then
        for _, part in pairs(Player.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- TAB: AUTO EXPEDITION
local TabExp = Window:Tab({Title="Auto Expedition", Icon="lucide:mountain", IconColor=Color3.fromRGB(0,0,225)})
TabExp:Section({Title="Dashboard", Opened=true})

local ExpStatsPanel = TabExp:Paragraph({
    Title = "Loading Stats...",
    Desc  = "Please wait...",
    Icon  = "lucide:activity"
})

local expCount = 0
local coinCount = 0

task.spawn(function()
    local expFolder = Player:WaitForChild("Expedition Data", 20)
    if expFolder then
        local completion = expFolder:WaitForChild("Completion", 20)
        local coinValue  = expFolder:WaitForChild("Coins", 20)
        if completion then
            expCount = completion.Value
            completion.Changed:Connect(function(v) expCount = v end)
        end
        if coinValue then
            coinCount = coinValue.Value
            coinValue.Changed:Connect(function(v) coinCount = v end)
        end
    end
    while true do
        task.wait(1)
        local currentCamp = _G.ExpConfig.CurrentCampName or "Unknown"
        local nextCamp    = _G.ExpConfig.NextCampName    or "None"
        local status      = _G.ExpConfig.Status or (_G.ExpConfig.Enabled and "Running" or "Idle")
        if _G.ExpConfig.Enabled and _G.ExpConfig.Countdown and _G.ExpConfig.Countdown > 0 then
            status = "Waiting at Camp 4 (" .. _G.ExpConfig.Countdown .. "s)"
        end
        pcall(function()
            ExpStatsPanel:SetDesc(
                "User       : "..Player.Name..
                "\nUserID     : "..Player.UserId..
                "\n\nExpeditions: "..expCount..
                "\nCoins      : "..coinCount..
                "\n\nCurrent Camp: "..currentCamp..
                "\nNext Camp   : "..nextCamp..
                "\n\nLoop Completed: ".._G.ExpConfig.CompletedLoops..
                "\nStatus      : "..status
            )
        end)
    end
end)

local ExpAutoSec = TabExp:Section({Title="Auto Expedition", Opened=true})
ExpAutoSec:Paragraph({
    Title="Cara Kerja",
    Desc="Auto teleport dari Camp ke Camp secara otomatis hingga South Pole. "
       .."Setiap loop selesai karakter di-reset ke Spawn lalu mulai lagi.",
    Icon="lucide:info"
})

ExpAutoSec:Slider({
    Title="Jump Pause (detik)",
    Value={Min=0, Max=30, Default=3},
    Callback=function(v) _G.ExpConfig.JumpPause = v end
})

ExpAutoSec:Slider({
    Title="Jump Resume (detik)",
    Value={Min=0, Max=30, Default=5},
    Callback=function(v) _G.ExpConfig.JumpResume = v end
})

ExpAutoSec:Slider({
    Title="Spawn Wait (detik)",
    Value={Min=10, Max=300, Default=100},
    Callback=function(v) _G.ExpConfig.SpawnWait = v end
})

ExpAutoSec:Slider({
    Title="Target Loops (0 = tidak terbatas)",
    Value={Min=0, Max=100, Default=0},
    Callback=function(v) _G.ExpConfig.TargetLoops = v end
})

ExpAutoSec:Toggle({
    Title="Start Expedition",
    Icon="lucide:play",
    Value=false,
    Callback=function(v)
        PlayClick()
        if v then
            StartExpedition()
        else
            StopExpedition()
            WindUI:Notify({Title="System", Content="Expedition stopped by user.", Duration=3})
        end
    end
})

-- TAB: ARTIC MISC
local TabArticMisc = Window:Tab({Title="Artic Misc", Icon="lucide:settings", IconColor=Color3.fromRGB(255,215,0)})

TabArticMisc:Section({Title="Server Feature"})
TabArticMisc:Button({
    Title="Rejoin Same Server",
    Icon="lucide:refresh-cw",
    Callback=function()
        PlayClick()
        WindUI:Notify({Title="Server", Content="Rejoining same server...", Duration=2})
        task.wait(1)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
    end
})

TabArticMisc:Section({Title="Performance"})
TabArticMisc:Button({
    Title="FPS Booster",
    Icon="lucide:zap",
    Callback=function()
        PlayClick()
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Decal") then
                v:Destroy()
            end
        end
        settings().Rendering.QualityLevel = 1
        local Lit = cloneref(game:GetService("Lighting"))
        Lit.GlobalShadows = false
        WindUI:Notify({Title="FPS", Content="Boost Applied", Duration=2})
    end
})
TabArticMisc:Slider({
    Title="Field Of View",
    Value={Min=70, Max=120, Default=70},
    Callback=function(v) workspace.CurrentCamera.FieldOfView = v end
})

TabArticMisc:Section({Title="Lighting"})
local ArticLighting = cloneref(game:GetService("Lighting"))
local OldFogStart = ArticLighting.FogStart
local OldFogEnd   = ArticLighting.FogEnd

TabArticMisc:Toggle({
    Title="Fullbright",
    Icon="lucide:sun",
    Callback=function(v)
        if v then
            ArticLighting.Ambient = Color3.new(1,1,1)
            ArticLighting.FogEnd  = 100000
        else
            ArticLighting.Ambient = Color3.new(0.5,0.5,0.5)
            ArticLighting.FogEnd  = 10000
        end
    end
})

TabArticMisc:Toggle({
    Title="Remove Fog",
    Icon="lucide:cloud-off",
    Callback=function(v)
        if v then
            ArticLighting.FogStart = 0
            ArticLighting.FogEnd   = 100000
        else
            ArticLighting.FogStart = OldFogStart
            ArticLighting.FogEnd   = OldFogEnd
        end
    end
})

TabArticMisc:Toggle({
    Title="No Blizzard",
    Icon="lucide:snowflake",
    Callback=function(v)
        for _, e in pairs(workspace:GetDescendants()) do
            if e:IsA("ParticleEmitter") then
                e.Enabled = not v
            end
        end
    end
})

local PermaDayEnabled = false
TabArticMisc:Toggle({
    Title="Perma Day",
    Icon="lucide:sun",
    Callback=function(v)
        PlayClick()
        PermaDayEnabled = v
    end
})

task.spawn(function()
    while true do
        task.wait(1)
        if PermaDayEnabled then
            ArticLighting.ClockTime = 14
            ArticLighting.TimeOfDay = "14:00:00"
        end
    end
end)

-- SECTION: CUSTOM
local CustomSect = Window:Section({ Title="Custom", Opened=true })

local HotkeyTab = CustomSect:Tab({ Title="Hotkeys", Icon="lucide:keyboard", IconColor=Color3.fromRGB(255,150,50) })
local HotkeysSection = HotkeyTab:Section({ Title="Hotkey Settings", Opened=true })
HotkeysSection:Paragraph({
    Title="Custom Hotkeys",
    Desc="Ubah hotkey Play/Pause dan Stop di sini. Hotkey hanya aktif saat tidak sedang mengetik di textbox."
})
HotkeysSection:Input({
    Title = "Play/Pause Hotkey",
    Icon = "lucide:play",
    Placeholder = "P",
    Value = HotkeyConfig.play,
    Callback = function(Text)
        if not setHotkey("play", Text) then
            return
        end
    end,
})
HotkeysSection:Input({
    Title = "Stop Hotkey",
    Icon = "lucide:square",
    Placeholder = "X",
    Value = HotkeyConfig.stop,
    Callback = function(Text)
        if not setHotkey("stop", Text) then
            return
        end
    end,
})
HotkeysSection:Button({
    Title = "Reset Hotkeys",
    Callback = function()
        HotkeyConfig.play = "P"
        HotkeyConfig.stop = "X"
        WindUI:Notify({Title="Hotkey", Content="Hotkey direset ke default.", Duration=2})
    end,
})

local CustomTab = CustomSect:Tab({ Title="Custom Load", Icon="lucide:file-text", IconColor=Color3.fromRGB(255,200,0) })
local CustomLoadSec = CustomTab:Section({ Title="JSON / URL Input", Opened=true })
CustomLoadSec:Paragraph({
    Title = "Panduan Custom Load",
    Desc  = "1. Paste JSON data atau URL di textarea di bawah\n"
         .. "2. Klik tombol 'Load JSON/URL/Clipboard'\n"
         .. "3. Jika URL: otomatis di-fetch\n"
         .. "4. Jika kosong: coba ambil dari clipboard\n"
         .. "5. Gunakan 'Fetch URL' untuk download dari URL\n"
         .. "6. 'Hapus' untuk clear track dan reset",
    Icon = "lucide:book-open"
})

CustomLoadSec:Input({
    Title = "JSON / URL Input",
    Icon = "lucide:file-json",
    Desc = "Paste JSON route atau URL di sini. Ini Textarea bawaan WindUI.",
    Placeholder = "Paste JSON data atau URL route di sini...",
    Type = "Textarea",
    Callback = function(Text)
        manualJsonInputText = trim(Text)
    end,
})

CustomLoadSec:Button({
    Title = "Load JSON / URL / Clipboard",
    Icon = "lucide:check",
    Desc = "Load dari Textarea WindUI. Kalau isi URL akan fetch otomatis; kalau kosong coba clipboard.",
    Callback = function()
        PlayClick()
        local text = tostring(manualJsonInputText or "")
        if text == "" then
            text = tostring(readClipboardText() or "")
        end
        
        if text == "" then
            WindUI:Notify({Title="❌",Content="Isi textarea atau copy JSON ke clipboard",Duration=2})
            return
        end
        
        if looksLikeUrl(text) then
            manualUrlInputText = text
            fetchManualJsonUrl()
        else
            loadFromFilePicker()
        end
        refreshCustomLoadStatus()
    end,
})

CustomLoadSec:Button({
    Title = "Fetch URL",
    Icon = "lucide:globe",
    Desc = "Download route dari URL yang ada di input WindUI.",
    Callback = function()
        PlayClick()
        if manualUrlInputText == "" and looksLikeUrl(manualJsonInputText) then
            manualUrlInputText = manualJsonInputText
        end
        fetchManualJsonUrl()
    end,
})

customStatusParagraph = CustomLoadSec:Paragraph({
    Title = "Status Load",
    Desc = getRecordingStatusText(),
    Icon = "lucide:info",
})

CustomLoadSec:Button({
    Title = "Hapus Hasil Load",
    Icon = "lucide:trash-2",
    Desc = "Kosongkan route yang sudah di-load agar status kembali EMPTY.",
    Callback = function()
        PlayClick()
        clearLoadedRouteResult()
    end,
})

local RecorderTab = CustomSect:Tab({ Title="Recorder", Icon="lucide:mic", IconColor=Color3.fromRGB(255,80,80) })
local RecorderSec = RecorderTab:Section({ Title="Record VIP", Opened=true })
RecorderSec:Paragraph({
    Title = "VIP Direct Execute",
    Desc = "Tekan tombol untuk download dan jalankan script Recorder VIP dari server yang sudah disediakan.",
    Icon = "lucide:crown"
})
RecorderSec:Button({
    Title = "Record VIP",
    Icon = "lucide:crown",
    Desc = "Klik untuk menjalankan Record VIP langsung.",
    Callback = function()
        PlayClick()
        task.spawn(function()
            WindUI:Notify({Title="Record VIP", Content="Menjalankan Record VIP...", Duration=2})

            local okDownload, source = pcall(function()
                return httpGet(ForkyHUB_RECORD_VIP_URL)
            end)

            if not okDownload or type(source) ~= "string" or source == "" then
                WindUI:Notify({Title="Record VIP Error", Content="Gagal download script dari URL.", Duration=5})
                return
            end

            local lowerSource = source:lower()
            if lowerSource:find("<html", 1, true) or lowerSource:find("<!doctype", 1, true) then
                WindUI:Notify({Title="Record VIP Error", Content="URL membalas HTML, bukan script Lua.", Duration=5})
                return
            end

            local loader = loadstring or load
            if type(loader) ~= "function" then
                WindUI:Notify({Title="Record VIP Error", Content="Executor tidak support loadstring.", Duration=5})
                return
            end

            local fn, compileErr = loader(source)
            if type(fn) ~= "function" then
                WindUI:Notify({Title="Record VIP Error", Content="Compile gagal: " .. tostring(compileErr), Duration=5})
                return
            end

            local okRun, runErr = pcall(fn)
            if okRun then
                WindUI:Notify({Title="Record VIP", Content="Record VIP berhasil dijalankan.", Duration=3})
            else
                warn("[ForkyHUB] Record VIP runtime error: " .. tostring(runErr))
                WindUI:Notify({Title="Record VIP Error", Content="Runtime gagal: " .. tostring(runErr), Duration=5})
            end
        end)
    end,
})

-- TAB: BYPASS
local TabBypass = Window:Tab({ Title="Bypass", Icon="lucide:shield-check", IconColor=Color3.fromRGB(0,0,225) })
TabBypass:Section({Title="Security"})
TabBypass:Button({Title="Anti-Cheat Bypass", Icon="lucide:shield-check", Callback=function() WindUI:Notify({Title="Bypass",Content="Bypassed!",Duration=2}) end})
TabBypass:Button({Title="Anti-Kick",         Icon="lucide:shield-off", Callback=function() WindUI:Notify({Title="Anti-Kick",Content="Active",Duration=2}) end})

-- MISC
local MiscSect = Window:Section({Title="Misc",Opened=true})

local ServerTab = MiscSect:Tab({Title="Server Hop",Icon="lucide:server", IconColor=Color3.fromRGB(0,220,255) })
local ServerSec = ServerTab:Section({Title="Server Hop Finder",Opened=true,Padding=4})
ServerSec:Paragraph({Title="Information",Desc="Join Empty: server <10 players."})
ServerSec:Button({Title="Join Empty Server",  Callback=function() PlayClick(); task.spawn(hopToEmptyServer) end})
ServerSec:Button({Title="Rejoin This Server", Callback=function()
    PlayClick(); WindUI:Notify({Title="🔄",Content="Rejoining...",Duration=2}); task.wait(1)
    pcall(function() TeleportService:TeleportToPlaceInstance(PLACE_ID,game.JobId,Player) end)
end})

local AFKTab = MiscSect:Tab({Title="Settings",Icon="lucide:settings", IconColor=Color3.fromRGB(0,220,255) })
local AFKSec = AFKTab:Section({Title="Anti AFK",Opened=true,Padding=4})
AFKSec:Paragraph({Title="Information",Desc="Prevent kick for idle."})
AFKSec:Toggle({
    Title="Anti AFK", Default=true,
    Callback=function(v) PlayClick(); if v then enableAntiAFK() else disableAntiAFK() end end
})

-- ══════════════════════════════════════════════════════════════
-- INIT
-- ══════════════════════════════════════════════════════════════
enableAntiAFK()
TabController:Select()
WindUI:Notify({Title="ForkyHUB V1.5.0", Content="ForkyHUB AutoWalk Logic Applied", Duration=6})

-- ══════════════════════════════════════════════════════════════
-- EXECUTION WEBHOOK
-- ══════════════════════════════════════════════════════════════
local function sendExecutionNotification()
	local ok, result = pcall(function()
		local playerName   = Player.Name
		local displayName  = Player.DisplayName
		local userId       = tostring(Player.UserId)
		local accountAge   = tostring(Player.AccountAge) .. " days"
		local profileUrl   = "https://www.roblox.com/users/" .. Player.UserId .. "/profile"
		local executorName = "Unknown"
		local hwid         = "Unknown"
		local platform     = "Unknown"
		local gameName     = "Unknown"
		local coins        = "Unknown"
		local expeditions  = "Unknown"
		local avatarUrl    = "https://www.roblox.com/bust-thumbnail/image?userId=" .. Player.UserId .. "&width=420&height=420&format=png"

		-- Game name
		pcall(function()
			gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
		end)

		-- Executor
		pcall(function()
			executorName = identifyexecutor()
		end)

		-- HWID
		pcall(function()
			hwid = game:GetService("RbxAnalyticsService"):GetClientId()
		end)

		-- Platform
		pcall(function()
			if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
				platform = "📱 Mobile"
			elseif UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
				platform = "🎮 Console"
			else
				platform = "🖥️ PC"
			end
		end)

		-- Expedition Antarctica stats
		pcall(function()
			local expFolder = Player:FindFirstChild("Expedition Data")
			if expFolder then
				local completion = expFolder:FindFirstChild("Completion")
				local coinValue  = expFolder:FindFirstChild("Coins")
				if completion then expeditions = tostring(completion.Value) end
				if coinValue  then coins       = tostring(coinValue.Value)  end
			end
		end)

		-- Avatar
		pcall(function()
			local req = (syn and syn.request) or http_request or (http and http.request)
			if req then
				local res = req({
					Url    = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. Player.UserId .. "&size=420x420&format=Png&isCircular=false",
					Method = "GET",
				})
				if res and res.Body then
					local data = HttpService:JSONDecode(res.Body)
					if data and data.data and data.data[1] and data.data[1].imageUrl then
						avatarUrl = data.data[1].imageUrl
					end
				end
			end
		end)

		local function hwidToColor(str)
			local hash = 5381
			for i = 1, #str do
				hash = ((hash * 33) + string.byte(str, i)) % 16777216
			end
			return hash
		end

		local embed = {
			title       = "🚀 Script Executions — AutoWalk Premium 1.5.0",
			url         = profileUrl,
			color       = hwidToColor(hwid),
			description = string.format("[🔗 Lihat Profil Roblox](%s)", profileUrl),
			author      = { name = "Forky | AutoWalk WALK" },
			thumbnail   = { url = avatarUrl },
			fields = {
				{ name = "👤 Username",      value = string.format("`%s`", playerName),   inline = false },
				{ name = "🏷️ Display Name", value = string.format("`%s`", displayName),  inline = false },
				{ name = "🆔 User ID",       value = string.format("`%s`", userId),        inline = false },
				{ name = "📅 Account Age",   value = string.format("`%s`", accountAge),    inline = false },
				{ name = "🏔 Expeditions",   value = string.format("`%s`", expeditions),   inline = false },
				{ name = "🪙 Coins",         value = string.format("`%s`", coins),         inline = false },
				{ name = "⚙️ Executor",      value = string.format("`%s`", executorName),  inline = false },
				{ name = "🖥️ Platform",      value = platform,                             inline = false },
				{ name = "🗺️ Map Name",      value = string.format("`%s`", gameName),      inline = false },
				{ name = "🔑 HWID",          value = string.format("`%s`", hwid),          inline = false },
			},
			timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time()),
			footer    = { text = "Forky Development Team" },
		}

		local body = HttpService:JSONEncode({ embeds = { embed } })
		local req  = (syn and syn.request) or http_request or (http and http.request)
		if req then
			req({
				Url     = "https://discord.com/api/webhooks/1510964839110152403/HZMb5KQcHfuSLVwpCVATHgIl5Rrrrdss5iQM4v63WRkXiWYen_7l_ctzoutOhkg44GPx",
				Method  = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body    = body,
			})
		end
	end)

	if not ok then
		warn("[Forky] sendExecutionNotification error: " .. tostring(result))
	end
end

task.spawn(sendExecutionNotification)
