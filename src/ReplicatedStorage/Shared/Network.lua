--!strict
--[[
    PANIC SHIFT: Network.lua
    Centralized network manager for remote creation, retrieval, and registration.
    Prevents race conditions between server startup and client replication.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(script.Parent.Constants)

local Network = {}

local REMOTES_FOLDER_NAME = "PanicShiftRemotes"
local remotesFolder: Folder

-- Retrieves or creates the Remotes container folder
local function getRemotesFolder(): Folder
    if remotesFolder then
        return remotesFolder
    end

    if RunService:IsServer() then
        local existing = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
        if existing and existing:IsA("Folder") then
            remotesFolder = existing
        else
            local folder = Instance.new("Folder")
            folder.Name = REMOTES_FOLDER_NAME
            folder.Parent = ReplicatedStorage
            remotesFolder = folder
        end
    else
        remotesFolder = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME, 10) :: Folder
        if not remotesFolder then
            error(string.format("[PanicShift Network] Timed out waiting for %s folder on client!", REMOTES_FOLDER_NAME))
        end
    end

    return remotesFolder
end

-- Initializes all required remotes on the server
function Network.InitServer(): ()
    assert(RunService:IsServer(), "[PanicShift Network] InitServer must only be called on the server!")
    local folder = getRemotesFolder()

    -- RemoteFunctions
    local functions = {
        Constants.Remotes.REQUEST_TASK_ACTION,
        Constants.Remotes.REQUEST_EQUIP_COSMETIC,
        Constants.Remotes.REQUEST_PURCHASE_COSMETIC,
        Constants.Remotes.REQUEST_PLAYER_PROFILE,
    }
    for _, name in ipairs(functions) do
        if not folder:FindFirstChild(name) then
            local remoteFunc = Instance.new("RemoteFunction")
            remoteFunc.Name = name
            remoteFunc.Parent = folder
        end
    end

    -- RemoteEvents
    local events = {
        Constants.Remotes.ROUND_STATE_CHANGED,
        Constants.Remotes.TASK_STATE_CHANGED,
        Constants.Remotes.DISASTER_STATE_CHANGED,
        Constants.Remotes.PLAYER_PROFILE_UPDATED,
        Constants.Remotes.ROUND_RESULTS,
    }
    for _, name in ipairs(events) do
        if not folder:FindFirstChild(name) then
            local remoteEvt = Instance.new("RemoteEvent")
            remoteEvt.Name = name
            remoteEvt.Parent = folder
        end
    end
end

-- Retrieves a RemoteEvent by name
function Network.GetRemoteEvent(name: string): RemoteEvent
    local folder = getRemotesFolder()
    local remote = folder:WaitForChild(name, 10) :: RemoteEvent
    if not remote or not remote:IsA("RemoteEvent") then
        error(string.format("[PanicShift Network] RemoteEvent '%s' was not found in %s!", name, REMOTES_FOLDER_NAME))
    end
    return remote
end

-- Retrieves a RemoteFunction by name
function Network.GetRemoteFunction(name: string): RemoteFunction
    local folder = getRemotesFolder()
    local remote = folder:WaitForChild(name, 10) :: RemoteFunction
    if not remote or not remote:IsA("RemoteFunction") then
        error(string.format("[PanicShift Network] RemoteFunction '%s' was not found in %s!", name, REMOTES_FOLDER_NAME))
    end
    return remote
end

return table.freeze(Network)
