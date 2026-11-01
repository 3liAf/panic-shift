# PANIC SHIFT — Multiplayer Test Specification

## 1. Concurrency & Race Conditions

| Test ID | Scenario | Procedure | Expected Outcome |
| :--- | :--- | :--- | :--- |
| **TEST-MP-01** | Simultaneous Task Completion | 2 players interact with the exact same shelf box within 10ms of each other. | Server processes one request as successful; second request receives `ALREADY_COMPLETED` response. Only 1 quota point and 1 reward issued. |
| **TEST-MP-02** | Disconnect During Disaster | The targeted player in `AngryCustomer` disconnects mid-chase. | Disaster catches nil target, re-targets nearest active player within 1 second without throwing an unhandled exception. |
| **TEST-MP-03** | Server Empties During Active Shift | All players leave the server during `ACTIVE` phase. | `RoundService` detects 0 players, terminates disaster immediately, runs cleanup, and reverts state to `LOBBY`. |
| **TEST-MP-04** | Late Join During Closing Rush | Player joins server when shift has 15s remaining. | Client receives current round state, timer, and current quota; spawns safely in designated spectator area or safe aisle. |
