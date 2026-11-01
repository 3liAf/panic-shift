--!strict
--[[
    PANIC SHIFT: Constants.lua
    Central definitions for round states, task types, disaster keys,
    network identifiers, and error codes.
]]

local Constants = {}

-- Round State Machine States
Constants.RoundStates = {
    LOBBY = "LOBBY",
    PREPARATION = "PREPARATION",
    ACTIVE = "ACTIVE",
    CLOSING = "CLOSING",
    RESULTS = "RESULTS",
    RESET = "RESET",
}

-- Core Task Types
Constants.TaskTypes = {
    RESTOCK = "RESTOCK",
    CLEAN_SPILL = "CLEAN_SPILL",
    DELIVER_ORDER = "DELIVER_ORDER",
    REPAIR = "REPAIR",
}

-- Disaster Identifiers
Constants.Disasters = {
    RUNAWAY_CARTS = "RunawayCarts",
    BLACKOUT = "Blackout",
    ANGRY_CUSTOMER = "AngryCustomer",
    PRODUCT_AVALANCHE = "ProductAvalanche",
    SOAP_APOCALYPSE = "SoapApocalypse",
    MANAGER_MADNESS = "ManagerMadness",
}

-- Remote Identifiers
Constants.Remotes = {
    -- RemoteFunctions (Client -> Server with response)
    REQUEST_TASK_ACTION = "RequestTaskAction",
    REQUEST_EQUIP_COSMETIC = "RequestEquipCosmetic",
    REQUEST_PURCHASE_COSMETIC = "RequestPurchaseCosmetic",
    REQUEST_PLAYER_PROFILE = "RequestPlayerProfile",
    
    -- RemoteEvents (Server -> Client broadcast or targeted)
    ROUND_STATE_CHANGED = "RoundStateChanged",
    TASK_STATE_CHANGED = "TaskStateChanged",
    DISASTER_STATE_CHANGED = "DisasterStateChanged",
    PLAYER_PROFILE_UPDATED = "PlayerProfileUpdated",
    ROUND_RESULTS = "RoundResults",
}

-- Disaster Lifecycle States
Constants.DisasterStatus = {
    TELEGRAPH = "TELEGRAPH",
    ACTIVE = "ACTIVE",
    COMPLETED = "COMPLETED",
    CANCELLED = "CANCELLED",
}

-- Security & Validation Error Codes
Constants.ErrorCodes = {
    SUCCESS = "SUCCESS",
    RATE_LIMITED = "RATE_LIMITED",
    OUT_OF_RANGE = "OUT_OF_RANGE",
    TASK_NOT_FOUND = "TASK_NOT_FOUND",
    TASK_ALREADY_COMPLETED = "TASK_ALREADY_COMPLETED",
    INVALID_STATE = "INVALID_STATE",
    ITEM_NOT_OWNED = "ITEM_NOT_OWNED",
    INSUFFICIENT_FUNDS = "INSUFFICIENT_FUNDS",
    INVALID_ARGUMENTS = "INVALID_ARGUMENTS",
    PROFILE_NOT_LOADED = "PROFILE_NOT_LOADED",
}

-- Collision & Interaction Groups
Constants.CollisionGroups = {
    PLAYERS = "PanicShiftPlayers",
    CARTS = "PanicShiftCarts",
    DEBRIS = "PanicShiftDebris",
    BOUNDARIES = "PanicShiftBoundaries",
}

-- Max interaction distance in studs
Constants.MAX_INTERACTION_DISTANCE = 14

return table.freeze(Constants)
