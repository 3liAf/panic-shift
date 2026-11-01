# PANIC SHIFT — Unit Test Specification

## 1. Test Suite Overview

Unit tests evaluate pure computational logic, schema migrations, and utility methods independent of the Roblox engine runtime.

| Test ID | Target Module | Function / Logic | Expected Behavior |
| :--- | :--- | :--- | :--- |
| **TEST-UNIT-CFG** | `Config.lua` | Schema validation | All required constants, prices, durations, and weights exist and are positive numbers. |
| **TEST-UNIT-XP** | `EconomyService.lua` | Level & XP calculations | Level 1: 0 XP; Level 2: 100 XP; Level 5: 1118 XP; calculates correct level from total XP. |
| **TEST-UNIT-RATELIMIT**| `Utility.lua` | `CreateRateLimiter` | Rejects requests exceeding threshold within the sliding time window. |
| **TEST-UNIT-MIG** | `DataService.lua` | `MigrateProfile` | Upgrades schema v0/v1 data structures safely while preserving balances and unlocked items. |
| **TEST-UNIT-STATE** | `RoundService.lua` | State Transition Rules | Only valid transitions allowed: `LOBBY` $\rightarrow$ `PREPARATION` $\rightarrow$ `ACTIVE` $\rightarrow$ `CLOSING` $\rightarrow$ `RESULTS` $\rightarrow$ `RESET`. |
