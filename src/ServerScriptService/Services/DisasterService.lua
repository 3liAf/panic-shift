--!strict
--[[
    PANIC SHIFT: DisasterService.lua
    The Disaster Director. Manages disaster weighted selection, telegraph countdowns,
    module lifecycle execution, and guaranteed fail-safe cleanup.
]]

local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")
local Types = require(Shared:WaitForChild("Types"))
local Config = require(Shared:WaitForChild("Config"))
local Constants = require(Shared:WaitForChild("Constants"))
local Network = require(Shared:WaitForChild("Network"))

local DisasterService = {
    Name = "DisasterService",
}

local services: { [string]: any } = {}
local disasterModules: { [string]: any } = {}
local activeDisasterId: string? = nil
local activeDisasterModule: any = nil
local activeDisasterContext: Types.DisasterContext? = nil
local disasterStopThread: thread? = nil

function DisasterService:Init(serviceRegistry: { [string]: any })
    services = serviceRegistry

    -- Dynamically locate and register disaster modules
    local storageFolder = ServerStorage:FindFirstChild("PanicShiftStorage")
    local modulesFolder = storageFolder and storageFolder:FindFirstChild("DisasterModules") or ServerStorage:FindFirstChild("DisasterModules")

    if modulesFolder then
        for _, child in ipairs(modulesFolder:GetChildren()) do
            if child:IsA("ModuleScript") then
                local success, disasterMod = pcall(function()
                    return require(child)
                end)
                if success and typeof(disasterMod) == "table" then
                    disasterModules[child.Name] = disasterMod
                else
                    warn(string.format("[PanicShift DisasterService] Failed to load module %s", child.Name))
                end
            end
        end
    end
end

function DisasterService:Start()
    -- Ready for shift disasters
end

-- Weighted random selection of the next disaster
function DisasterService:SelectNextDisaster(): string?
    local eligible: { { id: string, weight: number } } = {}
    local totalWeight = 0

    for id, weight in pairs(Config.Disasters.Weights) do
        -- Exclude currently active disaster
        if id ~= activeDisasterId and disasterModules[id] then
            local mod = disasterModules[id]
            local canStart = true
            if typeof(mod.CanStart) == "function" then
                canStart = mod.CanStart()
            end
            if canStart then
                table.insert(eligible, { id = id, weight = weight })
                totalWeight = totalWeight + weight
            end
        end
    end

    if totalWeight <= 0 or #eligible == 0 then
        return nil
    end

    local roll = math.random(1, totalWeight)
    local accumulated = 0
    for _, item in ipairs(eligible) do
        accumulated = accumulated + item.weight
        if roll <= accumulated then
            return item.id
        end
    end

    return eligible[1].id
end

-- Initiates a disaster event with telegraphing and scheduled cleanup
function DisasterService:TriggerDisaster(disasterId: string, customDuration: number?): boolean
    if activeDisasterId then
        self:StopActiveDisaster()
    end

    local mod = disasterModules[disasterId]
    if not mod then
        warn(string.format("[PanicShift DisasterService] Disaster module '%s' not registered!", disasterId))
        return false
    end

    local duration = customDuration or Config.Disasters.Durations[disasterId] or 25
    local telegraphDuration = Config.Disasters.TelegraphDuration

    local context: Types.DisasterContext = {
        RoundId = services.RoundService and services.RoundService:GetCurrentRoundId() or "DevShift",
        Duration = duration,
        SupermarketMap = (services.RoundService and services.RoundService:GetSupermarketMap()) or workspace:FindFirstChild("SupermarketMap") or workspace,
        Services = services,
        TelegraphDuration = telegraphDuration,
    }

    activeDisasterId = disasterId
    activeDisasterModule = mod
    activeDisasterContext = context

    -- Broadcast telegraph warning
    local remote = Network.GetRemoteEvent(Constants.Remotes.DISASTER_STATE_CHANGED)
    remote:FireAllClients(disasterId, Constants.DisasterStatus.TELEGRAPH, telegraphDuration, {
        Duration = duration,
    })

    if services.AnalyticsService then
        services.AnalyticsService:LogEvent("DisasterTelegraph", { DisasterId = disasterId })
    end

    -- Run disaster execution in a dedicated task thread
    disasterStopThread = task.spawn(function()
        task.wait(telegraphDuration)

        if activeDisasterId ~= disasterId then
            return -- Was cancelled during telegraph
        end

        remote:FireAllClients(disasterId, Constants.DisasterStatus.ACTIVE, duration, {})

        -- Protected start execution
        local startOk, startErr = pcall(function()
            if typeof(mod.Start) == "function" then
                mod.Start(context)
            end
        end)

        if not startOk then
            warn(string.format("[PanicShift DisasterService] Disaster %s Start() errored: %s", disasterId, tostring(startErr)))
        end

        task.wait(duration)

        -- Natural expiration
        if activeDisasterId == disasterId then
            self:StopActiveDisaster()
        end
    end)

    return true
end

-- Guaranteed safe cleanup of active disaster
function DisasterService:StopActiveDisaster(): ()
    if not activeDisasterId then
        return
    end

    local currentId = activeDisasterId
    local currentMod = activeDisasterModule
    local currentCtx = activeDisasterContext

    if disasterStopThread then
        local threadToCancel = disasterStopThread
        disasterStopThread = nil
        if threadToCancel ~= coroutine.running() then
            pcall(task.cancel, threadToCancel)
        end
    end

    activeDisasterId = nil
    activeDisasterModule = nil
    activeDisasterContext = nil

    if currentMod and typeof(currentMod.Stop) == "function" then
        local ok, err = pcall(function()
            currentMod.Stop(currentCtx)
        end)
        if not ok then
            warn(string.format("[PanicShift DisasterService] Error during %s Stop(): %s", currentId, tostring(err)))
        end
    end

    local remote = Network.GetRemoteEvent(Constants.Remotes.DISASTER_STATE_CHANGED)
    remote:FireAllClients(currentId, Constants.DisasterStatus.COMPLETED, 0, {})

    if services.AnalyticsService then
        services.AnalyticsService:LogEvent("DisasterEnded", { DisasterId = currentId })
    end
end

function DisasterService:IsDisasterActive(): boolean
    return activeDisasterId ~= nil
end

return DisasterService
