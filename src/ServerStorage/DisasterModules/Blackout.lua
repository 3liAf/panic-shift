--!strict
--[[
    PANIC SHIFT: Disaster - Blackout.lua
    Disaster 2: Complete power outage with emergency red lights.
    Players locate and flip BreakerPanel_1 and BreakerPanel_2 to restore power early.
]]

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")
local Types = require(Shared:WaitForChild("Types"))

local Blackout = {
    Name = "Blackout",
}

local originalBrightness: number = 2
local originalAmbient: Color3 = Color3.fromRGB(128, 128, 128)
local originalOutdoorAmbient: Color3 = Color3.fromRGB(128, 128, 128)
local breakerPrompts: { ProximityPrompt } = {}
local breakersFixed = 0
local modifiedNeons: { { part: Part, originalColor: Color3 } } = {}

function Blackout.CanStart(context: Types.DisasterContext?): boolean
    return true
end

function Blackout.Start(context: Types.DisasterContext): ()
    print("[Disaster: Blackout] Power outage triggered! Switching to emergency lighting.")

    originalBrightness = Lighting.Brightness
    originalAmbient = Lighting.Ambient
    originalOutdoorAmbient = Lighting.OutdoorAmbient

    -- Deep retail darkness
    Lighting.Brightness = 0.1
    Lighting.Ambient = Color3.fromRGB(10, 10, 18)
    Lighting.OutdoorAmbient = Color3.fromRGB(10, 10, 18)

    local map = context.SupermarketMap or Workspace:FindFirstChild("SupermarketMap")
    if not map then return end

    -- Turn ceiling lights into emergency pulsating red neon
    local arch = map:FindFirstChild("Architecture")
    if arch then
        for _, child in ipairs(arch:GetChildren()) do
            if child.Name == "LightFixture" then
                local tube = child:FindFirstChild("NeonTube")
                if tube and tube:IsA("Part") then
                    table.insert(modifiedNeons, { part = tube, originalColor = tube.Color })
                    tube.Color = Color3.fromRGB(255, 30, 30)
                    local light = tube:FindFirstChildOfClass("PointLight")
                    if light then
                        light.Color = Color3.fromRGB(255, 40, 40)
                        light.Brightness = 0.8
                    end
                end
            end
        end
    end

    -- Hook interactive ProximityPrompts onto the two breaker boxes
    breakersFixed = 0
    local maintenance = map:FindFirstChild("Maintenance")
    if maintenance then
        for _, panelName in ipairs({ "BreakerPanel_1", "BreakerPanel_2" }) do
            local panel = maintenance:FindFirstChild(panelName)
            if panel and panel:IsA("BasePart") then
                local prompt = Instance.new("ProximityPrompt")
                prompt.ActionText = "Restore Circuit"
                prompt.ObjectText = panelName
                prompt.HoldDuration = 2.0
                prompt.MaxActivationDistance = 9
                prompt.RequiresLineOfSight = false
                prompt.Parent = panel

                prompt.Triggered:Connect(function(player: Player)
                    prompt.Enabled = false
                    breakersFixed = breakersFixed + 1
                    print(string.format("[Blackout] %s flipped %s! (%d/2)", player.Name, panelName, breakersFixed))

                    if breakersFixed >= 2 then
                        print("[Blackout] Both circuit breakers restored! Early power restoration.")
                        local disasterService = context.Services.DisasterService
                        if disasterService then
                            disasterService:StopActiveDisaster()
                        end
                    end
                end)

                table.insert(breakerPrompts, prompt)
            end
        end
    end
end

function Blackout.Stop(context: Types.DisasterContext?): ()
    print("[Disaster: Blackout] Power restored. Resetting lighting.")

    Lighting.Brightness = originalBrightness
    Lighting.Ambient = originalAmbient
    Lighting.OutdoorAmbient = originalOutdoorAmbient

    -- Restore light tube colors
    for _, item in ipairs(modifiedNeons) do
        if item.part and item.part.Parent then
            item.part.Color = item.originalColor
            local light = item.part:FindFirstChildOfClass("PointLight")
            if light then
                light.Color = item.originalColor
                light.Brightness = 1.2
            end
        end
    end
    table.clear(modifiedNeons)

    -- Clean up prompts
    for _, prompt in ipairs(breakerPrompts) do
        if prompt and prompt.Parent then
            prompt:Destroy()
        end
    end
    table.clear(breakerPrompts)
end

return Blackout
