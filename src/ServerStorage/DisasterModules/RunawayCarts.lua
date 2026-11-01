--!strict
--[[
    PANIC SHIFT: Disaster - RunawayCarts.lua
    Disaster 1: Rogue shopping carts move through aisles at high velocity.
    Players must dodge collisions; returning carts into corrals grants bonus credits.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")
local Types = require(Shared:WaitForChild("Types"))
local Utility = require(Shared:WaitForChild("Utility"))

local RunawayCarts = {
    Name = "RunawayCarts",
}

local activeCarts: { Model } = {}
local moverThread: thread? = nil
local cartsFolder: Folder? = nil

-- Constructs a physical shopping cart model
local function createCart(spawnCFrame: CFrame, parentFolder: Folder): Model
    local cartModel = Instance.new("Model")
    cartModel.Name = "RunawayCart"
    cartModel.Parent = parentFolder

    -- Basket Body
    local basket = Instance.new("Part")
    basket.Name = "Basket"
    basket.Size = Vector3.new(3.5, 3.0, 4.5)
    basket.CFrame = spawnCFrame
    basket.Color = Color3.fromRGB(180, 185, 195)
    basket.Material = Enum.Material.Metal
    basket.CanCollide = true
    basket.Anchored = false
    basket.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.1, 0.6) -- Low friction, bouncy
    basket.Parent = cartModel
    cartModel.PrimaryPart = basket

    -- Handlebar
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(3.6, 0.4, 0.4)
    handle.CFrame = spawnCFrame * CFrame.new(0, 1.2, 2.2)
    handle.Color = Color3.fromRGB(235, 95, 20) -- Panic Shift Orange
    handle.Material = Enum.Material.SmoothPlastic
    handle.CanCollide = false
    handle.Anchored = false
    handle.Parent = cartModel

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = basket
    weld.Part1 = handle
    weld.Parent = basket

    -- Directional Mover
    local linearVelocity = Instance.new("LinearVelocity")
    linearVelocity.Name = "CartMover"
    linearVelocity.MaxForce = 15000
    linearVelocity.VectorVelocity = spawnCFrame.LookVector * 28 -- High speed cart
    linearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector

    local attachment = Instance.new("Attachment")
    attachment.Parent = basket
    linearVelocity.Attachment0 = attachment
    linearVelocity.Parent = basket

    -- Proximity Prompt to wrangle/push cart
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Wrangle Cart"
    prompt.ObjectText = "Runaway Shopping Cart"
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 9
    prompt.Parent = basket

    -- Player hit detection (comedic stumble)
    local debounce = false
    basket.Touched:Connect(function(otherPart: BasePart)
        if debounce then return end
        local char = otherPart.Parent
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid and not debounce then
            debounce = true
            -- Knock back and brief stumble
            local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
            if root then
                root.AssemblyLinearVelocity = (root.Position - basket.Position).Unit * 35 + Vector3.new(0, 15, 0)
            end
            task.delay(1.5, function()
                debounce = false
            end)
        end
    end)

    return cartModel
end

function RunawayCarts.CanStart(context: Types.DisasterContext?): boolean
    local map = context and context.SupermarketMap or Workspace:FindFirstChild("SupermarketMap")
    return map ~= nil
end

function RunawayCarts.Start(context: Types.DisasterContext): ()
    print("[Disaster: RunawayCarts] Starting! Rattling cart wheels echoing across aisles.")

    cartsFolder = Instance.new("Folder")
    cartsFolder.Name = "ActiveRunawayCarts"
    cartsFolder.Parent = Workspace

    -- Spawn 5 runaway carts at aisle entrances
    local spawnPositions = {
        CFrame.new(-45, 3, -15) * CFrame.Angles(0, 0, 0),
        CFrame.new(-15, 3, 35) * CFrame.Angles(0, math.rad(180), 0),
        CFrame.new(15, 3, -15) * CFrame.Angles(0, 0, 0),
        CFrame.new(45, 3, 35) * CFrame.Angles(0, math.rad(180), 0),
        CFrame.new(0, 3, 10) * CFrame.Angles(0, math.rad(90), 0),
    }

    for _, cframe in ipairs(spawnPositions) do
        if cartsFolder then
            local cart = createCart(cframe, cartsFolder)
            table.insert(activeCarts, cart)
        end
    end

    -- Mover loop: occasionally change cart directions so they bounce through aisles
    moverThread = task.spawn(function()
        while true do
            task.wait(3.5)
            for _, cart in ipairs(activeCarts) do
                if cart.PrimaryPart then
                    local mover = cart.PrimaryPart:FindFirstChild("CartMover") :: LinearVelocity?
                    if mover then
                        local randomAngle = math.rad(math.random(0, 3) * 90)
                        mover.VectorVelocity = Vector3.new(math.cos(randomAngle) * 26, 0, math.sin(randomAngle) * 26)
                    end
                end
            end
        end
    end)
end

function RunawayCarts.Stop(context: Types.DisasterContext?): ()
    print("[Disaster: RunawayCarts] Stopped and cleaned up.")
    if moverThread then
        task.cancel(moverThread)
        moverThread = nil
    end

    if cartsFolder then
        cartsFolder:Destroy()
        cartsFolder = nil
    end

    for _, cart in ipairs(activeCarts) do
        if cart and cart.Parent then
            cart:Destroy()
        end
    end
    table.clear(activeCarts)
end

return RunawayCarts
