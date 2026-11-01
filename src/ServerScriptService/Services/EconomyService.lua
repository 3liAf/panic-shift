--!strict
--[[
    PANIC SHIFT: EconomyService.lua
    Server-authoritative wallet and progression manager.
    Enforces atomic credit/XP modifications, level scaling, and audit logging.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")
local Types = require(Shared:WaitForChild("Types"))
local Config = require(Shared:WaitForChild("Config"))

local MarketplaceService = game:GetService("MarketplaceService")

local EconomyService = {
    Name = "EconomyService",
}

local services: { [string]: any } = {}
local gamePassCache: { [number]: { [number]: boolean } } = {}

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

function EconomyService:Init(serviceRegistry: { [string]: any })
    services = serviceRegistry
end

function EconomyService:Start()
    -- Ready for shift operations
end

-- Checks if a player owns a specific GamePass with caching
function EconomyService:PlayerOwnsPass(player: Player, passId: number): boolean
    if passId <= 0 then return false end
    local pCache = gamePassCache[player.UserId]
    if pCache and pCache[passId] ~= nil then
        return pCache[passId]
    end
    local owns = false
    pcall(function()
        owns = MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
    end)
    if not gamePassCache[player.UserId] then
        gamePassCache[player.UserId] = {}
    end
    gamePassCache[player.UserId][passId] = owns
    return owns
end

-- Safely retrieves player wallet balance
function EconomyService:GetBalance(player: Player): number
    local dataService = getService("DataService")
    if not dataService then
        return 0
    end

    local profile = dataService:GetProfile(player)
    return profile and profile.credits or 0
end

-- Atomically awards credits with logging and GamePass multiplier support
function EconomyService:AwardCredits(player: Player, amount: number, reason: string): boolean
    if amount <= 0 then
        return false
    end

    local dataService = getService("DataService")
    if not dataService then
        return false
    end

    local finalAmount = amount
    if reason ~= "RobuxPurchase" and not string.find(reason, "Rollback") then
        local doublePass = Config.Monetization and Config.Monetization.GamePasses and Config.Monetization.GamePasses.DoubleCredits
        if doublePass and doublePass.PassId > 0 and self:PlayerOwnsPass(player, doublePass.PassId) then
            finalAmount = amount * 2
        end
    end

    return dataService:UpdateProfile(player, function(profile: Types.PlayerProfile)
        profile.credits = profile.credits + finalAmount
    end)
end

-- Atomically deducts credits with balance verification
function EconomyService:DeductCredits(player: Player, amount: number): boolean
    if amount <= 0 then
        return false
    end

    local dataService = getService("DataService")
    if not dataService then
        return false
    end

    local currentBalance = self:GetBalance(player)
    if currentBalance < amount then
        return false
    end

    return dataService:UpdateProfile(player, function(profile: Types.PlayerProfile)
        profile.credits = profile.credits - amount
    end)
end

-- Awards XP and evaluates progressive level-ups
function EconomyService:AwardXp(player: Player, amount: number, reason: string): (boolean, boolean)
    if amount <= 0 then
        return false, false
    end

    local dataService = getService("DataService")
    if not dataService then
        return false, false
    end

    local didLevelUp = false

    local updated = dataService:UpdateProfile(player, function(profile: Types.PlayerProfile)
        profile.xp = profile.xp + amount

        -- Check level up thresholds
        local nextLevelRequirement = Config.Progression.CalculateRequiredXp(profile.level)
        while profile.xp >= nextLevelRequirement do
            profile.xp = profile.xp - nextLevelRequirement
            profile.level = profile.level + 1
            didLevelUp = true
            nextLevelRequirement = Config.Progression.CalculateRequiredXp(profile.level)
        end
    end)

    local analyticsService = getService("AnalyticsService")
    if didLevelUp and analyticsService then
        local profile = dataService:GetProfile(player)
        analyticsService:LogEvent("PlayerLevelUp", {
            PlayerId = player.UserId,
            NewLevel = profile and profile.level or 1,
        })
    end

    return updated, didLevelUp
end

return EconomyService
