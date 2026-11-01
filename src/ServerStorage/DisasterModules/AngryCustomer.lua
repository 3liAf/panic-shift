--!strict
--[[
    PANIC SHIFT: Disaster - AngryCustomer.lua
    Disaster 3: An oversized cartoon customer aggressively stalks employees
    demanding to speak to the manager. Employees must avoid being cornered.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")
local Types = require(Shared:WaitForChild("Types"))
local Utility = require(Shared:WaitForChild("Utility"))

local AngryCustomer = {
    Name = "AngryCustomer",
}

local customerNpc: Model? = nil
local aiThread: thread? = nil

-- Creates the oversized cartoon customer model
local function createCustomerNpc(spawnPos: Vector3): Model
    local model = Instance.new("Model")
    model.Name = "AngryCustomerNPC"
    model.Parent = Workspace

    -- Humanoid Root
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(3, 4, 2)
    root.CFrame = CFrame.new(spawnPos)
    root.Transparency = 1
    root.CanCollide = false
    root.Anchored = false
    root.Parent = model
    model.PrimaryPart = root

    -- Torso (Purple flowery dress)
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(4, 5, 2.5)
    torso.CFrame = CFrame.new(spawnPos)
    torso.Color = Color3.fromRGB(180, 50, 160)
    torso.Material = Enum.Material.Fabric
    torso.CanCollide = true
    torso.Anchored = false
    torso.Parent = model

    local torsoWeld = Instance.new("WeldConstraint")
    torsoWeld.Part0 = root
    torsoWeld.Part1 = torso
    torsoWeld.Parent = root

    -- Head & Sunglasses
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(2.5, 2.5, 2.5)
    head.CFrame = CFrame.new(spawnPos + Vector3.new(0, 3.8, 0))
    head.Color = Color3.fromRGB(255, 215, 175)
    head.Material = Enum.Material.SmoothPlastic
    head.CanCollide = false
    head.Anchored = false
    head.Parent = model

    local headWeld = Instance.new("WeldConstraint")
    headWeld.Part0 = torso
    headWeld.Part1 = head
    headWeld.Parent = head

    -- Coupon Book Weapon
    local coupon = Instance.new("Part")
    coupon.Name = "CouponBook"
    coupon.Size = Vector3.new(1.8, 2.2, 0.5)
    coupon.CFrame = CFrame.new(spawnPos + Vector3.new(2.4, 0.5, -1))
    coupon.Color = Color3.fromRGB(240, 230, 80)
    coupon.Material = Enum.Material.SmoothPlastic
    coupon.CanCollide = false
    coupon.Anchored = false
    coupon.Parent = model

    local couponWeld = Instance.new("WeldConstraint")
    couponWeld.Part0 = torso
    couponWeld.Part1 = coupon
    couponWeld.Parent = coupon

    -- Billboard Nameplate
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "🚨 DEMANDS TO SEE THE MANAGER!"
    label.TextColor3 = Color3.fromRGB(255, 40, 40)
    label.Font = Enum.Font.FredokaOne
    label.TextScaled = true
    label.Parent = billboard

    -- Humanoid Controller
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 1000
    humanoid.Health = 1000
    humanoid.WalkSpeed = 20 -- Fast, aggressive pursuit
    humanoid.Parent = model

    -- Comedic tackle detection
    local debounce = false
    torso.Touched:Connect(function(otherPart: BasePart)
        if debounce then return end
        local char = otherPart.Parent
        local h = char and char:FindFirstChildOfClass("Humanoid")
        if h and h ~= humanoid and not debounce then
            debounce = true
            local charRoot = char:FindFirstChild("HumanoidRootPart") :: BasePart?
            if charRoot then
                charRoot.AssemblyLinearVelocity = (charRoot.Position - torso.Position).Unit * 30 + Vector3.new(0, 12, 0)
                h.PlatformStand = true
                task.delay(1.5, function()
                    if h and h.Parent then
                        h.PlatformStand = false
                    end
                end)
            end
            task.delay(2.0, function()
                debounce = false
            end)
        end
    end)

    return model
end

function AngryCustomer.CanStart(context: Types.DisasterContext?): boolean
    return true
end

function AngryCustomer.Start(context: Types.DisasterContext): ()
    print("[Disaster: AngryCustomer] Customer entered demanding a manager!")

    customerNpc = createCustomerNpc(Vector3.new(0, 4, -30))

    -- AI loop: repeatedly finds and paths towards nearest player
    aiThread = task.spawn(function()
        while customerNpc and customerNpc.Parent do
            local humanoid = customerNpc:FindFirstChildOfClass("Humanoid")
            local root = customerNpc.PrimaryPart

            if humanoid and root then
                local nearestPlayer: Player? = nil
                local shortestDist = 9999

                for _, player in ipairs(Players:GetPlayers()) do
                    local char = player.Character
                    local charPos = Utility.GetCharacterPosition(char)
                    if charPos then
                        local dist = (charPos - root.Position).Magnitude
                        if dist < shortestDist then
                            shortestDist = dist
                            nearestPlayer = player
                        end
                    end
                end

                if nearestPlayer and nearestPlayer.Character then
                    local targetPos = Utility.GetCharacterPosition(nearestPlayer.Character)
                    if targetPos then
                        humanoid:MoveTo(targetPos)
                    end
                else
                    -- Wander aisles
                    humanoid:MoveTo(Vector3.new(math.random(-45, 45), 2, math.random(-10, 40)))
                end
            end
            task.wait(0.8)
        end
    end)
end

function AngryCustomer.Stop(context: Types.DisasterContext?): ()
    print("[Disaster: AngryCustomer] Customer stormed out.")
    if aiThread then
        task.cancel(aiThread)
        aiThread = nil
    end

    if customerNpc and customerNpc.Parent then
        customerNpc:Destroy()
        customerNpc = nil
    end
end

return AngryCustomer
