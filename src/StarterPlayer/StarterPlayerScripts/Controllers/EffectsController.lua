--!strict
--[[
    PANIC SHIFT: EffectsController.lua
    Client visual effects, sound dispatch, particle generation,
    and comedic stumble/slip ragdoll reactions.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")
local Constants = require(Shared:WaitForChild("Constants"))

local EffectsController = {
    Name = "EffectsController",
}

local controllers: { [string]: any } = {}
local activeLoops: { [string]: Sound } = {}
local soundFolder: Folder

-- Audio definition registry: primary sound asset with fallback
export type SoundDef = {
    Id: string,
    FallbackId: string?,
    Volume: number,
    Pitch: number,
    Looped: boolean?,
}

local SOUND_CATALOG: { [string]: SoundDef } = {
    TaskComplete = {
        Id = "rbxasset://sounds/electronicpingshort.wav",
        FallbackId = "rbxassetid://6026947094",
        Volume = 0.75,
        Pitch = 1.1,
    },
    CashRegister = {
        Id = "rbxasset://sounds/victory.wav",
        FallbackId = "rbxassetid://9069609200",
        Volume = 0.85,
        Pitch = 1.2,
    },
    DisasterTelegraph = {
        Id = "rbxasset://sounds/action_falling.mp3",
        FallbackId = "rbxassetid://9065458027",
        Volume = 0.85,
        Pitch = 0.95,
    },
    DisasterActive = {
        Id = "rbxasset://sounds/glassbreak.wav",
        FallbackId = "rbxassetid://9065365518",
        Volume = 0.9,
        Pitch = 0.9,
    },
    DisasterCleared = {
        Id = "rbxasset://sounds/victory.wav",
        FallbackId = "rbxassetid://6026947094",
        Volume = 0.7,
        Pitch = 1.35,
    },
    SlipStumble = {
        Id = "rbxasset://sounds/splat.wav",
        FallbackId = "rbxassetid://9114223171",
        Volume = 0.8,
        Pitch = 1.15,
    },
    CartRattle = {
        Id = "rbxasset://sounds/action_footsteps_plastic.mp3",
        FallbackId = "rbxassetid://9114221580",
        Volume = 0.5,
        Pitch = 1.0,
        Looped = true,
    },
    Sparks = {
        Id = "rbxasset://sounds/snap.wav",
        FallbackId = "rbxassetid://9114223842",
        Volume = 0.65,
        Pitch = 1.3,
    },
    ButtonClick = {
        Id = "rbxasset://sounds/button.wav",
        FallbackId = "rbxassetid://6895079853",
        Volume = 0.45,
        Pitch = 1.1,
    },
    RushSiren = {
        Id = "rbxasset://sounds/action_jump.mp3",
        FallbackId = "rbxassetid://9065458027",
        Volume = 0.8,
        Pitch = 1.05,
    },
}

function EffectsController:Init(controllerRegistry: { [string]: any })
    controllers = controllerRegistry

    soundFolder = Instance.new("Folder")
    soundFolder.Name = "PanicShiftClientAudio"
    soundFolder.Parent = SoundService
end

function EffectsController:Start()
    print("[PanicShift EffectsController] Audio, Particle & Animation systems active.")
end

-- ====================================================================
-- AUDIO DISPATCHER
-- ====================================================================

function EffectsController:PlaySound(
    soundName: string,
    targetPositionOrPart: (Vector3 | Instance)?,
    customOptions: { Volume: number?, Pitch: number?, Looped: boolean? }?
): Sound?
    local soundDef = SOUND_CATALOG[soundName]
    if not soundDef then
        warn(string.format("[EffectsController] Unknown sound name: %s", soundName))
        return nil
    end

    local sound = Instance.new("Sound")
    sound.Name = soundName
    sound.SoundId = soundDef.Id
    sound.Volume = if customOptions and customOptions.Volume ~= nil then customOptions.Volume else soundDef.Volume
    
    -- Slight natural pitch variation for organic party game feel (±5%)
    local basePitch = if customOptions and customOptions.Pitch ~= nil then customOptions.Pitch else soundDef.Pitch
    local pitchVariation = (math.random(95, 105) / 100)
    sound.PlaybackSpeed = math.clamp(basePitch * pitchVariation, 0.5, 2.0)
    sound.Looped = if customOptions and customOptions.Looped ~= nil then customOptions.Looped else (soundDef.Looped or false)

    if targetPositionOrPart then
        if typeof(targetPositionOrPart) == "Vector3" then
            local attachment = Instance.new("Attachment")
            attachment.WorldPosition = targetPositionOrPart
            attachment.Parent = Workspace.Terrain
            sound.Parent = attachment
            
            sound.Ended:Connect(function()
                attachment:Destroy()
            end)
        elseif typeof(targetPositionOrPart) == "Instance" then
            sound.Parent = targetPositionOrPart
        end
    else
        sound.Parent = soundFolder
    end

    sound:Play()

    if not sound.Looped then
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
        -- Hard cleanup failsafe
        Debris:AddItem(sound, 8)
    else
        activeLoops[soundName] = sound
    end

    return sound
end

function EffectsController:StopSound(soundName: string)
    local active = activeLoops[soundName]
    if active then
        active:Stop()
        active:Destroy()
        activeLoops[soundName] = nil
    end
end

function EffectsController:PlayButtonClick()
    self:PlaySound("ButtonClick")
end

function EffectsController:PlayCreditSound()
    self:PlaySound("CashRegister")
end

function EffectsController:PlayTaskSuccess(taskType: string, position: Vector3?)
    self:PlaySound("TaskComplete", position)
    if position then
        self:EmitTaskSuccess(position)
    end
end

function EffectsController:PlayDisasterAudio(disasterId: string, status: string)
    if status == Constants.DisasterStatus.TELEGRAPH then
        self:PlaySound("DisasterTelegraph")
    elseif status == Constants.DisasterStatus.ACTIVE then
        self:PlaySound("DisasterActive")
        if disasterId == Constants.Disasters.RUNAWAY_CARTS then
            self:PlaySound("CartRattle", nil, { Looped = true })
        elseif disasterId == Constants.Disasters.BLACKOUT then
            self:PlaySound("Sparks")
        end
    elseif status == Constants.DisasterStatus.COMPLETED or status == Constants.DisasterStatus.CANCELLED then
        self:StopSound("CartRattle")
        self:PlaySound("DisasterCleared")
    end
end

-- ====================================================================
-- PROCEDURAL PARTICLES
-- ====================================================================

-- Bursts celebratory stars / sparkles at completed task location
function EffectsController:EmitTaskSuccess(worldPosition: Vector3)
    local attachment = Instance.new("Attachment")
    attachment.WorldPosition = worldPosition + Vector3.new(0, 1.5, 0)
    attachment.Parent = Workspace.Terrain

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "TaskSuccessSparkles"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 80)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(50, 255, 150)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
    })
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.4),
        NumberSequenceKeypoint.new(0.5, 1.2),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.8, 0.2),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Speed = NumberRange.new(4, 9)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Lifetime = NumberRange.new(0.6, 1.2)
    emitter.Rate = 0
    emitter.LightEmission = 0.8
    emitter.Parent = attachment

    emitter:Emit(25)
    Debris:AddItem(attachment, 1.5)
end

-- Attaches gentle bubbles to spill areas
function EffectsController:CreateSpillBubbles(parentPart: BasePart): ParticleEmitter
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "SpillBubbles"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Color = ColorSequence.new(Color3.fromRGB(130, 225, 255), Color3.fromRGB(80, 190, 240))
    emitter.Size = NumberSequence.new(0.3, 0.8)
    emitter.Transparency = NumberSequence.new(0.2, 0.8)
    emitter.Lifetime = NumberRange.new(1.0, 2.0)
    emitter.Speed = NumberRange.new(1.5, 3.5)
    emitter.Rate = 8
    emitter.Acceleration = Vector3.new(0, 2, 0)
    emitter.Parent = parentPart
    return emitter
end

-- Attaches electrical spark bursts to breaker and maintenance panels
function EffectsController:CreateBreakerSparks(parentPart: BasePart): ParticleEmitter
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "BreakerSparks"
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Color = ColorSequence.new(Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 140, 20))
    emitter.Size = NumberSequence.new(0.2, 0.6)
    emitter.Speed = NumberRange.new(6, 14)
    emitter.SpreadAngle = Vector2.new(60, 60)
    emitter.Lifetime = NumberRange.new(0.2, 0.5)
    emitter.Rate = 12
    emitter.Acceleration = Vector3.new(0, -20, 0)
    emitter.LightEmission = 1.0
    emitter.Parent = parentPart
    return emitter
end

-- Attaches slippery foam particles for soap disaster
function EffectsController:CreateSoapFoam(parentPart: BasePart): ParticleEmitter
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "SoapFoam"
    emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
    emitter.Color = ColorSequence.new(Color3.fromRGB(240, 250, 255))
    emitter.Size = NumberSequence.new(0.6, 1.4)
    emitter.Transparency = NumberSequence.new(0.3, 0.9)
    emitter.Lifetime = NumberRange.new(1.0, 1.8)
    emitter.Speed = NumberRange.new(0.5, 1.5)
    emitter.Rate = 10
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Parent = parentPart
    return emitter
end

-- Attaches dust cloud puff for avalanche collapses
function EffectsController:CreateAvalancheDust(parentPart: BasePart): ParticleEmitter
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "AvalancheDust"
    emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
    emitter.Color = ColorSequence.new(Color3.fromRGB(190, 175, 160))
    emitter.Size = NumberSequence.new(1.5, 4.0)
    emitter.Transparency = NumberSequence.new(0.2, 1.0)
    emitter.Lifetime = NumberRange.new(1.2, 2.4)
    emitter.Speed = NumberRange.new(4, 10)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Rate = 20
    emitter.Parent = parentPart
    return emitter
end

-- ====================================================================
-- PROCEDURAL CHARACTER STUMBLES / PHYSICAL COMEDY (FR-12)
-- ====================================================================

-- Plays a temporary stumble/slip ragdoll reaction
function EffectsController:PlayStumbleReaction(duration: number, knockbackVelocity: Vector3?)
    local localPlayer = Players.LocalPlayer
    local character = localPlayer.Character
    if not character then
        return
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not humanoid or not rootPart then
        return
    end

    -- Trigger stumble sound & camera shock
    self:PlaySound("SlipStumble", rootPart.Position)
    local cameraCtrl = controllers["CameraController"]
    if cameraCtrl and typeof(cameraCtrl.TriggerShake) == "function" then
        cameraCtrl:TriggerShake(0.75)
    end

    -- Apply comedic knockback impulse
    if knockbackVelocity then
        rootPart.AssemblyLinearVelocity = knockbackVelocity
    else
        local randomImpulse = Vector3.new(
            math.random(-25, 25),
            math.random(15, 30),
            math.random(-25, 25)
        )
        rootPart.AssemblyLinearVelocity = randomImpulse
    end

    -- Ragdoll stumble state
    humanoid.PlatformStand = true

    local safeDuration = math.clamp(duration, 0.4, 2.5)
    task.delay(safeDuration, function()
        if humanoid and humanoid.Parent then
            humanoid.PlatformStand = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end

return EffectsController
