# PANIC SHIFT — Requirements Traceability Matrix

This document maps all Functional Requirements (`FR-01` to `FR-24`) and Non-Functional Requirements (`NFR-01` to `NFR-12`) from the SRS to architectural components, code files, and automated/manual test procedures.

---

## 1. Functional Requirements Matrix

| Req ID | Requirement Description | Priority | Architectural Component | Implementing Source File(s) | Verification Test ID |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FR-01** | Safe Player Spawning | P0 | RoundService | `RoundService.lua` | `TEST-RND-01`, `TEST-MP-01` |
| **FR-02** | Round State Machine | P0 | RoundService | `RoundService.lua`, `Constants.lua` | `TEST-RND-02`, `TEST-UNIT-SM` |
| **FR-03** | Minimum Player Adaptability | P0 | RoundService | `RoundService.lua`, `Config.lua` | `TEST-RND-03` |
| **FR-04** | Authoritative Timers | P0 | RoundService | `RoundService.lua`, `Network.lua` | `TEST-RND-04` |
| **FR-05** | Shift Quota Tracking | P0 | TaskService, RoundService | `TaskService.lua`, `RoundService.lua` | `TEST-TSK-01` |
| **FR-06** | Shift Results Screen | P0 | UIController, RoundService | `UIController.lua`, `RoundService.lua` | `TEST-UI-01` |
| **FR-07** | Dynamic Task Generation | P0 | TaskService | `TaskService.lua`, `Config.lua` | `TEST-TSK-02` |
| **FR-08** | Server-Validated Interactions | P0 | TaskService | `TaskService.lua`, `Utility.lua` | `TEST-SEC-01`, `TEST-TSK-03` |
| **FR-09** | Atomic Task Completion | P0 | TaskService | `TaskService.lua` | `TEST-SEC-02`, `TEST-MP-02` |
| **FR-10** | Disaster Selection Director | P0 | DisasterService | `DisasterService.lua`, `Config.lua` | `TEST-DST-01` |
| **FR-11** | Disaster Lifecycle & Cleanup | P0 | DisasterModules | `ServerStorage/DisasterModules/*.lua` | `TEST-DST-02` |
| **FR-12** | Player Comedic Recovery | P1 | EffectsController, RoundService | `EffectsController.lua` | `TEST-PLY-01` |
| **FR-13** | Authoritative Currency & XP | P0 | EconomyService | `EconomyService.lua` | `TEST-SEC-03` |
| **FR-14** | Level Progression Curve | P1 | EconomyService | `EconomyService.lua`, `Config.lua` | `TEST-UNIT-XP` |
| **FR-15** | Cosmetic Inventory Management | P1 | InventoryService | `InventoryService.lua` | `TEST-INV-01` |
| **FR-16** | Safe DataStore Persistence | P0 | DataService | `DataService.lua`, `Utility.lua` | `TEST-DAT-01`, `TEST-DAT-02` |
| **FR-17** | Daily Challenges & UTC Reset | P1 | ChallengeService | `ChallengeService.lua` | `TEST-CHL-01` |
| **FR-18** | Versioned Data Migration | P1 | DataService | `DataService.lua` | `TEST-UNIT-MIG` |
| **FR-19** | In-Game Shift HUD | P0 | UIController | `UIController.lua` | `TEST-UI-02` |
| **FR-20** | Cross-Platform Input Controls | P0 | InputController | `InputController.lua` | `TEST-INP-01` |
| **FR-21** | In-Game Cosmetic Shop | P1 | PurchaseService | `PurchaseService.lua`, `UIController.lua` | `TEST-SHP-01` |
| **FR-22** | Robux Receipt Fulfillment | P2 | PurchaseService | `PurchaseService.lua` | `TEST-PUR-01` |
| **FR-23** | Telemetry & Analytics | P1 | AnalyticsService | `AnalyticsService.lua` | `TEST-ANL-01` |
| **FR-24** | Centralized Game Configuration | P1 | Shared Config | `Config.lua`, `Constants.lua` | `TEST-UNIT-CFG` |

---

## 2. Non-Functional Requirements Verification

| Req ID | Target Metric | Verification Method | Pass / Fail Criteria |
| :--- | :--- | :--- | :--- |
| **NFR-01** | $\ge 30$ FPS on mid-range mobile | Roblox Studio Device Emulator + Profile | 0 frame drops $< 30$ FPS under 12-player load. |
| **NFR-02** | No per-frame remotes | RemoteEvent spy & static code audit | 0 Remotes fired on `RenderStepped`/`Heartbeat`. |
| **NFR-03** | 12-Player Server Stability | Simulated multiplayer soak test (30 min) | Server memory $< 400$ MB, 0 unhandled script crashes. |
| **NFR-04** | 0% Data Corruption | Fault-injection unit test on DataStore save | Failed reads do not overwrite save data. |
| **NFR-05** | Exploit Immunity | Malicious RemoteFunction parameter fuzzing | All unauthorized reward/inventory calls rejected. |
| **NFR-06** | Disaster Crash Containment | Error simulation during disaster run | `Stop()` runs in protected finalizer; round continues. |
| **NFR-07** | Multimodal Hazard Warning | Visual UI + 3D particle + sound telegraph | Colorblind & audio-muted players spot warnings. |
| **NFR-08** | Codebase Decoupling | Static dependency analysis | Zero circular references between services. |
