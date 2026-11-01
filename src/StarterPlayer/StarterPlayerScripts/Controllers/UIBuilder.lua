--!strict
--[[
    PANIC SHIFT: UIBuilder.lua
    Procedural UI builder creating the complete responsive ScreenGui hierarchy.
    Includes Shift HUD, Disaster Alert Banners, Results Modal, Cosmetic Shop,
    Daily Challenges Drawer, and Settings.
]]

local Players = game:GetService("Players")

local UIBuilder = {}

local COLORS = {
    BRAND_GREEN = Color3.fromRGB(26, 120, 68),
    BRAND_ORANGE = Color3.fromRGB(235, 95, 20),
    BRAND_YELLOW = Color3.fromRGB(250, 200, 30),
    DARK_BG = Color3.fromRGB(22, 25, 34),
    CARD_BG = Color3.fromRGB(32, 36, 48),
    CARD_HOVER = Color3.fromRGB(44, 50, 66),
    WHITE = Color3.fromRGB(255, 255, 255),
    GRAY_TEXT = Color3.fromRGB(180, 185, 200),
    DANGER_RED = Color3.fromRGB(235, 50, 50),
    SUCCESS_GREEN = Color3.fromRGB(40, 200, 90),
}

local FONT_BOLD = Enum.Font.FredokaOne
local FONT_REGULAR = Enum.Font.GothamMedium

local function createCorner(parent: Instance, radius: number): UICorner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function createStroke(parent: Instance, color: Color3, thickness: number): UIStroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

function UIBuilder.Build(playerGui: PlayerGui): { [string]: any }
    -- Clear any old GUI
    for _, child in ipairs(playerGui:GetChildren()) do
        if child.Name == "PanicShiftGui" then
            child:Destroy()
        end
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PanicShiftGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    local refs: { [string]: any } = {
        ScreenGui = screenGui,
    }

    -- =========================================================================
    -- 1. TOP CENTER: SHIFT HUD (Timer & Quota Progress)
    -- =========================================================================
    local topCenterFrame = Instance.new("Frame")
    topCenterFrame.Name = "TopCenter_ShiftHeader"
    topCenterFrame.Size = UDim2.new(0, 340, 0, 84)
    topCenterFrame.Position = UDim2.new(0.5, -170, 0, 16)
    topCenterFrame.BackgroundColor3 = COLORS.DARK_BG
    topCenterFrame.BackgroundTransparency = 0.15
    topCenterFrame.BorderSizePixel = 0
    topCenterFrame.Parent = screenGui
    createCorner(topCenterFrame, 14)
    createStroke(topCenterFrame, Color3.fromRGB(50, 55, 75), 1.5)

    local shiftTimerLabel = Instance.new("TextLabel")
    shiftTimerLabel.Name = "ShiftTimerLabel"
    shiftTimerLabel.Size = UDim2.new(0, 100, 0, 34)
    shiftTimerLabel.Position = UDim2.new(0, 12, 0, 6)
    shiftTimerLabel.BackgroundTransparency = 1
    shiftTimerLabel.Text = "03:00"
    shiftTimerLabel.TextColor3 = COLORS.WHITE
    shiftTimerLabel.Font = FONT_BOLD
    shiftTimerLabel.TextSize = 28
    shiftTimerLabel.TextXAlignment = Enum.TextXAlignment.Left
    shiftTimerLabel.Parent = topCenterFrame
    refs.ShiftTimerLabel = shiftTimerLabel

    local shiftStateBadge = Instance.new("TextLabel")
    shiftStateBadge.Name = "ShiftStateBadge"
    shiftStateBadge.Size = UDim2.new(0, 200, 0, 24)
    shiftStateBadge.Position = UDim2.new(1, -212, 0, 10)
    shiftStateBadge.BackgroundColor3 = COLORS.BRAND_GREEN
    shiftStateBadge.Text = "ACTIVE SHIFT"
    shiftStateBadge.TextColor3 = COLORS.WHITE
    shiftStateBadge.Font = FONT_BOLD
    shiftStateBadge.TextSize = 13
    shiftStateBadge.Parent = topCenterFrame
    createCorner(shiftStateBadge, 6)
    refs.ShiftStateBadge = shiftStateBadge

    -- Quota Bar Container
    local quotaContainer = Instance.new("Frame")
    quotaContainer.Name = "QuotaContainer"
    quotaContainer.Size = UDim2.new(1, -24, 0, 28)
    quotaContainer.Position = UDim2.new(0, 12, 1, -38)
    quotaContainer.BackgroundTransparency = 1
    quotaContainer.Parent = topCenterFrame

    local quotaBarBg = Instance.new("Frame")
    quotaBarBg.Name = "QuotaBarBg"
    quotaBarBg.Size = UDim2.new(1, 0, 1, 0)
    quotaBarBg.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
    quotaBarBg.BorderSizePixel = 0
    quotaBarBg.Parent = quotaContainer
    createCorner(quotaBarBg, 8)

    local quotaBarFill = Instance.new("Frame")
    quotaBarFill.Name = "QuotaBarFill"
    quotaBarFill.Size = UDim2.new(0.4, 0, 1, 0)
    quotaBarFill.BackgroundColor3 = COLORS.BRAND_ORANGE
    quotaBarFill.BorderSizePixel = 0
    quotaBarFill.Parent = quotaBarBg
    createCorner(quotaBarFill, 8)
    refs.QuotaBarFill = quotaBarFill

    local quotaLabel = Instance.new("TextLabel")
    quotaLabel.Name = "QuotaLabel"
    quotaLabel.Size = UDim2.new(1, 0, 1, 0)
    quotaLabel.BackgroundTransparency = 1
    quotaLabel.Text = "STORE QUOTA: 10 / 25"
    quotaLabel.TextColor3 = COLORS.WHITE
    quotaLabel.Font = FONT_BOLD
    quotaLabel.TextSize = 14
    quotaLabel.ZIndex = 3
    quotaLabel.Parent = quotaContainer
    refs.QuotaLabel = quotaLabel

    -- Helpful Objective / Guidance Banner
    local guideBanner = Instance.new("Frame")
    guideBanner.Name = "ObjectiveGuideBanner"
    guideBanner.Size = UDim2.new(0, 480, 0, 30)
    guideBanner.Position = UDim2.new(0.5, -240, 0, 108)
    guideBanner.BackgroundColor3 = COLORS.DARK_BG
    guideBanner.BackgroundTransparency = 0.2
    guideBanner.BorderSizePixel = 0
    guideBanner.Parent = screenGui
    createCorner(guideBanner, 8)
    createStroke(guideBanner, Color3.fromRGB(50, 60, 80), 1)
    refs.ObjectiveGuideBanner = guideBanner

    local guideText = Instance.new("TextLabel")
    guideText.Name = "ObjectiveGuideText"
    guideText.Size = UDim2.new(1, -20, 1, 0)
    guideText.Position = UDim2.new(0, 10, 0, 0)
    guideText.BackgroundTransparency = 1
    guideText.Text = "🌟 Head through the glass doors into the store! Follow waypoints to work."
    guideText.TextColor3 = Color3.fromRGB(255, 230, 120)
    guideText.Font = FONT_BOLD
    guideText.TextSize = 13
    guideText.Parent = guideBanner
    refs.ObjectiveGuideText = guideText

    -- =========================================================================
    -- 2. TOP RIGHT: PLAYER WALLET & XP
    -- =========================================================================
    local walletFrame = Instance.new("Frame")
    walletFrame.Name = "TopRight_PlayerWallet"
    walletFrame.Size = UDim2.new(0, 220, 0, 68)
    walletFrame.Position = UDim2.new(1, -236, 0, 16)
    walletFrame.BackgroundColor3 = COLORS.DARK_BG
    walletFrame.BackgroundTransparency = 0.15
    walletFrame.BorderSizePixel = 0
    walletFrame.Parent = screenGui
    createCorner(walletFrame, 12)
    createStroke(walletFrame, Color3.fromRGB(50, 55, 75), 1.5)

    local creditLabel = Instance.new("TextLabel")
    creditLabel.Name = "CreditLabel"
    creditLabel.Size = UDim2.new(1, -70, 0, 28)
    creditLabel.Position = UDim2.new(0, 14, 0, 8)
    creditLabel.BackgroundTransparency = 1
    creditLabel.Text = "💰 0 CREDITS"
    creditLabel.TextColor3 = COLORS.BRAND_YELLOW
    creditLabel.Font = FONT_BOLD
    creditLabel.TextSize = 16
    creditLabel.TextXAlignment = Enum.TextXAlignment.Left
    creditLabel.Parent = walletFrame
    refs.CreditLabel = creditLabel

    local levelBadge = Instance.new("TextLabel")
    levelBadge.Name = "LevelBadge"
    levelBadge.Size = UDim2.new(0, 48, 0, 26)
    levelBadge.Position = UDim2.new(1, -58, 0, 8)
    levelBadge.BackgroundColor3 = COLORS.BRAND_ORANGE
    levelBadge.Text = "LVL 1"
    levelBadge.TextColor3 = COLORS.WHITE
    levelBadge.Font = FONT_BOLD
    levelBadge.TextSize = 13
    levelBadge.Parent = walletFrame
    createCorner(levelBadge, 6)
    refs.LevelBadge = levelBadge

    local xpBarBg = Instance.new("Frame")
    xpBarBg.Name = "XpBarBg"
    xpBarBg.Size = UDim2.new(1, -28, 0, 12)
    xpBarBg.Position = UDim2.new(0, 14, 1, -22)
    xpBarBg.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
    xpBarBg.BorderSizePixel = 0
    xpBarBg.Parent = walletFrame
    createCorner(xpBarBg, 6)

    local xpBarFill = Instance.new("Frame")
    xpBarFill.Name = "XpBarFill"
    xpBarFill.Size = UDim2.new(0.2, 0, 1, 0)
    xpBarFill.BackgroundColor3 = Color3.fromRGB(60, 160, 255)
    xpBarFill.BorderSizePixel = 0
    xpBarFill.Parent = xpBarBg
    createCorner(xpBarFill, 6)
    refs.XpBarFill = xpBarFill

    -- =========================================================================
    -- 3. BOTTOM LEFT: ACTION DRAWER (Shop, Challenges, Settings)
    -- =========================================================================
    local drawerFrame = Instance.new("Frame")
    drawerFrame.Name = "BottomLeft_ActionDrawer"
    drawerFrame.Size = UDim2.new(0, 310, 0, 48)
    drawerFrame.Position = UDim2.new(0, 16, 1, -64)
    drawerFrame.BackgroundTransparency = 1
    drawerFrame.Parent = screenGui

    local function createActionButton(name: string, text: string, xOffset: number, color: Color3): TextButton
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(0, 96, 1, 0)
        btn.Position = UDim2.new(0, xOffset, 0, 0)
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = COLORS.WHITE
        btn.Font = FONT_BOLD
        btn.TextSize = 12
        btn.Parent = drawerFrame
        createCorner(btn, 10)
        createStroke(btn, Color3.fromRGB(50, 55, 75), 1)
        return btn
    end

    refs.ShopBtn = createActionButton("ShopBtn", "🛍️ SHOP", 0, COLORS.BRAND_GREEN)
    refs.ChallengesBtn = createActionButton("ChallengesBtn", "📋 QUESTS", 104, Color3.fromRGB(40, 110, 190))
    refs.SettingsBtn = createActionButton("SettingsBtn", "⚙️ CONFIG", 208, Color3.fromRGB(50, 55, 70))

    -- =========================================================================
    -- 4. CENTER: DISASTER ALERT BANNER (Animated Slide Down)
    -- =========================================================================
    local disasterBanner = Instance.new("Frame")
    disasterBanner.Name = "DisasterAlertBanner"
    disasterBanner.Size = UDim2.new(0, 460, 0, 90)
    disasterBanner.Position = UDim2.new(0.5, -230, 0, -110) -- Off-screen above
    disasterBanner.BackgroundColor3 = Color3.fromRGB(35, 15, 20)
    disasterBanner.BorderSizePixel = 0
    disasterBanner.Visible = false
    disasterBanner.Parent = screenGui
    createCorner(disasterBanner, 14)
    createStroke(disasterBanner, COLORS.DANGER_RED, 2.5)
    refs.DisasterBanner = disasterBanner

    local disasterTitle = Instance.new("TextLabel")
    disasterTitle.Name = "DisasterTitle"
    disasterTitle.Size = UDim2.new(1, -24, 0, 36)
    disasterTitle.Position = UDim2.new(0, 12, 0, 8)
    disasterTitle.BackgroundTransparency = 1
    disasterTitle.Text = "⚠️ DISASTER WARNING!"
    disasterTitle.TextColor3 = COLORS.BRAND_YELLOW
    disasterTitle.Font = FONT_BOLD
    disasterTitle.TextSize = 22
    disasterTitle.Parent = disasterBanner
    refs.DisasterTitle = disasterTitle

    local disasterSubtitle = Instance.new("TextLabel")
    disasterSubtitle.Name = "DisasterSubtitle"
    disasterSubtitle.Size = UDim2.new(1, -24, 0, 32)
    disasterSubtitle.Position = UDim2.new(0, 12, 0, 46)
    disasterSubtitle.BackgroundTransparency = 1
    disasterSubtitle.Text = "Rogue carts detected! Seek safe aisles immediately!"
    disasterSubtitle.TextColor3 = COLORS.WHITE
    disasterSubtitle.Font = FONT_REGULAR
    disasterSubtitle.TextSize = 14
    disasterSubtitle.Parent = disasterBanner
    refs.DisasterSubtitle = disasterSubtitle

    -- =========================================================================
    -- 5. CENTER: RESULTS MODAL (End of Shift Paycheck)
    -- =========================================================================
    local resultsModal = Instance.new("Frame")
    resultsModal.Name = "ResultsModal"
    resultsModal.Size = UDim2.new(0, 480, 0, 360)
    resultsModal.Position = UDim2.new(0.5, -240, 0.5, -180)
    resultsModal.BackgroundColor3 = COLORS.DARK_BG
    resultsModal.BorderSizePixel = 0
    resultsModal.Visible = false
    resultsModal.ZIndex = 10
    resultsModal.Parent = screenGui
    createCorner(resultsModal, 16)
    createStroke(resultsModal, COLORS.BRAND_ORANGE, 2.5)
    refs.ResultsModal = resultsModal

    local resultsTitle = Instance.new("TextLabel")
    resultsTitle.Name = "ResultsTitle"
    resultsTitle.Size = UDim2.new(1, -30, 0, 50)
    resultsTitle.Position = UDim2.new(0, 15, 0, 15)
    resultsTitle.BackgroundTransparency = 1
    resultsTitle.Text = "🎉 SHIFT SURVIVED!"
    resultsTitle.TextColor3 = COLORS.BRAND_YELLOW
    resultsTitle.Font = FONT_BOLD
    resultsTitle.TextSize = 30
    resultsTitle.ZIndex = 11
    resultsTitle.Parent = resultsModal
    refs.ResultsTitle = resultsTitle

    local resultsDetails = Instance.new("TextLabel")
    resultsDetails.Name = "ResultsDetails"
    resultsDetails.Size = UDim2.new(1, -40, 0, 190)
    resultsDetails.Position = UDim2.new(0, 20, 0, 75)
    resultsDetails.BackgroundColor3 = COLORS.CARD_BG
    resultsDetails.Text = "Paycheck Summary:\n\n• Team Quota Reached: 25 / 25\n• Base Shift Pay: +50 Credits\n• MVP Bonus: +25 Credits\n• Shift XP Earned: +60 XP\n\n⭐ EMPLOYEE OF THE SHIFT: Astrameld"
    resultsDetails.TextColor3 = COLORS.WHITE
    resultsDetails.Font = FONT_REGULAR
    resultsDetails.TextSize = 16
    resultsDetails.ZIndex = 11
    resultsDetails.Parent = resultsModal
    createCorner(resultsDetails, 12)
    refs.ResultsDetails = resultsDetails

    local resultsCloseBtn = Instance.new("TextButton")
    resultsCloseBtn.Name = "ResultsCloseBtn"
    resultsCloseBtn.Size = UDim2.new(0, 220, 0, 46)
    resultsCloseBtn.Position = UDim2.new(0.5, -110, 1, -62)
    resultsCloseBtn.BackgroundColor3 = COLORS.BRAND_GREEN
    resultsCloseBtn.Text = "CONTINUE TO BREAKROOM"
    resultsCloseBtn.TextColor3 = COLORS.WHITE
    resultsCloseBtn.Font = FONT_BOLD
    resultsCloseBtn.TextSize = 14
    resultsCloseBtn.ZIndex = 11
    resultsCloseBtn.Parent = resultsModal
    createCorner(resultsCloseBtn, 10)
    refs.ResultsCloseBtn = resultsCloseBtn

    -- =========================================================================
    -- 6. CENTER: COSMETIC SHOP MODAL
    -- =========================================================================
    local shopModal = Instance.new("Frame")
    shopModal.Name = "ShopModal"
    shopModal.Size = UDim2.new(0, 560, 0, 420)
    shopModal.Position = UDim2.new(0.5, -280, 0.5, -210)
    shopModal.BackgroundColor3 = COLORS.DARK_BG
    shopModal.BorderSizePixel = 0
    shopModal.Visible = false
    shopModal.ZIndex = 15
    shopModal.Parent = screenGui
    createCorner(shopModal, 16)
    createStroke(shopModal, COLORS.BRAND_GREEN, 2.5)
    refs.ShopModal = shopModal

    local shopTitle = Instance.new("TextLabel")
    shopTitle.Name = "ShopTitle"
    shopTitle.Size = UDim2.new(1, -80, 0, 45)
    shopTitle.Position = UDim2.new(0, 20, 0, 12)
    shopTitle.BackgroundTransparency = 1
    shopTitle.Text = "🛍️ PANIC SHIFT APPAREL & GEAR"
    shopTitle.TextColor3 = COLORS.WHITE
    shopTitle.Font = FONT_BOLD
    shopTitle.TextSize = 20
    shopTitle.TextXAlignment = Enum.TextXAlignment.Left
    shopTitle.ZIndex = 16
    shopTitle.Parent = shopModal

    local shopCloseBtn = Instance.new("TextButton")
    shopCloseBtn.Name = "ShopCloseBtn"
    shopCloseBtn.Size = UDim2.new(0, 36, 0, 36)
    shopCloseBtn.Position = UDim2.new(1, -48, 0, 14)
    shopCloseBtn.BackgroundColor3 = COLORS.CARD_BG
    shopCloseBtn.Text = "✕"
    shopCloseBtn.TextColor3 = COLORS.WHITE
    shopCloseBtn.Font = FONT_BOLD
    shopCloseBtn.TextSize = 18
    shopCloseBtn.ZIndex = 16
    shopCloseBtn.Parent = shopModal
    createCorner(shopCloseBtn, 8)
    refs.ShopCloseBtn = shopCloseBtn

    local shopBalanceLabel = Instance.new("TextLabel")
    shopBalanceLabel.Name = "ShopBalanceLabel"
    shopBalanceLabel.Size = UDim2.new(1, -40, 0, 25)
    shopBalanceLabel.Position = UDim2.new(0, 20, 0, 55)
    shopBalanceLabel.BackgroundTransparency = 1
    shopBalanceLabel.Text = "Store Wallet: 💰 0 Credits"
    shopBalanceLabel.TextColor3 = COLORS.BRAND_YELLOW
    shopBalanceLabel.Font = FONT_BOLD
    shopBalanceLabel.TextSize = 14
    shopBalanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    shopBalanceLabel.ZIndex = 16
    shopBalanceLabel.Parent = shopModal
    refs.ShopBalanceLabel = shopBalanceLabel

    local shopScroll = Instance.new("ScrollingFrame")
    shopScroll.Name = "ShopItemsScroll"
    shopScroll.Size = UDim2.new(1, -40, 1, -100)
    shopScroll.Position = UDim2.new(0, 20, 0, 85)
    shopScroll.BackgroundColor3 = COLORS.CARD_BG
    shopScroll.BorderSizePixel = 0
    shopScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    shopScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    shopScroll.ScrollBarThickness = 6
    shopScroll.ZIndex = 16
    shopScroll.Parent = shopModal
    createCorner(shopScroll, 12)
    refs.ShopItemsScroll = shopScroll

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 158, 0, 175)
    gridLayout.CellPadding = UDim2.new(0, 12, 0, 12)
    gridLayout.Parent = shopScroll

    local gridPadding = Instance.new("UIPadding")
    gridPadding.PaddingTop = UDim.new(0, 12)
    gridPadding.PaddingLeft = UDim.new(0, 12)
    gridPadding.PaddingRight = UDim.new(0, 12)
    gridPadding.Parent = shopScroll

    -- =========================================================================
    -- 7. CENTER: DAILY CHALLENGES MODAL
    -- =========================================================================
    local challengesModal = Instance.new("Frame")
    challengesModal.Name = "ChallengesModal"
    challengesModal.Size = UDim2.new(0, 480, 0, 360)
    challengesModal.Position = UDim2.new(0.5, -240, 0.5, -180)
    challengesModal.BackgroundColor3 = COLORS.DARK_BG
    challengesModal.BorderSizePixel = 0
    challengesModal.Visible = false
    challengesModal.ZIndex = 15
    challengesModal.Parent = screenGui
    createCorner(challengesModal, 16)
    createStroke(challengesModal, Color3.fromRGB(40, 110, 190), 2.5)
    refs.ChallengesModal = challengesModal

    local chTitle = Instance.new("TextLabel")
    chTitle.Name = "ChallengesTitle"
    chTitle.Size = UDim2.new(1, -70, 0, 45)
    chTitle.Position = UDim2.new(0, 20, 0, 12)
    chTitle.BackgroundTransparency = 1
    chTitle.Text = "📋 DAILY SHIFT OBJECTIVES"
    chTitle.TextColor3 = COLORS.WHITE
    chTitle.Font = FONT_BOLD
    chTitle.TextSize = 20
    chTitle.TextXAlignment = Enum.TextXAlignment.Left
    chTitle.ZIndex = 16
    chTitle.Parent = challengesModal

    local chCloseBtn = Instance.new("TextButton")
    chCloseBtn.Name = "ChallengesCloseBtn"
    chCloseBtn.Size = UDim2.new(0, 36, 0, 36)
    chCloseBtn.Position = UDim2.new(1, -48, 0, 14)
    chCloseBtn.BackgroundColor3 = COLORS.CARD_BG
    chCloseBtn.Text = "✕"
    chCloseBtn.TextColor3 = COLORS.WHITE
    chCloseBtn.Font = FONT_BOLD
    chCloseBtn.TextSize = 18
    chCloseBtn.ZIndex = 16
    chCloseBtn.Parent = challengesModal
    createCorner(chCloseBtn, 8)
    refs.ChallengesCloseBtn = chCloseBtn

    local chList = Instance.new("Frame")
    chList.Name = "ChallengesList"
    chList.Size = UDim2.new(1, -40, 1, -80)
    chList.Position = UDim2.new(0, 20, 0, 65)
    chList.BackgroundTransparency = 1
    chList.ZIndex = 16
    chList.Parent = challengesModal
    refs.ChallengesList = chList

    local chLayout = Instance.new("UIListLayout")
    chLayout.Padding = UDim.new(0, 12)
    chLayout.Parent = chList

    -- =========================================================================
    -- 8. CENTER: SETTINGS MODAL
    -- =========================================================================
    local settingsModal = Instance.new("Frame")
    settingsModal.Name = "SettingsModal"
    settingsModal.Size = UDim2.new(0, 420, 0, 300)
    settingsModal.Position = UDim2.new(0.5, -210, 0.5, -150)
    settingsModal.BackgroundColor3 = COLORS.DARK_BG
    settingsModal.BorderSizePixel = 0
    settingsModal.Visible = false
    settingsModal.ZIndex = 15
    settingsModal.Parent = screenGui
    createCorner(settingsModal, 16)
    createStroke(settingsModal, Color3.fromRGB(70, 75, 95), 2.5)
    refs.SettingsModal = settingsModal

    local stTitle = Instance.new("TextLabel")
    stTitle.Name = "SettingsTitle"
    stTitle.Size = UDim2.new(1, -70, 0, 45)
    stTitle.Position = UDim2.new(0, 20, 0, 12)
    stTitle.BackgroundTransparency = 1
    stTitle.Text = "⚙️ GAME SETTINGS"
    stTitle.TextColor3 = COLORS.WHITE
    stTitle.Font = FONT_BOLD
    stTitle.TextSize = 20
    stTitle.TextXAlignment = Enum.TextXAlignment.Left
    stTitle.ZIndex = 16
    stTitle.Parent = settingsModal

    local stCloseBtn = Instance.new("TextButton")
    stCloseBtn.Name = "SettingsCloseBtn"
    stCloseBtn.Size = UDim2.new(0, 36, 0, 36)
    stCloseBtn.Position = UDim2.new(1, -48, 0, 14)
    stCloseBtn.BackgroundColor3 = COLORS.CARD_BG
    stCloseBtn.Text = "✕"
    stCloseBtn.TextColor3 = COLORS.WHITE
    stCloseBtn.Font = FONT_BOLD
    stCloseBtn.TextSize = 18
    stCloseBtn.ZIndex = 16
    stCloseBtn.Parent = settingsModal
    createCorner(stCloseBtn, 8)
    refs.SettingsCloseBtn = stCloseBtn

    local shakeToggleBtn = Instance.new("TextButton")
    shakeToggleBtn.Name = "ShakeToggleBtn"
    shakeToggleBtn.Size = UDim2.new(1, -40, 0, 46)
    shakeToggleBtn.Position = UDim2.new(0, 20, 0, 80)
    shakeToggleBtn.BackgroundColor3 = COLORS.CARD_BG
    shakeToggleBtn.Text = "📳 Screen Shake: ENABLED"
    shakeToggleBtn.TextColor3 = COLORS.WHITE
    shakeToggleBtn.Font = FONT_BOLD
    shakeToggleBtn.TextSize = 14
    shakeToggleBtn.ZIndex = 16
    shakeToggleBtn.Parent = settingsModal
    createCorner(shakeToggleBtn, 10)
    refs.ShakeToggleBtn = shakeToggleBtn

    -- =========================================================================
    -- 9. NOTIFICATION TOAST POPUP
    -- =========================================================================
    local toast = Instance.new("Frame")
    toast.Name = "NotificationToast"
    toast.Size = UDim2.new(0, 380, 0, 50)
    toast.Position = UDim2.new(0.5, -190, 1, -100)
    toast.BackgroundColor3 = Color3.fromRGB(20, 26, 38)
    toast.BorderSizePixel = 0
    toast.Visible = false
    toast.ZIndex = 25
    toast.Parent = screenGui
    createCorner(toast, 12)
    createStroke(toast, Color3.fromRGB(250, 200, 40), 2)
    refs.NotificationToast = toast

    local toastLabel = Instance.new("TextLabel")
    toastLabel.Name = "ToastLabel"
    toastLabel.Size = UDim2.new(1, -20, 1, 0)
    toastLabel.Position = UDim2.new(0, 10, 0, 0)
    toastLabel.BackgroundTransparency = 1
    toastLabel.Text = "Notification"
    toastLabel.TextColor3 = COLORS.WHITE
    toastLabel.Font = FONT_BOLD
    toastLabel.TextSize = 14
    toastLabel.ZIndex = 26
    toastLabel.Parent = toast
    refs.ToastLabel = toastLabel

    return refs
end

return UIBuilder
