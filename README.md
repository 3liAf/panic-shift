# PANIC SHIFT: Survive the Night

> **Tagline:** One store. One shift. Absolutely everything goes wrong.  
> **Platform:** Roblox (PC, Mobile, Tablet, Console)  
> **Engine:** Roblox Studio + Luau  

---

## 1. Project Overview

**PANIC SHIFT** is a fast-paced multiplayer comedy-survival game. 1 to 12 players cooperate as supermarket associates racing to restock shelves, mop chemical spills, fulfill customer orders, and repair malfunctioning equipment—all while the store is randomly struck by catastrophic comedic disasters (runaway carts, total blackouts, rampaging customers, soap floods, and manager madness).

---

## 2. Directory Structure

```
PanicShift/
├── default.project.json             # Rojo project file
├── README.md
├── docs/
│   ├── SRS.md                       # Authoritative Software Requirements (PS-SRS-001)
│   ├── GAME_DESIGN.md               # Game Design Document (GDD)
│   ├── ARCHITECTURE.md              # Technical Architecture Specification
│   ├── REQUIREMENTS_TRACEABILITY.md # Traceability Matrix (FR-01 to FR-24)
│   └── TEST_PLAN.md                 # Master QA & Testing Plan
├── src/
│   ├── ReplicatedStorage/
│   │   ├── Shared/
│   │   │   ├── Constants.lua        # Enums, remote names, error codes
│   │   │   ├── Config.lua           # Authoritative balance & catalog
│   │   │   ├── Types.lua            # Strict Luau types
│   │   │   ├── Utility.lua          # Math, rate limiter, retry backoff
│   │   │   └── Network.lua          # Central Remote accessor
│   │   └── Remotes/
│   ├── ServerScriptService/
│   │   ├── Bootstrap.server.lua     # Server entry & lifecycle manager
│   │   └── Services/                # Authoritative server services
│   │       ├── RoundService.lua
│   │       ├── TaskService.lua
│   │       ├── DisasterService.lua
│   │       ├── EconomyService.lua
│   │       ├── DataService.lua
│   │       ├── InventoryService.lua
│   │       ├── ChallengeService.lua
│   │       ├── PurchaseService.lua
│   │       └── AnalyticsService.lua
│   ├── ServerStorage/
│   │   ├── DisasterModules/         # Modular disaster scripts
│   │   │   ├── RunawayCarts.lua
│   │   │   ├── Blackout.lua
│   │   │   ├── AngryCustomer.lua
│   │   │   ├── ProductAvalanche.lua
│   │   │   ├── SoapApocalypse.lua
│   │   │   └── ManagerMadness.lua
│   │   └── Templates/
│   ├── StarterPlayer/
│   │   └── StarterPlayerScripts/
│   │       ├── ClientBootstrap.client.lua # Client entry point
│   │       └── Controllers/               # Client controllers
│   │           ├── UIController.lua
│   │           ├── InputController.lua
│   │           ├── InteractionController.lua
│   │           ├── CameraController.lua
│   │           └── EffectsController.lua
│   └── StarterGui/
│       └── PanicShiftUI/
└── tests/
    ├── UNIT_TESTS.md
    ├── MULTIPLAYER_TESTS.md
    └── EXPLOIT_TESTS.md
```

---

## 3. Quickstart & Rojo Setup

### Building the Project
To compile the Luau source into a full Roblox place file (`.rbxlx`):
```bash
./bin/rojo build -o PanicShift.rbxlx
```

### Live Syncing with Roblox Studio
1. Start the Rojo development server:
   ```bash
   ./bin/rojo serve
   ```
2. In Roblox Studio, install and open the **Rojo** plugin.
3. Click **Connect** (default port `34872`). Studio will sync all files in real-time.

---

## 4. Verification and Validation

Run the automated offline static test suite:
```bash
node tests/validate_project.js
```
And build verification:
```bash
./bin/rojo build -o build_test.rbxlx
```

---

## 5. Development Milestones

- [x] **Milestone 1: Project Foundation** (Architecture, Shared modules, Service-Controller lifecycle, Remote contracts, Rojo config)
- [ ] **Milestone 2: Playable Supermarket** (Modular 3D geometry, aisles, checkouts, stockroom, hazard zones)
- [ ] **Milestone 3: Full Playable Loop** (Tasks, Quota tracking, Closing rush, Results calculation)
- [ ] **Milestone 4: Disasters** (Runaway Carts, Blackout, Angry Customer, Product Avalanche, Soap Apocalypse, Manager Madness)
- [ ] **Milestone 5: Player Progression** (DataStore persistence, Session locking, Daily challenges, Inventory)
- [ ] **Milestone 6: Complete UI** (HUD, Alerts, Shop, Results modal, Mobile Touch controls)
- [ ] **Milestone 7: Security Audit** (Exploit tests, distance verifiers, rate limits)
- [ ] **Milestone 8: Audio & Polish** (SFX, character stumble physics, particles)
- [ ] **Milestone 9: QA & Soak Testing** (Multiplayer stress tests, fault injection)
- [ ] **Milestone 10: Release Readiness** (Production checklist, store creative briefs)
