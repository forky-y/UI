local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local LocalPlayer = Players.LocalPlayer

-- ================= CONFIG =================
local webhookURL = "https://discord.com/api/webhooks/1462050938536857662/p1ZdTyznw0KvStxKnau0A0VocivfEVqsB4eGmjGtChKwY29rYJeO_QOkl_Up5UnCmN7L"
local chatWebhookURL = "https://discord.com/api/webhooks/1509429583328579645/MMRdPgtQSuJvfiq0rAvbuFFbraQmpH83keLqWB2Z78dgCsIUKFqOw2C9KNOzKT2D9YJ5"
local playerChatWebhookURL = "https://discord.com/api/webhooks/1509469994004648027/qXA35wDQ1j7-nGIXKoG3oFBjT7UZWi0M6d-WFYkgWbjIqSVLbk5MCrrobcS9fZhGgIzM"

local interval = 30
local messageId = nil
local sendPlayerChatLogs = true 
local sendServerChatLogs = true 
-- =========================================

-- ================= DATA ===================
local knownUsers = {}        
local previousStatus = {}
local statusHistory = {}
local MAX_HISTORY = 5
-- =========================================

local function addHistory(event, username)
    local line = string.format("[%s] %-6s | %s", os.date("%H:%M:%S"), event, username)
    table.insert(statusHistory, 1, line)
    if #statusHistory > MAX_HISTORY then table.remove(statusHistory) end
end

local function getRequestFunction()
    return syn and syn.request or http_request or request
end

local function sendWebhookPayload(url, payload)
    if not url or url == "" then return end
    local req = getRequestFunction()
    if not req then return end
    pcall(function()
        req({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end)
end

-- KEBAL 100% (BYTE-BASED): Membersihkan RichText menggunakan tabel byte, tanpa string.sub / pattern matching
local function cleanRichText(text)
    if not text then return "" end
    
    local cleanedBytes = {}
    pcall(function()
        local insideTag = false
        -- Ambil seluruh byte dari string sekaligus (Aman dari pembacaan setengah karakter UTF-8)
        local bytes = { string.byte(text, 1, #text) }
        
        for _, b in ipairs(bytes) do
            if b == 60 then -- Karakter '<'
                insideTag = true
            elseif b == 62 then -- Karakter '>'
                insideTag = false
            elseif not insideTag then
                -- Hanya izinkan karakter printable ASCII standard (32-126), Newline (10), dan Carriage Return (13)
                if (b >= 32 and b <= 126) or b == 10 or b == 13 then
                    table.insert(cleanedBytes, b)
                end
            end
        end
    end)
    
    if #cleanedBytes > 0 then
        local success, result = pcall(function()
            return string.char(unpack(cleanedBytes))
        end)
        if success then return result end
    end
    
    return "[Pesan Tidak Terbaca]"
end

-- KEBAL 100% (BYTE-BASED): Mengambil warna RGB lewat array byte murni
local function extractEmbedColor(text, defaultColor)
    if not text then return defaultColor end
    
    local extractedColor = nil
    pcall(function()
        local bytes = { string.byte(text, 1, #text) }
        local len = #bytes
        
        -- Cari sekuens teks murni "rgb(" secara byte manual
        -- r=114, g=103, b=98, (=40
        for i = 1, len - 4 do
            if bytes[i] == 114 and bytes[i+1] == 103 and bytes[i+2] == 98 and bytes[i+3] == 40 then
                -- Kumpulkan karakter angka setelah "rgb(" sampai bertemu ")" (41)
                local currentNum = 0
                local components = {}
                
                for j = i + 4, math.min(i + 25, len) do
                    local b = bytes[j]
                    if b >= 48 and b <= 57 then -- Karakter Angka 0-9
                        currentNum = (currentNum * 10) + (b - 48)
                    elseif b == 44 or b == 41 then -- Karakter Koma ',' atau Tutup Kurung ')'
                        table.insert(components, currentNum)
                        currentNum = 0
                        if b == 41 then break end -- Selesai jika sudah ketemu ')'
                    end
                end
                
                if #components >= 3 then
                    local r = math.clamp(components[1] or 0, 0, 255)
                    local g = math.clamp(components[2] or 0, 0, 255)
                    local b = math.clamp(components[3] or 0, 0, 255)
                    extractedColor = (r * 65536) + (g * 256) + b
                    break
                end
            end
        end
    end)
    
    return extractedColor or defaultColor
end

-- Fungsi pembantu pengecekan substring murni berbasis byte (Plain Text Search alternatif)
local function byteContains(sourceStr, checkStr)
    if not sourceStr or not checkStr then return false end
    local srcBytes = { string.byte(sourceStr, 1, #sourceStr) }
    local chkBytes = { string.byte(checkStr, 1, #checkStr) }
    
    if #chkBytes > #srcBytes then return false end
    
    for i = 1, #srcBytes - #chkBytes + 1 do
        local match = true
        for j = 1, #chkBytes do
            if srcBytes[i + j - 1] ~= chkBytes[j] then
                match = false
                break
            end
        end
        if match then return true end
    end
    return false
end

-- CALLBACK INTERCEPTOR CHAT
TextChatService.OnIncomingMessage = function(message)
    if message.Status ~= Enum.TextChatMessageStatus.Success then return end

    task.spawn(function()
        local rawText = ""
        local success = pcall(function()
            rawText = message.Text
        end)
        
        if not success or not rawText or rawText == "" then return end
        
        local cleanText = cleanRichText(rawText)

        local senderName = "Server System"
        local senderType = "Server"
        local channelName = "Server Alerts"
        local embedColor = 0x5865F2 

        local textSource = message.TextSource
        if textSource then
            local targetPlayer = nil
            pcall(function()
                targetPlayer = Players:GetPlayerByUserId(textSource.UserId)
            end)
            
            if targetPlayer then
                senderType = "Player"
                senderName = string.format("%s (@%s)", targetPlayer.DisplayName, targetPlayer.Name)
                channelName = "RBXGeneral"
                embedColor = 0x3498DB
            else
                senderType = "Player"
                senderName = "Unknown Player"
                channelName = "RBXGeneral"
                embedColor = 0x3498DB
            end
        else
            senderType = "Server"
            
            -- Gunakan fungsi pencarian berbasis byte agar Luau tidak menyentuh regex string internal
            local isGlobal = byteContains(cleanText, "Global")
            local isServer = byteContains(cleanText, "Server")
            
            if isGlobal then
                senderName = "Global System"
                channelName = "Global Alerts"
                embedColor = extractEmbedColor(rawText, 0x9B59B6)
            elseif isServer then
                senderName = "Server System"
                channelName = "Server Alerts"
                embedColor = extractEmbedColor(rawText, 0x2ECC71)
            else
                senderName = "System Notification"
                channelName = "Game Alerts"
                embedColor = 0x95A5A6
            end
        end

        if senderType == "Server" and not sendServerChatLogs then return end
        if senderType == "Player" and not sendPlayerChatLogs then return end

        -- Limitasi karakter aman menggunakan pembatasan sub murni dengan pcall
        pcall(function()
            if #cleanText > 1000 then 
                cleanText = string.sub(cleanText, 1, 1000) .. "..." 
            end
        end)

        local payload = {
            embeds = {{
                title = "Chat Log Update",
                color = embedColor,
                fields = {
                    { name = "Pengirim", value = senderName, inline = true },
                    { name = "Tipe", value = senderType, inline = true },
                    { name = "Channel", value = channelName, inline = true },
                    { name = "Pesan", value = cleanText, inline = false },
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }}
        }
        
        if senderType == "Player" then
            sendWebhookPayload(playerChatWebhookURL, payload)
        else
            sendWebhookPayload(chatWebhookURL, payload)
        end
    end)
end

-- ================= UI GENERATOR =================
local function createChatToggleGui()
    local targetCore = LocalPlayer:WaitForChild("PlayerGui")
    if targetCore:FindFirstChild("ChatLogToggleGUI") then return end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ChatLogToggleGUI"
    screenGui.ResetOnSpawn = false

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 50, 0, 50)
    toggleButton.Position = UDim2.new(0, 15, 0, 15)
    toggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    toggleButton.Text = "CHAT"
    toggleButton.TextSize = 14
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.Parent = screenGui

    local btnCorner = Instance.new("UICorner", toggleButton)
    btnCorner.CornerRadius = UDim.new(0, 12)
    local btnStroke = Instance.new("UIStroke", toggleButton)
    btnStroke.Color = Color3.fromRGB(50, 50, 65)
    btnStroke.Thickness = 2

    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 260, 0, 150)
    frame.Position = UDim2.new(0, 15, 0, 80)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.Visible = true
    frame.Parent = screenGui

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    local frameStroke = Instance.new("UIStroke", frame)
    frameStroke.Color = Color3.fromRGB(45, 45, 55)
    frameStroke.Thickness = 1.5

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 35)
    title.Position = UDim2.new(0, 15, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "Chat Log Status"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = Color3.fromRGB(240, 240, 245)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local playerButton = Instance.new("TextButton")
    playerButton.Name = "PlayerToggle"
    playerButton.Size = UDim2.new(1, -30, 0, 38)
    playerButton.Position = UDim2.new(0, 15, 0, 45)
    playerButton.Font = Enum.Font.GothamMedium
    playerButton.TextSize = 13
    playerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    playerButton.Parent = frame
    Instance.new("UICorner", playerButton).CornerRadius = UDim.new(0, 8)

    local serverButton = Instance.new("TextButton")
    serverButton.Name = "ServerToggle"
    serverButton.Size = UDim2.new(1, -30, 0, 38)
    serverButton.Position = UDim2.new(0, 15, 0, 95)
    serverButton.Font = Enum.Font.GothamMedium
    serverButton.TextSize = 13
    serverButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    serverButton.Parent = frame
    Instance.new("UICorner", serverButton).CornerRadius = UDim.new(0, 8)

    local TweenService = game:GetService("TweenService")
    local function updateButtonVisual(btn, enabled)
        local base = btn.Name == "PlayerToggle" and "Player Chat" or "Server Chat"
        btn.Text = base .. " : " .. (enabled and "ON" or "OFF")
        local col = enabled and Color3.fromRGB(46, 196, 182) or Color3.fromRGB(231, 76, 60)
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = col}):Play()
    end

    updateButtonVisual(playerButton, sendPlayerChatLogs)
    updateButtonVisual(serverButton, sendServerChatLogs)

    playerButton.MouseButton1Click:Connect(function()
        sendPlayerChatLogs = not sendPlayerChatLogs
        updateButtonVisual(playerButton, sendPlayerChatLogs)
    end)

    serverButton.MouseButton1Click:Connect(function()
        sendServerChatLogs = not sendServerChatLogs
        updateButtonVisual(serverButton, sendServerChatLogs)
    end)

    toggleButton.MouseButton1Click:Connect(function()
        frame.Visible = not frame.Visible
        toggleButton.Text = frame.Visible and "CHAT" or "X"
    end)

    screenGui.Parent = targetCore
end

createChatToggleGui()

-- ================= MONITOR SERVER STATUS =================
local function updateDiscordStatus()
    local playerMap = {}
    for _, p in pairs(Players:GetPlayers()) do
        playerMap[p.Name] = p.DisplayName
        knownUsers[p.Name] = p.DisplayName
    end

    local onlineText, offlineText = "", ""
    local onlineCount, offlineCount, totalUsers = 0, 0, 0

    for name, display in pairs(knownUsers) do
        totalUsers += 1
        local isOnline = playerMap[name] ~= nil
        local wasOnline = previousStatus[name]

        if isOnline and not wasOnline then
            addHistory("JOIN", name)
        elseif not isOnline and wasOnline then
            addHistory("LEAVE", name)
        end

        previousStatus[name] = isOnline

        if isOnline then
            onlineCount += 1
            onlineText = onlineText .. string.format("[ONLINE] **%s** (@%s)\n", display, name)
        else
            offlineCount += 1
            offlineText = offlineText .. string.format("[OFFLINE] **%s**\n", name)
        end
    end

    local description = ""
    if onlineText ~= "" then description = description .. "**ONLINE**\n" .. onlineText .. "\n" end
    if offlineText ~= "" then description = description .. "**OFFLINE**\n" .. offlineText end

    local historyText = "No activity yet"
    if #statusHistory > 0 then
        historyText = "```text\nTIME     EVENT  | USER\n---------------------------\n" .. table.concat(statusHistory, "\n") .. "\n```"
    end

    local color = onlineCount == 0 and 0xE74C3C or offlineCount == 0 and 0x2ECC71 or 0x3498DB
    local data = {
        embeds = {{
            title = "LIVE Server Monitor",
            description = description,
            color = color,
            fields = {
                {
                    name = "Server Status",
                    value = string.format("Online: **%d/%d**\nEmpty Slots: **%d**", onlineCount, Players.MaxPlayers, Players.MaxPlayers - onlineCount),
                    inline = true
                },
                {
                    name = "User History",
                    value = string.format("Known Users: **%d**\nOffline (History): **%d**", totalUsers, offlineCount),
                    inline = true
                },
                {
                    name = "Activity Logs",
                    value = historyText,
                    inline = false
                },
                {
                    name = "Server ID",
                    value = "```" .. game.JobId .. "```",
                    inline = false
                }
            },
            footer = { text = "LIVE Server Monitor | Last Update" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }

    local req = getRequestFunction()
    if not req then return end

    local url = messageId and (webhookURL .. "/messages/" .. messageId) or (webhookURL .. "?wait=true")
    local method = messageId and "PATCH" or "POST"

    local ok, res = pcall(function()
        return req({
            Url = url,
            Method = method,
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(data)
        })
    end)

    if ok and not messageId and res and res.Body then
        pcall(function()
            messageId = HttpService:JSONDecode(res.Body).id
        end)
    end
end

task.spawn(function()
    while true do
        updateDiscordStatus()
        task.wait(interval)
    end
end)
