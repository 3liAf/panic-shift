--!strict
--[[
    PANIC SHIFT: CameraController.lua
    Manages trauma-based camera shakes, FOV shifts during closing rush,
    and comedic stumble punch-ins with full accessibility toggle support.
]]

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local CameraController = {
    Name = "CameraController",
}

local controllers: { [string]: any } = {}
local camera: Camera? = Workspace.CurrentCamera

-- Camera Shake Parameters
local trauma: number = 0
local TRAUMA_DECAY_RATE: number = 1.8
local MAX_TRANSLATION_STUDS: number = 1.2
local MAX_ROTATION_DEGREES: number = 3.5

-- FOV Parameters
local DEFAULT_FOV: number = 70
local CLOSING_RUSH_FOV: number = 82
local currentFov: number = DEFAULT_FOV
local targetBaseFov: number = DEFAULT_FOV
local fovPunchOffset: number = 0
local FOV_LERP_SPEED: number = 6.0
local PUNCH_DECAY_SPEED: number = 8.0

-- Perlin noise seed
local noiseTime: number = 0

function CameraController:Init(controllerRegistry: { [string]: any })
    controllers = controllerRegistry
end

function CameraController:Start()
    camera = Workspace.CurrentCamera
    if camera then
        currentFov = camera.FieldOfView
    end

    RunService.RenderStepped:Connect(function(deltaTime: number)
        if not camera then
            camera = Workspace.CurrentCamera
            if not camera then
                return
            end
        end

        local uiCtrl = controllers["UIController"]
        local isShakeEnabled = true
        if uiCtrl and typeof(uiCtrl.IsScreenShakeEnabled) == "function" then
            isShakeEnabled = uiCtrl:IsScreenShakeEnabled()
        end

        -- 1. Trauma decay and shake calculation
        if trauma > 0 then
            trauma = math.max(0, trauma - (deltaTime * TRAUMA_DECAY_RATE))

            if isShakeEnabled and trauma > 0.01 then
                noiseTime = noiseTime + (deltaTime * 35.0)
                local shakeFactor = trauma * trauma -- Quadratic falloff for physical punch

                local offsetX = (math.noise(noiseTime, 0, 0) or 0) * MAX_TRANSLATION_STUDS * shakeFactor
                local offsetY = (math.noise(0, noiseTime, 0) or 0) * MAX_TRANSLATION_STUDS * shakeFactor
                local offsetZ = (math.noise(0, 0, noiseTime) or 0) * (MAX_TRANSLATION_STUDS * 0.5) * shakeFactor

                local rotX = math.rad((math.noise(noiseTime + 10, 0, 0) or 0) * MAX_ROTATION_DEGREES * shakeFactor)
                local rotY = math.rad((math.noise(0, noiseTime + 10, 0) or 0) * MAX_ROTATION_DEGREES * shakeFactor)
                local rotZ = math.rad((math.noise(0, 0, noiseTime + 10) or 0) * (MAX_ROTATION_DEGREES * 1.5) * shakeFactor)

                local shakeCFrame = CFrame.new(offsetX, offsetY, offsetZ) * CFrame.Angles(rotX, rotY, rotZ)
                camera.CFrame = camera.CFrame * shakeCFrame
            end
        end

        -- 2. Dynamic FOV Smoothing
        if math.abs(fovPunchOffset) > 0.1 then
            fovPunchOffset = fovPunchOffset - (fovPunchOffset * math.clamp(deltaTime * PUNCH_DECAY_SPEED, 0, 1))
        else
            fovPunchOffset = 0
        end

        local desiredFov = targetBaseFov + fovPunchOffset
        currentFov = currentFov + ((desiredFov - currentFov) * math.clamp(deltaTime * FOV_LERP_SPEED, 0, 1))
        camera.FieldOfView = currentFov
    end)

    print("[PanicShift CameraController] Camera shake & dynamic FOV active.")
end

-- Adds trauma to the camera [0 to 1]
function CameraController:TriggerShake(intensity: number)
    local clamped = math.clamp(intensity, 0, 1)
    trauma = math.clamp(trauma + clamped, 0, 1)
end

-- Sets base FOV (e.g. for Closing Rush wide angle)
function CameraController:SetTargetFov(fov: number)
    targetBaseFov = math.clamp(fov, 50, 100)
end

-- Temporarily punches FOV (e.g. quick zoom punch on impact or stumble)
function CameraController:PunchFov(amount: number)
    fovPunchOffset = math.clamp(fovPunchOffset + amount, -25, 25)
end

function CameraController:SetClosingRushActive(active: boolean)
    if active then
        self:SetTargetFov(CLOSING_RUSH_FOV)
        self:PunchFov(-6) -- Quick punch-in before widening for dramatic flair
    else
        self:SetTargetFov(DEFAULT_FOV)
    end
end

return CameraController
