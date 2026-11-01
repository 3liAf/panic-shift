--!strict
--[[
    PANIC SHIFT: RoundService.lua
    Authoritative round lifecycle state machine. Manages lobby wait,
    preparation countdown, main shift quotas, closing rush, results, and resets.
    Strictly validates allowed state transitions and manages player teleportation.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")
local Types = require(Shared:WaitForChild("Types"))
local Config = require(Shared:WaitForChild("Config"))
local Constants = require(Shared:WaitForChild("Constants"))
local Utility = require(Shared:WaitForChild("Utility"))
local Network = require(Shared:WaitForChild("Network"))

local RoundService = {
    Name = "RoundService",
}

local services: { [string]: any } = {}
local currentState: Types.RoundState = "LOBBY"
local currentRoundId: string = ""
local stateTimer: number = 0
local currentQuota: number = 0
local targetQuota: number = 0
local playerContributions: { [number]: { TasksCompleted: number, CreditsEarned: number, XpEarned: number } } = {}
local disasterTimer: number = 0
local nextDisasterInterval: number = 35

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

-- State Transition Validation Matrix (FR-02)
local VALID_TRANSITIONS: { [Types.RoundState]: { [Types.RoundState]: boolean } } = {
    LOBBY = { PREPARATION = true },
    PREPARATION = { ACTIVE = true, LOBBY = true },
    ACTIVE = { CLOSING = true, LOBBY = true },
    CLOSING = { RESULTS = true, LOBBY = true },
    RESULTS = { RESET = true, LOBBY = true },
    RESET = { LOBBY = true },
}

function RoundService:Init(serviceRegistry: { [string]: any })
    services = serviceRegistry
end

function RoundService:Start()
    currentRoundId = Utility.GenerateUUID()
    self:ForceState("LOBBY")

    -- Engine-authoritative heartbeat clock tick loop
    local accumulated = 0
    RunService.Heartbeat:Connect(function(dt: number)
        accumulated = accumulated + dt
        if accumulated >= 1.0 then
            accumulated = accumulated - 1.0
            local ok, err = pcall(function()
                self:Tick(1.0)
            end)
            if not ok then
                warn(string.format("[RoundService Tick Error]: %s", tostring(err)))
            end
        end
    end)
end

function RoundService:GetCurrentRoundId(): string
    return currentRoundId
end

function RoundService:GetState(): Types.RoundState
    return currentState
end

function RoundService:GetTimerRemaining(): number
    return stateTimer
end

function RoundService:GetQuotaProgress(): (number, number)
    return currentQuota, targetQuota
end

function RoundService:GetSupermarketMap(): Model?
    return workspace:FindFirstChild("SupermarketMap") :: Model?
end

-- Teleports players to a target location
local function teleportAllPlayers(targetCFrame: CFrame)
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character and character.PrimaryPart then
            character:PivotTo(targetCFrame + Vector3.new(math.random(-4, 4), 0, math.random(-4, 4)))
        end
    end
end

-- Unconditionally forces a state (used for initial startup or hard reset)
function RoundService:ForceState(newState: Types.RoundState)
    currentState = newState
    self:ApplyStateLogic(newState)
end

-- Validates and applies state transition (rejects invalid transitions)
function RoundService:SetState(newState: Types.RoundState): boolean
    if currentState == newState then
        return true
    end

    local allowed = VALID_TRANSITIONS[currentState]
    if not allowed or not allowed[newState] then
        warn(string.format("[RoundService] INVALID STATE TRANSITION REJECTED: %s -> %s", currentState, newState))
        return false
    end

    currentState = newState
    self:ApplyStateLogic(newState)
    return true
end

function RoundService:ApplyStateLogic(newState: Types.RoundState)
    if newState == "LOBBY" then
        stateTimer = Config.RoundTimers.LOBBY_DURATION
        currentQuota = 0
        targetQuota = 0
        table.clear(playerContributions)

    elseif newState == "PREPARATION" then
        stateTimer = Config.RoundTimers.PREPARATION_DURATION
        currentRoundId = Utility.GenerateUUID()
        table.clear(playerContributions)

        local playerCount = math.max(1, #Players:GetPlayers())
        targetQuota = Config.QuotaConfig.BASE_QUOTA + (playerCount * Config.QuotaConfig.QUOTA_PER_PLAYER)
        currentQuota = 0

        disasterTimer = 0
        nextDisasterInterval = math.random(Config.Disasters.IntervalMin, Config.Disasters.IntervalMax)

        -- Populate initial tasks on supermarket floor
        local taskService = getService("TaskService")
        if taskService then
            taskService:PopulateInitialTasks()
        end

        -- Teleport players to store entrance
        teleportAllPlayers(CFrame.new(0, 3, -35))

    elseif newState == "ACTIVE" then
        stateTimer = Config.RoundTimers.MAIN_SHIFT_DURATION

    elseif newState == "CLOSING" then
        stateTimer = Config.RoundTimers.CLOSING_RUSH_DURATION

    elseif newState == "RESULTS" then
        stateTimer = Config.RoundTimers.RESULTS_DURATION
        self:ProcessRoundResults()

    elseif newState == "RESET" then
        stateTimer = Config.RoundTimers.RESET_DURATION
        self:CleanupRound()
        -- Teleport players back to Lobby
        teleportAllPlayers(CFrame.new(0, 3, -65))
    end

    self:BroadcastState()

    local analyticsService = getService("AnalyticsService")
    if analyticsService then
        analyticsService:LogEvent("RoundStateChanged", {
            State = newState,
            RoundId = currentRoundId,
        })
    end
end

-- Broadcasts synchronized round state to all connected clients
function RoundService:BroadcastState()
    local remote = Network.GetRemoteEvent(Constants.Remotes.ROUND_STATE_CHANGED)
    remote:FireAllClients(currentState, stateTimer, currentQuota, targetQuota)
end

-- Master authoritative clock tick
function RoundService:Tick(deltaTime: number)
    local players = Players:GetPlayers()
    local playerCount = #players

    if currentState == "LOBBY" then
        if playerCount >= Config.ServerConfig.MIN_PLAYERS_TO_START then
            stateTimer = math.max(0, stateTimer - deltaTime)
            if stateTimer <= 0 then
                self:SetState("PREPARATION")
            end
        else
            stateTimer = Config.RoundTimers.LOBBY_DURATION
        end

    elseif currentState == "PREPARATION" then
        stateTimer = math.max(0, stateTimer - deltaTime)
        if stateTimer <= 0 then
            self:SetState("ACTIVE")
        end

    elseif currentState == "ACTIVE" then
        stateTimer = math.max(0, stateTimer - deltaTime)

        -- Keep active tasks replenished if they run low
        local taskService = getService("TaskService")
        if taskService and taskService:GetActiveTaskCount() < 4 then
            local map = self:GetSupermarketMap()
            local taskAnchors = map and map:FindFirstChild("TaskAnchors")
            if taskAnchors then
                local children = taskAnchors:GetChildren()
                if #children > 0 then
                    local randomAnchor = children[math.random(1, #children)]
                    if randomAnchor:IsA("BasePart") then
                        local taskTypes = { "CLEAN_SPILL", "RESTOCK", "DELIVER_ORDER", "RETURN_CART", "EXTINGUISH_FIRE" }
                        local pickedType = taskTypes[math.random(1, #taskTypes)]
                        taskService:CreateTask(pickedType, randomAnchor.Position, randomAnchor)
                    end
                end
            end
        end

        -- Check disaster interval
        disasterTimer = disasterTimer + deltaTime
        if disasterTimer >= nextDisasterInterval then
            disasterTimer = 0
            nextDisasterInterval = math.random(Config.Disasters.IntervalMin, Config.Disasters.IntervalMax)
            local disasterService = getService("DisasterService")
            if disasterService and not disasterService:IsDisasterActive() then
                local nextDisaster = disasterService:SelectNextDisaster()
                if nextDisaster then
                    disasterService:TriggerDisaster(nextDisaster)
                end
            end
        end

        if stateTimer <= 0 then
            self:SetState("CLOSING")
        end

    elseif currentState == "CLOSING" then
        stateTimer = math.max(0, stateTimer - deltaTime)
        if stateTimer <= 0 or currentQuota >= targetQuota then
            self:SetState("RESULTS")
        end

    elseif currentState == "RESULTS" then
        stateTimer = math.max(0, stateTimer - deltaTime)
        if stateTimer <= 0 then
            self:SetState("RESET")
        end

    elseif currentState == "RESET" then
        stateTimer = math.max(0, stateTimer - deltaTime)
        if stateTimer <= 0 then
            self:SetState("LOBBY")
        end
    end

    self:BroadcastState()
end

-- Tracks team quota points and individual contribution
function RoundService:AddQuotaProgress(points: number, contributingPlayer: Player?)
    local multiplier = (currentState == "CLOSING") and Config.QuotaConfig.CLOSING_RUSH_MULTIPLIER or 1.0
    local awardedPoints = math.floor(points * multiplier)

    currentQuota = currentQuota + awardedPoints

    if contributingPlayer then
        local userId = contributingPlayer.UserId
        if not playerContributions[userId] then
            playerContributions[userId] = { TasksCompleted = 0, CreditsEarned = 0, XpEarned = 0 }
        end
        playerContributions[userId].TasksCompleted = playerContributions[userId].TasksCompleted + 1
    end

    self:BroadcastState()
end

-- Distributes end-of-shift rewards and produces results screen data
function RoundService:ProcessRoundResults()
    local isSuccess = currentQuota >= targetQuota
    local teamBonus = isSuccess and 50 or 15

    local mvpPlayerId: number? = nil
    local maxTasks = -1

    for userId, stats in pairs(playerContributions) do
        if stats.TasksCompleted > maxTasks then
            maxTasks = stats.TasksCompleted
            mvpPlayerId = userId
        end
    end

    local individualSummary: { [number]: any } = {}

    for _, player in ipairs(Players:GetPlayers()) do
        local stats = playerContributions[player.UserId] or { TasksCompleted = 0, CreditsEarned = 0, XpEarned = 0 }
        local isMvp = (player.UserId == mvpPlayerId) and (stats.TasksCompleted > 0)
        local finalCredits = teamBonus + (isMvp and 25 or 0)
        local finalXp = isSuccess and 60 or 20

        local economyService = getService("EconomyService")
        if economyService then
            economyService:AwardCredits(player, finalCredits, "ShiftResultBonus")
            economyService:AwardXp(player, finalXp, "ShiftResultBonus")
        end

        -- Lifetime stats & Badges
        local dataService = getService("DataService")
        local analyticsService = getService("AnalyticsService")
        if dataService and analyticsService then
            local shiftsDone = dataService:IncrementStat(player, "shiftsCompleted", 1)
            if shiftsDone >= 1 then
                analyticsService:AwardBadge(player, "FIRST_SHIFT")
            end
            if isMvp then
                analyticsService:AwardBadge(player, "SHIFT_MVP")
            end
            if isSuccess then
                dataService:IncrementStat(player, "shiftsWon", 1)
                if currentQuota >= targetQuota then
                    analyticsService:AwardBadge(player, "CHAOS_SURVIVOR")
                end
            end
        end

        individualSummary[player.UserId] = {
            PlayerName = player.Name,
            TasksCompleted = stats.TasksCompleted,
            CreditsEarned = finalCredits,
            XpEarned = finalXp,
            IsMvp = isMvp,
        }
    end

    local resultsPayload: Types.RoundResultsData = {
        Success = isSuccess,
        ShiftName = "Night Shift #" .. string.sub(currentRoundId, -4),
        QuotaReached = currentQuota,
        QuotaTarget = targetQuota,
        DurationSeconds = Config.RoundTimers.MAIN_SHIFT_DURATION + Config.RoundTimers.CLOSING_RUSH_DURATION - stateTimer,
        TeamBonusCredits = teamBonus,
        IndividualStats = individualSummary,
    }

    local remote = Network.GetRemoteEvent(Constants.Remotes.ROUND_RESULTS)
    remote:FireAllClients(resultsPayload)

    print(string.format("[RoundService] Shift %s concluded! Outcome: %s. Quota: %d/%d", resultsPayload.ShiftName, isSuccess and "SURVIVED" or "FAILED", currentQuota, targetQuota))
end

-- Teardown of round instances
function RoundService:CleanupRound()
    local disasterService = getService("DisasterService")
    if disasterService then
        disasterService:StopActiveDisaster()
    end
    local taskService = getService("TaskService")
    if taskService then
        taskService:ClearAllTasks()
    end
end

return RoundService
