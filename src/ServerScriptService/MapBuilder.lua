--!strict
--[[
    PANIC SHIFT: MapBuilder.lua
    High-fidelity procedural builder for the PANIC SHIFT supermarket.
    Creates a bright, modern, polished retail store:
    - Clean tiled floor with subtle reflection
    - High-contrast hanging aisle category signage
    - Real stocked shelves (cereal boxes, cans, bottles, produce crates)
    - 3 Checkout lanes with conveyor belts, scanners & POS screens
    - Detailed employee breakroom with coffee station, lockers & table
    - Warehouse stockroom with heavy pallet racking and restock crates
    - Warm retail lighting with balanced bloom and shadows
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local MapBuilder = {}

-- Color Palette
local PALETTE = {
    -- Supermarket branding
    BRAND_TEAL = Color3.fromRGB(15, 110, 100),
    BRAND_GOLD = Color3.fromRGB(240, 185, 40),
    BRAND_ORANGE = Color3.fromRGB(235, 95, 30),
    BRAND_RED = Color3.fromRGB(215, 45, 45),
    BRAND_NAVY = Color3.fromRGB(18, 30, 48),
    BRAND_BLUE = Color3.fromRGB(35, 120, 220),

    -- Floor & Walls
    FLOOR_BASE = Color3.fromRGB(228, 230, 235),
    FLOOR_GROUT = Color3.fromRGB(195, 198, 205),
    FLOOR_ACCENT = Color3.fromRGB(45, 55, 70),
    FLOOR_WOOD = Color3.fromRGB(140, 95, 60),
    FLOOR_CONCRETE = Color3.fromRGB(105, 110, 118),
    WALL_INTERIOR = Color3.fromRGB(242, 244, 248),
    WALL_TRIM = Color3.fromRGB(20, 95, 85),
    CEILING_TILE = Color3.fromRGB(225, 228, 232),
    CEILING_GRID = Color3.fromRGB(80, 85, 95),

    -- Fixtures
    SHELF_FRAME = Color3.fromRGB(210, 215, 222),
    SHELF_RAIL = Color3.fromRGB(20, 105, 90),
    COUNTER_BASE = Color3.fromRGB(48, 55, 68),
    CONVEYOR = Color3.fromRGB(28, 30, 35),
    SCANNER_GLASS = Color3.fromRGB(255, 40, 40),
    METAL_CHROME = Color3.fromRGB(190, 195, 205),
    GLASS_CLEAR = Color3.fromRGB(215, 238, 255),
    WOOD_CRATE = Color3.fromRGB(180, 130, 80),
    CARDBOARD = Color3.fromRGB(195, 155, 105),

    -- Products
    PROD_RED = Color3.fromRGB(220, 50, 40),
    PROD_BLUE = Color3.fromRGB(40, 120, 220),
    PROD_YELLOW = Color3.fromRGB(250, 200, 30),
    PROD_GREEN = Color3.fromRGB(50, 170, 75),
    PROD_PURPLE = Color3.fromRGB(140, 60, 200),
    PROD_WHITE = Color3.fromRGB(245, 245, 250),
}

local function createPart(
    parent: Instance,
    name: string,
    size: Vector3,
    cframe: CFrame,
    color: Color3,
    material: Enum.Material,
    anchored: boolean?,
    canCollide: boolean?
): Part
    if color == nil then
        error(string.format("[createPart] color is nil for part: '%s' under parent '%s'", name, parent.Name))
    end
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Color = color
    part.Material = material
    part.Anchored = if anchored ~= nil then anchored else true
    part.CanCollide = if canCollide ~= nil then canCollide else true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

-- Creates high-contrast, professional double-sided hanging signs
local function createHangingSign(
    parent: Instance,
    text: string,
    cframe: CFrame,
    size: Vector3,
    accentColor: Color3
): Part
    local board = createPart(parent, "Sign_" .. text, size, cframe, PALETTE.BRAND_NAVY, Enum.Material.SmoothPlastic)

    -- Hanging wire rods from ceiling
    local rod1 = createPart(board, "RodL", Vector3.new(0.15, 4, 0.15), cframe * CFrame.new(-size.X * 0.35, 2.5, 0), PALETTE.METAL_CHROME, Enum.Material.Metal)
    local rod2 = createPart(board, "RodR", Vector3.new(0.15, 4, 0.15), cframe * CFrame.new(size.X * 0.35, 2.5, 0), PALETTE.METAL_CHROME, Enum.Material.Metal)

    -- Accent trim bar at bottom of sign
    createPart(board, "AccentTrim", Vector3.new(size.X, 0.3, size.Z + 0.05), cframe * CFrame.new(0, -size.Y * 0.5 + 0.15, 0), accentColor, Enum.Material.SmoothPlastic)

    for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
        local gui = Instance.new("SurfaceGui")
        gui.Name = "SignDisplay_" .. tostring(face)
        gui.Face = face
        gui.CanvasSize = Vector2.new(900, 130)
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.LightInfluence = 0.0
        gui.Brightness = 1.0
        gui.Parent = board

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = PALETTE.BRAND_NAVY
        frame.BorderSizePixel = 0
        frame.Parent = gui

        local border = Instance.new("UIStroke")
        border.Color = accentColor
        border.Thickness = 4
        border.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -30, 1, -16)
        label.Position = UDim2.new(0, 15, 0, 8)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextScaled = true
        label.Font = Enum.Font.FredokaOne
        label.ZIndex = 5
        label.Parent = frame
    end

    return board
end

-- Atmospheric supermarket lighting configuration
function MapBuilder.ConfigureLighting()
    pcall(function()
        Lighting.Technology = Enum.Technology.Future
    end)
    Lighting.Brightness = 1.6
    Lighting.ClockTime = 13.5
    Lighting.GlobalShadows = true
    Lighting.Ambient = Color3.fromRGB(110, 115, 125)
    Lighting.OutdoorAmbient = Color3.fromRGB(130, 135, 145)
    Lighting.ExposureCompensation = 0.05

    -- Cheerful daytime atmosphere
    local atmosphere = Lighting:FindFirstChild("PanicShiftAtmosphere") :: Atmosphere?
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Name = "PanicShiftAtmosphere"
        atmosphere.Parent = Lighting
    end
    atmosphere.Density = 0.28
    atmosphere.Offset = 0.15
    atmosphere.Color = Color3.fromRGB(195, 215, 245)
    atmosphere.Decay = Color3.fromRGB(120, 135, 160)
    atmosphere.Glare = 0.25
    atmosphere.Haze = 0.9

    -- Color correction for saturated, welcoming retail atmosphere
    local cc = Lighting:FindFirstChild("PanicShiftColorCorrection") :: ColorCorrectionEffect?
    if not cc then
        cc = Instance.new("ColorCorrectionEffect")
        cc.Name = "PanicShiftColorCorrection"
        cc.Parent = Lighting
    end
    cc.Brightness = 0.02
    cc.Contrast = 0.08
    cc.Saturation = 0.16

    -- Controlled, subtle bloom
    local bloom = Lighting:FindFirstChild("PanicShiftBloom") :: BloomEffect?
    if not bloom then
        bloom = Instance.new("BloomEffect")
        bloom.Name = "PanicShiftBloom"
        bloom.Parent = Lighting
    end
    bloom.Intensity = 0.22
    bloom.Size = 10
    bloom.Threshold = 0.92
end

function MapBuilder.Build(): Model
    local existing = Workspace:FindFirstChild("SupermarketMap")
    if existing then
        existing:Destroy()
    end

    MapBuilder.ConfigureLighting()

    local map = Instance.new("Model")
    map.Name = "SupermarketMap"
    map.Parent = Workspace

    local architectureFolder = Instance.new("Folder")
    architectureFolder.Name = "Architecture"
    architectureFolder.Parent = map

    local storeFloorFolder = Instance.new("Folder")
    storeFloorFolder.Name = "StoreFloor"
    storeFloorFolder.Parent = map

    local lobbyFolder = Instance.new("Folder")
    lobbyFolder.Name = "Lobby"
    lobbyFolder.Parent = map

    local frontEndFolder = Instance.new("Folder")
    frontEndFolder.Name = "FrontEnd"
    frontEndFolder.Parent = map

    local stockroomFolder = Instance.new("Folder")
    stockroomFolder.Name = "Stockroom"
    stockroomFolder.Parent = map

    local maintenanceFolder = Instance.new("Folder")
    maintenanceFolder.Name = "Maintenance"
    maintenanceFolder.Parent = map

    local taskAnchorsFolder = Instance.new("Folder")
    taskAnchorsFolder.Name = "TaskAnchors"
    taskAnchorsFolder.Parent = map

    print("[MapBuilder] Building polished supermarket floors...")

    -- 1. Main Supermarket Floor (150x110 studs)
    local mainFloor = createPart(
        architectureFolder,
        "Floor_MainStore",
        Vector3.new(150, 2, 110),
        CFrame.new(0, -1, 15),
        PALETTE.FLOOR_BASE,
        Enum.Material.SmoothPlastic
    )
    mainFloor.Reflectance = 0.04

    -- Subtle checkered floor tile borders
    for x = -60, 60, 30 do
        for z = -25, 45, 20 do
            local tile = createPart(
                architectureFolder,
                "FloorTileAccent",
                Vector3.new(10, 0.02, 10),
                CFrame.new(x, 0.01, z),
                PALETTE.FLOOR_GROUT,
                Enum.Material.SmoothPlastic
            )
            tile.Reflectance = 0.05
        end
    end

    -- 2. Breakroom Floor (90x40 studs) - Warm Oak Planks
    createPart(
        lobbyFolder,
        "Floor_Lobby",
        Vector3.new(90, 2, 40),
        CFrame.new(0, -1, -65),
        PALETTE.FLOOR_WOOD,
        Enum.Material.WoodPlanks
    )

    -- 3. Stockroom Floor (150x30 studs) - Sealed Gray Concrete
    createPart(
        stockroomFolder,
        "Floor_Stockroom",
        Vector3.new(150, 2, 30),
        CFrame.new(0, -1, 75),
        PALETTE.FLOOR_CONCRETE,
        Enum.Material.Concrete
    )

    -- 4. Walls and Ceilings
    local CEILING_Y = 22
    local WALL_HEIGHT = 22

    -- Main Store Walls with Teal Accent Stripe
    createPart(architectureFolder, "Wall_Left", Vector3.new(2, WALL_HEIGHT, 110), CFrame.new(-75, WALL_HEIGHT / 2, 15), PALETTE.WALL_INTERIOR, Enum.Material.SmoothPlastic)
    createPart(architectureFolder, "Stripe_Left", Vector3.new(0.2, 3, 110), CFrame.new(-73.9, 15, 15), PALETTE.BRAND_TEAL, Enum.Material.SmoothPlastic)

    createPart(architectureFolder, "Wall_Right", Vector3.new(2, WALL_HEIGHT, 110), CFrame.new(75, WALL_HEIGHT / 2, 15), PALETTE.WALL_INTERIOR, Enum.Material.SmoothPlastic)
    createPart(architectureFolder, "Stripe_Right", Vector3.new(0.2, 3, 110), CFrame.new(73.9, 15, 15), PALETTE.BRAND_ORANGE, Enum.Material.SmoothPlastic)

    -- Fully Enclosed Stockroom Walls
    createPart(stockroomFolder, "Wall_StockRear", Vector3.new(152, WALL_HEIGHT, 2), CFrame.new(0, WALL_HEIGHT / 2, 90), PALETTE.FLOOR_CONCRETE, Enum.Material.Concrete)
    createPart(stockroomFolder, "Wall_StockLeft", Vector3.new(2, WALL_HEIGHT, 30), CFrame.new(-75, WALL_HEIGHT / 2, 75), PALETTE.FLOOR_CONCRETE, Enum.Material.Concrete)
    createPart(stockroomFolder, "Wall_StockRight", Vector3.new(2, WALL_HEIGHT, 30), CFrame.new(75, WALL_HEIGHT / 2, 75), PALETTE.FLOOR_CONCRETE, Enum.Material.Concrete)

    -- Stockroom Partition Wall with Wide Central Doorway
    createPart(stockroomFolder, "StockWall_L", Vector3.new(60, WALL_HEIGHT, 2), CFrame.new(-45, WALL_HEIGHT / 2, 60), PALETTE.WALL_INTERIOR, Enum.Material.SmoothPlastic)
    createPart(stockroomFolder, "StockWall_R", Vector3.new(60, WALL_HEIGHT, 2), CFrame.new(45, WALL_HEIGHT / 2, 60), PALETTE.WALL_INTERIOR, Enum.Material.SmoothPlastic)
    createPart(stockroomFolder, "StockDoor_Lintel", Vector3.new(30, 8, 2), CFrame.new(0, 18, 60), PALETTE.WALL_INTERIOR, Enum.Material.SmoothPlastic)
    createHangingSign(stockroomFolder, "STOCKROOM (EMPLOYEES ONLY)", CFrame.new(0, 13, 58.8), Vector3.new(22, 2.5, 0.4), PALETTE.BRAND_ORANGE)

    -- Fully Enclosed Breakroom Walls
    createPart(lobbyFolder, "Lobby_Wall_Rear", Vector3.new(92, WALL_HEIGHT, 2), CFrame.new(0, WALL_HEIGHT / 2, -85), PALETTE.WALL_INTERIOR, Enum.Material.SmoothPlastic)
    createPart(lobbyFolder, "Lobby_Wall_Left", Vector3.new(2, WALL_HEIGHT, 44), CFrame.new(-45, WALL_HEIGHT / 2, -63), PALETTE.WALL_INTERIOR, Enum.Material.SmoothPlastic)
    createPart(lobbyFolder, "Lobby_Wall_Right", Vector3.new(2, WALL_HEIGHT, 44), CFrame.new(45, WALL_HEIGHT / 2, -63), PALETTE.WALL_INTERIOR, Enum.Material.SmoothPlastic)

    -- Breakroom Decorative Accent Stripes
    createPart(lobbyFolder, "Lobby_Trim_Rear", Vector3.new(90, 1.2, 0.2), CFrame.new(0, 12, -83.9), PALETTE.BRAND_TEAL, Enum.Material.SmoothPlastic)
    createPart(lobbyFolder, "Lobby_Trim_Left", Vector3.new(0.2, 1.2, 42), CFrame.new(-43.9, 12, -63), PALETTE.BRAND_TEAL, Enum.Material.SmoothPlastic)
    createPart(lobbyFolder, "Lobby_Trim_Right", Vector3.new(0.2, 1.2, 42), CFrame.new(43.9, 12, -63), PALETTE.BRAND_TEAL, Enum.Material.SmoothPlastic)

    -- Front Glass Wall & Sliding Doors to Breakroom Lobby at Z = -40
    createPart(architectureFolder, "FrontWall_L", Vector3.new(32, WALL_HEIGHT, 2), CFrame.new(-44, WALL_HEIGHT / 2, -40), PALETTE.WALL_INTERIOR, Enum.Material.SmoothPlastic)
    createPart(architectureFolder, "FrontWall_R", Vector3.new(32, WALL_HEIGHT, 2), CFrame.new(44, WALL_HEIGHT / 2, -40), PALETTE.WALL_INTERIOR, Enum.Material.SmoothPlastic)
    createPart(architectureFolder, "FrontDoor_Lintel", Vector3.new(28, 8, 2), CFrame.new(0, 18, -40), PALETTE.WALL_INTERIOR, Enum.Material.SmoothPlastic)

    -- Wide sliding glass doors (CanCollide = false so players can walk freely!)
    local doorL = createPart(architectureFolder, "SlidingDoor_L", Vector3.new(12, 13.5, 0.3), CFrame.new(-7, 6.8, -40), PALETTE.GLASS_CLEAR, Enum.Material.Glass, true, false)
    doorL.Transparency = 0.65
    local doorR = createPart(architectureFolder, "SlidingDoor_R", Vector3.new(12, 13.5, 0.3), CFrame.new(7, 6.8, -40), PALETTE.GLASS_CLEAR, Enum.Material.Glass, true, false)
    doorR.Transparency = 0.65

    createHangingSign(architectureFolder, "SALES FLOOR & AISLES", CFrame.new(0, 13, -39.2), Vector3.new(22, 2.4, 0.3), PALETTE.BRAND_TEAL)
    createHangingSign(architectureFolder, "EMPLOYEE BREAKROOM", CFrame.new(0, 13, -40.8), Vector3.new(22, 2.4, 0.3), PALETTE.BRAND_ORANGE)

    -- Light Acoustic Tile Ceiling
    createPart(architectureFolder, "Ceiling_Main", Vector3.new(150, 1, 110), CFrame.new(0, CEILING_Y, 15), PALETTE.CEILING_TILE, Enum.Material.SmoothPlastic)
    createPart(stockroomFolder, "Ceiling_Stockroom", Vector3.new(150, 1, 30), CFrame.new(0, CEILING_Y, 75), PALETTE.FLOOR_CONCRETE, Enum.Material.Metal)
    createPart(lobbyFolder, "Ceiling_Lobby", Vector3.new(90, 1, 44), CFrame.new(0, CEILING_Y, -63), PALETTE.CEILING_TILE, Enum.Material.SmoothPlastic)

    -- Breakroom Overhead Warm Lights
    for bx = -25, 25, 25 do
        for bz = -75, -55, 20 do
            local bFixture = createPart(lobbyFolder, "LobbyLightFix", Vector3.new(8, 0.4, 3), CFrame.new(bx, CEILING_Y - 0.4, bz), PALETTE.CEILING_GRID, Enum.Material.Metal)
            local bTube = createPart(bFixture, "Diffuser", Vector3.new(7.4, 0.2, 2.4), CFrame.new(bx, CEILING_Y - 0.6, bz), Color3.fromRGB(255, 245, 220), Enum.Material.Neon)
            local bLight = Instance.new("PointLight")
            bLight.Name = "LobbyWarmLight"
            bLight.Brightness = 1.3
            bLight.Range = 26
            bLight.Color = Color3.fromRGB(255, 235, 210)
            bLight.Shadows = true
            bLight.Parent = bTube
        end
    end

    -- Fluorescent Ceiling Troffers with Warm Soft Light
    print("[MapBuilder] Mounting overhead ceiling troffer lights...")
    for x = -45, 45, 30 do
        for z = -20, 40, 20 do
            local fixture = createPart(architectureFolder, "TrofferFixture", Vector3.new(10, 0.4, 2.5), CFrame.new(x, CEILING_Y - 0.4, z), PALETTE.CEILING_GRID, Enum.Material.Metal)
            local tube = createPart(fixture, "Diffuser", Vector3.new(9.4, 0.2, 2.0), CFrame.new(x, CEILING_Y - 0.6, z), Color3.fromRGB(255, 250, 240), Enum.Material.Neon)

            local light = Instance.new("PointLight")
            light.Name = "StoreLight"
            light.Brightness = 1.2
            light.Range = 28
            light.Color = Color3.fromRGB(255, 248, 235)
            light.Shadows = true
            light.Parent = tube
        end
    end

    -- 5. Breakroom Safe Spawns & Furniture
    print("[MapBuilder] Setting up employee breakroom...")
    for i = 1, 12 do
        local xOffset = -33 + ((i - 1) % 6) * 13
        local zOffset = (i <= 6) and -76 or -70

        local spawnPart = Instance.new("SpawnLocation")
        spawnPart.Name = "LobbySpawn_" .. i
        spawnPart.Size = Vector3.new(4, 0.3, 4)
        spawnPart.CFrame = CFrame.new(xOffset, 0.15, zOffset)
        spawnPart.Color = (i % 2 == 0) and PALETTE.BRAND_TEAL or PALETTE.BRAND_ORANGE
        spawnPart.Material = Enum.Material.SmoothPlastic
        spawnPart.Anchored = true
        spawnPart.CanCollide = true
        spawnPart.Neutral = true
        spawnPart.Duration = 0
        spawnPart.Parent = lobbyFolder

        CollectionService:AddTag(spawnPart, "SafeSpawn")
    end

    -- Breakroom Table with Mugs & Donut Box
    local tableTop = createPart(lobbyFolder, "BreakroomTable", Vector3.new(16, 2.8, 6), CFrame.new(0, 1.4, -60), PALETTE.WOOD_CRATE, Enum.Material.Wood)
    createPart(tableTop, "Leg1", Vector3.new(1, 2.8, 1), CFrame.new(-7, 1.4, -60), PALETTE.METAL_CHROME, Enum.Material.Metal)
    createPart(tableTop, "Leg2", Vector3.new(1, 2.8, 1), CFrame.new(7, 1.4, -60), PALETTE.METAL_CHROME, Enum.Material.Metal)

    -- Coffee Mugs on table
    for mx = -4, 4, 4 do
        local mug = createPart(tableTop, "CoffeeMug", Vector3.new(0.8, 1.0, 0.8), CFrame.new(mx, 3.3, -60), PALETTE.PROD_WHITE, Enum.Material.SmoothPlastic)
        mug.Shape = Enum.PartType.Cylinder
        mug.CFrame = mug.CFrame * CFrame.Angles(0, 0, math.rad(90))
    end

    -- Employee Lockers along Left Wall
    local lockerColor = Color3.fromRGB(55, 75, 95)
    for lz = -75, -53, 3.2 do
        local locker = createPart(lobbyFolder, "EmployeeLocker", Vector3.new(2.4, 7.5, 2.8), CFrame.new(-43.5, 3.75, lz), lockerColor, Enum.Material.Metal)
        local handle = createPart(locker, "LockerHandle", Vector3.new(0.2, 0.8, 0.2), CFrame.new(-42.1, 4.0, lz + 0.8), PALETTE.METAL_CHROME, Enum.Material.Metal)
        handle.CanCollide = false
    end

    -- Kitchenette Counter along Right Wall
    local counter = createPart(lobbyFolder, "KitchenCounter", Vector3.new(3.0, 3.2, 20), CFrame.new(43.2, 1.6, -64), PALETTE.COUNTER_BASE, Enum.Material.SmoothPlastic)
    createPart(counter, "CounterTop", Vector3.new(3.2, 0.3, 20.2), CFrame.new(43.2, 3.35, -64), Color3.fromRGB(240, 240, 245), Enum.Material.Marble)
    -- Microwave
    createPart(counter, "Microwave", Vector3.new(1.8, 1.2, 2.4), CFrame.new(43.2, 4.1, -70), Color3.fromRGB(25, 25, 30), Enum.Material.Metal)
    -- Coffee Brewer
    local brewer = createPart(counter, "CoffeeBrewer", Vector3.new(1.4, 1.6, 1.4), CFrame.new(43.2, 4.3, -64), Color3.fromRGB(40, 40, 45), Enum.Material.Metal)
    local pot = createPart(brewer, "CoffeePot", Vector3.new(0.9, 0.9, 0.9), CFrame.new(43.2, 3.9, -63.3), PALETTE.GLASS_CLEAR, Enum.Material.Glass)
    pot.Transparency = 0.5

    -- Motivational Noticeboard on Rear Wall
    local noticeBoard = createPart(lobbyFolder, "EmployeeNoticeboard", Vector3.new(18, 7, 0.3), CFrame.new(0, 7.5, -83.8), Color3.fromRGB(180, 140, 90), Enum.Material.WoodPlanks)
    local boardGui = Instance.new("SurfaceGui")
    boardGui.Name = "NoticeboardGui"
    boardGui.Face = Enum.NormalId.Front
    boardGui.CanvasSize = Vector2.new(900, 350)
    boardGui.Parent = noticeBoard

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0.28, 0)
    header.BackgroundColor3 = PALETTE.BRAND_NAVY
    header.TextColor3 = Color3.fromRGB(255, 255, 255)
    header.Font = Enum.Font.FredokaOne
    header.TextScaled = true
    header.Text = "EMPLOYEE BULLETIN BOARD"
    header.Parent = boardGui

    local bodyText = Instance.new("TextLabel")
    bodyText.Position = UDim2.new(0.04, 0, 0.34, 0)
    bodyText.Size = UDim2.new(0.92, 0, 0.60, 0)
    bodyText.BackgroundTransparency = 1
    bodyText.TextColor3 = Color3.fromRGB(40, 30, 20)
    bodyText.Font = Enum.Font.FredokaOne
    bodyText.TextScaled = true
    bodyText.Text = "SHIFT RULES:\n1. Mop slippery spills with your Store Mop!\n2. Grab Restock Boxes in back to fill shelves!\n3. Return runaway shopping carts to the corral!\n4. Work together to fill the Store Quota!"
    bodyText.Parent = boardGui

    -- 6. Grocery Aisles (Detailed Gondola Shelving & Stocked Items)
    print("[MapBuilder] Stocking supermarket aisles...")
    local aisleData = {
        { Number = 1, Name = "FRESH PRODUCE & BAKERY", X = -45, Color = PALETTE.BRAND_TEAL, Products = { PALETTE.PROD_GREEN, PALETTE.PROD_RED, PALETTE.WOOD_CRATE } },
        { Number = 2, Name = "CANNED SOUPS & PASTA", X = -15, Color = PALETTE.BRAND_RED, Products = { PALETTE.PROD_RED, PALETTE.PROD_BLUE, PALETTE.PROD_YELLOW } },
        { Number = 3, Name = "CEREALS & BREAKFAST", X = 15, Color = PALETTE.BRAND_GOLD, Products = { PALETTE.PROD_YELLOW, PALETTE.PROD_PURPLE, PALETTE.PROD_BLUE } },
        { Number = 4, Name = "CHILLED DAIRY & SODA", X = 45, Color = PALETTE.BRAND_BLUE, Products = { PALETTE.PROD_BLUE, PALETTE.PROD_WHITE, PALETTE.PROD_RED } },
    }

    for _, a in ipairs(aisleData) do
        local aisleModel = Instance.new("Model")
        aisleModel.Name = "Aisle_" .. a.Number
        aisleModel.Parent = storeFloorFolder

        -- Hanging category sign
        createHangingSign(aisleModel, string.format("[%d] %s", a.Number, a.Name), CFrame.new(a.X, 15, 10), Vector3.new(24, 3.0, 0.4), a.Color)

        -- Gondola Backing Board (Height 8.5 studs, Length 48 studs)
        createPart(aisleModel, "GondolaBacking", Vector3.new(0.8, 8.5, 48), CFrame.new(a.X, 4.25, 10), PALETTE.SHELF_FRAME, Enum.Material.SmoothPlastic)

        -- 3 Tiers of Shelves on Left and Right
        for tier = 1, 3 do
            local shelfY = 0.5 + tier * 2.4
            local shelfL = createPart(aisleModel, "Shelf_L_" .. tier, Vector3.new(2.4, 0.3, 46), CFrame.new(a.X - 1.4, shelfY, 10), PALETTE.SHELF_FRAME, Enum.Material.SmoothPlastic)
            local shelfR = createPart(aisleModel, "Shelf_R_" .. tier, Vector3.new(2.4, 0.3, 46), CFrame.new(a.X + 1.4, shelfY, 10), PALETTE.SHELF_FRAME, Enum.Material.SmoothPlastic)

            -- Green price tag rails along the shelf edge
            createPart(shelfL, "PriceRail_L", Vector3.new(0.1, 0.25, 46), CFrame.new(a.X - 2.65, shelfY, 10), PALETTE.SHELF_RAIL, Enum.Material.SmoothPlastic)
            createPart(shelfR, "PriceRail_R", Vector3.new(0.1, 0.25, 46), CFrame.new(a.X + 2.65, shelfY, 10), PALETTE.SHELF_RAIL, Enum.Material.SmoothPlastic)

            -- Stocked grocery products (customized per aisle type)
            for z = -10, 30, 5 do
                local colorL = a.Products[(tier + z) % #a.Products + 1]
                local colorR = a.Products[(tier + z + 1) % #a.Products + 1]

                if a.Number == 1 then
                    -- Fresh Produce Crates & Breads
                    local crateL = createPart(aisleModel, "Crate_L_" .. tier .. "_" .. z, Vector3.new(2.0, 0.8, 2.2), CFrame.new(a.X - 1.4, shelfY + 0.5, z), PALETTE.WOOD_CRATE, Enum.Material.WoodPlanks)
                    createPart(crateL, "Fruit_L", Vector3.new(1.4, 0.6, 1.6), CFrame.new(a.X - 1.4, shelfY + 1.0, z), colorL, Enum.Material.SmoothPlastic)

                    local crateR = createPart(aisleModel, "Crate_R_" .. tier .. "_" .. z, Vector3.new(2.0, 0.8, 2.2), CFrame.new(a.X + 1.4, shelfY + 0.5, z), PALETTE.WOOD_CRATE, Enum.Material.WoodPlanks)
                    createPart(crateR, "Fruit_R", Vector3.new(1.4, 0.6, 1.6), CFrame.new(a.X + 1.4, shelfY + 1.0, z), colorR, Enum.Material.SmoothPlastic)

                elseif a.Number == 2 then
                    -- Canned Soups (Cylinders)
                    local canL = createPart(aisleModel, "Can_L_" .. tier .. "_" .. z, Vector3.new(1.4, 1.2, 1.2), CFrame.new(a.X - 1.4, shelfY + 0.8, z) * CFrame.Angles(0, 0, math.rad(90)), colorL, Enum.Material.SmoothPlastic)
                    canL.Shape = Enum.PartType.Cylinder
                    local canR = createPart(aisleModel, "Can_R_" .. tier .. "_" .. z, Vector3.new(1.4, 1.2, 1.2), CFrame.new(a.X + 1.4, shelfY + 0.8, z) * CFrame.Angles(0, 0, math.rad(90)), colorR, Enum.Material.SmoothPlastic)
                    canR.Shape = Enum.PartType.Cylinder

                elseif a.Number == 3 then
                    -- Realistic Cereal Boxes (Tall, slender boxes)
                    createPart(aisleModel, "Cereal_L_" .. tier .. "_" .. z, Vector3.new(0.6, 2.0, 1.5), CFrame.new(a.X - 1.4, shelfY + 1.1, z), colorL, Enum.Material.SmoothPlastic)
                    createPart(aisleModel, "Cereal_R_" .. tier .. "_" .. z, Vector3.new(0.6, 2.0, 1.5), CFrame.new(a.X + 1.4, shelfY + 1.1, z), colorR, Enum.Material.SmoothPlastic)

                else
                    -- Dairy Cartons & Soda Packs
                    createPart(aisleModel, "Dairy_L_" .. tier .. "_" .. z, Vector3.new(1.4, 1.8, 1.4), CFrame.new(a.X - 1.4, shelfY + 1.0, z), colorL, Enum.Material.SmoothPlastic)
                    createPart(aisleModel, "Dairy_R_" .. tier .. "_" .. z, Vector3.new(1.4, 1.8, 1.4), CFrame.new(a.X + 1.4, shelfY + 1.0, z), colorR, Enum.Material.SmoothPlastic)
                end
            end
        end

        -- Endcap display stands at both ends of the aisle
        for _, endZ in ipairs({ -15, 35 }) do
            local endcap = createPart(aisleModel, "Endcap_Display", Vector3.new(5.5, 7.5, 2.5), CFrame.new(a.X, 3.75, endZ), PALETTE.SHELF_FRAME, Enum.Material.SmoothPlastic)
            createHangingSign(endcap, "⭐ FEATURED SALE ⭐", CFrame.new(a.X, 8.5, endZ + ((endZ < 0) and -1.4 or 1.4)), Vector3.new(6.5, 1.6, 0.3), a.Color)
        end

        if a.Number == 2 then
            CollectionService:AddTag(aisleModel, "AvalancheAisle")
        end
    end

    -- 7. Checkout Lanes (Registers 1 to 3)
    print("[MapBuilder] Assembling checkout counters...")
    for reg = 1, 3 do
        local regX = -35 + (reg - 1) * 35
        local regZ = -28

        local checkoutModel = Instance.new("Model")
        checkoutModel.Name = "Register_" .. reg
        checkoutModel.Parent = frontEndFolder

        -- Dark base counter
        createPart(checkoutModel, "CounterBase", Vector3.new(6.5, 3.2, 14), CFrame.new(regX, 1.6, regZ), PALETTE.COUNTER_BASE, Enum.Material.SmoothPlastic)

        -- Black textured conveyor belt
        createPart(checkoutModel, "ConveyorBelt", Vector3.new(3.2, 0.2, 11), CFrame.new(regX - 1.2, 3.3, regZ), PALETTE.CONVEYOR, Enum.Material.Fabric)

        -- Red laser scanner glass
        local scanner = createPart(checkoutModel, "ScannerGlass", Vector3.new(2.2, 0.1, 2.2), CFrame.new(regX - 1.2, 3.45, regZ + 2), PALETTE.SCANNER_GLASS, Enum.Material.Neon)
        local scannerLight = Instance.new("PointLight")
        scannerLight.Color = Color3.fromRGB(255, 30, 30)
        scannerLight.Brightness = 0.8
        scannerLight.Range = 4
        scannerLight.Parent = scanner

        -- POS Touchscreen Monitor & Stand
        createPart(checkoutModel, "MonitorPole", Vector3.new(0.3, 2.2, 0.3), CFrame.new(regX + 1.8, 4.3, regZ), PALETTE.METAL_CHROME, Enum.Material.Metal)
        local monitor = createPart(checkoutModel, "RegisterScreen", Vector3.new(2.4, 1.8, 0.3), CFrame.new(regX + 1.8, 5.2, regZ), PALETTE.BRAND_NAVY, Enum.Material.SmoothPlastic)

        local screenGui = Instance.new("SurfaceGui")
        screenGui.Face = Enum.NormalId.Back
        screenGui.CanvasSize = Vector2.new(300, 200)
        screenGui.Parent = monitor

        local screenText = Instance.new("TextLabel")
        screenText.Size = UDim2.new(1, 0, 1, 0)
        screenText.BackgroundColor3 = Color3.fromRGB(20, 28, 40)
        screenText.Text = string.format("LANE %d\nREADY TO SCAN", reg)
        screenText.TextColor3 = Color3.fromRGB(60, 240, 120)
        screenText.Font = Enum.Font.FredokaOne
        screenText.TextSize = 28
        screenText.Parent = screenGui

        -- Hanging Lane Number Light (mounted on monitor pole at Y = 7.5)
        local lanePole = createPart(checkoutModel, "LanePole", Vector3.new(0.2, 3.5, 0.2), CFrame.new(regX - 1.2, 5.0, regZ), PALETTE.METAL_CHROME, Enum.Material.Metal)
        local laneSign = createPart(checkoutModel, "LaneSign", Vector3.new(2.4, 1.0, 0.3), CFrame.new(regX - 1.2, 7.0, regZ), PALETTE.BRAND_TEAL, Enum.Material.SmoothPlastic)
        local laneGui = Instance.new("SurfaceGui")
        laneGui.Face = Enum.NormalId.Back
        laneGui.CanvasSize = Vector2.new(240, 100)
        laneGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        laneGui.Parent = laneSign
        local laneLabel = Instance.new("TextLabel")
        laneLabel.Size = UDim2.new(1, 0, 1, 0)
        laneLabel.BackgroundColor3 = PALETTE.BRAND_TEAL
        laneLabel.Text = "LANE " .. reg
        laneLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        laneLabel.Font = Enum.Font.FredokaOne
        laneLabel.TextSize = 24
        laneLabel.ZIndex = 5
        laneLabel.Parent = laneGui

        -- Order Drop Target Anchor
        local dropTarget = createPart(taskAnchorsFolder, "OrderDropTarget_" .. reg, Vector3.new(3.5, 0.4, 3.5), CFrame.new(regX - 1.2, 3.5, regZ - 3), PALETTE.BRAND_GOLD, Enum.Material.Neon)
        dropTarget.Transparency = 0.5
        CollectionService:AddTag(dropTarget, "OrderDropTarget")
        CollectionService:AddTag(dropTarget, "TaskAnchor")
    end

    -- Shopping Cart Return Corrals (Left & Right Front)
    for _, cx in ipairs({ -65, 65 }) do
        local corral = Instance.new("Model")
        corral.Name = "CartCorral_" .. ((cx < 0) and "Left" or "Right")
        corral.Parent = frontEndFolder

        createPart(corral, "Rail_L", Vector3.new(0.6, 2.8, 16), CFrame.new(cx - 3, 1.4, -28), PALETTE.METAL_CHROME, Enum.Material.Metal)
        createPart(corral, "Rail_R", Vector3.new(0.6, 2.8, 16), CFrame.new(cx + 3, 1.4, -28), PALETTE.METAL_CHROME, Enum.Material.Metal)
        createPart(corral, "Rail_Back", Vector3.new(6.6, 2.8, 0.6), CFrame.new(cx, 1.4, -20), PALETTE.METAL_CHROME, Enum.Material.Metal)
        createHangingSign(corral, "CART RETURN", CFrame.new(cx, 6.0, -28), Vector3.new(7.5, 1.8, 0.3), PALETTE.BRAND_ORANGE)

        local cartZone = createPart(corral, "CartDepositZone", Vector3.new(5.5, 0.1, 14), CFrame.new(cx, 0.05, -28), PALETTE.BRAND_GOLD, Enum.Material.Neon)
        cartZone.Transparency = 0.6
        CollectionService:AddTag(cartZone, "CartCorral")
    end

    -- 8. Back Stockroom Pallets & Boxes
    print("[MapBuilder] Setting up stockroom pallets & inventory...")
    for i = 1, 3 do
        local px = -35 + (i - 1) * 35
        local pz = 75

        -- Heavy wooden pallet
        createPart(stockroomFolder, "Pallet_" .. i, Vector3.new(8, 0.8, 8), CFrame.new(px, 0.4, pz), PALETTE.WOOD_CRATE, Enum.Material.WoodPlanks)

        -- Stacked restock crates
        for bx = -2, 2, 2 do
            for bz = -2, 2, 2 do
                local box = createPart(
                    stockroomFolder,
                    "StockBox_" .. i .. "_" .. bx .. "_" .. bz,
                    Vector3.new(1.8, 1.8, 1.8),
                    CFrame.new(px + bx, 1.7, pz + bz),
                    PALETTE.CARDBOARD,
                    Enum.Material.SmoothPlastic
                )
                CollectionService:AddTag(box, "StockBox")
            end
        end

        local restockSource = createPart(taskAnchorsFolder, "RestockSource_" .. i, Vector3.new(7, 0.4, 7), CFrame.new(px, 0.3, pz), PALETTE.BRAND_TEAL, Enum.Material.Neon)
        restockSource.Transparency = 0.6
        CollectionService:AddTag(restockSource, "RestockSource")
        CollectionService:AddTag(restockSource, "TaskAnchor")
    end

    -- 9. Maintenance & Repair Stations
    print("[MapBuilder] Mounting breakers & dairy cooler units...")
    local breaker1 = createPart(maintenanceFolder, "BreakerPanel_1", Vector3.new(0.6, 4, 3), CFrame.new(-74.5, 5, 20), PALETTE.COUNTER_BASE, Enum.Material.Metal)
    createHangingSign(breaker1, "MAIN BREAKER 1", CFrame.new(-74.1, 6.2, 20), Vector3.new(3.0, 0.8, 0.2), PALETTE.BRAND_ORANGE)
    CollectionService:AddTag(breaker1, "RepairTarget")
    CollectionService:AddTag(breaker1, "TaskAnchor")

    local breaker2 = createPart(maintenanceFolder, "BreakerPanel_2", Vector3.new(3, 4, 0.6), CFrame.new(35, 5, 89.5), PALETTE.COUNTER_BASE, Enum.Material.Metal)
    createHangingSign(breaker2, "AUX BREAKER 2", CFrame.new(35, 6.2, 89.1), Vector3.new(3.0, 0.8, 0.2), PALETTE.BRAND_ORANGE)
    CollectionService:AddTag(breaker2, "RepairTarget")
    CollectionService:AddTag(breaker2, "TaskAnchor")

    -- Dairy Coolers along Right Wall
    for c = 1, 4 do
        local cz = -10 + (c - 1) * 16
        local cooler = createPart(maintenanceFolder, "CoolerUnit_" .. c, Vector3.new(4, 9, 14), CFrame.new(72.5, 4.5, cz), PALETTE.SHELF_FRAME, Enum.Material.Metal)
        local glassDoor = createPart(cooler, "CoolerGlassDoor", Vector3.new(0.3, 8.2, 13.2), CFrame.new(70.3, 4.5, cz), PALETTE.GLASS_CLEAR, Enum.Material.Glass)
        glassDoor.Transparency = 0.55
        createHangingSign(cooler, "38°F DAIRY COOLER", CFrame.new(70.1, 8.2, cz), Vector3.new(7.5, 1.2, 0.1), PALETTE.BRAND_BLUE)

        if c == 2 then
            CollectionService:AddTag(cooler, "RepairTarget")
            CollectionService:AddTag(cooler, "TaskAnchor")
        end
    end

    -- Janitor Cleaning Stations
    for _, mopPos in ipairs({ Vector3.new(-70, 0.2, -35), Vector3.new(50, 0.2, 70) }) do
        local mopStation = createPart(maintenanceFolder, "MopStation", Vector3.new(4, 0.4, 4), CFrame.new(mopPos), PALETTE.BRAND_GOLD, Enum.Material.SmoothPlastic)
        createHangingSign(mopStation, "JANITOR MOP STATION", CFrame.new(mopPos + Vector3.new(0, 3.5, 0)), Vector3.new(5, 1.2, 0.2), PALETTE.BRAND_GOLD)
        CollectionService:AddTag(mopStation, "MopPickup")
        CollectionService:AddTag(mopStation, "TaskAnchor")
    end

    -- Spill Target Anchors
    local spillLocations = {
        Vector3.new(-45, 0.1, 15),  -- Aisle 1
        Vector3.new(-15, 0.1, 0),   -- Aisle 2
        Vector3.new(15, 0.1, 25),   -- Aisle 3
        Vector3.new(45, 0.1, -5),   -- Aisle 4
        Vector3.new(-10, 0.1, -25), -- Near Checkout 1
        Vector3.new(20, 0.1, -25),  -- Near Checkout 2
    }
    for idx, sPos in ipairs(spillLocations) do
        local anchor = createPart(taskAnchorsFolder, "SpillAnchor_" .. idx, Vector3.new(4, 0.1, 4), CFrame.new(sPos), PALETTE.BRAND_ORANGE, Enum.Material.SmoothPlastic)
        anchor.Transparency = 1
        CollectionService:AddTag(anchor, "SpillAnchor")
        CollectionService:AddTag(anchor, "TaskAnchor")
    end

    -- Restock Target Anchors on Shelves
    local restockTargets = {
        Vector3.new(-43, 3.5, 10),
        Vector3.new(-13, 6.2, 20),
        Vector3.new(17, 3.5, -5),
        Vector3.new(47, 6.2, 15),
    }
    for idx, rPos in ipairs(restockTargets) do
        local anchor = createPart(taskAnchorsFolder, "RestockTarget_" .. idx, Vector3.new(3, 2, 3), CFrame.new(rPos), PALETTE.BRAND_GOLD, Enum.Material.Neon)
        anchor.Transparency = 0.7
        CollectionService:AddTag(anchor, "RestockTarget")
        CollectionService:AddTag(anchor, "TaskAnchor")
    end

    print(string.format("[MapBuilder] Build complete! %d total instances in Workspace.SupermarketMap.", #map:GetDescendants()))
    return map
end

function MapBuilder.EnsureMap(): Model
    local existing = Workspace:FindFirstChild("SupermarketMap")
    if existing and #existing:GetDescendants() > 20 then
        MapBuilder.ConfigureLighting()
        return existing :: Model
    end
    return MapBuilder.Build()
end

return MapBuilder
