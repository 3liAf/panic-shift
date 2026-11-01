--!strict
--[[
    PANIC SHIFT: Disaster - ProductAvalanche.lua
    Disaster 4: Gondola shelf in Aisle 2 collapses, sending dozens of soup cans
    and cereal boxes tumbling into the aisle with slapstick physics.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")
local Types = require(Shared:WaitForChild("Types"))
local Utility = require(Shared:WaitForChild("Utility"))

local ProductAvalanche = {
    Name = "ProductAvalanche",
}

local avalancheFolder: Folder? = nil
local dangerDecals: { Instance } = {}

function ProductAvalanche.CanStart(context: Types.DisasterContext?): boolean
    local map = context and context.SupermarketMap or Workspace:FindFirstChild("SupermarketMap")
    return map ~= nil
end

function ProductAvalanche.Start(context: Types.DisasterContext): ()
    print("[Disaster: ProductAvalanche] Creaking metal heard in Aisle 2!")

    local map = context.SupermarketMap or Workspace:FindFirstChild("SupermarketMap")
    if not map then return end

    avalancheFolder = Instance.new("Folder")
    avalancheFolder.Name = "ActiveAvalancheDebris"
    avalancheFolder.Parent = Workspace

    -- 1. Floor danger warning strips along Aisle 2 (X = -15, Z from -10 to 40)
    for z = -10, 40, 10 do
        local warningPart = Instance.new("Part")
        warningPart.Name = "DangerZone"
        warningPart.Size = Vector3.new(12, 0.1, 8)
        warningPart.CFrame = CFrame.new(-15, 0.08, z)
        warningPart.Color = Color3.fromRGB(255, 60, 60)
        warningPart.Material = Enum.Material.Neon
        warningPart.Transparency = 0.5
        warningPart.Anchored = true
        warningPart.CanCollide = false
        warningPart.Parent = avalancheFolder
        table.insert(dangerDecals, warningPart)
    end

    -- 2. Avalanche collapse: Spawn 30 unanchored bouncing soup cans and cracker boxes
    task.delay(1.5, function()
        if not avalancheFolder then return end

        for i = 1, 30 do
            local isCan = (i % 2 == 0)
            local debris = Instance.new("Part")
            debris.Name = isCan and "SoupCan" or "CerealBox"
            
            if isCan then
                debris.Shape = Enum.PartType.Cylinder
                debris.Size = Vector3.new(2.2, 1.6, 1.6)
                debris.Color = Color3.fromRGB(230, 45, 45) -- Tomato soup red
            else
                debris.Size = Vector3.new(2.2, 2.5, 1.2)
                debris.Color = Color3.fromRGB(245, 175, 45) -- Cereal gold
            end

            debris.Material = Enum.Material.SmoothPlastic
            debris.Anchored = false
            debris.CanCollide = true
            debris.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.4, 0.7) -- Very bouncy
            
            -- Spawn along Aisle 2 shelf height (Y = 10 to 14)
            local dropZ = math.random(-10, 35)
            debris.CFrame = CFrame.new(-15 + math.random(-2, 2), math.random(10, 15), dropZ) * CFrame.Angles(math.random(), math.random(), math.random())
            debris.AssemblyLinearVelocity = Vector3.new(math.random(-15, 15), -10, math.random(-15, 15))
            debris.Parent = avalancheFolder

            -- Comedic hit detection
            local debounce = false
            debris.Touched:Connect(function(hit: BasePart)
                if debounce then return end
                local char = hit.Parent
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                if humanoid and not debounce then
                    debounce = true
                    humanoid.PlatformStand = true
                    task.delay(1.2, function()
                        if humanoid and humanoid.Parent then
                            humanoid.PlatformStand = false
                        end
                    end)
                end
            end)
        end
    end)
end

function ProductAvalanche.Stop(context: Types.DisasterContext?): ()
    print("[Disaster: ProductAvalanche] Maintenance cleared the fallen products.")

    if avalancheFolder then
        avalancheFolder:Destroy()
        avalancheFolder = nil
    end

    table.clear(dangerDecals)
end

return ProductAvalanche
