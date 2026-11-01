--!strict
--[[
    PANIC SHIFT: Utility.lua
    Shared utility functions for math, distance checks, table operations,
    exponential backoff retries, rate limiting, and network payloads.
]]

local Types = require(script.Parent.Types)

local Utility = {}

-- Checks if two 3D positions are within a maximum Euclidean distance
function Utility.IsWithinDistance(posA: Vector3, posB: Vector3, maxDistance: number): boolean
    local diff = posA - posB
    return diff:Dot(diff) <= (maxDistance * maxDistance)
end

-- Extracts the PrimaryPart or HumanoidRootPart position safely from a character model
function Utility.GetCharacterPosition(character: Model?): Vector3?
    if not character then
        return nil
    end
    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root.Position
    end
    if character.PrimaryPart then
        return character.PrimaryPart.Position
    end
    return nil
end

-- Deep copies any Lua table recursively
function Utility.DeepCopy<T>(original: T): T
    if typeof(original) ~= "table" then
        return original
    end
    local copy = {}
    for key, value in pairs(original :: any) do
        if typeof(value) == "table" then
            copy[key] = Utility.DeepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy :: any
end

-- Formats seconds into a clean "MM:SS" time string
function Utility.FormatTime(totalSeconds: number): string
    local safeSeconds = math.max(0, math.floor(totalSeconds))
    local minutes = math.floor(safeSeconds / 60)
    local seconds = safeSeconds % 60
    return string.format("%02d:%02d", minutes, seconds)
end

-- Generates a lightweight unique identifier
local seedCounter = 0
function Utility.GenerateUUID(): string
    seedCounter = (seedCounter + 1) % 1000000
    local timestamp = os.time()
    local randomPart = math.random(10000, 99999)
    return string.format("PS-%d-%d-%06d", timestamp, randomPart, seedCounter)
end

-- Creates a standard token-bucket rate limiter per key (e.g., UserId)
function Utility.CreateRateLimiter(maxCalls: number, windowSeconds: number)
    local records: { [any]: { count: number, resetTime: number } } = {}

    return function(key: any): boolean
        local now = os.clock()
        local record = records[key]

        if not record or now >= record.resetTime then
            records[key] = {
                count = 1,
                resetTime = now + windowSeconds,
            }
            return true
        end

        if record.count < maxCalls then
            record.count = record.count + 1
            return true
        end

        return false -- Rate limit exceeded
    end
end

-- Executes a fallible operation with bounded retries and exponential backoff
function Utility.RetryWithBackoff<T>(
    maxAttempts: number,
    initialDelay: number,
    operation: () -> (boolean, T)
): (boolean, T?)
    local currentDelay = initialDelay
    for attempt = 1, maxAttempts do
        local success, result = operation()
        if success then
            return true, result
        end
        if attempt < maxAttempts then
            task.wait(currentDelay)
            currentDelay = currentDelay * 2
        end
    end
    return false, nil
end

-- Creates a standard success response payload
function Utility.CreateSuccessResponse(data: any?): Types.NetworkResponse
    return {
        Success = true,
        ErrorCode = "SUCCESS",
        Message = nil,
        Data = data,
    }
end

-- Creates a standard error response payload
function Utility.CreateErrorResponse(errorCode: string, message: string?): Types.NetworkResponse
    return {
        Success = false,
        ErrorCode = errorCode,
        Message = message,
        Data = nil,
    }
end

return table.freeze(Utility)
