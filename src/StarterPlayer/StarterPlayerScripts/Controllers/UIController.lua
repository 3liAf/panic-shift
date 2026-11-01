--!strict
--[[
    PANIC SHIFT: UIController.lua
    Client controller for shift HUD, dynamic quota bar, animated disaster alerts,
    results screen, interactive cosmetic shop, daily challenges, and settings.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")
local Types = require(Shared:WaitForChild("Types"))
local Config = require(Shared:WaitForChild("Config"))
local Constants = require(Shared:WaitForChild("Constants"))
local Utility = require(Shared:WaitForChild("Utility"))
local Network = require(Shared:WaitForChild("Network"))

local UIBuilder = require(script.Parent:WaitForChild("UIBuilder"))

local UIController = {
    Name = "UIController",
}

local controllers: { [string]: any } = {}
local player = Players.LocalPlayer
local uiRefs: { [string]: any } = {}
local currentProfile: Types.PlayerProfile? = nil
local screenShakeEnabled = true

local DISASTER_DESCRIPTIONS: { [string]: string } = {
    RunawayCarts = "Dodge speeding carts or guide them into the cart corrals!",
    Blackout = "Lights out! Locate and flip both circuit breakers to restore power!",
    AngryCustomer = "The customer demands the manager! Don't get tackled!",
    ProductAvalanche = "Aisle 2 shelf collapse! Jump clear of the impact zone!",
    SoapApocalypse = "Frictionless floor! Ice-skating physics active!",
    ManagerMadness = "Corporate emergency rule enacted! Follow the manager's orders!",
}

local STATE_BADGES: { [string]: { text: string, color: Color3 } } = {
    LOBBY = { text = "BREAKROOM LOBBY", color = Color3.fromRGB(50, 100, 180) },
    PREPARATION = { text = "SHIFT PREPARATION", color = Color3.fromRGB(230, 170, 20) },
    ACTIVE = { text = "ACTIVE SHIFT", color = Color3.fromRGB(26, 120, 68) },
    CLOSING = { text = "⚡ CLOSING RUSH (2X PTS)", color = Color3.fromRGB(220, 45, 45) },
    RESULTS = { text = "SHIFT CONCLUDED", color = Color3.fromRGB(235, 95, 20) },
    RESET = { text = "RESTOCKING STORE...", color = Color3.fromRGB(120, 60, 160) },
}

local function closeAllModals()
    if uiRefs.ShopModal then uiRefs.ShopModal.Visible = false end
    if uiRefs.ChallengesModal then uiRefs.ChallengesModal.Visible = false end
    if uiRefs.SettingsModal then uiRefs.SettingsModal.Visible = false end
    if uiRefs.ResultsModal then uiRefs.ResultsModal.Visible = false end
end

function UIController:Init(controllerRegistry: { [string]: any })
    controllers = controllerRegistry
end

function UIController:Start()
    local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
    uiRefs = UIBuilder.Build(playerGui)

    local function onButtonClick()
        local effects = controllers["EffectsController"]
        if effects and typeof(effects.PlayButtonClick) == "function" then
            effects:PlayButtonClick()
        end
    end

    -- 1. Connect Drawer Buttons
    uiRefs.ShopBtn.Activated:Connect(function()
        onButtonClick()
        local isOpen = uiRefs.ShopModal.Visible
        closeAllModals()
        uiRefs.ShopModal.Visible = not isOpen
        if uiRefs.ShopModal.Visible then
            self:RenderShopItems()
        end
    end)

    uiRefs.ChallengesBtn.Activated:Connect(function()
        onButtonClick()
        local isOpen = uiRefs.ChallengesModal.Visible
        closeAllModals()
        uiRefs.ChallengesModal.Visible = not isOpen
        if uiRefs.ChallengesModal.Visible then
            self:RenderChallenges()
        end
    end)

    uiRefs.SettingsBtn.Activated:Connect(function()
        onButtonClick()
        local isOpen = uiRefs.SettingsModal.Visible
        closeAllModals()
        uiRefs.SettingsModal.Visible = not isOpen
    end)

    -- Modal Close Buttons
    uiRefs.ShopCloseBtn.Activated:Connect(function() onButtonClick(); uiRefs.ShopModal.Visible = false end)
    uiRefs.ChallengesCloseBtn.Activated:Connect(function() onButtonClick(); uiRefs.ChallengesModal.Visible = false end)
    uiRefs.SettingsCloseBtn.Activated:Connect(function() onButtonClick(); uiRefs.SettingsModal.Visible = false end)
    uiRefs.ResultsCloseBtn.Activated:Connect(function() onButtonClick(); uiRefs.ResultsModal.Visible = false end)

    -- Settings Shake Toggle
    uiRefs.ShakeToggleBtn.Activated:Connect(function()
        onButtonClick()
        screenShakeEnabled = not screenShakeEnabled
        uiRefs.ShakeToggleBtn.Text = string.format("📳 Screen Shake: %s", screenShakeEnabled and "ENABLED" or "DISABLED")
    end)

    -- 2. Connect Remote Listeners
    local roundStateRemote = Network.GetRemoteEvent(Constants.Remotes.ROUND_STATE_CHANGED)
    roundStateRemote.OnClientEvent:Connect(function(state: string, timerRemaining: number, currentQuota: number, targetQuota: number)
        self:OnRoundStateChanged(state, timerRemaining, currentQuota, targetQuota)
    end)

    local disasterRemote = Network.GetRemoteEvent(Constants.Remotes.DISASTER_STATE_CHANGED)
    disasterRemote.OnClientEvent:Connect(function(disasterId: string, status: string, duration: number, metadata: any)
        self:OnDisasterStateChanged(disasterId, status, duration, metadata)
    end)

    local profileRemote = Network.GetRemoteEvent(Constants.Remotes.PLAYER_PROFILE_UPDATED)
    profileRemote.OnClientEvent:Connect(function(profile: Types.PlayerProfile)
        self:OnProfileUpdated(profile)
    end)

    local resultsRemote = Network.GetRemoteEvent(Constants.Remotes.ROUND_RESULTS)
    resultsRemote.OnClientEvent:Connect(function(results: Types.RoundResultsData)
        self:OnRoundResults(results)
    end)

    -- Initial profile fetch to guarantee instant load
    task.spawn(function()
        local getProfileFunc = Network.GetRemoteFunction(Constants.Remotes.REQUEST_PLAYER_PROFILE)
        local profile = getProfileFunc:InvokeServer()
        if profile then
            self:OnProfileUpdated(profile)
        end
    end)

    print("[PanicShift UIController] Full UI mounted and reactive listeners connected.")
end

function UIController:IsScreenShakeEnabled(): boolean
    return screenShakeEnabled
end

function UIController:OnRoundStateChanged(state: string, timerRemaining: number, currentQuota: number, targetQuota: number)
    if not uiRefs.ShiftTimerLabel then return end

    -- Timer text
    uiRefs.ShiftTimerLabel.Text = Utility.FormatTime(timerRemaining)

    -- Shift State badge
    local badgeInfo = STATE_BADGES[state] or { text = state, color = Color3.fromRGB(50, 50, 50) }
    uiRefs.ShiftStateBadge.Text = badgeInfo.text
    uiRefs.ShiftStateBadge.BackgroundColor3 = badgeInfo.color

    -- Quota Bar Progress
    local safeTarget = math.max(1, targetQuota)
    local progressRatio = math.clamp(currentQuota / safeTarget, 0, 1)

    uiRefs.QuotaLabel.Text = string.format("STORE QUOTA: %d / %d", currentQuota, targetQuota)

    local tween = TweenService:Create(uiRefs.QuotaBarFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(progressRatio, 0, 1, 0)
    })
    tween:Play()

    -- Helpful Objective / Guidance Banner Text
    if uiRefs.ObjectiveGuideText then
        if state == "LOBBY" then
            uiRefs.ObjectiveGuideText.Text = "🌟 BREAKROOM: Walk through glass doors into store! Store Mop ready in pack."
        elseif state == "PREPARATION" then
            uiRefs.ObjectiveGuideText.Text = "⏱️ SHIFT STARTING: Head down aisles and watch the 3D objective waypoints!"
        elseif state == "ACTIVE" then
            uiRefs.ObjectiveGuideText.Text = "📢 SHIFT ACTIVE: Follow 3D waypoints! Restock shelves, mop spills & return carts."
        elseif state == "CLOSING" then
            uiRefs.ObjectiveGuideText.Text = "⚡ CLOSING RUSH (2X PTS): Frantic quota push! Complete remaining tasks!"
        elseif state == "RESULTS" then
            uiRefs.ObjectiveGuideText.Text = "🎉 SHIFT CONCLUDED: Check your employee paycheck and MVP standings!"
        else
            uiRefs.ObjectiveGuideText.Text = "🛒 Restocking supermarket sales floor..."
        end
    end

    -- Auto close results on round reset
    if state == "RESET" or state == "PREPARATION" then
        uiRefs.ResultsModal.Visible = false
    end

    -- Camera FOV shift & audio for Closing Rush
    local cameraCtrl = controllers["CameraController"]
    local effectsCtrl = controllers["EffectsController"]
    if state == "CLOSING" then
        if cameraCtrl and typeof(cameraCtrl.SetClosingRushActive) == "function" then
            cameraCtrl:SetClosingRushActive(true)
        end
        if effectsCtrl and typeof(effectsCtrl.PlaySound) == "function" then
            effectsCtrl:PlaySound("RushSiren")
        end
    elseif state == "LOBBY" or state == "RESULTS" or state == "RESET" then
        if cameraCtrl and typeof(cameraCtrl.SetClosingRushActive) == "function" then
            cameraCtrl:SetClosingRushActive(false)
        end
    end
end

function UIController:OnDisasterStateChanged(disasterId: string, status: string, duration: number, metadata: any)
    if not uiRefs.DisasterBanner then return end

    local effectsCtrl = controllers["EffectsController"]
    local cameraCtrl = controllers["CameraController"]

    if effectsCtrl and typeof(effectsCtrl.PlayDisasterAudio) == "function" then
        effectsCtrl:PlayDisasterAudio(disasterId, status)
    end

    if status == Constants.DisasterStatus.TELEGRAPH or status == Constants.DisasterStatus.ACTIVE then
        if cameraCtrl and typeof(cameraCtrl.TriggerShake) == "function" then
            local intensity = (status == Constants.DisasterStatus.ACTIVE) and 0.85 or 0.4
            cameraCtrl:TriggerShake(intensity)
            if status == Constants.DisasterStatus.ACTIVE and typeof(cameraCtrl.PunchFov) == "function" then
                cameraCtrl:PunchFov(3.5)
            end
        end

        uiRefs.DisasterBanner.Visible = true
        uiRefs.DisasterTitle.Text = string.format("⚠️ %s!", string.upper(disasterId))
        uiRefs.DisasterSubtitle.Text = DISASTER_DESCRIPTIONS[disasterId] or "Survive the supermarket hazard!"

        -- Slide down animation (positioned neatly below the top center header)
        local slideDown = TweenService:Create(uiRefs.DisasterBanner, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -230, 0, 108)
        })
        slideDown:Play()

    elseif status == Constants.DisasterStatus.COMPLETED or status == Constants.DisasterStatus.CANCELLED then
        -- Slide up and hide
        local slideUp = TweenService:Create(uiRefs.DisasterBanner, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, -230, 0, -110)
        })
        slideUp:Play()
        task.delay(0.4, function()
            if uiRefs.DisasterBanner then
                uiRefs.DisasterBanner.Visible = false
            end
        end)
    end
end

function UIController:ShowToast(text: string, duration: number?)
    if not uiRefs.NotificationToast or not uiRefs.ToastLabel then return end
    uiRefs.ToastLabel.Text = text
    uiRefs.NotificationToast.Visible = true
    uiRefs.NotificationToast.Position = UDim2.new(0.5, -190, 1, -50)
    uiRefs.NotificationToast.BackgroundTransparency = 1
    uiRefs.ToastLabel.TextTransparency = 1

    TweenService:Create(uiRefs.NotificationToast, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -190, 1, -110),
        BackgroundTransparency = 0,
    }):Play()
    TweenService:Create(uiRefs.ToastLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        TextTransparency = 0,
    }):Play()

    local showTime = duration or 3.0
    task.delay(showTime, function()
        if uiRefs.NotificationToast and uiRefs.NotificationToast.Parent then
            local tw = TweenService:Create(uiRefs.NotificationToast, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                Position = UDim2.new(0.5, -190, 1, -40),
                BackgroundTransparency = 1,
            })
            tw:Play()
            tw.Completed:Connect(function()
                if uiRefs.NotificationToast then
                    uiRefs.NotificationToast.Visible = false
                end
            end)
        end
    end)
end

function UIController:OnProfileUpdated(profile: Types.PlayerProfile)
    local previousCredits = if currentProfile then currentProfile.credits else profile.credits
    local previousLevel = if currentProfile then currentProfile.level else profile.level
    currentProfile = profile
    if not uiRefs.CreditLabel then return end

    -- Play cash chime and toast if credits increased
    if profile.credits > previousCredits then
        local effectsCtrl = controllers["EffectsController"]
        if effectsCtrl and typeof(effectsCtrl.PlayCreditSound) == "function" then
            effectsCtrl:PlayCreditSound()
        end
        self:ShowToast(string.format("💰 +%d Store Credits received!", profile.credits - previousCredits), 2.5)
    end

    -- Level up celebration
    if profile.level > previousLevel then
        local effectsCtrl = controllers["EffectsController"]
        if effectsCtrl and typeof(effectsCtrl.PlaySound) == "function" then
            effectsCtrl:PlaySound("CashRegister")
        end
        self:ShowToast(string.format("🎉 LEVEL UP! You reached LEVEL %d!", profile.level), 4.0)
    end

    uiRefs.CreditLabel.Text = string.format("💰 %s CREDITS", tostring(profile.credits))
    uiRefs.LevelBadge.Text = string.format("LVL %d", profile.level)

    local requiredXp = Config.Progression.CalculateRequiredXp(profile.level)
    local xpRatio = math.clamp(profile.xp / math.max(1, requiredXp), 0, 1)

    TweenService:Create(uiRefs.XpBarFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Size = UDim2.new(xpRatio, 0, 1, 0)
    }):Play()

    if uiRefs.ShopBalanceLabel then
        uiRefs.ShopBalanceLabel.Text = string.format("Store Wallet: 💰 %d Credits", profile.credits)
    end

    if uiRefs.ShopModal and uiRefs.ShopModal.Visible then
        self:RenderShopItems()
    end
end

function UIController:OnRoundResults(results: Types.RoundResultsData)
    if not uiRefs.ResultsModal then return end

    local effectsCtrl = controllers["EffectsController"]
    if effectsCtrl and typeof(effectsCtrl.PlaySound) == "function" then
        if results.Success then
            effectsCtrl:PlaySound("DisasterCleared")
        else
            effectsCtrl:PlaySound("SlipStumble")
        end
    end

    uiRefs.ResultsModal.Visible = true
    uiRefs.ResultsTitle.Text = results.Success and "🎉 SHIFT SURVIVED!" or "❌ UNDER QUOTA - SHIFT FAILED"
    uiRefs.ResultsTitle.TextColor3 = results.Success and Color3.fromRGB(40, 220, 100) or Color3.fromRGB(240, 60, 60)

    local myStats = results.IndividualStats[player.UserId]
    local myTasks = myStats and myStats.TasksCompleted or 0
    local myCredits = myStats and myStats.CreditsEarned or results.TeamBonusCredits
    local myXp = myStats and myStats.XpEarned or 0

    local mvpName = "None"
    for _, stats in pairs(results.IndividualStats) do
        if stats.IsMvp then
            mvpName = stats.PlayerName
            break
        end
    end

    uiRefs.ResultsDetails.Text = string.format(
        "Shift Performance:\n\n• Team Quota Reached: %d / %d\n• Tasks Completed By You: %d\n• Shift Paycheck: +%d Credits\n• Shift Experience: +%d XP\n\n⭐ EMPLOYEE OF THE SHIFT: %s",
        results.QuotaReached,
        results.QuotaTarget,
        myTasks,
        myCredits,
        myXp,
        mvpName
    )
end

function UIController:RenderShopItems()
    if not uiRefs.ShopItemsScroll or not currentProfile then return end

    -- Clear existing cards
    for _, child in ipairs(uiRefs.ShopItemsScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    -- =========================================================================
    -- 1. ROBUX MONETIZATION CARDS (DevProducts & GamePasses)
    -- =========================================================================
    if Config.Monetization then
        -- Game Passes
        if Config.Monetization.GamePasses then
            for passKey, passDef in pairs(Config.Monetization.GamePasses) do
                local card = Instance.new("Frame")
                card.Name = "PassCard_" .. passKey
                card.BackgroundColor3 = Color3.fromRGB(55, 45, 20)
                card.BorderSizePixel = 0
                card.Parent = uiRefs.ShopItemsScroll

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 10)
                corner.Parent = card

                local stroke = Instance.new("UIStroke")
                stroke.Color = Color3.fromRGB(240, 190, 40)
                stroke.Thickness = 1.5
                stroke.Parent = card

                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, -12, 0, 36)
                title.Position = UDim2.new(0, 6, 0, 6)
                title.BackgroundTransparency = 1
                title.Text = (passDef.Icon or "⚡") .. " " .. passDef.Name
                title.TextColor3 = Color3.fromRGB(255, 220, 80)
                title.Font = Enum.Font.FredokaOne
                title.TextSize = 13
                title.TextWrapped = true
                title.Parent = card

                local priceTag = Instance.new("TextLabel")
                priceTag.Size = UDim2.new(1, -12, 0, 20)
                priceTag.Position = UDim2.new(0, 6, 0, 44)
                priceTag.BackgroundTransparency = 1
                priceTag.Text = string.format("R$ %d (PASS)", passDef.RobuxPrice or 199)
                priceTag.TextColor3 = Color3.fromRGB(130, 240, 150)
                priceTag.Font = Enum.Font.GothamBold
                priceTag.TextSize = 12
                priceTag.Parent = card

                local descLabel = Instance.new("TextLabel")
                descLabel.Size = UDim2.new(1, -12, 0, 46)
                descLabel.Position = UDim2.new(0, 6, 0, 68)
                descLabel.BackgroundTransparency = 1
                descLabel.Text = passDef.Description or "Game pass upgrade"
                descLabel.TextColor3 = Color3.fromRGB(200, 205, 220)
                descLabel.Font = Enum.Font.GothamMedium
                descLabel.TextSize = 10
                descLabel.TextWrapped = true
                descLabel.Parent = card

                local buyBtn = Instance.new("TextButton")
                buyBtn.Size = UDim2.new(1, -16, 0, 32)
                buyBtn.Position = UDim2.new(0, 8, 1, -40)
                buyBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
                buyBtn.Text = "GET PASS"
                buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                buyBtn.Font = Enum.Font.FredokaOne
                buyBtn.TextSize = 12
                buyBtn.Parent = card

                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 8)
                btnCorner.Parent = buyBtn

                buyBtn.Activated:Connect(function()
                    if passDef.PassId and passDef.PassId > 0 then
                        MarketplaceService:PromptGamePassPurchase(player, passDef.PassId)
                    else
                        buyBtn.Text = "READY FOR ID"
                        task.delay(1.5, function()
                            if buyBtn and buyBtn.Parent then buyBtn.Text = "GET PASS" end
                        end)
                    end
                end)
            end
        end

        -- DevProducts (Credits Packs)
        if Config.Monetization.Products then
            for prodKey, prodDef in pairs(Config.Monetization.Products) do
                local card = Instance.new("Frame")
                card.Name = "ProdCard_" .. prodKey
                card.BackgroundColor3 = Color3.fromRGB(30, 45, 55)
                card.BorderSizePixel = 0
                card.Parent = uiRefs.ShopItemsScroll

                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 10)
                corner.Parent = card

                local stroke = Instance.new("UIStroke")
                stroke.Color = Color3.fromRGB(60, 170, 240)
                stroke.Thickness = 1.2
                stroke.Parent = card

                local title = Instance.new("TextLabel")
                title.Size = UDim2.new(1, -12, 0, 36)
                title.Position = UDim2.new(0, 6, 0, 6)
                title.BackgroundTransparency = 1
                title.Text = (prodDef.Icon or "💰") .. " " .. prodDef.Name
                title.TextColor3 = Color3.fromRGB(100, 210, 255)
                title.Font = Enum.Font.FredokaOne
                title.TextSize = 13
                title.TextWrapped = true
                title.Parent = card

                local priceTag = Instance.new("TextLabel")
                priceTag.Size = UDim2.new(1, -12, 0, 20)
                priceTag.Position = UDim2.new(0, 6, 0, 44)
                priceTag.BackgroundTransparency = 1
                priceTag.Text = string.format("R$ %d", prodDef.RobuxPrice or 49)
                priceTag.TextColor3 = Color3.fromRGB(130, 240, 150)
                priceTag.Font = Enum.Font.GothamBold
                priceTag.TextSize = 12
                priceTag.Parent = card

                local descLabel = Instance.new("TextLabel")
                descLabel.Size = UDim2.new(1, -12, 0, 46)
                descLabel.Position = UDim2.new(0, 6, 0, 68)
                descLabel.BackgroundTransparency = 1
                descLabel.Text = prodDef.Description or "Credits pack"
                descLabel.TextColor3 = Color3.fromRGB(200, 205, 220)
                descLabel.Font = Enum.Font.GothamMedium
                descLabel.TextSize = 10
                descLabel.TextWrapped = true
                descLabel.Parent = card

                local buyBtn = Instance.new("TextButton")
                buyBtn.Size = UDim2.new(1, -16, 0, 32)
                buyBtn.Position = UDim2.new(0, 8, 1, -40)
                buyBtn.BackgroundColor3 = Color3.fromRGB(30, 130, 210)
                buyBtn.Text = "BUY PACK"
                buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                buyBtn.Font = Enum.Font.FredokaOne
                buyBtn.TextSize = 12
                buyBtn.Parent = card

                local btnCorner = Instance.new("UICorner")
                btnCorner.CornerRadius = UDim.new(0, 8)
                btnCorner.Parent = buyBtn

                buyBtn.Activated:Connect(function()
                    if prodDef.ProductId and prodDef.ProductId > 0 then
                        MarketplaceService:PromptProductPurchase(player, prodDef.ProductId)
                    else
                        buyBtn.Text = "READY FOR ID"
                        task.delay(1.5, function()
                            if buyBtn and buyBtn.Parent then buyBtn.Text = "BUY PACK" end
                        end)
                    end
                end)
            end
        end
    end

    -- =========================================================================
    -- 2. COSMETIC CATALOG CARDS
    -- =========================================================================
    local ownedMap: { [string]: boolean } = {}
    for _, id in ipairs(currentProfile.ownedCosmetics) do
        ownedMap[id] = true
    end

    for cosmeticId, item in pairs(Config.Cosmetics) do
        local card = Instance.new("Frame")
        card.Name = "Card_" .. cosmeticId
        card.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
        card.BorderSizePixel = 0
        card.Parent = uiRefs.ShopItemsScroll

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = card

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -12, 0, 36)
        title.Position = UDim2.new(0, 6, 0, 6)
        title.BackgroundTransparency = 1
        title.Text = item.Name
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.Font = Enum.Font.FredokaOne
        title.TextSize = 13
        title.TextWrapped = true
        title.Parent = card

        local priceTag = Instance.new("TextLabel")
        priceTag.Size = UDim2.new(1, -12, 0, 20)
        priceTag.Position = UDim2.new(0, 6, 0, 44)
        priceTag.BackgroundTransparency = 1
        priceTag.Text = (item.Price == 0) and "DEFAULT" or string.format("💰 %d C", item.Price)
        priceTag.TextColor3 = Color3.fromRGB(250, 200, 30)
        priceTag.Font = Enum.Font.GothamBold
        priceTag.TextSize = 12
        priceTag.Parent = card

        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, -12, 0, 46)
        descLabel.Position = UDim2.new(0, 6, 0, 68)
        descLabel.BackgroundTransparency = 1
        descLabel.Text = item.Description or ""
        descLabel.TextColor3 = Color3.fromRGB(180, 185, 200)
        descLabel.Font = Enum.Font.GothamMedium
        descLabel.TextSize = 10
        descLabel.TextWrapped = true
        descLabel.Parent = card

        local actionBtn = Instance.new("TextButton")
        actionBtn.Size = UDim2.new(1, -16, 0, 32)
        actionBtn.Position = UDim2.new(0, 8, 1, -40)
        actionBtn.Font = Enum.Font.FredokaOne
        actionBtn.TextSize = 12
        actionBtn.Parent = card

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = actionBtn

        local isEquipped = (currentProfile.equippedCosmetic == cosmeticId) or (currentProfile.equippedHat == cosmeticId)
        local isOwned = ownedMap[cosmeticId] == true

        if isEquipped then
            actionBtn.BackgroundColor3 = Color3.fromRGB(50, 130, 220)
            actionBtn.Text = "EQUIPPED"
            actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            actionBtn.AutoButtonColor = false
        elseif isOwned then
            actionBtn.BackgroundColor3 = Color3.fromRGB(26, 120, 68)
            actionBtn.Text = "EQUIP"
            actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            actionBtn.Activated:Connect(function()
                actionBtn.Text = "..."
                local equipFunc = Network.GetRemoteFunction(Constants.Remotes.REQUEST_EQUIP_COSMETIC)
                local res = equipFunc:InvokeServer(cosmeticId, item.Type)
                if res and not res.Success then
                    actionBtn.Text = res.ErrorCode or "FAILED"
                    actionBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
                    task.delay(2, function()
                        if actionBtn and actionBtn.Parent then
                            actionBtn.Text = "EQUIP"
                            actionBtn.BackgroundColor3 = Color3.fromRGB(26, 120, 68)
                        end
                    end)
                end
            end)
        else
            actionBtn.BackgroundColor3 = Color3.fromRGB(235, 95, 20)
            actionBtn.Text = "PURCHASE"
            actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            actionBtn.Activated:Connect(function()
                actionBtn.Text = "..."
                local purchaseFunc = Network.GetRemoteFunction(Constants.Remotes.REQUEST_PURCHASE_COSMETIC)
                local res = purchaseFunc:InvokeServer(cosmeticId)
                if res and not res.Success then
                    actionBtn.Text = res.ErrorCode or "FAILED"
                    actionBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
                    task.delay(2, function()
                        if actionBtn and actionBtn.Parent then
                            actionBtn.Text = "PURCHASE"
                            actionBtn.BackgroundColor3 = Color3.fromRGB(235, 95, 20)
                        end
                    end)
                end
            end)
        end
    end
end

function UIController:RenderChallenges()
    if not uiRefs.ChallengesList or not currentProfile then return end

    for _, child in ipairs(uiRefs.ChallengesList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    local chData = currentProfile.dailyChallenges

    for _, challenge in ipairs(Config.DailyChallenges) do
        local row = Instance.new("Frame")
        row.Name = "Challenge_" .. challenge.Id
        row.Size = UDim2.new(1, 0, 0, 68)
        row.BackgroundColor3 = Color3.fromRGB(32, 36, 48)
        row.BorderSizePixel = 0
        row.Parent = uiRefs.ChallengesList

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = row

        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, -120, 0, 24)
        desc.Position = UDim2.new(0, 12, 0, 8)
        desc.BackgroundTransparency = 1
        desc.Text = challenge.Description
        desc.TextColor3 = Color3.fromRGB(255, 255, 255)
        desc.Font = Enum.Font.FredokaOne
        desc.TextSize = 14
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = row

        local currentCount = chData.progress[challenge.Id] or 0
        local isDone = chData.completed[challenge.Id] == true

        local progLabel = Instance.new("TextLabel")
        progLabel.Size = UDim2.new(1, -120, 0, 20)
        progLabel.Position = UDim2.new(0, 12, 0, 36)
        progLabel.BackgroundTransparency = 1
        progLabel.Text = string.format("Progress: %d / %d (%s)", currentCount, challenge.TargetCount, isDone and "CLAIMED" or "IN PROGRESS")
        progLabel.TextColor3 = isDone and Color3.fromRGB(40, 220, 100) or Color3.fromRGB(180, 185, 200)
        progLabel.Font = Enum.Font.GothamMedium
        progLabel.TextSize = 12
        progLabel.TextXAlignment = Enum.TextXAlignment.Left
        progLabel.Parent = row

        local rewardBadge = Instance.new("TextLabel")
        rewardBadge.Size = UDim2.new(0, 95, 0, 36)
        rewardBadge.Position = UDim2.new(1, -105, 0, 16)
        rewardBadge.BackgroundColor3 = isDone and Color3.fromRGB(30, 80, 50) or Color3.fromRGB(235, 95, 20)
        rewardBadge.Text = isDone and "CLAIMED" or string.format("+%d C\n+%d XP", challenge.CreditReward, challenge.XpReward)
        rewardBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
        rewardBadge.Font = Enum.Font.FredokaOne
        rewardBadge.TextSize = 11
        rewardBadge.Parent = row

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 8)
        bCorner.Parent = rewardBadge
    end
end

return UIController
