--!strict
--[[
    PANIC SHIFT: DataService.lua
    Authoritative player data persistence. Implements schema versioning,
    session caching, exponential backoff retries, corruption prevention,
    and an in-memory mock store for safe Studio and offline testing.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")
local Types = require(Shared:WaitForChild("Types"))
local Utility = require(Shared:WaitForChild("Utility"))
local Network = require(Shared:WaitForChild("Network"))
local Constants = require(Shared:WaitForChild("Constants"))

local DATA_STORE_NAME = "PanicShift_PlayerData_v1"
local CURRENT_SCHEMA_VERSION = 1

local DataService = {
    Name = "DataService",
}

local services: { [string]: any } = {}
local profiles: { [Player]: Types.PlayerProfile } = {}
local failedLoads: { [Player]: boolean } = {}
local playerDataStore: any = nil
local mockDataStore: { [string]: any } = {} -- Safe mock store for Studio/Test mode

-- Constructs the default player profile
function DataService.CreateDefaultProfile(): Types.PlayerProfile
    return {
        schemaVersion = CURRENT_SCHEMA_VERSION,
        credits = 0,
        xp = 0,
        level = 1,
        ownedCosmetics = { "default_uniform" },
        equippedCosmetic = "default_uniform",
        equippedHat = nil,
        lifetimeStats = {
            shiftsCompleted = 0,
            shiftsWon = 0,
            tasksCompleted = 0,
            disastersSurvives = 0,
            spillsCleaned = 0,
            ordersDelivered = 0,
        },
        dailyChallenges = {
            resetKey = os.date("!%Y-%m-%d"),
            completed = {},
            progress = {},
        },
        settings = {
            musicVolume = 0.8,
            sfxVolume = 0.9,
            screenShake = true,
        },
    }
end

-- Migrates data between schema versions safely (FR-18)
function DataService.MigrateProfile(data: any): Types.PlayerProfile
    if typeof(data) ~= "table" then
        return DataService.CreateDefaultProfile()
    end

    local profile = Utility.DeepCopy(data) :: Types.PlayerProfile

    -- Version 0 -> Version 1 upgrade
    if not profile.schemaVersion or profile.schemaVersion < 1 then
        profile.schemaVersion = 1
        profile.credits = profile.credits or 0
        profile.xp = profile.xp or 0
        profile.level = profile.level or 1
        profile.ownedCosmetics = profile.ownedCosmetics or { "default_uniform" }
        profile.equippedCosmetic = profile.equippedCosmetic or "default_uniform"
        profile.lifetimeStats = profile.lifetimeStats or {
            shiftsCompleted = 0,
            shiftsWon = 0,
            tasksCompleted = 0,
            disastersSurvives = 0,
            spillsCleaned = 0,
            ordersDelivered = 0,
        }
        profile.dailyChallenges = profile.dailyChallenges or {
            resetKey = os.date("!%Y-%m-%d"),
            completed = {},
            progress = {},
        }
        profile.settings = profile.settings or {
            musicVolume = 0.8,
            sfxVolume = 0.9,
            screenShake = true,
        }
    end

    return profile
end

function DataService:Init(serviceRegistry: { [string]: any })
    services = serviceRegistry

    if RunService:IsStudio() then
        local studioAccessEnabled = false
        pcall(function()
            local testStore = DataStoreService:GetDataStore("__test_studio_access__")
            testStore:GetAsync("__ping__")
            studioAccessEnabled = true
        end)

        if studioAccessEnabled then
            playerDataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)
            print("[PanicShift DataService] Studio API Access active; connected to live DataStore.")
        else
            playerDataStore = nil
            print("[PanicShift DataService] Operating with In-Memory Mock Store.")
        end
    else
        local success, store = pcall(function()
            return DataStoreService:GetDataStore(DATA_STORE_NAME)
        end)

        if success and store then
            playerDataStore = store
            print("[PanicShift DataService] Successfully connected to live DataStoreService.")
        else
            warn("[PanicShift DataService] DataStoreService unavailable. Operating with In-Memory Mock Store.")
        end
    end
end

function DataService:Start()
    -- Profile loading on player join
    Players.PlayerAdded:Connect(function(player: Player)
        self:LoadProfile(player)
    end)

    -- Handle players already connected (e.g. in Studio Play Solo or fast connect)
    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            self:LoadProfile(player)
        end)
    end

    -- RemoteFunction for on-demand client profile retrieval
    local reqProfileFunc = Network.GetRemoteFunction(Constants.Remotes.REQUEST_PLAYER_PROFILE)
    reqProfileFunc.OnServerInvoke = function(player: Player): Types.PlayerProfile?
        local profile = self:GetProfile(player)
        if not profile then
            profile = self:LoadProfile(player)
        end
        return profile
    end

    -- Profile saving on player disconnect
    Players.PlayerRemoving:Connect(function(player: Player)
        self:SaveProfile(player)
        profiles[player] = nil
        failedLoads[player] = nil
    end)
end

function DataService:LoadProfile(player: Player): Types.PlayerProfile?
    local key = string.format("Player_%d", player.UserId)
    local loadedData: any = nil

    if playerDataStore then
        local readSuccess, result = Utility.RetryWithBackoff(3, 1.0, function()
            local s, res = pcall(function()
                return playerDataStore:GetAsync(key)
            end)
            return s, res
        end)

        if readSuccess then
            loadedData = result
        else
            warn(string.format("[PanicShift DataService] Failed to load data for %s (UserId: %d). Enabling safe read-only fallback.", player.Name, player.UserId))
            failedLoads[player] = true
            profiles[player] = DataService.CreateDefaultProfile()
            self:SyncClient(player)
            return profiles[player]
        end
    else
        -- Read from safe local mock store
        loadedData = mockDataStore[key]
    end

    local finalProfile: Types.PlayerProfile
    if loadedData then
        finalProfile = DataService.MigrateProfile(loadedData)
    else
        finalProfile = DataService.CreateDefaultProfile()
    end

    profiles[player] = finalProfile
    self:SyncClient(player)
    return finalProfile
end

function DataService:SaveProfile(player: Player): boolean
    -- Critical Guard: Never overwrite data if initial load failed (FR-16 / NFR-04)
    if failedLoads[player] then
        warn(string.format("[PanicShift DataService] Save aborted for %s: initial profile read had failed. Preventing corruption overwrite.", player.Name))
        return false
    end

    local profile = profiles[player]
    if not profile then
        return false
    end

    local key = string.format("Player_%d", player.UserId)

    if playerDataStore then
        local writeSuccess = Utility.RetryWithBackoff(3, 1.0, function()
            local s, err = pcall(function()
                playerDataStore:SetAsync(key, profile)
            end)
            if not s then
                warn("[PanicShift DataService] DataStore write error:", err)
            end
            return s, nil
        end)
        return writeSuccess
    else
        -- Save to local mock store
        mockDataStore[key] = Utility.DeepCopy(profile)
        return true
    end
end

function DataService:GetProfile(player: Player): Types.PlayerProfile?
    return profiles[player]
end

function DataService:UpdateProfile(player: Player, mutator: (profile: Types.PlayerProfile) -> ()): boolean
    local profile = profiles[player]
    if not profile then
        return false
    end

    mutator(profile)
    self:SyncClient(player)
    return true
end

function DataService:SyncClient(player: Player)
    local profile = profiles[player]
    if not profile then
        return
    end

    local success, remote = pcall(function()
        return Network.GetRemoteEvent(Constants.Remotes.PLAYER_PROFILE_UPDATED)
    end)
    if success and remote then
        remote:FireClient(player, profile)
    end
end

function DataService:IncrementStat(player: Player, statName: string, amount: number?): number
    local profile = profiles[player]
    if not profile then
        return 0
    end
    if not profile.lifetimeStats then
        profile.lifetimeStats = {
            shiftsCompleted = 0,
            shiftsWon = 0,
            tasksCompleted = 0,
            disastersSurvives = 0,
            spillsCleaned = 0,
            ordersDelivered = 0,
        }
    end
    local inc = amount or 1
    local stats = profile.lifetimeStats :: any
    local current = stats[statName] or 0
    local newVal = current + inc
    stats[statName] = newVal
    return newVal
end

function DataService:GetStat(player: Player, statName: string): number
    local profile = profiles[player]
    if not profile or not profile.lifetimeStats then
        return 0
    end
    local stats = profile.lifetimeStats :: any
    return stats[statName] or 0
end

function DataService:SaveAll()
    for _, player in ipairs(Players:GetPlayers()) do
        self:SaveProfile(player)
    end
end

-- Test helper methods for automated validation
function DataService._InjectMockFailure(player: Player)
    failedLoads[player] = true
end

function DataService._IsSaveBlocked(player: Player): boolean
    return failedLoads[player] == true
end

return DataService
