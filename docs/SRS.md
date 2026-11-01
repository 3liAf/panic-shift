# PANIC SHIFT — Software Requirements Specification (SRS)

**Document ID:** PS-SRS-001  
**Version:** 1.0  
**Status:** Proposed baseline  
**Date:** 27 October 2026  
**Target Platform:** Roblox (PC, Mobile, Tablet, Console)  
**Engine:** Roblox Studio + Luau  

---

## 1. Purpose and Scope

**PANIC SHIFT** is a free-to-play Roblox multiplayer comedy-survival experience where 1 to 12 players cooperate as supermarket employees during high-stakes shifts disrupted by escalating comedic disasters. The game combines cooperative objective completion, slapstick physics, short replayable rounds (4–6 minutes), persistent cosmetic progression, and server-authoritative security.

### 1.1 In Scope for Initial Release (Vertical Slice)
- 1 complete, modular supermarket map with lobby and designated disaster zones.
- Multiplayer server supporting 1 to 12 concurrent players.
- Fully server-authoritative round lifecycle state machine (Lobby, Preparation, Active, Closing Rush, Results, Reset).
- 4 core task types: Restock Shelves, Clean Spill, Deliver Order, Repair Equipment.
- 6 independent disaster modules: Runaway Carts, Blackout, Angry Customer, Product Avalanche, Soap Apocalypse, Manager Madness.
- Server-validated task interactions and reward distribution.
- Store credits, XP, levels, and cosmetic inventory system.
- Persistent player profiles using `DataStoreService` with session locks, migration, and failure-safe safeguards.
- In-game cosmetic shop and loadout equipping interface.
- 3 rotating daily challenges and basic achievement badges.
- Responsive cross-platform UI for PC, Mobile, Tablet, and Gamepad.
- Audio cues, procedural animations, and visual telegraphs.
- Telemetry logging, anti-exploit rate-limiting, and distance validation.

### 1.2 Out of Scope for Initial Release
- Trading items between players.
- User-generated marketplace items / UGC creation inside game.
- Complex pet breeding or multi-tier combat systems.
- Multiple independent maps (focused on 1 stellar supermarket map first).
- Ranked matchmaking ladders.
- Paid randomized loot boxes / chance-based monetization.
- External account linking / off-platform web backends.

---

## 2. Stakeholders and User Classes

| User Class | Primary Needs | Key Behaviors |
| :--- | :--- | :--- |
| **Solo / Casual Player** | Understand tasks in seconds, survive hazards, earn quick progression. | Joins public servers, focuses on simple tasks (cleaning, restocking). |
| **Co-op Group / Friends** | Coordinate tasks, laugh at slapstick failures, rescue teammates. | Joins as a party, communicates via voice/chat, clips viral moments. |
| **Returning Player** | Level up, unlock prestige aprons/hats, complete daily streaks. | Checks daily challenges, browses cosmetic shop, optimizes routes. |
| **Game Creator / Engineer** | Add new disasters and tasks without modifying core round engine. | Uses modular interfaces (`Disaster` contract, `Task` registry). |
| **Moderator / Platform** | Ensure compliance with Roblox Terms of Use and safety policies. | Monitors chat filtering, asset licensing, and exploit reports. |

---

## 3. Assumptions and Constraints

1. **Authoritative Engine:** Roblox Studio and Luau runtime.
2. **Security Model:** Strict server authority. The client is a display and input terminal; it can request actions, but the server validates state, distance, cooldowns, and awards.
3. **Data Persistence:** `DataStoreService` calls must be wrapped in `pcall` with exponential backoff and safe default safeguards against data corruption.
4. **Fair Play:** Core gameplay is strictly free-to-play. Cosmetics provide zero competitive advantages.
5. **Multiplayer Scale:** Must run smoothly at 30+ FPS on mid-range mobile devices with 12 players and simultaneous disasters.

---

## 4. Functional Requirements

### 4.1 Player Entry and Round Lifecycle (FR-01 – FR-06)
- **FR-01 [P0] Player Spawning:** Players spawn in a designated safe Lobby. Spawning into moving carts, falling boxes, or active hazard zones is prohibited.
- **FR-02 [P0] Round State Machine:** The server manages exact state transitions: `LOBBY` $\rightarrow$ `PREPARATION` $\rightarrow$ `ACTIVE` $\rightarrow$ `CLOSING` $\rightarrow$ `RESULTS` $\rightarrow$ `RESET`. Invalid state transitions are rejected.
- **FR-03 [P0] Player Count Adaptability:** Studio testing allows 1-player shifts. Production waits for the configured minimum player threshold.
- **FR-04 [P0] Authoritative Timers:** All countdowns are computed and decremented on the server. Clients receive state updates for synchronized display.
- **FR-05 [P0] Team Quota:** Quota scales with player count. The shift is successful if the quota is reached before the closing rush deadline expires.
- **FR-06 [P0] Shift Results:** Detailed end-of-round screen displaying Win/Loss, team tasks completed, MVP ("Employee of the Shift"), credits earned, XP gained, and level-up feedback.

### 4.2 Tasks and Disasters (FR-07 – FR-12)
- **FR-07 [P0] Task Generation:** Server dynamically generates tasks across supermarket zones. Every task has a unique GUID, type, target instance, and reward definition.
- **FR-08 [P0] Interaction Validation:** Server validates player proximity ($\le 12$ studs), carried item prerequisites, task active status, and rate limits.
- **FR-09 [P0] Atomic Task Completion:** Exactly one completion event per task instance. Race conditions and remote spam produce a single validated reward.
- **FR-10 [P0] Disaster Director:** Weighted random selection every 30–45s during `ACTIVE` and `CLOSING` phases. Conflicting simultaneous disasters are prevented.
- **FR-11 [P0] Disaster Lifecycle:** Disasters implement `CanStart`, `Start`, and `Stop` with guaranteed cleanup upon round end, server empty, or script error.
- **FR-12 [P1] Player Recovery:** Comedic failure states (stumble, slipping, ragdoll knockback) have short recovery windows ($\le 2.5$s) with no permanent elimination.

### 4.3 Economy and Persistence (FR-13 – FR-18)
- **FR-13 [P0] Server-Authoritative Rewards:** Store credits and XP are mutated exclusively by server-side services.
- **FR-14 [P1] Level Progression Curve:** XP thresholds scale via quadratic formula: $\text{RequiredXP}(L) = 100 \times L^{1.5}$. Level calculations occur on the server.
- **FR-15 [P1] Cosmetic Inventory:** Tracks owned cosmetic IDs and current equipped uniform/hat. Unauthorized equip requests are rejected.
- **FR-16 [P0] Safe DataStore Persistence:** Atomic session locking and safe write buffers. A failed read will NEVER overwrite an existing save with default data.
- **FR-17 [P1] Daily Challenges:** 3 rotating challenges with 24-hour UTC reset keys. Completion status is saved persistently.
- **FR-18 [P1] Versioned Data Migration:** Saved JSON contains `schemaVersion`. Upgrade migrations run automatically on profile load.

### 4.4 UI, Shop, and Operations (FR-19 – FR-24)
- **FR-19 [P0] In-Game HUD:** Clear display of Shift Timer, Quota Bar, Active Objective Marker, Disaster Warning Banner, and Player Wallet.
- **FR-20 [P0] Multi-Platform Controls:** Full input parity across Mouse/Keyboard, Mobile Touch Action Buttons, and Console Gamepad.
- **FR-21 [P1] Cosmetic Shop:** Server validates wallet balance, deducts credits atomically, and unlocks cosmetic IDs.
- **FR-22 [P2] Robux Product Fulfillment:** If developer products/gamepasses are enabled, receipts must be processed idempotently via `ProcessReceipt`.
- **FR-23 [P1] Telemetry & Analytics:** Logs round starts, outcomes, disaster occurrences, and task completion metrics.
- **FR-24 [P1] Central Configuration:** Timers, quotas, disaster probabilities, and rewards are defined in a single configuration module (`Shared/Config.lua`).

---

## 5. Non-Functional Requirements (NFR)

- **NFR-01 Performance:** Maintain $\ge 30$ FPS on mid-tier mobile hardware (iPhone 11 / Samsung Galaxy A52).
- **NFR-02 Network Optimization:** No per-frame remote traffic. Network packets use compact payloads with throttled rate-limiting.
- **NFR-03 Concurrency:** Server must handle 12 players simultaneously interacting with tasks and hazard physics without tick drops ($< 60\text{ Hz}$ drops).
- **NFR-04 Persistence Safety:** $0\%$ accidental data loss during network blips or unexpected server termination.
- **NFR-05 Security:** 100% server authority against arbitrary currency additions, task completion spoofing, or illegal cosmetic equipping.
- **NFR-06 Robustness:** An uncaught error in a disaster module or player disconnection must never halt the round state machine.
- **NFR-07 Accessibility:** High-contrast text, colorblind-friendly hazard telegraphs (icons + ground decals + audio cues).
- **NFR-08 Maintainability:** Modular decoupled service architecture with single-responsibility principles.
