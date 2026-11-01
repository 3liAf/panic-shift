--!strict
--[[
    PANIC SHIFT: Types.lua
    Exported Luau types for strict compile-time checking across services,
    controllers, networks, and data stores.
]]

export type RoundState = "LOBBY" | "PREPARATION" | "ACTIVE" | "CLOSING" | "RESULTS" | "RESET"

export type TaskType = "RESTOCK" | "CLEAN_SPILL" | "DELIVER_ORDER" | "REPAIR" | "RETURN_CART" | "EXTINGUISH_FIRE"

export type TaskData = {
    Id: string,
    Type: TaskType,
    Title: string,
    LocationPart: BasePart?,
    Position: Vector3,
    IsActive: boolean,
    IsCompleted: boolean,
    AssignedPlayer: Player?,
    CreatedAt: number,
    ExpiresAt: number?,
    Metadata: { [string]: any }?,
}

export type DisasterContext = {
    RoundId: string,
    Duration: number,
    SupermarketMap: Model?,
    Services: { [string]: any },
    TelegraphDuration: number,
}

export type LifetimeStats = {
    shiftsCompleted: number,
    shiftsWon: number,
    tasksCompleted: number,
    disastersSurvives: number,
    spillsCleaned: number,
    ordersDelivered: number,
}

export type DailyChallengeProgress = {
    resetKey: string,
    completed: { [string]: boolean },
    progress: { [string]: number },
}

export type UserSettings = {
    musicVolume: number,
    sfxVolume: number,
    screenShake: boolean,
}

export type PlayerProfile = {
    schemaVersion: number,
    credits: number,
    xp: number,
    level: number,
    ownedCosmetics: { string },
    equippedCosmetic: string,
    equippedHat: string?,
    lifetimeStats: LifetimeStats,
    dailyChallenges: DailyChallengeProgress,
    settings: UserSettings,
}

export type NetworkResponse = {
    Success: boolean,
    ErrorCode: string,
    Message: string?,
    Data: any?,
}

export type RoundResultsData = {
    Success: boolean,
    ShiftName: string,
    QuotaReached: number,
    QuotaTarget: number,
    DurationSeconds: number,
    TeamBonusCredits: number,
    IndividualStats: {
        [number]: {
            PlayerName: string,
            TasksCompleted: number,
            CreditsEarned: number,
            XpEarned: number,
            IsMvp: boolean,
        }
    },
}

export type Service = {
    Name: string,
    Init: (self: any, services: { [string]: any }) -> (),
    Start: (self: any) -> (),
    [string]: any,
}

export type Controller = {
    Name: string,
    Init: (self: any, controllers: { [string]: any }) -> (),
    Start: (self: any) -> (),
    [string]: any,
}

return {}
