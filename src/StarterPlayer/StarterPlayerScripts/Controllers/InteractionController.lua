--!strict
--[[
    PANIC SHIFT: InteractionController.lua
    Client raycasting, prompt detection, task interaction dispatcher,
    and 3D floating objective waypoint billboards with live distance indicators.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")
local Types = require(Shared:WaitForChild("Types"))
local Constants = require(Shared:WaitForChild("Constants"))
local Network = require(Shared:WaitForChild("Network"))

local InteractionController = {
    Name = "InteractionController",
}

local controllers: { [string]: any } = {}
local currentFocusedTaskId: string? = nil
local knownClientTasks: { [string]: any } = {}

type WaypointEntry = {
    AnchorPart: BasePart,
    Gui: BillboardGui,
    TitleLabel: TextLabel,
    DistanceLabel: TextLabel,
    BasePos: Vector3,
    Color: Color3,
}

local activeWaypoints: { [string]: WaypointEntry } = {}

local TASK_VISUAL_META: { [string]: { Title: string, Color: Color3 } } = {
    RESTOCK = { Title = "RESTOCK SHELF", Color = Color3.fromRGB(245, 175, 30) },
    CLEAN_SPILL = { Title = "MOP SPILL", Color = Color3.fromRGB(40, 200, 110) },
    DELIVER_ORDER = { Title = "SCAN ORDER", Color = Color3.fromRGB(30, 180, 240) },
    RETURN_CART = { Title = "RETURN CART", Color = Color3.fromRGB(245, 120, 30) },
    EXTINGUISH_FIRE = { Title = "PUT OUT FIRE", Color = Color3.fromRGB(235, 50, 50) },
    REPAIR = { Title = "FIX BREAKER", Color = Color3.fromRGB(235, 190, 40) },
}

-- Creates a floating 3D objective waypoint billboard
local function createWaypoint(taskId: string, data: any): WaypointEntry?
    local pos: Vector3 = data.Position
    if not pos then return nil end

    local meta = TASK_VISUAL_META[data.Type] or { Title = "SUPERMARKET TASK", Color = Color3.fromRGB(240, 180, 40) }

    -- Invisible anchor part for BillboardGui
    local anchor = Instance.new("Part")
    anchor.Name = "WaypointAnchor_" .. taskId
    anchor.Size = Vector3.new(0.2, 0.2, 0.2)
    anchor.CFrame = CFrame.new(pos + Vector3.new(0, 4.2, 0))
    anchor.Transparency = 1
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.Parent = Workspace

    local bGui = Instance.new("BillboardGui")
    bGui.Name = "TaskBillboard"
    bGui.Size = UDim2.new(0, 160, 0, 50)
    bGui.StudsOffset = Vector3.new(0, 0.5, 0)
    bGui.AlwaysOnTop = true
    bGui.LightInfluence = 0
    bGui.MaxDistance = 180
    bGui.Parent = anchor

    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
    container.BackgroundTransparency = 0.15
    container.Parent = bGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2.5
    stroke.Color = meta.Color
    stroke.Transparency = 0.2
    stroke.Parent = container

    -- Left accent strip
    local strip = Instance.new("Frame")
    strip.Name = "AccentStrip"
    strip.Size = UDim2.new(0, 6, 1, 0)
    strip.BackgroundColor3 = meta.Color
    strip.BorderSizePixel = 0
    strip.Parent = container

    local stripCorner = Instance.new("UICorner")
    stripCorner.CornerRadius = UDim.new(0, 8)
    stripCorner.Parent = strip

    -- Task Title Label
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Name = "Title"
    titleLbl.Position = UDim2.new(0, 14, 0, 4)
    titleLbl.Size = UDim2.new(1, -18, 0.52, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLbl.Font = Enum.Font.FredokaOne
    titleLbl.TextScaled = true
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = meta.Title
    titleLbl.Parent = container

    -- Live Distance Label
    local distLbl = Instance.new("TextLabel")
    distLbl.Name = "Distance"
    distLbl.Position = UDim2.new(0, 14, 0.54, 0)
    distLbl.Size = UDim2.new(1, -18, 0.40, 0)
    distLbl.BackgroundTransparency = 1
    distLbl.TextColor3 = meta.Color
    distLbl.Font = Enum.Font.FredokaOne
    distLbl.TextScaled = true
    distLbl.TextXAlignment = Enum.TextXAlignment.Left
    distLbl.Text = "... studs"
    distLbl.Parent = container

    -- Pop-in animation
    container.Size = UDim2.new(0, 0, 0, 0)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
    }):Play()

    local entry: WaypointEntry = {
        AnchorPart = anchor,
        Gui = bGui,
        TitleLabel = titleLbl,
        DistanceLabel = distLbl,
        BasePos = pos + Vector3.new(0, 4.2, 0),
        Color = meta.Color,
    }

    activeWaypoints[taskId] = entry
    return entry
end

local function removeWaypoint(taskId: string)
    local entry = activeWaypoints[taskId]
    if not entry then return end
    activeWaypoints[taskId] = nil

    local container = entry.Gui:FindFirstChild("Container") :: Frame?
    if container then
        local tween = TweenService:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(1.3, 0, 1.3, 0),
            Position = UDim2.new(-0.15, 0, -0.15, 0),
            BackgroundTransparency = 1,
        })
        tween:Play()
        tween.Completed:Connect(function()
            if entry.AnchorPart and entry.AnchorPart.Parent then
                entry.AnchorPart:Destroy()
            end
        end)
    else
        if entry.AnchorPart and entry.AnchorPart.Parent then
            entry.AnchorPart:Destroy()
        end
    end
end

function InteractionController:Init(controllerRegistry: { [string]: any })
    controllers = controllerRegistry
end

function InteractionController:Start()
    local taskStateRemote = Network.GetRemoteEvent(Constants.Remotes.TASK_STATE_CHANGED)
    taskStateRemote.OnClientEvent:Connect(function(taskId: string, eventType: string, data: any)
        if eventType == "CREATED" then
            knownClientTasks[taskId] = data
            createWaypoint(taskId, data)

        elseif eventType == "COMPLETED" or eventType == "CLEARED" then
            local existingTask = knownClientTasks[taskId]
            knownClientTasks[taskId] = nil
            removeWaypoint(taskId)

            if currentFocusedTaskId == taskId then
                currentFocusedTaskId = nil
            end

            if eventType == "COMPLETED" and data and data.CompletedBy == Players.LocalPlayer.Name then
                local effectsCtrl = controllers["EffectsController"]
                local cameraCtrl = controllers["CameraController"]
                local taskType = if existingTask and existingTask.Type then existingTask.Type else "RESTOCK"
                local worldPos: Vector3? = if existingTask and existingTask.Position then existingTask.Position else nil

                if not worldPos then
                    local character = Players.LocalPlayer.Character
                    if character and character:FindFirstChild("HumanoidRootPart") then
                        worldPos = (character:FindFirstChild("HumanoidRootPart") :: BasePart).Position
                    end
                end

                if effectsCtrl and typeof(effectsCtrl.PlayTaskSuccess) == "function" then
                    effectsCtrl:PlayTaskSuccess(taskType, worldPos)
                end
                if cameraCtrl then
                    if typeof(cameraCtrl.TriggerShake) == "function" then
                        cameraCtrl:TriggerShake(0.15)
                    end
                    if typeof(cameraCtrl.PunchFov) == "function" then
                        cameraCtrl:PunchFov(2.0)
                    end
                end
            end
        end
    end)

    -- Real-time distance update & vertical bobbing loop
    RunService.RenderStepped:Connect(function()
        local character = Players.LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
        local myPos = if rootPart then rootPart.Position else nil
        local t = os.clock()

        for taskId, entry in pairs(activeWaypoints) do
            if entry.AnchorPart and entry.AnchorPart.Parent then
                -- Bob gently up and down
                local bobY = math.sin(t * 3.0) * 0.35
                entry.AnchorPart.CFrame = CFrame.new(entry.BasePos + Vector3.new(0, bobY, 0))

                -- Update distance label
                if myPos then
                    local dist = math.floor((entry.BasePos - myPos).Magnitude)
                    entry.DistanceLabel.Text = string.format("%d studs", dist)
                end
            end
        end
    end)
end

function InteractionController:SetFocusedTask(taskId: string?)
    currentFocusedTaskId = taskId
end

function InteractionController:TriggerCurrentInteraction(): ()
    local taskId: string? = currentFocusedTaskId

    -- If no focused task, automatically find nearest interactive task or anchor
    if not taskId then
        local character = Players.LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if rootPart then
            local myPos = rootPart.Position
            local closestDist = Constants.MAX_INTERACTION_DISTANCE

            -- Check known replicated tasks
            for id, data in pairs(knownClientTasks) do
                if data and data.Position then
                    local dist = (data.Position - myPos).Magnitude
                    if dist <= closestDist then
                        closestDist = dist
                        taskId = id
                    end
                end
            end
        end
    end

    if not taskId then return end

    local taskInfo = knownClientTasks[taskId]
    local requestFunc = Network.GetRemoteFunction(Constants.Remotes.REQUEST_TASK_ACTION)
    local response: Types.NetworkResponse = requestFunc:InvokeServer(taskId, "INTERACT")

    if response.Success then
        print(string.format("[Interaction] Completed task %s successfully!", taskId))
        currentFocusedTaskId = nil
    else
        warn(string.format("[Interaction] Task interaction: %s (%s)", response.Message or "", response.ErrorCode))
    end
end

return InteractionController
