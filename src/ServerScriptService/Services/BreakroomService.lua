--!strict
--[[
    PANIC SHIFT: BreakroomService.lua
    Interactive employee breakroom features:
    - Vending Machine: Gives temporary energy speed boost
    - Punch Clock: Daily shift check-in / attendance bonus
    - 3D Digital Leaderboard: Displays real-time shift MVPs and quotas
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")
local Types = require(Shared:WaitForChild("Types"))
local Config = require(Shared:WaitForChild("Config"))
local Constants = require(Shared:WaitForChild("Constants"))
local Utility = require(Shared:WaitForChild("Utility"))
local Network = require(Shared:WaitForChild("Network"))

local BreakroomService = {
    Name = "BreakroomService",
}

local services: { [string]: any } = {}
local punchClockCooldowns: { [number]: number } = {}
local vendingCooldowns: { [number]: number } = {}

local function getService(serviceName: string): any
    if services[serviceName] then
        return services[serviceName]
    end
    local parent = script.Parent
    if parent and parent:FindFirstChild(serviceName) then
        local mod = parent[serviceName]
        if mod:IsA("ModuleScript") then
            services[serviceName] = require(mod)
            return services[serviceName]
        end
    end
    return nil
end

function BreakroomService:Init(serviceRegistry: { [string]: any })
    services = serviceRegistry
end

function BreakroomService:Start()
    self:SpawnBreakroomProps()

    -- Hook round state changes to update 3D leaderboard
    local roundService = getService("RoundService")
    if roundService then
        task.spawn(function()
            while true do
                task.wait(2.0)
                self:UpdateLeaderboardScreen()
            end
        end)
    end
end

-- Procedurally generates Breakroom interactive stations
function BreakroomService:SpawnBreakroomProps()
    local map = Workspace:FindFirstChild("SupermarketMap")
    local lobby = map and map:FindFirstChild("Lobby")
    if not lobby then
        warn("[BreakroomService] SupermarketMap.Lobby not found, skipping breakroom props.")
        return
    end

    local existingFolder = lobby:FindFirstChild("InteractiveStations")
    if existingFolder then
        existingFolder:Destroy()
    end

    local folder = Instance.new("Folder")
    folder.Name = "InteractiveStations"
    folder.Parent = lobby

    -- 1. VENDING MACHINE ("PANIC FUEL SODA")
    local vendingModel = Instance.new("Model")
    vendingModel.Name = "VendingMachine_Energy"
    vendingModel.Parent = folder

    local body = Instance.new("Part")
    body.Name = "VendingBody"
    body.Size = Vector3.new(4, 7, 3)
    body.CFrame = CFrame.new(-22, 5.5, -41)
    body.Color = Color3.fromRGB(30, 40, 60)
    body.Material = Enum.Material.Metal
    body.Anchored = true
    body.Parent = vendingModel

    local glass = Instance.new("Part")
    glass.Name = "VendingGlass"
    glass.Size = Vector3.new(3.2, 4, 0.4)
    glass.CFrame = body.CFrame * CFrame.new(0, 0.8, 1.4)
    glass.Color = Color3.fromRGB(80, 200, 255)
    glass.Material = Enum.Material.Neon
    glass.Transparency = 0.4
    glass.Anchored = true
    glass.CanCollide = false
    glass.Parent = vendingModel

    -- Glowing soda rows
    for row = -1, 1 do
        local canRow = Instance.new("Part")
        canRow.Name = "CanRow_" .. row
        canRow.Size = Vector3.new(2.8, 0.6, 0.4)
        canRow.CFrame = glass.CFrame * CFrame.new(0, row * 1.1, -0.3)
        canRow.Color = (row == -1) and Color3.fromRGB(255, 60, 60) or ((row == 0) and Color3.fromRGB(60, 255, 120) or Color3.fromRGB(255, 200, 40))
        canRow.Material = Enum.Material.Neon
        canRow.Anchored = true
        canRow.CanCollide = false
        canRow.Parent = vendingModel
    end

    -- Vending audio cue
    local drinkSound = Instance.new("Sound")
    drinkSound.Name = "DrinkSound"
    drinkSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    drinkSound.Volume = 0.8
    drinkSound.Parent = body

    local vendingPrompt = Instance.new("ProximityPrompt")
    vendingPrompt.ActionText = "Chug Energy Soda"
    vendingPrompt.ObjectText = "Panic Fuel Vending"
    vendingPrompt.HoldDuration = 0.5
    vendingPrompt.MaxActivationDistance = 8
    vendingPrompt.RequiresLineOfSight = false
    vendingPrompt.Parent = body

    vendingPrompt.Triggered:Connect(function(player: Player)
        local now = os.clock()
        local lastUsed = vendingCooldowns[player.UserId] or 0
        if now - lastUsed < 12 then
            return
        end
        vendingCooldowns[player.UserId] = now
        drinkSound:Play()

        local character = player.Character
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
        if hum then
            hum.WalkSpeed = 24

            -- Attach celebratory speed sparkles to character
            local emitter: ParticleEmitter? = nil
            if root and root:IsA("BasePart") then
                emitter = Instance.new("ParticleEmitter")
                emitter.Name = "PanicFuelBoostVFX"
                emitter.Rate = 25
                emitter.Speed = NumberRange.new(2, 5)
                emitter.Lifetime = NumberRange.new(0.4, 0.8)
                emitter.Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.6),
                    NumberSequenceKeypoint.new(1, 0),
                })
                emitter.Color = ColorSequence.new(Color3.fromRGB(60, 255, 200))
                emitter.LightEmission = 0.8
                emitter.Parent = root
            end

            task.delay(8, function()
                if hum and hum.Parent then
                    hum.WalkSpeed = 16
                end
                if emitter and emitter.Parent then
                    emitter.Enabled = false
                    task.delay(1, function()
                        if emitter and emitter.Parent then
                            emitter:Destroy()
                        end
                    end)
                end
            end)
        end
    end)

    -- 2. PUNCH CLOCK ("ATTENDANCE / TIME CARD")
    local punchModel = Instance.new("Model")
    punchModel.Name = "PunchClock_Attendance"
    punchModel.Parent = folder

    local punchBox = Instance.new("Part")
    punchBox.Name = "PunchBox"
    punchBox.Size = Vector3.new(2.5, 3.5, 1)
    punchBox.CFrame = CFrame.new(16, 5.5, -41)
    punchBox.Color = Color3.fromRGB(160, 140, 110)
    punchBox.Material = Enum.Material.WoodPlanks
    punchBox.Anchored = true
    punchBox.Parent = punchModel

    local clockFace = Instance.new("Part")
    clockFace.Name = "ClockFace"
    clockFace.Shape = Enum.PartType.Cylinder
    clockFace.Size = Vector3.new(0.2, 1.8, 1.8)
    clockFace.CFrame = punchBox.CFrame * CFrame.new(0, 0.6, 0.55) * CFrame.Angles(0, 0, math.rad(90))
    clockFace.Color = Color3.fromRGB(255, 255, 255)
    clockFace.Material = Enum.Material.SmoothPlastic
    clockFace.Anchored = true
    clockFace.CanCollide = false
    clockFace.Parent = punchModel

    local punchSound = Instance.new("Sound")
    punchSound.Name = "PunchSound"
    punchSound.SoundId = "rbxasset://sounds/button.wav"
    punchSound.Volume = 0.9
    punchSound.Parent = punchBox

    local punchPrompt = Instance.new("ProximityPrompt")
    punchPrompt.ActionText = "Punch Time Card"
    punchPrompt.ObjectText = "Employee Attendance"
    punchPrompt.HoldDuration = 1.0
    punchPrompt.MaxActivationDistance = 8
    punchPrompt.RequiresLineOfSight = false
    punchPrompt.Parent = punchBox

    punchPrompt.Triggered:Connect(function(player: Player)
        local today = os.date("!%Y-%m-%d")
        local key = player.UserId
        local lastDay = punchClockCooldowns[key]

        local nowTime = os.time()
        if lastDay and (nowTime - lastDay < 60) then
            return
        end
        punchClockCooldowns[key] = nowTime
        punchSound:Play()

        local economyService = getService("EconomyService")
        if economyService then
            economyService:AwardCredits(player, 25, "BreakroomAttendance")
            economyService:AwardXp(player, 30, "BreakroomAttendance")
        end
    end)

    -- 3. 3D DIGITAL LEADERBOARD SCREEN
    local boardPart = Instance.new("Part")
    boardPart.Name = "BreakroomLeaderboardScreen"
    boardPart.Size = Vector3.new(18, 9, 0.5)
    boardPart.CFrame = CFrame.new(-3, 8.5, -42)
    boardPart.Color = Color3.fromRGB(15, 20, 30)
    boardPart.Material = Enum.Material.Glass
    boardPart.Anchored = true
    boardPart.Parent = folder

    local surfGui = Instance.new("SurfaceGui")
    surfGui.Name = "LeaderboardDisplay"
    surfGui.Face = Enum.NormalId.Back
    surfGui.CanvasSize = Vector2.new(900, 450)
    surfGui.Parent = boardPart

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(18, 24, 38)
    frame.BorderSizePixel = 0
    frame.Parent = surfGui

    local header = Instance.new("TextLabel")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 70)
    header.BackgroundColor3 = Color3.fromRGB(28, 40, 65)
    header.BorderSizePixel = 0
    header.Text = "🏆 PANIC SHIFT — SHIFT ROSTER & METRICS"
    header.TextColor3 = Color3.fromRGB(255, 215, 60)
    header.Font = Enum.Font.FredokaOne
    header.TextSize = 28
    header.Parent = frame

    local content = Instance.new("TextLabel")
    content.Name = "Content"
    content.Size = UDim2.new(1, -40, 1, -90)
    content.Position = UDim2.new(0, 20, 0, 80)
    content.BackgroundTransparency = 1
    content.Text = "Loading shift records..."
    content.TextColor3 = Color3.fromRGB(220, 230, 245)
    content.Font = Enum.Font.GothamMedium
    content.TextSize = 22
    content.TextXAlignment = Enum.TextXAlignment.Left
    content.TextYAlignment = Enum.TextYAlignment.Top
    content.TextWrapped = true
    content.Parent = frame
end

-- Periodically refreshes the 3D Leaderboard SurfaceGui text
function BreakroomService:UpdateLeaderboardScreen()
    local map = Workspace:FindFirstChild("SupermarketMap")
    local lobby = map and map:FindFirstChild("Lobby")
    local stations = lobby and lobby:FindFirstChild("InteractiveStations")
    local board = stations and stations:FindFirstChild("BreakroomLeaderboardScreen")
    local surfGui = board and board:FindFirstChild("LeaderboardDisplay")
    local frame = surfGui and surfGui:FindFirstChild("Frame")
    local content = frame and frame:FindFirstChild("Content") :: TextLabel?

    if not content then
        return
    end

    local roundService = getService("RoundService")
    local currentState = roundService and roundService:GetState() or "LOBBY"
    local timeRem = roundService and roundService:GetTimerRemaining() or 0
    local curQ, tarQ = 0, 0
    if roundService then
        curQ, tarQ = roundService:GetQuotaProgress()
    end

    local playerList = Players:GetPlayers()
    local lines = {}
    table.insert(lines, string.format("📌 CURRENT STATUS: %s | Time Left: %ds", currentState, timeRem))
    table.insert(lines, string.format("📦 STORE QUOTA: %d / %d", curQ, tarQ))
    table.insert(lines, "")
    table.insert(lines, "⭐ EMPLOYEES ON CLOCK (" .. tostring(#playerList) .. " Active):")

    for i = 1, math.min(5, #playerList) do
        local p = playerList[i]
        local economy = getService("EconomyService")
        local bal = economy and economy:GetBalance(p) or 0
        table.insert(lines, string.format("  #%d. %s  —  💰 %d Credits", i, p.Name, bal))
    end

    if #playerList == 0 then
        table.insert(lines, "  (Waiting for employees to punch in...)")
    end

    content.Text = table.concat(lines, "\n")
end

return BreakroomService
