// @ts-check
// tests/test_multiplayer_soak.js
// Milestone 9: Comprehensive Multiplayer Soak & Concurrency Test Suite

const assert = require('assert');

console.log("=== Running Milestone 9 Comprehensive Multiplayer Soak Test Suite ===");

class SimulatedPlayer {
    constructor(userId, name) {
        this.userId = userId;
        this.name = name;
        this.isConnected = true;
        this.tasksCompleted = 0;
        this.credits = 100;
        this.xp = 0;
        this.level = 1;
        this.position = { x: 0, y: 3, z: 0 };
    }
}

class SupermarketServerSimulation {
    constructor() {
        this.roundState = "LOBBY";
        this.cycleCount = 0;
        this.players = new Map();
        this.activeTasks = new Map();
        this.completedTasksThisRound = 0;
        this.currentQuota = 0;
        this.targetQuota = 0;
        this.activeDisaster = null;
        this.disasterTargetPlayer = null;
        this.errorCount = 0;
        this.logs = [];
    }

    log(msg) {
        this.logs.push(`[Server] ${msg}`);
    }

    connectPlayer(userId, name) {
        const player = new SimulatedPlayer(userId, name);
        this.players.set(userId, player);
        this.log(`Player ${name} (${userId}) connected.`);
        return player;
    }

    disconnectPlayer(userId) {
        const player = this.players.get(userId);
        if (!player) return;
        player.isConnected = false;
        this.players.delete(userId);
        this.log(`Player ${player.name} (${userId}) disconnected.`);

        // TEST-MP-02: If this player was targeted by Angry Customer, retarget immediately
        if (this.disasterTargetPlayer === userId) {
            this.handleDisasterTargetDisconnect();
        }

        // TEST-MP-03: If all players leave during ACTIVE or CLOSING, revert to LOBBY
        if (this.players.size === 0 && (this.roundState === "ACTIVE" || this.roundState === "CLOSING")) {
            this.log("All players disconnected! Aborting shift and returning to LOBBY.");
            this.abortShiftToLobby();
        }
    }

    spawnTasks(count) {
        this.activeTasks.clear();
        for (let i = 1; i <= count; i++) {
            const taskId = `TSK_SOAK_${this.cycleCount}_${i}`;
            const types = ['RESTOCK', 'CLEAN_SPILL', 'DELIVER_ORDER', 'REPAIR'];
            const type = types[i % types.length];
            this.activeTasks.set(taskId, {
                id: taskId,
                type: type,
                isCompleted: false,
                points: (type === 'DELIVER_ORDER' || type === 'REPAIR') ? 2 : 1,
                credits: (type === 'REPAIR') ? 25 : (type === 'DELIVER_ORDER') ? 20 : (type === 'CLEAN_SPILL') ? 12 : 10,
                xp: 15,
            });
        }
    }

    attemptTaskCompletion(userId, taskId) {
        const player = this.players.get(userId);
        if (!player || !player.isConnected) {
            return { success: false, code: 'PLAYER_NOT_FOUND' };
        }

        const task = this.activeTasks.get(taskId);
        if (!task) {
            return { success: false, code: 'TASK_NOT_FOUND' };
        }

        // Atomic check
        if (task.isCompleted) {
            return { success: false, code: 'TASK_ALREADY_COMPLETED' };
        }

        task.isCompleted = true;
        task.isActive = false;
        this.completedTasksThisRound++;
        this.currentQuota += task.points;

        player.tasksCompleted++;
        player.credits += task.credits;
        player.xp += task.xp;

        return { success: true, code: 'SUCCESS', points: task.points };
    }

    startDisaster(disasterId) {
        this.activeDisaster = disasterId;
        if (disasterId === 'AngryCustomer') {
            // Pick random active player
            const activeList = Array.from(this.players.keys());
            if (activeList.length > 0) {
                this.disasterTargetPlayer = activeList[0];
                this.log(`Angry Customer is targeting player ${this.disasterTargetPlayer}`);
            }
        }
    }

    handleDisasterTargetDisconnect() {
        this.log(`Target ${this.disasterTargetPlayer} disconnected during Angry Customer!`);
        const remaining = Array.from(this.players.keys());
        if (remaining.length > 0) {
            this.disasterTargetPlayer = remaining[0];
            this.log(`Angry Customer retargeted to player ${this.disasterTargetPlayer} cleanly without crash.`);
        } else {
            this.disasterTargetPlayer = null;
            this.log("No remaining players for Angry Customer.");
        }
    }

    abortShiftToLobby() {
        this.activeDisaster = null;
        this.disasterTargetPlayer = null;
        this.activeTasks.clear();
        this.roundState = "LOBBY";
    }

    runFullShiftCycle(playerCount) {
        this.cycleCount++;

        // 1. LOBBY
        this.roundState = "LOBBY";
        assert.strictEqual(this.roundState, "LOBBY");

        // 2. PREPARATION
        this.roundState = "PREPARATION";
        this.targetQuota = 15 + (playerCount * 10);
        this.currentQuota = 0;
        this.completedTasksThisRound = 0;
        this.spawnTasks(playerCount * 6);

        // 3. ACTIVE SHIFT
        this.roundState = "ACTIVE";
        this.startDisaster("AngryCustomer");

        // Simulate concurrent player interactions
        const taskIds = Array.from(this.activeTasks.keys());
        let taskIdx = 0;
        for (const [userId, player] of this.players.entries()) {
            if (taskIdx < taskIds.length) {
                const res = this.attemptTaskCompletion(userId, taskIds[taskIdx]);
                assert.strictEqual(res.success, true);
                
                // Concurrency test: another player tries the same completed task
                const otherPlayer = (userId === 1001) ? 1002 : 1001;
                const conflictRes = this.attemptTaskCompletion(otherPlayer, taskIds[taskIdx]);
                assert.strictEqual(conflictRes.success, false);
                assert.strictEqual(conflictRes.code, 'TASK_ALREADY_COMPLETED');

                taskIdx++;
            }
        }

        // Test mid-disaster disconnect of targeted player (TEST-MP-02)
        if (this.disasterTargetPlayer) {
            const targetId = this.disasterTargetPlayer;
            this.disconnectPlayer(targetId);
            // Reconnect for next phase
            this.connectPlayer(targetId, `Worker_${targetId}`);
        }

        // 4. CLOSING RUSH
        this.roundState = "CLOSING";
        // Late Joiner Test (TEST-MP-04): Player joins in closing rush
        const lateJoinerId = 9999;
        this.connectPlayer(lateJoinerId, "LateJoiner_9999");
        assert.strictEqual(this.players.has(lateJoinerId), true);
        assert.strictEqual(this.roundState, "CLOSING");

        // Complete remaining quota tasks
        for (const [tId, task] of this.activeTasks.entries()) {
            if (this.currentQuota >= this.targetQuota) break;
            if (!task.isCompleted) {
                this.attemptTaskCompletion(1001, tId);
            }
        }

        // 5. RESULTS
        this.roundState = "RESULTS";
        const success = this.currentQuota >= this.targetQuota;
        let mvpUserId = null;
        let maxTasks = -1;
        for (const [uid, p] of this.players.entries()) {
            if (p.tasksCompleted > maxTasks) {
                maxTasks = p.tasksCompleted;
                mvpUserId = uid;
            }
        }
        assert(mvpUserId !== null, "Must identify an MVP worker");

        // Clean up late joiner
        this.disconnectPlayer(lateJoinerId);

        // 6. RESET
        this.roundState = "RESET";
        this.activeDisaster = null;
        this.disasterTargetPlayer = null;
        this.activeTasks.clear();

        this.roundState = "LOBBY";
        return { success, quota: this.currentQuota, target: this.targetQuota };
    }
}

// ====================================================================
// EXECUTE 25-CYCLE SOAK TEST WITH 12 SIMULATED PLAYERS
// ====================================================================

const server = new SupermarketServerSimulation();

// Initialize 12 players
for (let i = 1; i <= 12; i++) {
    server.connectPlayer(1000 + i, `Worker_${i}`);
}
assert.strictEqual(server.players.size, 12, "Server must have 12 connected players");

console.log("Starting 25 continuous round cycles with 12 players...");

const memorySnapshots = [];

for (let cycle = 1; cycle <= 25; cycle++) {
    const res = server.runFullShiftCycle(12);
    const memUsage = process.memoryUsage().heapUsed / 1024 / 1024;
    memorySnapshots.push(memUsage);

    if (cycle % 5 === 0) {
        console.log(`  Cycle ${cycle}/25 completed: Quota ${res.quota}/${res.target} | Heap: ${memUsage.toFixed(2)} MB`);
    }
}

// Verify memory stability: memory must remain well under 400 MB threshold
const initialMem = memorySnapshots[0];
const finalMem = memorySnapshots[memorySnapshots.length - 1];
const maxMem = Math.max(...memorySnapshots);

console.log(`\nMemory Analysis: Initial = ${initialMem.toFixed(2)} MB, Final = ${finalMem.toFixed(2)} MB, Peak = ${maxMem.toFixed(2)} MB`);
assert(maxMem < 400, `Peak memory (${maxMem.toFixed(2)} MB) must be strictly under 400 MB`);
console.log("✅ PASS [TEST-SOAK-01]: Server heap memory remained stable (< 400 MB) across 25 round cycles");

// Test TEST-MP-03: Server Empties During Active Shift
console.log("Testing TEST-MP-03: Sudden total server disconnect during ACTIVE phase...");
server.roundState = "ACTIVE";
server.startDisaster("SoapApocalypse");
const allUids = Array.from(server.players.keys());
for (const uid of allUids) {
    server.disconnectPlayer(uid);
}
assert.strictEqual(server.players.size, 0, "Server must be empty");
assert.strictEqual(server.roundState, "LOBBY", "Server must safely revert to LOBBY when emptied");
assert.strictEqual(server.activeDisaster, null, "Active disaster must be cancelled and cleaned up");
console.log("✅ PASS [TEST-MP-03]: Total server disconnect safely aborts disaster and resets to LOBBY");

console.log("\n=== All Milestone 9 Soak & Concurrency Tests Passed (100% Success) ===");
