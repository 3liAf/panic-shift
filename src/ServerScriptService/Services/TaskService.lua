--!strict
--[[
    PANIC SHIFT: TaskService.lua
    Server-authoritative task manager. Dynamically spawns interactive physical tasks
    (Restock, Spill, Delivery, Repair) at map anchors with ProximityPrompts,
    performs atomic completion validation, and distributes rewards.
]]

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")
local Types = require(Shared:WaitForChild("Types"))
local Config = require(Shared:WaitForChild("Config"))
local Constants = require(Shared:WaitForChild("Constants"))
local Utility = require(Shared:WaitForChild("Utility"))
local Network = require(Shared:WaitForChild("Network"))

local TaskService = {
    Name = "TaskService",
}

local services: { [string]: any } = {}
local activeTasks: { [string]: Types.TaskData } = {}
local taskInstances: { [string]: Instance } = {}
local rateLimiter: (key: any) -> boolean
local activeTasksFolder: Folder

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

-- Helper to create visual effects for physical tasks
local function createPhysicalTaskVisual(taskData: Types.TaskData, parentFolder: Folder): Instance?
    local taskDef = Config.Tasks[taskData.Type]
    local holdDuration = taskDef and taskDef.InteractionDuration or 1.5

    if taskData.Type == "CLEAN_SPILL" then
        -- Slippery liquid puddle on floor
        local puddle = Instance.new("Part")
        puddle.Name = "Spill_" .. taskData.Id
        puddle.Shape = Enum.PartType.Cylinder
        puddle.Size = Vector3.new(0.2, 7, 7) -- Cylinder height is X axis
        puddle.CFrame = CFrame.new(taskData.Position + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90))
        puddle.Color = Color3.fromRGB(240, 70, 180) -- Toxic neon berry spill
        puddle.Material = Enum.Material.Glass
        puddle.Transparency = 0.25
        puddle.Anchored = true
        puddle.CanCollide = false
        puddle.Parent = parentFolder

        -- Sparkle / soap bubbles
        local particles = Instance.new("ParticleEmitter")
        particles.Rate = 5
        particles.Lifetime = NumberRange.new(1, 2)
        particles.Speed = NumberRange.new(1, 3)
        particles.Size = NumberSequence.new(0.4, 0.8)
        particles.Color = ColorSequence.new(Color3.fromRGB(255, 200, 240))
        particles.Parent = puddle

        -- ProximityPrompt
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Mop Spill"
        prompt.ObjectText = "Slippery Mess"
        prompt.HoldDuration = holdDuration
        prompt.MaxActivationDistance = 10
        prompt.RequiresLineOfSight = false
        prompt.Parent = puddle

        prompt.Triggered:Connect(function(player: Player)
            TaskService:HandleTaskAction(player, taskData.Id, "MOP")
        end)

        return puddle

    elseif taskData.Type == "RESTOCK" then
        -- Empty shelf highlight
        local boxMarker = Instance.new("Part")
        boxMarker.Name = "Restock_" .. taskData.Id
        boxMarker.Size = Vector3.new(3.5, 2.5, 3.5)
        boxMarker.CFrame = CFrame.new(taskData.Position)
        boxMarker.Color = Color3.fromRGB(250, 200, 30)
        boxMarker.Material = Enum.Material.Neon
        boxMarker.Transparency = 0.55
        boxMarker.Anchored = true
        boxMarker.CanCollide = false
        boxMarker.Parent = parentFolder

        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Stock Shelf (Requires Box)"
        prompt.ObjectText = "Empty Grocery Shelf"
        prompt.HoldDuration = 0.5
        prompt.MaxActivationDistance = 10
        prompt.RequiresLineOfSight = false
        prompt.Parent = boxMarker

        prompt.Triggered:Connect(function(player: Player)
            TaskService:HandleTaskAction(player, taskData.Id, "RESTOCK")
        end)

        return boxMarker

    elseif taskData.Type == "REPAIR" then
        -- Malfunctioning breaker or cooler with electrical sparks
        local repairMarker = Instance.new("Part")
        repairMarker.Name = "Repair_" .. taskData.Id
        repairMarker.Size = Vector3.new(2, 2, 2)
        repairMarker.CFrame = CFrame.new(taskData.Position)
        repairMarker.Transparency = 1
        repairMarker.Anchored = true
        repairMarker.CanCollide = false
        repairMarker.Parent = parentFolder

        local sparks = Instance.new("ParticleEmitter")
        sparks.Rate = 18
        sparks.Speed = NumberRange.new(5, 12)
        sparks.Lifetime = NumberRange.new(0.2, 0.5)
        sparks.SpreadAngle = Vector2.new(45, 45)
        sparks.Color = ColorSequence.new(Color3.fromRGB(255, 230, 80))
        sparks.Parent = repairMarker

        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Repair Sparks"
        prompt.ObjectText = "Faulty Breaker"
        prompt.HoldDuration = holdDuration
        prompt.MaxActivationDistance = 10
        prompt.RequiresLineOfSight = false
        prompt.Parent = repairMarker

        prompt.Triggered:Connect(function(player: Player)
            TaskService:HandleTaskAction(player, taskData.Id, "REPAIR")
        end)

        return repairMarker

    elseif taskData.Type == "DELIVER_ORDER" then
        -- Delivery order at checkout conveyor
        local ticketMarker = Instance.new("Part")
        ticketMarker.Name = "Order_" .. taskData.Id
        ticketMarker.Size = Vector3.new(3, 0.4, 3)
        ticketMarker.CFrame = CFrame.new(taskData.Position)
        ticketMarker.Color = Color3.fromRGB(40, 220, 100)
        ticketMarker.Material = Enum.Material.Neon
        ticketMarker.Transparency = 0.4
        ticketMarker.Anchored = true
        ticketMarker.CanCollide = false
        ticketMarker.Parent = parentFolder

        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Deliver Groceries"
        prompt.ObjectText = "Customer Order"
        prompt.HoldDuration = 1.0
        prompt.MaxActivationDistance = 10
        prompt.RequiresLineOfSight = false
        prompt.Parent = ticketMarker

        prompt.Triggered:Connect(function(player: Player)
            TaskService:HandleTaskAction(player, taskData.Id, "DELIVER")
        end)

        return ticketMarker

    elseif taskData.Type == "RETURN_CART" then
        -- Realistic 3D Shopping Cart Model
        local cartModel = Instance.new("Model")
        cartModel.Name = "Cart_" .. taskData.Id
        cartModel.Parent = parentFolder

        -- Primary Root Base
        local cartBase = Instance.new("Part")
        cartBase.Name = "CartBase"
        cartBase.Size = Vector3.new(2.4, 0.4, 3.6)
        cartBase.CFrame = CFrame.new(taskData.Position + Vector3.new(0, 0.8, 0))
        cartBase.Color = Color3.fromRGB(195, 200, 210)
        cartBase.Material = Enum.Material.Metal
        cartBase.Anchored = false
        cartBase.CanCollide = false
        cartBase.Parent = cartModel
        cartModel.PrimaryPart = cartBase

        -- Wire Basket Walls
        local wireColor = Color3.fromRGB(205, 210, 220)
        local basketFront = Instance.new("Part")
        basketFront.Name = "BasketFront"
        basketFront.Size = Vector3.new(2.4, 1.8, 0.2)
        basketFront.CFrame = cartBase.CFrame * CFrame.new(0, 0.9, -1.7)
        basketFront.Color = wireColor
        basketFront.Material = Enum.Material.Metal
        basketFront.CanCollide = false
        basketFront.Parent = cartModel

        local bFrontWeld = Instance.new("WeldConstraint")
        bFrontWeld.Part0 = cartBase
        bFrontWeld.Part1 = basketFront
        bFrontWeld.Parent = cartBase

        local basketBack = Instance.new("Part")
        basketBack.Name = "BasketBack"
        basketBack.Size = Vector3.new(2.4, 1.8, 0.2)
        basketBack.CFrame = cartBase.CFrame * CFrame.new(0, 0.9, 1.7)
        basketBack.Color = wireColor
        basketBack.Material = Enum.Material.Metal
        basketBack.CanCollide = false
        basketBack.Parent = cartModel

        local bBackWeld = Instance.new("WeldConstraint")
        bBackWeld.Part0 = cartBase
        bBackWeld.Part1 = basketBack
        bBackWeld.Parent = cartBase

        local basketLeft = Instance.new("Part")
        basketLeft.Name = "BasketLeft"
        basketLeft.Size = Vector3.new(0.2, 1.8, 3.4)
        basketLeft.CFrame = cartBase.CFrame * CFrame.new(-1.1, 0.9, 0)
        basketLeft.Color = wireColor
        basketLeft.Material = Enum.Material.Metal
        basketLeft.CanCollide = false
        basketLeft.Parent = cartModel

        local bLeftWeld = Instance.new("WeldConstraint")
        bLeftWeld.Part0 = cartBase
        bLeftWeld.Part1 = basketLeft
        bLeftWeld.Parent = cartBase

        local basketRight = Instance.new("Part")
        basketRight.Name = "BasketRight"
        basketRight.Size = Vector3.new(0.2, 1.8, 3.4)
        basketRight.CFrame = cartBase.CFrame * CFrame.new(1.1, 0.9, 0)
        basketRight.Color = wireColor
        basketRight.Material = Enum.Material.Metal
        basketRight.CanCollide = false
        basketRight.Parent = cartModel

        local bRightWeld = Instance.new("WeldConstraint")
        bRightWeld.Part0 = cartBase
        bRightWeld.Part1 = basketRight
        bRightWeld.Parent = cartBase

        -- Red Plastic Push Handle Bar
        local handleBar = Instance.new("Part")
        handleBar.Name = "HandleBar"
        handleBar.Size = Vector3.new(2.2, 0.3, 0.3)
        handleBar.CFrame = cartBase.CFrame * CFrame.new(0, 1.9, 1.9)
        handleBar.Color = Color3.fromRGB(225, 40, 40)
        handleBar.Material = Enum.Material.SmoothPlastic
        handleBar.CanCollide = false
        handleBar.Parent = cartModel

        local hWeld = Instance.new("WeldConstraint")
        hWeld.Part0 = cartBase
        hWeld.Part1 = handleBar
        hWeld.Parent = cartBase

        -- 4 Caster Wheels
        for _, wx in ipairs({ -0.9, 0.9 }) do
            for _, wz in ipairs({ -1.4, 1.4 }) do
                local wheel = Instance.new("Part")
                wheel.Name = "Wheel"
                wheel.Shape = Enum.PartType.Cylinder
                wheel.Size = Vector3.new(0.3, 0.8, 0.8)
                wheel.CFrame = cartBase.CFrame * CFrame.new(wx, -0.4, wz) * CFrame.Angles(0, 0, math.rad(90))
                wheel.Color = Color3.fromRGB(35, 35, 40)
                wheel.Material = Enum.Material.SmoothPlastic
                wheel.CanCollide = false
                wheel.Parent = cartModel

                local wWeld = Instance.new("WeldConstraint")
                wWeld.Part0 = cartBase
                wWeld.Part1 = wheel
                wWeld.Parent = cartBase
            end
        end

        -- Anchor base initially
        cartBase.Anchored = true

        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Push Shopping Cart"
        prompt.ObjectText = "Runaway Shopping Cart"
        prompt.HoldDuration = 0.2
        prompt.MaxActivationDistance = 10
        prompt.RequiresLineOfSight = false
        prompt.Parent = cartBase

        local currentWeld: WeldConstraint? = nil
        local pushingPlayer: Player? = nil

        prompt.Triggered:Connect(function(player: Player)
            if pushingPlayer == player then
                -- Release cart
                if currentWeld then currentWeld:Destroy(); currentWeld = nil end
                pushingPlayer = nil
                player:SetAttribute("PushingCart", false)
                prompt.ActionText = "Push Shopping Cart"
                cartBase.Anchored = true
            else
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
                if not root then return end

                cartBase.Anchored = false
                cartBase.CFrame = root.CFrame * CFrame.new(0, -0.5, -3.2)
                currentWeld = Instance.new("WeldConstraint")
                currentWeld.Part0 = root
                currentWeld.Part1 = cartBase
                currentWeld.Parent = cartBase

                pushingPlayer = player
                player:SetAttribute("PushingCart", true)
                prompt.ActionText = "Release Shopping Cart"
            end
        end)

        -- Touch detector for Cart Corral
        cartBase.Touched:Connect(function(otherPart: BasePart)
            if otherPart and CollectionService:HasTag(otherPart, "CartCorral") then
                if pushingPlayer then
                    pushingPlayer:SetAttribute("PushingCart", false)
                end
                if currentWeld then currentWeld:Destroy() end
                cartBase.Anchored = true

                -- Clang audio feedback
                local clang = Instance.new("Sound")
                clang.SoundId = "rbxasset://sounds/snap.wav"
                clang.Volume = 0.9
                clang.Parent = cartBase
                clang:Play()

                local solver = pushingPlayer or Players:GetPlayers()[1]
                if solver then
                    TaskService:HandleTaskAction(solver, taskData.Id, "RETURN_CART")
                end
            end
        end)

        return cartModel

    elseif taskData.Type == "EXTINGUISH_FIRE" then
        -- Flaming trashcan or electrical burnout hazard
        local fireMarker = Instance.new("Part")
        fireMarker.Name = "Fire_" .. taskData.Id
        fireMarker.Size = Vector3.new(2, 2.5, 2)
        fireMarker.CFrame = CFrame.new(taskData.Position + Vector3.new(0, 1.25, 0))
        fireMarker.Color = Color3.fromRGB(50, 40, 40)
        fireMarker.Material = Enum.Material.CorrodedMetal
        fireMarker.Anchored = true
        fireMarker.CanCollide = false
        fireMarker.Parent = parentFolder

        local flames = Instance.new("ParticleEmitter")
        flames.Name = "Flames"
        flames.Texture = "rbxasset://textures/particles/smoke_main.dds"
        flames.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 60)),
            ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 100, 20)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 30, 20)),
        })
        flames.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1.0),
            NumberSequenceKeypoint.new(0.5, 2.0),
            NumberSequenceKeypoint.new(1, 0.2),
        })
        flames.LightEmission = 1.0
        flames.Rate = 22
        flames.Speed = NumberRange.new(3, 7)
        flames.Lifetime = NumberRange.new(0.5, 1.0)
        flames.Acceleration = Vector3.new(0, 10, 0)
        flames.Parent = fireMarker

        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Extinguish Fire"
        prompt.ObjectText = "Active Flame Hazard"
        prompt.HoldDuration = holdDuration
        prompt.MaxActivationDistance = 10
        prompt.RequiresLineOfSight = false
        prompt.Parent = fireMarker

        prompt.Triggered:Connect(function(player: Player)
            TaskService:HandleTaskAction(player, taskData.Id, "EXTINGUISH_FIRE")
        end)

        return fireMarker
    end

    return nil
end

function TaskService:Init(serviceRegistry: { [string]: any })
    services = serviceRegistry
    rateLimiter = Utility.CreateRateLimiter(Config.RateLimits.TASK_ACTION_MAX_PER_SECOND, 1.0)

    -- Container for spawned task physical instances
    local existing = Workspace:FindFirstChild("ActivePanicShiftTasks")
    if existing then
        existing:Destroy()
    end
    activeTasksFolder = Instance.new("Folder")
    activeTasksFolder.Name = "ActivePanicShiftTasks"
    activeTasksFolder.Parent = Workspace
end

function TaskService:Start()
    local taskActionFunc = Network.GetRemoteFunction(Constants.Remotes.REQUEST_TASK_ACTION)
    taskActionFunc.OnServerInvoke = function(player: Player, taskId: any, actionType: any): Types.NetworkResponse
        return self:HandleTaskAction(player, taskId, actionType)
    end
end

-- Populates initial tasks for a shift from the map's anchors
function TaskService:PopulateInitialTasks()
    self:ClearAllTasks()

    local roundService = getService("RoundService")
    local map = roundService and roundService:GetSupermarketMap()
    if not map then
        warn("[TaskService] Cannot populate tasks: SupermarketMap not found in Workspace!")
        return
    end

    local taskAnchors = map:FindFirstChild("TaskAnchors")
    if not taskAnchors then
        warn("[TaskService] TaskAnchors folder not found in SupermarketMap!")
        return
    end

    -- 1. Spills (at least 3 spills)
    local spillAnchors = {}
    for _, child in ipairs(taskAnchors:GetChildren()) do
        if child.Name:find("SpillAnchor") and child:IsA("BasePart") then
            table.insert(spillAnchors, child)
        end
    end
    for _, anchor in ipairs(spillAnchors) do
        self:CreateTask("CLEAN_SPILL", anchor.Position, anchor)
    end

    -- 2. Restocks (shelves needing boxes)
    local restockAnchors = {}
    for _, child in ipairs(taskAnchors:GetChildren()) do
        if child.Name:find("RestockTarget") and child:IsA("BasePart") then
            table.insert(restockAnchors, child)
        end
    end
    for _, anchor in ipairs(restockAnchors) do
        self:CreateTask("RESTOCK", anchor.Position, anchor)
    end

    -- 3. Order Deliveries (checkouts)
    local orderAnchors = {}
    for _, child in ipairs(taskAnchors:GetChildren()) do
        if child.Name:find("OrderDropTarget") and child:IsA("BasePart") then
            table.insert(orderAnchors, child)
        end
    end
    for idx = 1, math.min(2, #orderAnchors) do
        local anchor = orderAnchors[idx]
        self:CreateTask("DELIVER_ORDER", anchor.Position, anchor)
    end

    -- 4. Repairs (breaker panels)
    local maintenance = map:FindFirstChild("Maintenance")
    if maintenance then
        local b1 = maintenance:FindFirstChild("BreakerPanel_1")
        if b1 and b1:IsA("BasePart") then
            self:CreateTask("REPAIR", b1.Position + Vector3.new(1.5, 0, 0), b1)
        end
        local cooler = maintenance:FindFirstChild("CoolerUnit_2")
        if cooler and cooler:IsA("BasePart") then
            self:CreateTask("REPAIR", cooler.Position + Vector3.new(-2, 0, 0), cooler)
        end
    end

    -- 5. Stray Cart Returns (aisles / front entrance)
    self:CreateTask("RETURN_CART", Vector3.new(-6, 2.15, 12), nil)
    self:CreateTask("RETURN_CART", Vector3.new(22, 2.15, 28), nil)

    -- 6. Fire Hazard (waste bin or electrical)
    self:CreateTask("EXTINGUISH_FIRE", Vector3.new(-32, 2.15, 72), nil)

    -- 7. Initialize Stockroom Pallet Pickup Prompts
    self:InitStockroomPallets()

    print(string.format("[TaskService] Populated %d initial tasks for the shift.", self:GetActiveTaskCount()))
end

-- Creates and spawns a single task instance
function TaskService:CreateTask(taskType: Types.TaskType, position: Vector3, locationPart: BasePart?): Types.TaskData
    local taskId = Utility.GenerateUUID()
    local taskDef = Config.Tasks[taskType]

    local taskData: Types.TaskData = {
        Id = taskId,
        Type = taskType,
        Title = taskDef and taskDef.Name or "Supermarket Task",
        LocationPart = locationPart,
        Position = position,
        IsActive = true,
        IsCompleted = false,
        AssignedPlayer = nil,
        CreatedAt = os.clock(),
        ExpiresAt = taskDef and taskDef.OrderTimeLimit and (os.clock() + taskDef.OrderTimeLimit) or nil,
        Metadata = {},
    }

    activeTasks[taskId] = taskData

    -- Spawn physical 3D interactive object
    local visualInstance = createPhysicalTaskVisual(taskData, activeTasksFolder)
    if visualInstance then
        taskInstances[taskId] = visualInstance
    end

    -- Broadcast to clients
    local remote = Network.GetRemoteEvent(Constants.Remotes.TASK_STATE_CHANGED)
    remote:FireAllClients(taskId, "CREATED", {
        Id = taskData.Id,
        Type = taskData.Type,
        Title = taskData.Title,
        Position = taskData.Position,
        ExpiresAt = taskData.ExpiresAt,
    })

    return taskData
end

function TaskService:GetActiveTasks(): { [string]: Types.TaskData }
    return activeTasks
end

function TaskService:GetActiveTaskCount(): number
    local count = 0
    for _, t in pairs(activeTasks) do
        if t.IsActive and not t.IsCompleted then
            count = count + 1
        end
    end
    return count
end

-- Populates stocked goods onto empty shelf after player restocks
function TaskService:PopulateRestockedShelf(shelfPos: Vector3)
    local floor = Workspace:FindFirstChild("SupermarketMap") and Workspace.SupermarketMap:FindFirstChild("StoreFloor")
    if not floor then return end

    local colors = {
        Color3.fromRGB(240, 60, 50),
        Color3.fromRGB(40, 140, 240),
        Color3.fromRGB(250, 200, 30),
        Color3.fromRGB(50, 180, 80),
    }

    for i = 1, 4 do
        local item = Instance.new("Part")
        item.Name = "RestockedProduct"
        item.Size = Vector3.new(0.8, 1.5, 0.8)
        item.CFrame = CFrame.new(shelfPos + Vector3.new((i - 2.5) * 0.9, 0.75, 0))
        item.Color = colors[i]
        item.Material = Enum.Material.SmoothPlastic
        item.Anchored = true
        item.CanCollide = false
        item.Parent = floor
    end
end

-- Hooks all stockroom pallets with box pickup prompts
function TaskService:InitStockroomPallets()
    local map = Workspace:FindFirstChild("SupermarketMap")
    local anchors = map and map:FindFirstChild("TaskAnchors")
    if not anchors then return end

    for _, anchor in ipairs(anchors:GetChildren()) do
        if anchor.Name:find("RestockSource") and anchor:IsA("BasePart") then
            local existingPrompt = anchor:FindFirstChildOfClass("ProximityPrompt")
            if not existingPrompt then
                local prompt = Instance.new("ProximityPrompt")
                prompt.ActionText = "Pick Up Restock Box"
                prompt.ObjectText = "Stockroom Pallet"
                prompt.HoldDuration = 0.2
                prompt.MaxActivationDistance = 12
                prompt.RequiresLineOfSight = false
                prompt.Parent = anchor

                prompt.Triggered:Connect(function(player: Player)
                    local char = player.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
                    if not root then return end

                    if player:GetAttribute("CarryingRestockBox") == true then
                        return
                    end

                    -- Create 3D Cardboard Box held in front of character
                    local box = Instance.new("Part")
                    box.Name = "HeldRestockBox"
                    box.Size = Vector3.new(2.2, 1.6, 1.6)
                    box.CFrame = root.CFrame * CFrame.new(0, 0.4, -1.8)
                    box.Color = Color3.fromRGB(195, 155, 105)
                    box.Material = Enum.Material.SmoothPlastic
                    box.CanCollide = false
                    box.Parent = char

                    -- Packaging tape stripe
                    local tape = Instance.new("Part")
                    tape.Name = "BoxTape"
                    tape.Size = Vector3.new(0.4, 0.05, 1.62)
                    tape.CFrame = box.CFrame * CFrame.new(0, 0.81, 0)
                    tape.Color = Color3.fromRGB(225, 190, 130)
                    tape.Material = Enum.Material.SmoothPlastic
                    tape.CanCollide = false
                    tape.Parent = box

                    local tWeld = Instance.new("WeldConstraint")
                    tWeld.Part0 = box
                    tWeld.Part1 = tape
                    tWeld.Parent = box

                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = root
                    weld.Part1 = box
                    weld.Parent = box

                    player:SetAttribute("CarryingRestockBox", true)

                    -- Pickup audio
                    local sound = Instance.new("Sound")
                    sound.SoundId = "rbxasset://sounds/action_get_up.mp3"
                    sound.Volume = 0.8
                    sound.Parent = box
                    sound:Play()
                end)
            end
        end
    end
end

-- Safely clears all currently active tasks
function TaskService:ClearAllTasks()
    for taskId, _ in pairs(activeTasks) do
        local remote = Network.GetRemoteEvent(Constants.Remotes.TASK_STATE_CHANGED)
        remote:FireAllClients(taskId, "CLEARED", nil)
    end

    for _, inst in pairs(taskInstances) do
        if inst and inst.Parent then
            inst:Destroy()
        end
    end

    table.clear(activeTasks)
    table.clear(taskInstances)
end

-- Validates and processes a player's interaction with a task
function TaskService:HandleTaskAction(player: Player, taskId: any, actionType: any): Types.NetworkResponse
    -- Anti-exploit: Rate limiting check
    if not rateLimiter(player.UserId) then
        return Utility.CreateErrorResponse(Constants.ErrorCodes.RATE_LIMITED, "Interaction throttled.")
    end

    -- Argument validation
    if typeof(taskId) ~= "string" then
        return Utility.CreateErrorResponse(Constants.ErrorCodes.INVALID_ARGUMENTS, "Invalid task ID.")
    end

    local taskData = activeTasks[taskId]
    if not taskData then
        -- Resilient Fallback 1: match by LocationPart anchor name
        for realId, data in pairs(activeTasks) do
            if (data.LocationPart and data.LocationPart.Name == taskId) or data.Id == taskId then
                taskData = data
                taskId = realId
                break
            end
        end
    end

    if not taskData then
        -- Resilient Fallback 2: match closest active uncompleted task within range
        local charPos = Utility.GetCharacterPosition(player.Character)
        if charPos then
            local closestDist = Constants.MAX_INTERACTION_DISTANCE
            for realId, data in pairs(activeTasks) do
                if data.IsActive and not data.IsCompleted then
                    local dist = (data.Position - charPos).Magnitude
                    if dist <= closestDist then
                        closestDist = dist
                        taskData = data
                        taskId = realId
                    end
                end
            end
        end
    end

    if not taskData then
        return Utility.CreateErrorResponse(Constants.ErrorCodes.TASK_NOT_FOUND, "Task does not exist.")
    end

    -- Atomic completion lock check (FR-09 / TEST-MP-01)
    if taskData.IsCompleted then
        return Utility.CreateErrorResponse(Constants.ErrorCodes.TASK_ALREADY_COMPLETED, "Task was already completed by another employee.")
    end

    if not taskData.IsActive then
        return Utility.CreateErrorResponse(Constants.ErrorCodes.INVALID_STATE, "Task is no longer active.")
    end

    -- Distance validation (FR-08 / TEST-SEC-02)
    local charPos = Utility.GetCharacterPosition(player.Character)
    if not charPos then
        return Utility.CreateErrorResponse(Constants.ErrorCodes.INVALID_STATE, "Character position unknown.")
    end

    if not Utility.IsWithinDistance(charPos, taskData.Position, Constants.MAX_INTERACTION_DISTANCE) then
        return Utility.CreateErrorResponse(Constants.ErrorCodes.OUT_OF_RANGE, "You are too far away from this task.")
    end

    -- Specialized Task Validation
    if taskData.Type == "RESTOCK" then
        local isCarryingBox = player:GetAttribute("CarryingRestockBox") == true
        if not isCarryingBox then
            return Utility.CreateErrorResponse(Constants.ErrorCodes.INVALID_STATE, "Grab a Restock Box from the Stockroom pallets first!")
        end
        player:SetAttribute("CarryingRestockBox", false)
        local char = player.Character
        if char then
            local held = char:FindFirstChild("HeldRestockBox")
            if held then held:Destroy() end
        end
        self:PopulateRestockedShelf(taskData.Position)
    elseif taskData.Type == "RETURN_CART" then
        player:SetAttribute("PushingCart", false)
    end

    -- ATOMIC STATE MUTATION: Mark completed immediately to block race conditions
    taskData.IsCompleted = true
    taskData.IsActive = false

    -- Remove physical world instance
    local visual = taskInstances[taskId]
    if visual and visual.Parent then
        visual:Destroy()
        taskInstances[taskId] = nil
    end

    local taskDef = Config.Tasks[taskData.Type]
    local creditReward = taskDef and taskDef.CreditReward or 10
    local xpReward = taskDef and taskDef.XpReward or 15
    local quotaPoints = taskDef and taskDef.QuotaPoints or 1

    -- Reward distribution
    local economyService = getService("EconomyService")
    if economyService then
        economyService:AwardCredits(player, creditReward, "TaskCompletion_" .. taskData.Type)
        economyService:AwardXp(player, xpReward, "TaskCompletion_" .. taskData.Type)
    end

    -- Quota contribution
    local roundService = getService("RoundService")
    if roundService then
        roundService:AddQuotaProgress(quotaPoints, player)
    end

    -- Daily challenge progress
    local challengeService = getService("ChallengeService")
    if challengeService then
        challengeService:IncrementProgress(player, "DAILY_TASKS_10", 1)
        if taskData.Type == "CLEAN_SPILL" then
            challengeService:IncrementProgress(player, "DAILY_CLEAN_SPILLS_5", 1)
        end
    end

    -- Lifetime stats & Badges
    local dataService = getService("DataService")
    if dataService then
        dataService:IncrementStat(player, "tasksCompleted", 1)
        if taskData.Type == "CLEAN_SPILL" then
            local spills = dataService:IncrementStat(player, "spillsCleaned", 1)
            if spills >= 25 then
                local analytics = getService("AnalyticsService")
                if analytics then
                    analytics:AwardBadge(player, "CLEANING_CREW")
                end
            end
        elseif taskData.Type == "DELIVER_ORDER" then
            dataService:IncrementStat(player, "ordersDelivered", 1)
        end
    end

    -- Telemetry
    local analyticsService = getService("AnalyticsService")
    if analyticsService then
        analyticsService:LogEvent("TaskCompleted", {
            PlayerId = player.UserId,
            TaskType = taskData.Type,
            TaskId = taskId,
        })
    end

    -- Broadcast completion to all clients
    local remote = Network.GetRemoteEvent(Constants.Remotes.TASK_STATE_CHANGED)
    remote:FireAllClients(taskId, "COMPLETED", {
        CompletedBy = player.Name,
    })

    print(string.format("[TaskService] Player %s completed %s (+%d Credits, +%d XP, +%d Quota)", player.Name, taskData.Type, creditReward, xpReward, quotaPoints))

    return Utility.CreateSuccessResponse({
        TaskId = taskId,
        CreditsAwarded = creditReward,
        XpAwarded = xpReward,
        QuotaPoints = quotaPoints,
    })
end

return TaskService
