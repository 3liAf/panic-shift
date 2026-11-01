--!strict
--[[
    PANIC SHIFT: MusicController.lua
    Client dynamic background music engine.
    Controls ambient retail muzak, pitch-shifting during Closing Rush,
    ducking during Blackouts, and smooth volume transitions.
]]

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("PanicShiftShared", 15) :: Folder
local Constants = require(Shared:WaitForChild("Constants"))
local Network = require(Shared:WaitForChild("Network"))

local MusicController = {
    Name = "MusicController",
}

local controllers: { [string]: any } = {}
local bgmSound: Sound? = nil
local currentBaseVolume = 0.32
local isMuted = false
local currentRoundState = "LOBBY"
local activeDisaster: string? = nil

-- Primary licensed APM retail track
local BGM_TRACK_ID = "rbxassetid://1837849285"

function MusicController:Init(controllerRegistry: { [string]: any })
    controllers = controllerRegistry

    local sound = Instance.new("Sound")
    sound.Name = "PanicShiftBGM"
    sound.SoundId = BGM_TRACK_ID
    sound.Volume = 0
    sound.PlaybackSpeed = 1.0
    sound.Looped = true
    sound.Parent = SoundService
    bgmSound = sound
end

function MusicController:Start()
    if not bgmSound then return end
    bgmSound:Play()

    -- Fade in ambient music
    TweenService:Create(bgmSound, TweenInfo.new(2.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Volume = currentBaseVolume
    }):Play()

    -- Hook round state changes
    local roundRemote = Network.GetRemoteEvent(Constants.Remotes.ROUND_STATE_CHANGED)
    roundRemote.OnClientEvent:Connect(function(state: string)
        self:OnRoundStateChanged(state)
    end)

    -- Hook disaster state changes
    local disasterRemote = Network.GetRemoteEvent(Constants.Remotes.DISASTER_STATE_CHANGED)
    disasterRemote.OnClientEvent:Connect(function(disasterId: string, status: string)
        self:OnDisasterStateChanged(disasterId, status)
    end)

    print("[PanicShift MusicController] Ambient retail soundtrack online and reactive.")
end

function MusicController:OnRoundStateChanged(state: string)
    currentRoundState = state
    self:ApplyAudioState()
end

function MusicController:OnDisasterStateChanged(disasterId: string, status: string)
    if status == Constants.DisasterStatus.ACTIVE then
        activeDisaster = disasterId
    elseif status == Constants.DisasterStatus.COMPLETED or status == Constants.DisasterStatus.CANCELLED then
        if activeDisaster == disasterId then
            activeDisaster = nil
        end
    end
    self:ApplyAudioState()
end

function MusicController:ApplyAudioState()
    if not bgmSound or isMuted then return end

    local targetVol = currentBaseVolume
    local targetSpeed = 1.0

    if activeDisaster == Constants.Disasters.BLACKOUT then
        -- Power outage: duck volume and slow playback
        targetVol = 0.08
        targetSpeed = 0.72
    elseif currentRoundState == Constants.RoundStates.CLOSING then
        -- Closing Rush: high energy up-tempo urgency
        targetVol = currentBaseVolume * 1.25
        targetSpeed = 1.15
    elseif currentRoundState == Constants.RoundStates.RESULTS then
        -- Shift ended: gentle quiet background
        targetVol = currentBaseVolume * 0.45
        targetSpeed = 1.0
    end

    TweenService:Create(bgmSound, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Volume = targetVol,
        PlaybackSpeed = targetSpeed,
    }):Play()
end

function MusicController:SetMuted(muted: boolean)
    isMuted = muted
    if not bgmSound then return end
    if muted then
        bgmSound.Volume = 0
    else
        self:ApplyAudioState()
    end
end

function MusicController:SetVolume(vol: number)
    currentBaseVolume = math.clamp(vol, 0, 1)
    self:ApplyAudioState()
end

function MusicController:GetSoundInstance(): Sound?
    return bgmSound
end

return MusicController
