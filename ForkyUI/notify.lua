-- // VelarisUI | Notify.lua | Neverlose Style | (FIXED BY ANTIGRAVITY)

local HttpService = game:GetService("HttpService")

local function MakeNotifyModule(TweenService, CoreGui, getIconId, defaultColor)
    local TextService = game:GetService("TextService")
    local UserInputService = game:GetService("UserInputService")

    local function Create(Name, Properties, Parent)
        local inst = Instance.new(Name)
        for i, v in pairs(Properties) do
            inst[i] = v
        end
        if Parent then inst.Parent = Parent end
        return inst
    end

    -- Fixed built-in icons mapping for Neverlose style (menggunakan Roblox Asset ID)
    local BuiltInIcons = {
        info = "rbxassetid://7734068321",
        success = "rbxassetid://7733085271",
        warning = "rbxassetid://7733658504",
        error = "rbxassetid://7733658504",
        loading = "rbxassetid://10214309831",
        bell = "rbxassetid://7733765398",
        gear = "rbxassetid://7734053495",
        trash = "rbxassetid://7732924192",
        lock = "rbxassetid://7734052066",
        unlock = "rbxassetid://7734052044",
        download = "rbxassetid://7733920644",
        upload = "rbxassetid://7733920644",
        user = "rbxassetid://7734053426",
        heart = "rbxassetid://7733920399",
        star = "rbxassetid://7733920391",
        fire = "rbxassetid://7733920367",
    }

    local NotifyModule = {}

    -- Create shadow effect like Neverlose
    local function CreateShadow(parent)
        local shadows = {}

        local UIShadow1 = Create("UIStroke", {
            Thickness = 6,
            Transparency = 1,
            Color = Color3.fromRGB(0, 0, 0),
        }, parent)

        local UIShadow2 = Create("UIStroke", {
            Thickness = 5,
            Transparency = 1,
            Color = Color3.fromRGB(0, 0, 0),
        }, parent)

        local UIShadow3 = Create("UIStroke", {
            Thickness = 4,
            Transparency = 1,
            Color = Color3.fromRGB(0, 0, 0),
        }, parent)

        local UIShadow4 = Create("UIStroke", {
            Thickness = 3,
            Transparency = 1,
            Color = Color3.fromRGB(0, 0, 0),
        }, parent)

        return {
            Render = function(value)
                local trans = value and 0.9 or 1
                TweenService:Create(UIShadow1, TweenInfo.new(0.175), { Transparency = trans }):Play()
                TweenService:Create(UIShadow2, TweenInfo.new(0.175), { Transparency = trans }):Play()
                TweenService:Create(UIShadow3, TweenInfo.new(0.175), { Transparency = trans }):Play()
                TweenService:Create(UIShadow4, TweenInfo.new(0.175), { Transparency = trans }):Play()
            end
        }
    end

    -- Main notification container
    local notifyGui = CoreGui:FindFirstChild("VelarisNotifyGui")
    if not notifyGui then
        notifyGui = Create("ScreenGui", {
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Name = "VelarisNotifyGui",
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
        }, CoreGui)
    end

    local notifyLayout = notifyGui:FindFirstChild("NotifyLayout")
    if not notifyLayout then
        notifyLayout = Create("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -15, 0, 15),
            Size = UDim2.new(0, 320, 1, 0),
            Name = "NotifyLayout",
        }, notifyGui)

        local function reorganizeStack()
            local yOffset = 0
            local children = {}

            for _, v in ipairs(notifyLayout:GetChildren()) do
                if v:IsA("Frame") and v.Name == "NotifyContainer" then
                    table.insert(children, v)
                end
            end

            -- Reverse to stack from top to bottom
            for i = #children, 1, -1 do
                local v = children[i]
                local newPos = UDim2.new(0, 0, 0, yOffset)
                TweenService:Create(v, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = newPos }):Play()
                yOffset = yOffset + v.Size.Y.Offset + 10
            end
        end

        notifyLayout.ChildRemoved:Connect(reorganizeStack)
        notifyLayout.ChildAdded:Connect(reorganizeStack)
    end

    function NotifyModule:MakeNotify(NotifyConfig)
        NotifyConfig = NotifyConfig or {}
        NotifyConfig.Title = NotifyConfig.Title or "VelarisUI"
        NotifyConfig.Description = NotifyConfig.Description or ""
        NotifyConfig.Content = NotifyConfig.Content or ""
        NotifyConfig.Icon = NotifyConfig.Icon or "bell"
        NotifyConfig.Time = tonumber(NotifyConfig.Time) or 0.3

        NotifyConfig.Delay = tonumber(NotifyConfig.Delay) or tonumber(NotifyConfig.Duration) or 5
        NotifyConfig.Buttons = NotifyConfig.Buttons or {}
        NotifyConfig.Type = NotifyConfig.Type or "default" -- default, success, error, warning, info

        -- Color mapping for notification types
        local TypeColors = {
            default = defaultColor or Color3.fromRGB(78, 127, 252),
            success = Color3.fromRGB(68, 189, 50),
            error = Color3.fromRGB(230, 74, 25),
            warning = Color3.fromRGB(255, 184, 0),
            info = Color3.fromRGB(0, 184, 212),
        }

        NotifyConfig.Color = NotifyConfig.Color or TypeColors[NotifyConfig.Type] or TypeColors.default

        if typeof(NotifyConfig.Color) ~= "Color3" then
            NotifyConfig.Color = TypeColors.default
        end

        local NotifyFunction = {}
        local isClosing = false
        local notificationId = HttpService:GenerateGUID(false)

        -- Calculate current Y offset
        local yOffset = 0
        for _, v in ipairs(notifyLayout:GetChildren()) do
            if v:IsA("Frame") and v.Name == "NotifyContainer" then
                yOffset = yOffset + v.Size.Y.Offset + 10
            end
        end

        -- Main container
        local notifyContainer = Create("Frame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 300, 0, 0),
            Position = UDim2.new(0, 0, 0, yOffset),
            Name = "NotifyContainer",
            ClipsDescendants = false,
        }, notifyLayout)

        -- Main notification frame
        local notifyFrame = Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(20, 22, 27),
            BackgroundTransparency = 0.035,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 300, 0, 0),
            Position = UDim2.new(0, 350, 0, 0),
            Name = "NotifyFrame",
            ClipsDescendants = true,
        }, notifyContainer)

        Create("UICorner", { CornerRadius = UDim.new(0, 12) }, notifyFrame)

        -- Stroke like Neverlose
        Create("UIStroke", {
            Color = Color3.fromRGB(45, 48, 58),
            Thickness = 1,
            Transparency = 0.65,
        }, notifyFrame)

        -- Shadow effect
        local shadow = CreateShadow(notifyFrame)
        shadow.Render(true)

        -- Left accent bar (Neverlose style)
        local accentBar = Create("Frame", {
            BackgroundColor3 = NotifyConfig.Color,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 4, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            Name = "AccentBar",
        }, notifyFrame)

        Create("UICorner", { CornerRadius = UDim.new(0, 0) }, accentBar)

        -- Top header area
        local topFrame = Create("Frame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 38),
            Name = "TopFrame",
        }, notifyFrame)

        -- Icon
        local iconId = getIconId(NotifyConfig.Icon)
        local iconLabel

        if iconId ~= "" then
            iconLabel = Create("ImageLabel", {
                Image = iconId,
                ImageColor3 = NotifyConfig.Color,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 12, 0.5, 0),
                Size = UDim2.new(0, 20, 0, 20),
                ScaleType = Enum.ScaleType.Fit,
                Name = "IconImg",
            }, topFrame)
        else
            -- FIXED: Menggunakan gambar dari BuildInIcons, bukan TextLabel
            iconLabel = Create("ImageLabel", {
                Image = BuiltInIcons[NotifyConfig.Icon] or BuiltInIcons["bell"],
                ImageColor3 = NotifyConfig.Color,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 12, 0.5, 0),
                Size = UDim2.new(0, 20, 0, 20),
                ScaleType = Enum.ScaleType.Fit,
                Name = "IconImg",
            }, topFrame)
        end

        -- Title
        local titleLabel = Create("TextLabel", {
            Text = NotifyConfig.Title,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 42, 0, 10),
            Size = UDim2.new(1, -100, 0, 18),
            Name = "TitleLabel",
        }, topFrame)

        -- Close button
        local closeBtn = Create("TextButton", {
            Text = "",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(1, -30, 0.5, 0),
            Size = UDim2.new(0, 24, 0, 24),
            Name = "CloseBtn",
        }, topFrame)

        local closeIcon = Create("TextLabel", {
            Text = "✕",
            TextColor3 = Color3.fromRGB(150, 150, 150),
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 1, 0),
        }, closeBtn)

        -- Description (if exists)
        local descLabel = nil
        if NotifyConfig.Description ~= "" then
            descLabel = Create("TextLabel", {
                Text = NotifyConfig.Description,
                TextColor3 = NotifyConfig.Color,
                TextSize = 11,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 42, 0, 28),
                Size = UDim2.new(1, -60, 0, 16),
                Name = "DescLabel",
            }, topFrame)
        end

        -- Content text
        local contentStartY = descLabel and 52 or 40
        local contentLabel = Create("TextLabel", {
            Text = NotifyConfig.Content,
            TextColor3 = Color3.fromRGB(180, 180, 180),
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 12, 0, contentStartY),
            Size = UDim2.new(1, -24, 0, 0),
            Name = "ContentLabel",
        }, notifyFrame)

        -- Calculate content height
        local contentSize = TextService:GetTextSize(
            NotifyConfig.Content,
            11,
            Enum.Font.GothamMedium,
            Vector2.new(276, math.huge)
        )

        local contentHeight = math.max(contentSize.Y, 16)
        contentLabel.Size = UDim2.new(1, -24, 0, contentHeight)

        -- Calculate total height
        local totalHeight = contentStartY + contentHeight + 12

        if #NotifyConfig.Buttons > 0 then
            totalHeight = totalHeight + 36
        end

        notifyContainer.Size = UDim2.new(0, 300, 0, totalHeight)
        notifyFrame.Size = UDim2.new(0, 300, 0, totalHeight)

        -- Buttons area
        local btnFrame = nil
        if #NotifyConfig.Buttons > 0 then
            btnFrame = Create("Frame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 12, 0, totalHeight - 34),
                Size = UDim2.new(1, -24, 0, 28),
                Name = "BtnFrame",
            }, notifyFrame)

            local btnLayout = Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Padding = UDim.new(0, 8),
            }, btnFrame)

            for idx, btnCfg in ipairs(NotifyConfig.Buttons) do
                local isPrimary = btnCfg.Primary == true

                local btn = Create("TextButton", {
                    Text = btnCfg.Name or ("Button " .. idx),
                    TextSize = 12,
                    TextColor3 = isPrimary and NotifyConfig.Color or Color3.fromRGB(200, 200, 200),
                    Font = Enum.Font.GothamBold,
                    BackgroundColor3 = isPrimary and Color3.fromRGB(78, 127, 252) or Color3.fromRGB(30, 32, 38),
                    BackgroundTransparency = isPrimary and 0.2 or 0,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 0, 1, 0),
                    AutoButtonColor = false,
                    Name = "Btn" .. idx,
                }, btnFrame)

                Create("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)

                -- Hover effect

                btn.MouseEnter:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.15), {
                        BackgroundTransparency = isPrimary and 0.1 or 0.3,
                        TextColor3 = isPrimary and Color3.fromRGB(255, 255, 255) or NotifyConfig.Color,
                    }):Play()
                end)

                btn.MouseLeave:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.15), {
                        BackgroundTransparency = isPrimary and 0.2 or 0,
                        TextColor3 = isPrimary and NotifyConfig.Color or Color3.fromRGB(200, 200, 200),
                    }):Play()
                end)

                -- Calculate button width
                local btnTextSize = TextService:GetTextSize(btn.Text, 12, Enum.Font.GothamBold, Vector2.new(math.huge, math.huge))
                btn.Size = UDim2.new(0, btnTextSize.X + 24, 1, 0)

                btn.Activated:Connect(function()
                    if btnCfg.Callback then
                        local success, err = pcall(btnCfg.Callback)
                        if not success then
                            warn("Notify Button Error: " .. tostring(err))
                        end
                    end
                    NotifyFunction:Close()
                end)
            end
        end

        -- Close button hover effect
        closeBtn.MouseEnter:Connect(function()
            TweenService:Create(closeIcon, TweenInfo.new(0.15), { TextColor3 = NotifyConfig.Color }):Play()
        end)

        closeBtn.MouseLeave:Connect(function()
            TweenService:Create(closeIcon, TweenInfo.new(0.15), { TextColor3 = Color3.fromRGB(150, 150, 150) }):Play()
        end)

        -- Animate in
        TweenService:Create(notifyFrame, TweenInfo.new(NotifyConfig.Time, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()

        -- Auto close timer
        local autoCloseTask = nil
        if NotifyConfig.Delay > 0 then
            autoCloseTask = task.delay(NotifyConfig.Delay, function()
                if not isClosing then
                    autoCloseTask = nil -- CLEARED SO IT DOESNT CANCEL ITSELF!
                    NotifyFunction:Close()
                end
            end)
        end

        function NotifyFunction:Close()
            if isClosing then return false end
            isClosing = true

            if autoCloseTask then
                task.cancel(autoCloseTask)
            end

            -- Animate out
            local closeTween = TweenService:Create(notifyFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0, 350, 0, 0)
            })

            closeTween:Play()
            closeTween.Completed:Connect(function()
                if notifyContainer and notifyContainer.Parent then
                    notifyContainer:Destroy()
                end
            end)

            return true
        end

        closeBtn.Activated:Connect(function()
            NotifyFunction:Close()
        end)

        return NotifyFunction
    end

    -- Simplified notification methods
    function NotifyModule:Notify(msg, delay, type, title)
        local notificationType = type or "default"
        return self:MakeNotify({
            Title = title or "Notification",
            Content = msg or "",
            Delay = delay or 4,
            Type = notificationType,
        })
    end

    function NotifyModule:Success(msg, delay, title)
        return self:MakeNotify({
            Title = title or "Success",
            Content = msg or "",
            Delay = delay or 3.5,
            Type = "success",
            Icon = "check",
        })
    end

    function NotifyModule:Error(msg, delay, title)
        return self:MakeNotify({
            Title = title or "Error",
            Content = msg or "",
            Delay = delay or 5,
            Type = "error",
            Icon = "error",
        })
    end

    function NotifyModule:Warning(msg, delay, title)
        return self:MakeNotify({
            Title = title or "Warning",
            Content = msg or "",
            Delay = delay or 4,
            Type = "warning",
            Icon = "warning",
        })
    end

    function NotifyModule:Info(msg, delay, title)
        return self:MakeNotify({
            Title = title or "Info",
            Content = msg or "",
            Delay = delay or 4,
            Type = "info",
            Icon = "info",

        })
    end

    return NotifyModule
end

return MakeNotifyModule
