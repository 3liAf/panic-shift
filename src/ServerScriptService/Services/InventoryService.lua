--!strict
--[[
    PANIC SHIFT: InventoryService.lua
    Server-side cosmetic ownership and character loadout verifier.
]]

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")
local Types = require(Shared:WaitForChild("Types"))
local Config = require(Shared:WaitForChild("Config"))
local Constants = require(Shared:WaitForChild("Constants"))
local Utility = require(Shared:WaitForChild("Utility"))
local Network = require(Shared:WaitForChild("Network"))

local InventoryService = {
    Name = "InventoryService",
}

local services: { [string]: any } = {}
local rateLimiter: (key: any) -> boolean

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

function InventoryService:Init(serviceRegistry: { [string]: any })
    services = serviceRegistry
    rateLimiter = Utility.CreateRateLimiter(Config.RateLimits.EQUIP_MAX_PER_SECOND, 1.0)
end

function InventoryService:Start()
    local equipFunc = Network.GetRemoteFunction(Constants.Remotes.REQUEST_EQUIP_COSMETIC)
    equipFunc.OnServerInvoke = function(player: Player, cosmeticId: any, slot: any): Types.NetworkResponse
        return self:HandleEquipRequest(player, cosmeticId, slot)
    end

    -- Automatically apply 3D cosmetics when characters spawn
    local function onCharacterSpawn(player: Player, character: Model)
        task.wait(0.2)
        self:ApplyCharacterCosmetics(player)
    end

    Players.PlayerAdded:Connect(function(player: Player)
        player.CharacterAdded:Connect(function(char: Model)
            onCharacterSpawn(player, char)
        end)
        if player.Character then
            onCharacterSpawn(player, player.Character)
        end
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        player.CharacterAdded:Connect(function(char: Model)
            onCharacterSpawn(player, char)
        end)
        if player.Character then
            onCharacterSpawn(player, player.Character)
        end
    end
end

-- Checks if player owns a specific cosmetic
function InventoryService:OwnsCosmetic(player: Player, cosmeticId: string): boolean
    local dataService = getService("DataService")
    if not dataService then
        return false
    end

    local profile = dataService:GetProfile(player)
    if not profile then
        return false
    end

    for _, ownedId in ipairs(profile.ownedCosmetics) do
        if ownedId == cosmeticId then
            return true
        end
    end

    return false
end

-- Validates and applies character cosmetic equip
function InventoryService:HandleEquipRequest(player: Player, cosmeticId: any, slot: any): Types.NetworkResponse
    -- Anti-exploit: Rate limit check
    if not rateLimiter(player.UserId) then
        return Utility.CreateErrorResponse(Constants.ErrorCodes.RATE_LIMITED, "Equip requests are rate-limited.")
    end

    -- Argument validation
    if typeof(cosmeticId) ~= "string" or typeof(slot) ~= "string" then
        return Utility.CreateErrorResponse(Constants.ErrorCodes.INVALID_ARGUMENTS, "Invalid cosmetic request parameters.")
    end

    local itemDef = Config.Cosmetics[cosmeticId]
    if not itemDef then
        return Utility.CreateErrorResponse(Constants.ErrorCodes.INVALID_ARGUMENTS, "Cosmetic item does not exist.")
    end

    if not self:OwnsCosmetic(player, cosmeticId) then
        return Utility.CreateErrorResponse(Constants.ErrorCodes.ITEM_NOT_OWNED, "You do not own this cosmetic.")
    end

    local dataService = getService("DataService")
    if not dataService then
        return Utility.CreateErrorResponse(Constants.ErrorCodes.PROFILE_NOT_LOADED, "Profile unavailable.")
    end

    local success = dataService:UpdateProfile(player, function(profile: Types.PlayerProfile)
        if itemDef.Type == "Uniform" then
            profile.equippedCosmetic = cosmeticId
        elseif itemDef.Type == "Headwear" then
            profile.equippedHat = cosmeticId
        end
    end)

    if success then
        self:ApplyCharacterCosmetics(player)
        return Utility.CreateSuccessResponse({ EquippedId = cosmeticId, Slot = slot })
    else
        return Utility.CreateErrorResponse(Constants.ErrorCodes.INVALID_STATE, "Failed to update profile.")
    end
end

-- Renders 3D procedural cosmetic accessories on player character
function InventoryService:ApplyCharacterCosmetics(player: Player): ()
    local character = player.Character
    if not character then return end
    local head = character:FindFirstChild("Head") :: BasePart?
    local torso = (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")) :: BasePart?
    if not head or not torso then return end

    local dataService = getService("DataService")
    if not dataService then return end
    local profile = dataService:GetProfile(player)
    if not profile then return end

    -- 1. Remove previous cosmetic attachments
    for _, child in ipairs(character:GetChildren()) do
        if child.Name == "PanicShift_Hat" or child.Name == "PanicShift_Uniform" then
            child:Destroy()
        end
    end

    -- 2. Attach Headwear
    if profile.equippedHat and profile.equippedHat ~= "" then
        local hatId = profile.equippedHat
        local hatModel = Instance.new("Model")
        hatModel.Name = "PanicShift_Hat"

        if hatId == "paper_bag_hat" then
            local bag = Instance.new("Part")
            bag.Name = "PaperBag"
            bag.Size = Vector3.new(1.6, 1.5, 1.6)
            bag.Color = Color3.fromRGB(185, 145, 95)
            bag.Material = Enum.Material.SmoothPlastic
            bag.CanCollide = false
            bag.Massless = true
            bag.CFrame = head.CFrame * CFrame.new(0, 0.25, 0)
            bag.Parent = hatModel

            local weld = Instance.new("WeldConstraint")
            weld.Part0 = head
            weld.Part1 = bag
            weld.Parent = bag

            for _, xOff in ipairs({ -0.3, 0.3 }) do
                local eye = Instance.new("Part")
                eye.Name = "EyeCutout"
                eye.Size = Vector3.new(0.25, 0.25, 0.05)
                eye.Color = Color3.fromRGB(20, 15, 10)
                eye.Material = Enum.Material.SmoothPlastic
                eye.CanCollide = false
                eye.Massless = true
                eye.CFrame = bag.CFrame * CFrame.new(xOff, 0.1, -0.81)
                eye.Parent = hatModel

                local eyeWeld = Instance.new("WeldConstraint")
                eyeWeld.Part0 = bag
                eyeWeld.Part1 = eye
                eyeWeld.Parent = eye
            end

        elseif hatId == "traffic_cone_hat" then
            local cone = Instance.new("Part")
            cone.Name = "Cone"
            cone.Size = Vector3.new(1.2, 1.8, 1.2)
            cone.Color = Color3.fromRGB(255, 90, 0)
            cone.Material = Enum.Material.Neon
            cone.CanCollide = false
            cone.Massless = true
            cone.CFrame = head.CFrame * CFrame.new(0, 1.1, 0)
            cone.Parent = hatModel

            local weld = Instance.new("WeldConstraint")
            weld.Part0 = head
            weld.Part1 = cone
            weld.Parent = cone

            local band = Instance.new("Part")
            band.Name = "ReflectiveBand"
            band.Size = Vector3.new(1.22, 0.35, 1.22)
            band.Color = Color3.fromRGB(250, 250, 250)
            band.Material = Enum.Material.SmoothPlastic
            band.CanCollide = false
            band.Massless = true
            band.CFrame = cone.CFrame * CFrame.new(0, -0.2, 0)
            band.Parent = hatModel

            local bandWeld = Instance.new("WeldConstraint")
            bandWeld.Part0 = cone
            bandWeld.Part1 = band
            bandWeld.Parent = band

        elseif hatId == "cereal_box_helmet" then
            local box = Instance.new("Part")
            box.Name = "CerealBox"
            box.Size = Vector3.new(1.5, 1.6, 1.1)
            box.Color = Color3.fromRGB(225, 35, 45)
            box.Material = Enum.Material.SmoothPlastic
            box.CanCollide = false
            box.Massless = true
            box.CFrame = head.CFrame * CFrame.new(0, 0.4, 0)
            box.Parent = hatModel

            local weld = Instance.new("WeldConstraint")
            weld.Part0 = head
            weld.Part1 = box
            weld.Parent = box

        elseif hatId == "manager_visor" then
            local visor = Instance.new("Part")
            visor.Name = "Visor"
            visor.Size = Vector3.new(1.6, 0.25, 0.9)
            visor.Color = Color3.fromRGB(30, 160, 90)
            visor.Material = Enum.Material.Glass
            visor.Transparency = 0.35
            visor.CanCollide = false
            visor.Massless = true
            visor.CFrame = head.CFrame * CFrame.new(0, 0.3, -0.6) * CFrame.Angles(math.rad(15), 0, 0)
            visor.Parent = hatModel

            local weld = Instance.new("WeldConstraint")
            weld.Part0 = head
            weld.Part1 = visor
            weld.Parent = visor
        end

        hatModel.Parent = character
    end

    -- 3. Attach Uniform / Apron
    local uniformId = profile.equippedCosmetic or "default_uniform"
    local uniformModel = Instance.new("Model")
    uniformModel.Name = "PanicShift_Uniform"

    local apron = Instance.new("Part")
    apron.Name = "ApronPlate"
    apron.Size = Vector3.new(2.1, 2.05, 1.1)
    apron.CanCollide = false
    apron.Massless = true
    apron.CFrame = torso.CFrame
    apron.Parent = uniformModel

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = torso
    weld.Part1 = apron
    weld.Parent = apron

    if uniformId == "golden_apron" then
        apron.Color = Color3.fromRGB(255, 215, 0)
        apron.Material = Enum.Material.Metal
        local sparkles = Instance.new("ParticleEmitter")
        sparkles.Rate = 5
        sparkles.Lifetime = NumberRange.new(0.5, 1.0)
        sparkles.Speed = NumberRange.new(0.5, 1.2)
        sparkles.Size = NumberSequence.new(0.2, 0.4)
        sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 240, 100))
        sparkles.LightEmission = 0.8
        sparkles.Parent = apron

    elseif uniformId == "hazmat_suit" then
        apron.Color = Color3.fromRGB(240, 220, 30)
        apron.Material = Enum.Material.SmoothPlastic

    elseif uniformId == "manager_suit" then
        apron.Color = Color3.fromRGB(25, 25, 30)
        apron.Material = Enum.Material.Fabric

        local bow = Instance.new("Part")
        bow.Name = "BowTie"
        bow.Size = Vector3.new(0.6, 0.3, 0.2)
        bow.Color = Color3.fromRGB(200, 30, 40)
        bow.Material = Enum.Material.SmoothPlastic
        bow.CanCollide = false
        bow.Massless = true
        bow.CFrame = torso.CFrame * CFrame.new(0, 0.7, -0.6)
        bow.Parent = uniformModel

        local bowWeld = Instance.new("WeldConstraint")
        bowWeld.Part0 = torso
        bowWeld.Part1 = bow
        bowWeld.Parent = bow

    else -- default_uniform
        apron.Color = Color3.fromRGB(35, 95, 200)
        apron.Material = Enum.Material.Fabric
    end

    -- Staff Badge
    local badge = Instance.new("Part")
    badge.Name = "StaffBadge"
    badge.Size = Vector3.new(0.5, 0.3, 0.05)
    badge.Color = Color3.fromRGB(240, 240, 245)
    badge.Material = Enum.Material.SmoothPlastic
    badge.CanCollide = false
    badge.Massless = true
    badge.CFrame = torso.CFrame * CFrame.new(-0.55, 0.45, -0.58)
    badge.Parent = uniformModel

    local badgeWeld = Instance.new("WeldConstraint")
    badgeWeld.Part0 = torso
    badgeWeld.Part1 = badge
    badgeWeld.Parent = badge

    uniformModel.Parent = character
end

return InventoryService
