--!strict
--[[
    PANIC SHIFT: ClientBootstrap.client.lua
    Master client entry point. Waits for network remotes, loads controllers,
    and manages client startup lifecycle.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[PanicShift Client] Starting client initialization...")

-- 1. Ensure shared components and network replication
local Shared = ReplicatedStorage:WaitForChild("PanicShiftShared", 15) :: Folder
local Network = require(Shared:WaitForChild("Network"))

-- 2. Discover and register controllers
local controllersFolder = script.Parent:WaitForChild("Controllers")

local controllerOrder = {
    "EffectsController",
    "MusicController",
    "CameraController",
    "InteractionController",
    "InputController",
    "UIController",
}

local controllerRegistry: { [string]: any } = {}

for _, controllerName in ipairs(controllerOrder) do
    local mod = controllersFolder:FindFirstChild(controllerName)
    if mod and mod:IsA("ModuleScript") then
        local success, controllerInstance = pcall(function()
            return require(mod)
        end)
        if success and typeof(controllerInstance) == "table" then
            controllerRegistry[controllerName] = controllerInstance
        else
            error(string.format("[PanicShift Client] Error loading %s: %s", controllerName, tostring(controllerInstance)))
        end
    else
        error(string.format("[PanicShift Client] Controller %s missing from Controllers folder!", controllerName))
    end
end

-- 3. Execute Init Lifecycle
for _, controllerName in ipairs(controllerOrder) do
    local ctrl = controllerRegistry[controllerName]
    if typeof(ctrl.Init) == "function" then
        ctrl:Init(controllerRegistry)
    end
end
print("[PanicShift Client] All client controllers initialized.")

-- 4. Execute Start Lifecycle
for _, controllerName in ipairs(controllerOrder) do
    local ctrl = controllerRegistry[controllerName]
    if typeof(ctrl.Start) == "function" then
        ctrl:Start()
    end
end
print("[PanicShift Client] Client controllers started. Ready to work the shift!")
