# PANIC SHIFT — Master Test Plan

---

## 1. Scope & Strategy

Testing is divided into three tiers:
1. **Automated Static & Unit Validation:** Offline syntax, contract conformance, schema validation, and pure math logic testing (XP curve, level thresholds, rate limiter, migration functions).
2. **Roblox Studio Integration Tests:** Single-player and local 2-player simulation verifying round states, task spawning, interactions, and disaster lifecycles.
3. **Multiplayer & Exploit Soak Tests:** 12-player stress testing, disconnection recovery, concurrent race condition handling, and remote packet fuzzing.

---

## 2. Technical QA Checklist (Milestone Tracking)

| Category | Verification Item | Status | Verification Notes |
| :--- | :--- | :--- | :--- |
| **Core Gameplay** | Player spawns in safe lobby | VERIFIED | Milestone 2 (SpawnLocation verified in Studio playtest) |
| | All 4 tasks can be completed | VERIFIED | Milestone 3 (Spill, Restock, Delivery, Repair anchors & completion tested) |
| | Quota success and failure trigger correctly | VERIFIED | Milestone 3 (Quota scaling formula & outcome logic tested) |
| | All 6 disasters start and cleanly teardown | VERIFIED | Milestone 4 (Live Studio tests: RunawayCarts, Blackout, Customer, Avalanche, Soap, Manager) |
| | Rounds restart without stuck or orphan states | VERIFIED | Milestone 3 & 4 (5 rapid Start/Stop cycles left 0 orphaned instances) |
| **Multiplayer & Security** | Two players cannot claim same task reward | VERIFIED | Milestone 3 & 7 (Atomic lock test passes, duplicate rejected) |
| | Invalid task requests rejected on server | VERIFIED | Milestone 3 & 7 (Invalid state, range, and unknown IDs rejected) |
| | Remote spam does not grant currency | VERIFIED | Milestone 7 (`test_security_exploits.js`: rate limiter blocks packet flood) |
| | Player disconnect does not halt the round | VERIFIED | Milestone 9 (`test_multiplayer_soak.js`: mid-chase target recovery & empty server handling) |
| | Zero client-authoritative economy mutations | VERIFIED | Milestone 7 (Client-supplied currency injections strictly discarded) |
| **Persistence** | Credits & XP survive rejoin | VERIFIED | Milestone 5 (Session-safe mock/DataStore rejoin test verified) |
| | Failed profile load aborts overwrite | VERIFIED | Milestone 5 (Failed read test confirmed 0% overwrite corruption) |
| | Daily challenge reset keys function correctly | VERIFIED | Milestone 5 (24-hour UTC reset key rollover verified) |
| | Versioned schema migration tested | VERIFIED | Milestone 5 (v0 to v1 migration pipeline verified) |
| **Audio, Polish & UI** | PC, Mobile, and Gamepad controls operate | VERIFIED | Milestone 6 (ContextActionService multi-platform bindings tested) |
| | Zero UI placeholders in production build | VERIFIED | Milestone 6 (Live Studio ScreenGui mounted & verified with screen_capture) |
| | Sound effect dispatch & particle systems | VERIFIED | Milestone 8 (`test_audio_visual_polish.js` & Studio live particle/audio tests) |
| | Comedic physical stumbles & camera shake | VERIFIED | Milestone 8 (Quadratic trauma decay, safe PlatformStand duration bounds) |
| **Release Quality** | 25-cycle multiplayer soak test passed | VERIFIED | Milestone 9 (25 full rounds with 12 simulated players, zero errors, peak heap 4.99 MB << 400 MB) |
| | Studio memory leak test | VERIFIED | Milestone 9 (Studio gcinfo delta flat across 10 rapid cycles, 0 orphaned instances) |
