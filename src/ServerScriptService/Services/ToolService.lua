--!strict
--[[
    PANIC SHIFT: ToolService.lua
    Authoritative physical tool provider and interaction validator.
    Manages:
    1. Store Mop: Sweeping swing, bubbly splash VFX, cleans spills on click
    2. Fire Extinguisher: Pressurized CO2 foam jet, puts out fires on click
    3. Character tool distribution on join/respawn via StarterPack
]]

local Players = game:GetService("Players")
local StarterPack = game:GetService("StarterPack")
local Debris = game:GetService("Debris")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")
local Types = require(Shared:WaitForChild("Types"))
local Constants = require(Shared:WaitForChild("Constants"))
local Utility = require(Shared:WaitForChild("Utility"))

local ToolService = {
    Name = "ToolService",
}

local services: { [string]: any } = {}

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

-- Builds the Store Mop Tool
function ToolService:CreateMopTool(): Tool
    local tool = Instance.new("Tool")
    tool.Name = "Store Mop"
    tool.ToolTip = "Mop up slippery retail spills! Click to scrub."
    tool.RequiresHandle = true
    tool.CanBeDropped = false

    -- Handle (Wooden Shaft)
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.4, 5.2, 0.4)
    handle.Color = Color3.fromRGB(215, 175, 105)
    handle.Material = Enum.Material.Wood
    handle.TopSurface = Enum.SurfaceType.Smooth
    handle.BottomSurface = Enum.SurfaceType.Smooth
    handle.CanCollide = false
    handle.Parent = tool

    -- Chrome collar band
    local ferrule = Instance.new("Part")
    ferrule.Name = "Ferrule"
    ferrule.Size = Vector3.new(0.55, 0.4, 0.55)
    ferrule.Color = Color3.fromRGB(200, 205, 215)
    ferrule.Material = Enum.Material.Metal
    ferrule.CanCollide = false
    ferrule.CFrame = handle.CFrame * CFrame.new(0, -2.4, 0)
    ferrule.Parent = tool

    local fWeld = Instance.new("WeldConstraint")
    fWeld.Part0 = handle
    fWeld.Part1 = ferrule
    fWeld.Parent = handle

    -- Mop Head (Cotton Strands)
    local mopHead = Instance.new("Part")
    mopHead.Name = "MopHead"
    mopHead.Size = Vector3.new(1.4, 0.8, 1.4)
    mopHead.Color = Color3.fromRGB(245, 245, 250)
    mopHead.Material = Enum.Material.Fabric
    mopHead.CanCollide = false
    mopHead.CFrame = handle.CFrame * CFrame.new(0, -2.9, 0)
    mopHead.Parent = tool

    local hWeld = Instance.new("WeldConstraint")
    hWeld.Part0 = handle
    hWeld.Part1 = mopHead
    hWeld.Parent = handle

    -- Soap bubble / water splash particles
    local bubbles = Instance.new("ParticleEmitter")
    bubbles.Name = "SoapBubbles"
    bubbles.Rate = 0
    bubbles.Speed = NumberRange.new(2, 5)
    bubbles.Lifetime = NumberRange.new(0.3, 0.6)
    bubbles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.7, 0.6),
        NumberSequenceKeypoint.new(1, 0),
    })
    bubbles.Color = ColorSequence.new(Color3.fromRGB(220, 240, 255))
    bubbles.LightEmission = 0.5
    bubbles.Parent = mopHead

    -- Audio Squelch
    local squelch = Instance.new("Sound")
    squelch.Name = "MopSplat"
    squelch.SoundId = "rbxasset://sounds/splat.wav"
    squelch.Volume = 0.85
    squelch.Pitch = 1.2
    squelch.Parent = mopHead

    -- Grip alignment (hold vertically by the upper shaft)
    tool.Grip = CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, 0)

    -- Click / Activation Behavior
    tool.Activated:Connect(function()
        local character = tool.Parent
        local player = Players:GetPlayerFromCharacter(character)
        if not player then return end

        squelch:Play()
        bubbles:Emit(15)

        -- Check distance to spills
        local taskService = getService("TaskService")
        if not taskService then return end

        local charPos = Utility.GetCharacterPosition(character)
        if not charPos then return end

        -- Scrub nearby spills
        local activeTasks = taskService:GetActiveTasks()
        if activeTasks then
            for taskId, data in pairs(activeTasks) do
                if data.Type == "CLEAN_SPILL" and data.IsActive and not data.IsCompleted then
                    local dist = (data.Position - charPos).Magnitude
                    if dist <= 10.0 then
                        taskService:HandleTaskAction(player, taskId, "MOP")
                        break
                    end
                end
            end
        end
    end)

    return tool
end

-- Builds the Fire Extinguisher Tool
function ToolService:CreateExtinguisherTool(): Tool
    local tool = Instance.new("Tool")
    tool.Name = "Fire Extinguisher"
    tool.ToolTip = "Extinguish store fires! Aim and click to spray CO2 foam."
    tool.RequiresHandle = true
    tool.CanBeDropped = false

    -- Handle (Tank Body)
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Shape = Enum.PartType.Cylinder
    handle.Size = Vector3.new(2.4, 0.8, 0.8) -- Cylinder height is X axis
    handle.CFrame = handle.CFrame * CFrame.Angles(0, 0, math.rad(90))
    handle.Color = Color3.fromRGB(215, 35, 35)
    handle.Material = Enum.Material.SmoothPlastic
    handle.CanCollide = false
    handle.Parent = tool

    -- Gauge & Valve Top
    local valve = Instance.new("Part")
    valve.Name = "Valve"
    valve.Size = Vector3.new(0.6, 0.6, 0.6)
    valve.Color = Color3.fromRGB(35, 35, 40)
    valve.Material = Enum.Material.Metal
    valve.CanCollide = false
    valve.CFrame = handle.CFrame * CFrame.new(1.3, 0, 0)
    valve.Parent = tool

    local vWeld = Instance.new("WeldConstraint")
    vWeld.Part0 = handle
    vWeld.Part1 = valve
    vWeld.Parent = handle

    -- Nozzle Horn
    local nozzle = Instance.new("Part")
    nozzle.Name = "Nozzle"
    nozzle.Size = Vector3.new(0.4, 0.4, 1.2)
    nozzle.Color = Color3.fromRGB(20, 20, 20)
    nozzle.Material = Enum.Material.SmoothPlastic
    nozzle.CanCollide = false
    nozzle.CFrame = valve.CFrame * CFrame.new(0, 0.3, 0.7)
    nozzle.Parent = tool

    local nWeld = Instance.new("WeldConstraint")
    nWeld.Part0 = handle
    nWeld.Part1 = nozzle
    nWeld.Parent = handle

    -- Pressurized CO2 Foam Emitter
    local foam = Instance.new("ParticleEmitter")
    foam.Name = "CO2Foam"
    foam.Rate = 0
    foam.Speed = NumberRange.new(15, 25)
    foam.Lifetime = NumberRange.new(0.4, 0.8)
    foam.SpreadAngle = Vector2.new(15, 15)
    foam.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.4),
        NumberSequenceKeypoint.new(0.5, 1.8),
        NumberSequenceKeypoint.new(1, 2.5),
    })
    foam.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(0.8, 0.4),
        NumberSequenceKeypoint.new(1, 1.0),
    })
    foam.Color = ColorSequence.new(Color3.fromRGB(245, 250, 255))
    foam.Parent = nozzle

    -- Hiss Sound
    local hiss = Instance.new("Sound")
    hiss.Name = "ExtinguisherHiss"
    hiss.SoundId = "rbxasset://sounds/action_falling.mp3"
    hiss.Volume = 0.8
    hiss.Pitch = 1.8
    hiss.Parent = nozzle

    tool.Grip = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(90), 0)

    -- Activation Behavior
    tool.Activated:Connect(function()
        local character = tool.Parent
        local player = Players:GetPlayerFromCharacter(character)
        if not player then return end

        hiss:Play()
        foam:Emit(30)

        local taskService = getService("TaskService")
        if not taskService then return end

        local charPos = Utility.GetCharacterPosition(character)
        if not charPos then return end

        local activeTasks = taskService:GetActiveTasks()
        if activeTasks then
            for taskId, data in pairs(activeTasks) do
                if data.Type == "EXTINGUISH_FIRE" and data.IsActive and not data.IsCompleted then
                    local dist = (data.Position - charPos).Magnitude
                    if dist <= 14.0 then
                        taskService:HandleTaskAction(player, taskId, "EXTINGUISH_FIRE")
                        break
                    end
                end
            end
        end
    end)

    return tool
end

-- Equips player with essential shift tools
function ToolService:GiveTools(player: Player)
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return end

    if not backpack:FindFirstChild("Store Mop") and not (player.Character and player.Character:FindFirstChild("Store Mop")) then
        local mop = self:CreateMopTool()
        mop.Parent = backpack
    end

    if not backpack:FindFirstChild("Fire Extinguisher") and not (player.Character and player.Character:FindFirstChild("Fire Extinguisher")) then
        local ext = self:CreateExtinguisherTool()
        ext.Parent = backpack
    end
end

function ToolService:Init(serviceRegistry: { [string]: any })
    services = serviceRegistry

    -- Ensure tools in StarterPack for all future spawns
    if not StarterPack:FindFirstChild("Store Mop") then
        local mop = self:CreateMopTool()
        mop.Parent = StarterPack
    end

    if not StarterPack:FindFirstChild("Fire Extinguisher") then
        local ext = self:CreateExtinguisherTool()
        ext.Parent = StarterPack
    end
end

function ToolService:Start()
    -- Distribute tools to any currently joined players
    for _, player in ipairs(Players:GetPlayers()) do
        self:GiveTools(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.2)
            self:GiveTools(player)
        end)
    end

    Players.PlayerAdded:Connect(function(player: Player)
        player.CharacterAdded:Connect(function()
            task.wait(0.2)
            self:GiveTools(player)
        end)
    end)

    print("[ToolService] Store Mop and Fire Extinguisher active in StarterPack.")
end

return ToolService
