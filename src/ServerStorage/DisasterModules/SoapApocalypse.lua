--!strict
--[[
    PANIC SHIFT: Disaster - SoapApocalypse.lua
    Disaster 5: Detergent vents rupture, coating supermarket floors with soapy foam.
    Floor friction drops to near-zero (ice skating physics).
]]

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")
local Types = require(Shared:WaitForChild("Types"))

local SoapApocalypse = {
    Name = "SoapApocalypse",
}

local soapFolder: Folder? = nil
local modifiedFloorParts: { { part: BasePart, originalProperties: PhysicalProperties? } } = {}

function SoapApocalypse.CanStart(context: Types.DisasterContext?): boolean
    local map = context and context.SupermarketMap or Workspace:FindFirstChild("SupermarketMap")
    return map ~= nil
end

function SoapApocalypse.Start(context: Types.DisasterContext): ()
    print("[Disaster: SoapApocalypse] Detergent vents ruptured! Floors are frictionless ice!")

    local map = context.SupermarketMap or Workspace:FindFirstChild("SupermarketMap")
    if not map then return end

    soapFolder = Instance.new("Folder")
    soapFolder.Name = "ActiveSoapApocalypse"
    soapFolder.Parent = Workspace

    -- 1. Modify floor friction to 0.01 (frictionless sliding)
    local arch = map:FindFirstChild("Architecture")
    if arch then
        for _, child in ipairs(arch:GetChildren()) do
            if child.Name:find("Floor") and child:IsA("BasePart") then
                table.insert(modifiedFloorParts, {
                    part = child,
                    originalProperties = child.CustomPhysicalProperties,
                })
                -- Zero friction, slight bounciness
                child.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0.01, 0.2)
            end
        end
    end

    -- 2. Spawn floating soap bubble emitters from ceiling
    for x = -40, 40, 20 do
        for z = -10, 40, 20 do
            local ventBubble = Instance.new("Part")
            ventBubble.Name = "SoapVent"
            ventBubble.Size = Vector3.new(2, 0.4, 2)
            ventBubble.CFrame = CFrame.new(x, 20, z)
            ventBubble.Transparency = 1
            ventBubble.Anchored = true
            ventBubble.CanCollide = false
            ventBubble.Parent = soapFolder

            local bubbles = Instance.new("ParticleEmitter")
            bubbles.Rate = 12
            bubbles.Speed = NumberRange.new(2, 6)
            bubbles.Lifetime = NumberRange.new(3, 6)
            bubbles.SpreadAngle = Vector2.new(180, 180)
            bubbles.Size = NumberSequence.new(0.6, 1.4)
            bubbles.Color = ColorSequence.new(Color3.fromRGB(240, 245, 255))
            bubbles.Parent = ventBubble
        end
    end
end

function SoapApocalypse.Stop(context: Types.DisasterContext?): ()
    print("[Disaster: SoapApocalypse] Cleaning crew squeegeed the floor. Normal traction restored.")

    -- Restore floor properties
    for _, item in ipairs(modifiedFloorParts) do
        if item.part and item.part.Parent then
            if item.originalProperties then
                item.part.CustomPhysicalProperties = item.originalProperties
            else
                item.part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5)
            end
        end
    end
    table.clear(modifiedFloorParts)

    if soapFolder then
        soapFolder:Destroy()
        soapFolder = nil
    end
end

return SoapApocalypse
