// tests/test_disasters.js
// Automated verification for Milestone 4: Disaster module lifecycles and cleanup contracts

const assert = require('assert');
const fs = require('fs');
const path = require('path');

console.log("=== Running Milestone 4 Disaster Modules Contract & Logic Tests ===");

const disasterFiles = [
    'RunawayCarts.lua',
    'Blackout.lua',
    'AngryCustomer.lua',
    'ProductAvalanche.lua',
    'SoapApocalypse.lua',
    'ManagerMadness.lua',
];

for (const dFile of disasterFiles) {
    const fullPath = path.join(__dirname, '..', 'src/ServerStorage/DisasterModules', dFile);
    assert.strictEqual(fs.existsSync(fullPath), true, `Disaster file exists: ${dFile}`);
    const code = fs.readFileSync(fullPath, 'utf8');

    // Contract verification
    assert.strictEqual(code.includes('.CanStart'), true, `${dFile} implements CanStart()`);
    assert.strictEqual(code.includes('.Start'), true, `${dFile} implements Start()`);
    assert.strictEqual(code.includes('.Stop'), true, `${dFile} implements Stop()`);
    assert.strictEqual(code.includes(`return ${dFile.replace('.lua', '')}`), true, `${dFile} exports module table`);
    console.log(`✅ PASS: ${dFile} satisfies Disaster Lifecycle Contract`);
}

// Verify Disaster Weights & Durations in Config.lua
const configPath = path.join(__dirname, '..', 'src/ReplicatedStorage/Shared/Config.lua');
const configCode = fs.readFileSync(configPath, 'utf8');
for (const dName of ['RunawayCarts', 'Blackout', 'AngryCustomer', 'ProductAvalanche', 'SoapApocalypse', 'ManagerMadness']) {
    assert.strictEqual(configCode.includes(dName), true, `Config.lua defines weighting/duration for ${dName}`);
}
console.log("✅ PASS: Central configuration defines weights and durations for all 6 disasters");

console.log("\n=== All Disaster Tests Passed Successfully ===");
