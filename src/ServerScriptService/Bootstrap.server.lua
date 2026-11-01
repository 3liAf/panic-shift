--!strict
--[[
    PANIC SHIFT: Bootstrap.server.lua
    Master server entry point. Sets up networking remotes, registers services,
    executes lifecycle phases (Init -> Start), and handles safe shutdown.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("PanicShiftShared")
local Network = require(Shared:WaitForChild("Network"))

print("[PanicShift Server] Starting server initialization...")

-- 1. Initialize Network Remotes Folder & Remote Instances
Network.InitServer()
print("[PanicShift Server] Network remotes initialized.")

-- 1.5 Ensure Supermarket Map Exists in Workspace
local mapBuilderMod = script.Parent:FindFirstChild("MapBuilder")
if mapBuilderMod and mapBuilderMod:IsA("ModuleScript") then
    local MapBuilder = require(mapBuilderMod)
    if typeof(MapBuilder.EnsureMap) == "function" then
        MapBuilder.EnsureMap()
    elseif typeof(MapBuilder.Build) == "function" then
        MapBuilder.Build()
    end
end

-- 2. Service Discovery and Dependency Order
local servicesFolder = script.Parent:WaitForChild("Services")

local serviceOrder = {
    "DataService",
    "AnalyticsService",
    "EconomyService",
    "InventoryService",
    "ChallengeService",
    "PurchaseService",
    "TaskService",
    "ToolService",
    "DisasterService",
    "RoundService",
    "BreakroomService",
}

local serviceRegistry: { [string]: any } = {}

-- Load each service module
for _, serviceName in ipairs(serviceOrder) do
    local serviceModule = servicesFolder:FindFirstChild(serviceName)
    if serviceModule and serviceModule:IsA("ModuleScript") then
        local success, serviceInstance = pcall(function()
            return require(serviceModule)
        end)

        if success and typeof(serviceInstance) == "table" then
            serviceRegistry[serviceName] = serviceInstance
        else
            error(string.format("[PanicShift Server] Critical failure loading %s: %s", serviceName, tostring(serviceInstance)))
        end
    else
        error(string.format("[PanicShift Server] Service %s not found in Services folder!", serviceName))
    end
end

-- 3. Execute Init Lifecycle
for _, serviceName in ipairs(serviceOrder) do
    local service = serviceRegistry[serviceName]
    if typeof(service.Init) == "function" then
        service:Init(serviceRegistry)
    end
end
print("[PanicShift Server] All services successfully initialized.")

-- 4. Execute Start Lifecycle
for _, serviceName in ipairs(serviceOrder) do
    local service = serviceRegistry[serviceName]
    if typeof(service.Start) == "function" then
        service:Start()
    end
end
print("[PanicShift Server] All services successfully started. Game is LIVE.")

-- 5. Safe Server Shutdown Hook
game:BindToClose(function()
    print("[PanicShift Server] Server shutdown detected. Performing final data persistence...")
    if serviceRegistry.RoundService then
        serviceRegistry.RoundService:CleanupRound()
    end
    if serviceRegistry.DataService then
        serviceRegistry.DataService:SaveAll()
    end
    task.wait(2.0)
    print("[PanicShift Server] Final shutdown persistence complete.")
end)
