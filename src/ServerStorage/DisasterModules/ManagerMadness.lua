--!strict
--[[
    PANIC SHIFT: Disaster - ManagerMadness.lua
    Disaster 6: Absurd corporate emergency store policies announced over PA.
    Enforces funny temporary movement or task constraints.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")
local Types = require(Shared:WaitForChild("Types"))

local ManagerMadness = {
    Name = "ManagerMadness",
}

local POLICIES = {
    {
        Code = "POLICY_WALK",
        Title = "POLICY 402: NO SPRINTING!",
        Description = "Walk with retail dignity! Speed capped at 10 studs/sec.",
        WalkSpeed = 10,
        JumpPower = 50,
    },
    {
        Code = "POLICY_NO_JUMP",
        Title = "POLICY 501: ZERO GRAVITY PROHIBITED!",
        Description = "Associates must keep both feet on the floor at all times. No jumping!",
        WalkSpeed = 16,
        JumpPower = 0,
    },
    {
        Code = "POLICY_DOUBLE_TIME",
        Title = "POLICY 603: OVERTIME BLITZ!",
        Description = "Corporate bonus approved: All task quota points count DOUBLE!",
        WalkSpeed = 18,
        JumpPower = 55,
    },
}

local activePolicyIndex: number? = nil
local enforcementThread: thread? = nil
local playerAddedConn: RBXScriptConnection? = nil

function ManagerMadness.CanStart(context: Types.DisasterContext?): boolean
    return true
end

function ManagerMadness.Start(context: Types.DisasterContext): ()
    activePolicyIndex = math.random(1, #POLICIES)
    local policy = POLICIES[activePolicyIndex]

    print(string.format("[Disaster: ManagerMadness] Announcement: '%s' - %s", policy.Title, policy.Description))

    local function applyPolicy(player: Player)
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = policy.WalkSpeed
            humanoid.JumpPower = policy.JumpPower
        end
    end

    -- Apply movement policy to all current player characters
    for _, player in ipairs(Players:GetPlayers()) do
        applyPolicy(player)
    end

    -- Handle late-joining or respawning characters
    playerAddedConn = Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            if activePolicyIndex then
                applyPolicy(player)
            end
        end)
    end)

    -- Active enforcement loop: re-clamp speed if players attempt to exploit/sprint
    enforcementThread = task.spawn(function()
        while activePolicyIndex do
            for _, player in ipairs(Players:GetPlayers()) do
                local char = player.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum.WalkSpeed > policy.WalkSpeed then
                    hum.WalkSpeed = policy.WalkSpeed
                end
            end
            task.wait(0.5)
        end
    end)
end

function ManagerMadness.Stop(context: Types.DisasterContext?): ()
    print("[Disaster: ManagerMadness] Shift policy rescinded. Standard operating procedures resumed.")
    activePolicyIndex = nil

    if enforcementThread then
        task.cancel(enforcementThread)
        enforcementThread = nil
    end

    if playerAddedConn then
        playerAddedConn:Disconnect()
        playerAddedConn = nil
    end

    -- Restore standard humanoid movement
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 50
        end
    end

    -- Reward complying associates with 25 bonus credits
    if context and context.Services and context.Services.EconomyService then
        for _, player in ipairs(Players:GetPlayers()) do
            context.Services.EconomyService:AwardCredits(player, 25, "ManagerPolicyCompliance")
        end
    end
end

return ManagerMadness
