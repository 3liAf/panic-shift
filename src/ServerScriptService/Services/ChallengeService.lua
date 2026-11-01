--!strict
--[[
    PANIC SHIFT: ChallengeService.lua
    Manages daily challenge rotation, tracking, and objective completion.
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")
local Types = require(Shared:WaitForChild("Types"))
local Config = require(Shared:WaitForChild("Config"))

local ChallengeService = {
    Name = "ChallengeService",
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

function ChallengeService:Init(serviceRegistry: { [string]: any })
    services = serviceRegistry
end

function ChallengeService:Start()
    -- Daily challenge tracking ready
end

-- Checks and resets daily challenge data if day has rolled over
function ChallengeService:VerifyDailyReset(player: Player): ()
    local dataService = getService("DataService")
    if not dataService then
        return
    end

    local currentKey = os.date("!%Y-%m-%d")
    dataService:UpdateProfile(player, function(profile: Types.PlayerProfile)
        if profile.dailyChallenges.resetKey ~= currentKey then
            profile.dailyChallenges = {
                resetKey = currentKey,
                completed = {},
                progress = {},
            }
        end
    end)
end

-- Increments challenge progress for a specific target action
function ChallengeService:IncrementProgress(player: Player, challengeId: string, amount: number): ()
    local dataService = getService("DataService")
    local economyService = getService("EconomyService")
    if not dataService or not economyService then
        return
    end

    self:VerifyDailyReset(player)

    local profile = dataService:GetProfile(player)
    if not profile or profile.dailyChallenges.completed[challengeId] then
        return
    end

    -- Find challenge definition
    local challengeDef = nil
    for _, def in ipairs(Config.DailyChallenges) do
        if def.Id == challengeId then
            challengeDef = def
            break
        end
    end

    if not challengeDef then
        return
    end

    dataService:UpdateProfile(player, function(prof: Types.PlayerProfile)
        local current = (prof.dailyChallenges.progress[challengeId] or 0) + amount
        prof.dailyChallenges.progress[challengeId] = current

        if current >= challengeDef.TargetCount and not prof.dailyChallenges.completed[challengeId] then
            prof.dailyChallenges.completed[challengeId] = true
            economyService:AwardCredits(player, challengeDef.CreditReward, "DailyChallenge_" .. challengeId)
            economyService:AwardXp(player, challengeDef.XpReward, "DailyChallenge_" .. challengeId)
        end
    end)
end

return ChallengeService
