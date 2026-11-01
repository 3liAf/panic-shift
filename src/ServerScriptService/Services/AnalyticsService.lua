--!strict
--[[
    PANIC SHIFT: AnalyticsService.lua
    Server-side telemetry and event logging for gameplay funnels,
    retention indicators, balancing metrics, and official BadgeService dispatch.
]]

local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")
local Config = require(Shared:WaitForChild("Config"))

local AnalyticsService = {
    Name = "AnalyticsService",
}

local services: { [string]: any } = {}
local eventLog: { { Timestamp: number, Event: string, Params: { [string]: any } } } = {}
local awardedBadgeCache: { [number]: { [string]: boolean } } = {}

function AnalyticsService:Init(serviceRegistry: { [string]: any })
    services = serviceRegistry
end

function AnalyticsService:Start()
    print("[PanicShift AnalyticsService] Initialized telemetry pipeline & Badge dispatcher.")
end

-- Records a structured telemetry event
function AnalyticsService:LogEvent(eventName: string, params: { [string]: any }): ()
    local entry = {
        Timestamp = os.time(),
        Event = eventName,
        Params = params or {},
    }

    table.insert(eventLog, entry)
    
    -- Print structured telemetry for development/debugging
    local details = ""
    for k, v in pairs(entry.Params) do
        details = details .. string.format(" %s=%s", tostring(k), tostring(v))
    end
    print(string.format("[Telemetry] %s:%s", eventName, details))

    -- Keep memory footprint capped
    if #eventLog > 500 then
        table.remove(eventLog, 1)
    end
end

-- Authoritative badge dispatcher with safe fallbacks and caching
function AnalyticsService:AwardBadge(player: Player, badgeKey: string): ()
    local badgeDef = Config.Badges and Config.Badges[badgeKey]
    if not badgeDef then
        return
    end

    if not awardedBadgeCache[player.UserId] then
        awardedBadgeCache[player.UserId] = {}
    end

    if awardedBadgeCache[player.UserId][badgeKey] then
        return
    end

    awardedBadgeCache[player.UserId][badgeKey] = true

    if not badgeDef.BadgeId or badgeDef.BadgeId <= 0 then
        -- In Studio or pre-release testing with placeholder IDs
        self:LogEvent("BadgeAwardedMock", {
            PlayerId = player.UserId,
            BadgeKey = badgeKey,
            BadgeName = badgeDef.Name,
        })
        return
    end

    task.spawn(function()
        local success, err = pcall(function()
            return BadgeService:AwardBadge(player.UserId, badgeDef.BadgeId)
        end)
        if success then
            self:LogEvent("BadgeAwarded", {
                PlayerId = player.UserId,
                BadgeId = badgeDef.BadgeId,
                BadgeKey = badgeKey,
            })
        else
            warn(string.format("[AnalyticsService] Failed to award badge %s: %s", badgeKey, tostring(err)))
        end
    end)
end

return AnalyticsService
