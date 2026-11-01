# PANIC SHIFT — Technical Architecture Specification

**Architecture Standard:** Decoupled Service-Controller Pattern (Luau)  
**Security Model:** Authoritative Server with Validated Client Remote Calls  

---

## 1. System Topology & Layers

```
                     +---------------------------------------+
                     |         ROBLOX SERVER ENGINE          |
                     |  (ServerScriptService / ServerStorage)|
                     +---------------------------------------+
                                        |
                 +----------------------+----------------------+
                 |                                             |
       [CORE GAME SERVICES]                          [INFRASTRUCTURE & DATA]
       - RoundService                                - DataService (DataStore2/SessionLock)
       - TaskService                                 - EconomyService
       - DisasterService                             - InventoryService
       - AnalyticsService                            - ChallengeService
                 |                                             |
                 +----------------------+----------------------+
                                        |
                       [DISASTER MODULE REGISTRY]
                       - RunawayCarts, Blackout, etc.
                                        |
                       =================== [NETWORK LAYER] ===================
                       (RemoteEvents / RemoteFunctions in ReplicatedStorage)
                       - RequestTaskAction, DisasterStateChanged, etc.
                       =======================================================
                                        |
                     +---------------------------------------+
                     |         ROBLOX CLIENT ENGINE          |
                     |       (StarterPlayerScripts)          |
                     +---------------------------------------+
                                        |
                 +----------------------+----------------------+
                 |                                             |
       [CLIENT CONTROLLERS]                          [USER INTERFACE & FX]
       - InteractionController                       - UIController (HUD, Shop, Results)
       - InputController                             - EffectsController (Particles, Sounds)
       - CameraController
```

---

## 2. Directory & Namespace Structure

```
PanicShift/
├── default.project.json                 -- Rojo configuration
├── docs/                                -- Authoritative specifications
│   ├── SRS.md
│   ├── GAME_DESIGN.md
│   ├── ARCHITECTURE.md
│   ├── REQUIREMENTS_TRACEABILITY.md
│   └── TEST_PLAN.md
├── src/
│   ├── ReplicatedStorage/
│   │   ├── Shared/
│   │   │   ├── Constants.lua            -- Global enums, remote names, states
│   │   │   ├── Config.lua               -- Central tuning values & catalog
│   │   │   ├── Types.lua                -- Strict Luau type definitions
│   │   │   ├── Utility.lua              -- Reusable math, distance & retry helpers
│   │   │   └── Network.lua              -- Clean Remote Event/Function accessor
│   │   └── Remotes/                     -- Managed remote instances
│   ├── ServerScriptService/
│   │   ├── Bootstrap.server.lua         -- Server initialization & lifecycle
│   │   └── Services/
│   │       ├── RoundService.lua         -- Round state machine & shift lifecycle
│   │       ├── TaskService.lua          -- Dynamic task spawner & atomic validator
│   │       ├── DisasterService.lua      -- Disaster coordinator & director
│   │       ├── EconomyService.lua       -- Wallet, XP curve, and level calculations
│   │       ├── DataService.lua          -- Session-locked DataStore persistence
│   │       ├── InventoryService.lua     -- Cosmetic ownership & equip verifier
│   │       ├── ChallengeService.lua     -- Daily quests and rotation
│   │       ├── PurchaseService.lua      -- Soft-currency shop & receipt processor
│   │       └── AnalyticsService.lua     -- In-game telemetry and funnel events
│   ├── ServerStorage/
│   │   ├── DisasterModules/             -- Modular disaster implementations
│   │   │   ├── RunawayCarts.lua
│   │   │   ├── Blackout.lua
│   │   │   ├── AngryCustomer.lua
│   │   │   ├── ProductAvalanche.lua
│   │   │   ├── SoapApocalypse.lua
│   │   │   └── ManagerMadness.lua
│   │   └── Templates/                   -- Server-side asset templates
│   ├── StarterPlayer/
│   │   └── StarterPlayerScripts/
│   │       ├── ClientBootstrap.client.lua -- Client startup & controller registry
│   │       └── Controllers/
│   │           ├── UIController.lua     -- HUD, Shop, Results, Objective markers
│   │           ├── InputController.lua  -- Keyboard, Gamepad, Touch mappings
│   │           ├── InteractionController.lua -- Raycasting & interaction prompt detection
│   │           ├── CameraController.lua -- Dynamic FOV and camera shake
│   │           └── EffectsController.lua -- Particle spawning and client audio
│   └── StarterGui/
│       └── PanicShiftUI/                -- Responsive screen GUI components
└── tests/
    ├── UNIT_TESTS.md
    ├── MULTIPLAYER_TESTS.md
    └── EXPLOIT_TESTS.md
```

---

## 3. Remote Event & Network Contract

All remotes are centralized under `ReplicatedStorage.PanicShiftRemotes`.

| Remote Identifier | Type | Direction | Payload Schema | Description |
| :--- | :--- | :--- | :--- | :--- |
| `RequestTaskAction` | RemoteFunction | Client $\rightarrow$ Server | `(taskId: string, actionType: string)` $\rightarrow$ `(success: boolean, message: string)` | Interacting with a shelf, mop, order, or repair point. |
| `RequestEquipCosmetic` | RemoteFunction | Client $\rightarrow$ Server | `(cosmeticId: string, slot: string)` $\rightarrow$ `(success: boolean, message: string)` | Equipping a hat or uniform. |
| `RequestPurchaseCosmetic` | RemoteFunction | Client $\rightarrow$ Server | `(cosmeticId: string)` $\rightarrow$ `(success: boolean, message: string)` | Purchasing a shop item with store credits. |
| `RoundStateChanged` | RemoteEvent | Server $\rightarrow$ Client | `(state: string, timerRemaining: number, quotaCurrent: number, quotaTarget: number)` | Updates shift clock and progress bar. |
| `TaskStateChanged` | RemoteEvent | Server $\rightarrow$ Client | `(taskId: string, eventType: string, taskData: table)` | Spawns, updates, or cleans up task markers. |
| `DisasterStateChanged` | RemoteEvent | Server $\rightarrow$ Client | `(disasterId: string, status: string, duration: number, metadata: table)` | Broadcasts warnings, triggers music/lighting, and cleans up client effects. |
| `PlayerProfileUpdated` | RemoteEvent | Server $\rightarrow$ Client | `(profileData: table)` | Sends updated credits, XP, level, inventory to the owner. |
| `RoundResults` | RemoteEvent | Server $\rightarrow$ Client | `(resultsData: table)` | Emits final shift stats, awards, and paychecks. |

---

## 4. Disaster Module Interface

Every disaster script located in `ServerStorage/DisasterModules` must implement the following contract:

```lua
local Disaster = {}

export type DisasterContext = {
    RoundNumber: number,
    PlayerCount: number,
    SupermarketMap: Model,
    Services: table,
    Duration: number,
}

function Disaster.CanStart(context: DisasterContext): boolean
    -- Validates environment, active disasters, and prerequisites
    return true
end

function Disaster.Start(context: DisasterContext): ()
    -- Spawns hazard instances, applies physics, sends notifications
end

function Disaster.Stop(context: DisasterContext): ()
    -- Guaranteed teardown: despawns hazards, restores lighting, clears effects
end

return Disaster
```

---

## 5. Persistence & DataStore Architecture

- **Key Format:** `Player_<UserId>`
- **Storage Strategy:** Versioned JSON table with `schemaVersion`.
- **Session Locking:** On join, an active session token is written. Other servers cannot mutate or overwrite the profile until the lock is released on player departure.
- **Fail-Safe Mechanism:** If a load attempt fails after 3 exponential backoff retries, the player is set to a "Read-Only Fallback" state. Under no circumstances will a blank or default profile overwrite existing data on exit.
