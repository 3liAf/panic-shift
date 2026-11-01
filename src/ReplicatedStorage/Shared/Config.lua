--!strict
--[[
    PANIC SHIFT: Config.lua
    Authoritative single source of truth for round timers, quotas,
    task rewards, disaster weighting, cosmetic catalog, and player progression.
]]

local Config = {}

-- Round Timers (in seconds)
Config.RoundTimers = {
    LOBBY_DURATION = 20,          -- Countdown once min players are met
    PREPARATION_DURATION = 30,    -- Pre-shift setup and orientation
    MAIN_SHIFT_DURATION = 180,    -- 3 minutes of standard shift gameplay
    CLOSING_RUSH_DURATION = 45,   -- 45 seconds of frantic quota scramble
    RESULTS_DURATION = 15,        -- Paycheck and MVP celebration
    RESET_DURATION = 5,           -- Level teardown and reset
}

-- Minimum and Maximum Players
Config.ServerConfig = {
    MIN_PLAYERS_TO_START = 1,     -- Set to 1 for solo testing, tuned to 2+ for production
    MAX_PLAYERS_PER_SERVER = 12,
}

-- Quota Scaling Configuration
-- Quota = BaseQuota + (PlayerCount * QuotaPerPlayer)
Config.QuotaConfig = {
    BASE_QUOTA = 15,
    QUOTA_PER_PLAYER = 10,
    CLOSING_RUSH_MULTIPLIER = 2.0, -- Points awarded count double during closing rush
}

-- Task Rewards & Duration Configuration
Config.Tasks = {
    RESTOCK = {
        Id = "RESTOCK",
        Name = "Restock Shelves",
        CreditReward = 10,
        XpReward = 15,
        QuotaPoints = 1,
        InteractionDuration = 1.2, -- Time to hold interaction key
        MaxSimultaneous = 6,
    },
    CLEAN_SPILL = {
        Id = "CLEAN_SPILL",
        Name = "Clean Spill",
        CreditReward = 12,
        XpReward = 18,
        QuotaPoints = 1,
        InteractionDuration = 2.0,
        MaxSimultaneous = 5,
    },
    DELIVER_ORDER = {
        Id = "DELIVER_ORDER",
        Name = "Deliver Order",
        CreditReward = 20,
        XpReward = 25,
        QuotaPoints = 2,
        OrderTimeLimit = 60, -- Seconds to deliver before order expires
        MaxSimultaneous = 3,
    },
    REPAIR = {
        Id = "REPAIR",
        Name = "Repair Equipment",
        CreditReward = 25,
        XpReward = 30,
        QuotaPoints = 2,
        InteractionDuration = 3.0,
        MaxSimultaneous = 4,
    },
    RETURN_CART = {
        Id = "RETURN_CART",
        Name = "Return Shopping Cart",
        CreditReward = 15,
        XpReward = 20,
        QuotaPoints = 1,
        InteractionDuration = 1.0,
        MaxSimultaneous = 3,
    },
    EXTINGUISH_FIRE = {
        Id = "EXTINGUISH_FIRE",
        Name = "Extinguish Fire Hazard",
        CreditReward = 30,
        XpReward = 40,
        QuotaPoints = 3,
        InteractionDuration = 2.5,
        MaxSimultaneous = 2,
    },
}

-- Disaster Director Configuration
Config.Disasters = {
    IntervalMin = 30, -- Seconds between disasters (minimum)
    IntervalMax = 45, -- Seconds between disasters (maximum)
    TelegraphDuration = 4.0, -- Warning alert duration before disaster mechanics activate
    
    Weights = {
        RunawayCarts = 100,
        Blackout = 90,
        AngryCustomer = 85,
        ProductAvalanche = 95,
        SoapApocalypse = 90,
        ManagerMadness = 80,
    },
    
    Durations = {
        RunawayCarts = 25,
        Blackout = 30,
        AngryCustomer = 35,
        ProductAvalanche = 20,
        SoapApocalypse = 25,
        ManagerMadness = 30,
    },
}

-- Cosmetic Items Catalog
Config.Cosmetics = {
    -- Headwear
    paper_bag_hat = {
        Id = "paper_bag_hat",
        Name = "Paper Bag Hat",
        Type = "Headwear",
        Price = 150,
        Description = "Recycled fashion at its finest.",
        AssetId = "rbxassetid://0",
    },
    traffic_cone_hat = {
        Id = "traffic_cone_hat",
        Name = "Traffic Cone Hat",
        Type = "Headwear",
        Price = 1200,
        Description = "Safety first, dignity second.",
        AssetId = "rbxassetid://0",
    },
    cereal_box_helmet = {
        Id = "cereal_box_helmet",
        Name = "Cereal Box Helmet",
        Type = "Headwear",
        Price = 600,
        Description = "Fortified with 12 essential vitamins and defense.",
        AssetId = "rbxassetid://0",
    },
    manager_visor = {
        Id = "manager_visor",
        Name = "Manager Visor",
        Type = "Headwear",
        Price = 900,
        Description = "Projects middle-management authority.",
        AssetId = "rbxassetid://0",
    },
    
    -- Uniforms
    default_uniform = {
        Id = "default_uniform",
        Name = "Staff Apron",
        Type = "Uniform",
        Price = 0,
        Description = "Standard issue polyester supermarket apron.",
        AssetId = "rbxassetid://0",
    },
    golden_apron = {
        Id = "golden_apron",
        Name = "Golden Apron",
        Type = "Uniform",
        Price = 750,
        Description = "Shines brightly amidst the chaos.",
        AssetId = "rbxassetid://0",
    },
    hazmat_suit = {
        Id = "hazmat_suit",
        Name = "Hazmat Suit",
        Type = "Uniform",
        Price = 1800,
        Description = "For when Aisle 4 is completely compromised.",
        AssetId = "rbxassetid://0",
    },
    manager_suit = {
        Id = "manager_suit",
        Name = "Manager Tuxedo",
        Type = "Uniform",
        Price = 2500,
        Description = "Dress for the job you will lose in 3 minutes.",
        AssetId = "rbxassetid://0",
    },
}

-- Daily Challenges Template
Config.DailyChallenges = {
    {
        Id = "DAILY_TASKS_10",
        Description = "Complete 10 supermarket tasks",
        TargetCount = 10,
        CreditReward = 100,
        XpReward = 150,
    },
    {
        Id = "DAILY_SURVIVE_DISASTER_3",
        Description = "Survive 3 disaster events",
        TargetCount = 3,
        CreditReward = 120,
        XpReward = 180,
    },
    {
        Id = "DAILY_CLEAN_SPILLS_5",
        Description = "Mop 5 messy spills",
        TargetCount = 5,
        CreditReward = 90,
        XpReward = 120,
    },
}

-- Progression / XP Calculation
-- Required XP for next level = BaseXP * (CurrentLevel ^ LevelExponent)
Config.Progression = {
    BASE_XP = 100,
    LEVEL_EXPONENT = 1.5,
    
    CalculateRequiredXp = function(level: number): number
        return math.floor(Config.Progression.BASE_XP * (level ^ Config.Progression.LEVEL_EXPONENT))
    end,
}

-- Monetization: Developer Products (Robux -> Credits) & GamePasses
Config.Monetization = {
    Products = {
        SmallCredits = {
            ProductId = 0, -- Replace with live Roblox DevProduct ID
            Name = "500 Credits",
            Credits = 500,
            RobuxPrice = 49,
            Description = "Handy pocketful of store credits.",
            Icon = "💰",
        },
        MediumCredits = {
            ProductId = 0, -- Replace with live Roblox DevProduct ID
            Name = "1,500 Credits",
            Credits = 1500,
            RobuxPrice = 129,
            Description = "Popular pack! Unlock premium uniforms.",
            Icon = "💼",
        },
        LargeCredits = {
            ProductId = 0, -- Replace with live Roblox DevProduct ID
            Name = "5,000 Credits",
            Credits = 5000,
            RobuxPrice = 349,
            Description = "Massive vault! Clear out the apparel catalog.",
            Icon = "🏦",
        },
    },
    GamePasses = {
        DoubleCredits = {
            PassId = 0, -- Replace with live Roblox GamePass ID
            Name = "2x Shift Pay",
            Description = "Permanently doubles all Store Credits earned from every task & round!",
            Icon = "⚡",
            RobuxPrice = 199,
        },
        VipEmployee = {
            PassId = 0, -- Replace with live Roblox GamePass ID
            Name = "VIP Employee",
            Description = "VIP status, exclusive Golden Uniform, & +10% movement speed!",
            Icon = "👑",
            RobuxPrice = 299,
        },
    },
}

-- Official Roblox Badges
Config.Badges = {
    FIRST_SHIFT = {
        BadgeId = 0, -- Replace with live Roblox Badge ID
        Name = "First Day on the Job",
        Description = "Clock in and complete your very first Panic Shift!",
    },
    SHIFT_MVP = {
        BadgeId = 0, -- Replace with live Roblox Badge ID
        Name = "Employee of the Month",
        Description = "Lead the team with the highest task score during a shift!",
    },
    CLEANING_CREW = {
        BadgeId = 0, -- Replace with live Roblox Badge ID
        Name = "Spill Master",
        Description = "Mop 25 messy spills across your supermarket career!",
    },
    CHAOS_SURVIVOR = {
        BadgeId = 0, -- Replace with live Roblox Badge ID
        Name = "Closing Rush Hero",
        Description = "Hit 100% store quota during the frantic Closing Rush!",
    },
}

-- Rate Limiting Configuration (Anti-Exploit)
Config.RateLimits = {
    TASK_ACTION_MAX_PER_SECOND = 4,
    PURCHASE_MAX_PER_SECOND = 2,
    EQUIP_MAX_PER_SECOND = 3,
}

return table.freeze(Config)
