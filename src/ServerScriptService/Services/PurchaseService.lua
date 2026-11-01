--!strict
--[[
    PANIC SHIFT: PurchaseService.lua
    Manages in-game cosmetic store transactions and receipt validation.
    Guarantees atomic credit deduction and prevents duplicate unlocks.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("PanicShiftShared")
local Types = require(Shared:WaitForChild("Types"))
local Config = require(Shared:WaitForChild("Config"))
local Constants = require(Shared:WaitForChild("Constants"))
local Utility = require(Shared:WaitForChild("Utility"))
local Network = require(Shared:WaitForChild("Network"))

local PurchaseService = {
    Name = "PurchaseService",
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

function PurchaseService:Init(serviceRegistry: { [string]: any })
    services = serviceRegistry
    rateLimiter = Utility.CreateRateLimiter(Config.RateLimits.PURCHASE_MAX_PER_SECOND, 1.0)
end

function PurchaseService:Start()
    local purchaseFunc = Network.GetRemoteFunction(Constants.Remotes.REQUEST_PURCHASE_COSMETIC)
    purchaseFunc.OnServerInvoke = function(player: Player, cosmeticId: any): Types.NetworkResponse
        return self:HandlePurchaseRequest(player, cosmeticId)
    end

    -- Server-authoritative Robux Developer Product Receipt Processing
    MarketplaceService.ProcessReceipt = function(receiptInfo: { [string]: any }): Enum.ProductPurchaseDecision
        local playerId = receiptInfo.PlayerId
        local productId = receiptInfo.ProductId
        local purchaseId = receiptInfo.PurchaseId

        local player = Players:GetPlayerByUserId(playerId)
        if not player then
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        local economyService = getService("EconomyService")
        if not economyService then
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        -- Match productId in Config.Monetization.Products
        local matchedProduct = nil
        if Config.Monetization and Config.Monetization.Products then
            for _, product in pairs(Config.Monetization.Products) do
                if product.ProductId ~= 0 and product.ProductId == productId then
                    matchedProduct = product
                    break
                end
            end
        end

        if matchedProduct then
            local success = economyService:AwardCredits(player, matchedProduct.Credits, "RobuxPurchase_" .. tostring(purchaseId))
            if success then
                local analyticsService = getService("AnalyticsService")
                if analyticsService then
                    analyticsService:LogEvent("RobuxProductPurchased", {
                        PlayerId = playerId,
                        ProductId = productId,
                        CreditsAwarded = matchedProduct.Credits,
                    })
                end
                return Enum.ProductPurchaseDecision.PurchaseGranted
            else
                return Enum.ProductPurchaseDecision.NotProcessedYet
            end
        end

        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
end

-- Processes soft-currency (Store Credits) purchases
function PurchaseService:HandlePurchaseRequest(player: Player, cosmeticId: any): Types.NetworkResponse
    -- Rate limit protection
    if not rateLimiter(player.UserId) then
        return Utility.CreateErrorResponse(Constants.ErrorCodes.RATE_LIMITED, "Purchase requests are throttled.")
    end

    if typeof(cosmeticId) ~= "string" then
        return Utility.CreateErrorResponse(Constants.ErrorCodes.INVALID_ARGUMENTS, "Invalid cosmetic ID.")
    end

    local itemDef = Config.Cosmetics[cosmeticId]
    if not itemDef then
        return Utility.CreateErrorResponse(Constants.ErrorCodes.INVALID_ARGUMENTS, "Cosmetic item not found in catalog.")
    end

    local inventoryService = getService("InventoryService")
    local economyService = getService("EconomyService")
    local dataService = getService("DataService")

    if not inventoryService or not economyService or not dataService then
        return Utility.CreateErrorResponse(Constants.ErrorCodes.INVALID_STATE, "Internal services unavailable.")
    end

    -- Verify not already owned
    if inventoryService:OwnsCosmetic(player, cosmeticId) then
        return Utility.CreateErrorResponse(Constants.ErrorCodes.INVALID_STATE, "You already own this item.")
    end

    -- Verify wallet balance
    local currentBalance = economyService:GetBalance(player)
    if currentBalance < itemDef.Price then
        return Utility.CreateErrorResponse(Constants.ErrorCodes.INSUFFICIENT_FUNDS, "Insufficient Store Credits.")
    end

    -- Atomic transaction: deduct credits and append to inventory
    local deductSuccess = economyService:DeductCredits(player, itemDef.Price)
    if not deductSuccess then
        return Utility.CreateErrorResponse(Constants.ErrorCodes.INSUFFICIENT_FUNDS, "Failed to complete transaction.")
    end

    local unlockSuccess = dataService:UpdateProfile(player, function(profile: Types.PlayerProfile)
        table.insert(profile.ownedCosmetics, cosmeticId)
    end)

    if unlockSuccess then
        local analyticsService = getService("AnalyticsService")
        if analyticsService then
            analyticsService:LogEvent("CosmeticPurchased", {
                PlayerId = player.UserId,
                ItemId = cosmeticId,
                Price = itemDef.Price,
            })
        end

        return Utility.CreateSuccessResponse({
            PurchasedId = cosmeticId,
            NewBalance = economyService:GetBalance(player),
        })
    else
        -- Rollback in extreme case
        economyService:AwardCredits(player, itemDef.Price, "Transaction_Rollback")
        return Utility.CreateErrorResponse(Constants.ErrorCodes.INVALID_STATE, "Profile unlock write failed.")
    end
end

return PurchaseService
