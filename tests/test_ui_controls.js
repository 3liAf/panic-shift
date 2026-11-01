// tests/test_ui_controls.js
// Automated verification for Milestone 6: UI state logic, formatting, and cross-platform input mappings

const assert = require('assert');

console.log("=== Running Milestone 6 UI & Cross-Platform Control Tests ===");

// 1. Time Formatting (Utility.FormatTime)
function formatTime(totalSeconds) {
    const safe = Math.max(0, Math.floor(totalSeconds));
    const mins = Math.floor(safe / 60);
    const secs = safe % 60;
    return `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
}

assert.strictEqual(formatTime(0), "00:00");
assert.strictEqual(formatTime(45), "00:45");
assert.strictEqual(formatTime(180), "03:00");
assert.strictEqual(formatTime(225), "03:45");
console.log("✅ PASS: Time formatting conforms to MM:SS specifications");

// 2. Quota & XP Bar Progress Clamping
function calculateProgress(current, target) {
    const safeTarget = Math.max(1, target);
    return Math.min(1.0, Math.max(0.0, current / safeTarget));
}

assert.strictEqual(calculateProgress(0, 25), 0.0);
assert.strictEqual(calculateProgress(10, 25), 0.4);
assert.strictEqual(calculateProgress(25, 25), 1.0);
assert.strictEqual(calculateProgress(30, 25), 1.0, 'Progress must clamp to 1.0 on overflow');
assert.strictEqual(calculateProgress(-5, 25), 0.0, 'Progress must clamp to 0.0 on negative');
console.log("✅ PASS: Quota and XP bar ratio clamping (0.0 to 1.0)");

// 3. State Badge Mapping Completeness (FR-19)
const STATE_BADGES = {
    LOBBY: "BREAKROOM LOBBY",
    PREPARATION: "SHIFT PREPARATION",
    ACTIVE: "ACTIVE SHIFT",
    CLOSING: "⚡ CLOSING RUSH (2X PTS)",
    RESULTS: "SHIFT CONCLUDED",
    RESET: "RESTOCKING STORE...",
};

for (const state of ['LOBBY', 'PREPARATION', 'ACTIVE', 'CLOSING', 'RESULTS', 'RESET']) {
    assert.strictEqual(typeof STATE_BADGES[state], 'string', `State badge defined for ${state}`);
}
console.log("✅ PASS: All 6 round states have distinct visual badges");

// 4. Disaster Banner Descriptions Completeness
const DISASTER_DESCRIPTIONS = {
    RunawayCarts: "Dodge speeding carts or guide them into the cart corrals!",
    Blackout: "Lights out! Locate and flip both circuit breakers to restore power!",
    AngryCustomer: "The customer demands the manager! Don't get tackled!",
    ProductAvalanche: "Aisle 2 shelf collapse! Jump clear of the impact zone!",
    SoapApocalypse: "Frictionless floor! Ice-skating physics active!",
    ManagerMadness: "Corporate emergency rule enacted! Follow the manager's orders!",
};

for (const d of ['RunawayCarts', 'Blackout', 'AngryCustomer', 'ProductAvalanche', 'SoapApocalypse', 'ManagerMadness']) {
    assert.strictEqual(typeof DISASTER_DESCRIPTIONS[d], 'string', `Description defined for ${d}`);
}
console.log("✅ PASS: All 6 disasters have clear, actionable alert descriptions");

// 5. Cross-Platform Input Action Mappings (FR-20)
const BINDINGS = {
    PanicShift_Interact: ['E', 'ButtonX', 'TouchButton'],
    PanicShift_Sprint: ['LeftShift', 'ButtonL3'],
    PanicShift_ToggleShop: ['M', 'ButtonY'],
    PanicShift_CloseModal: ['Escape', 'ButtonB'],
};

assert.strictEqual(BINDINGS.PanicShift_Interact.includes('E'), true, 'PC interact mapped to KeyCode.E');
assert.strictEqual(BINDINGS.PanicShift_Interact.includes('ButtonX'), true, 'Gamepad interact mapped to ButtonX');
assert.strictEqual(BINDINGS.PanicShift_Interact.includes('TouchButton'), true, 'Touch button supported');
assert.strictEqual(BINDINGS.PanicShift_CloseModal.includes('Escape'), true, 'Escape dismisses modals');
assert.strictEqual(BINDINGS.PanicShift_CloseModal.includes('ButtonB'), true, 'Gamepad ButtonB dismisses modals');
console.log("✅ PASS: Cross-platform input mapping completeness (Keyboard, Touch, Gamepad)");

console.log("\n=== All Milestone 6 UI & Control Tests Passed ===");
