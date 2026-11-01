// tests/validate_project.js
// Automated offline validation runner for PANIC SHIFT source files and Rojo compilation.

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

let errors = 0;
let passed = 0;

function assert(condition, message) {
    if (!condition) {
        console.error(`❌ FAIL: ${message}`);
        errors++;
    } else {
        console.log(`✅ PASS: ${message}`);
        passed++;
    }
}

console.log("=== PANIC SHIFT: Automated Static Validation Runner ===");

// 1. Verify Essential Project Documentation
const requiredDocs = [
    'README.md',
    'default.project.json',
    'docs/SRS.md',
    'docs/GAME_DESIGN.md',
    'docs/ARCHITECTURE.md',
    'docs/REQUIREMENTS_TRACEABILITY.md',
    'docs/TEST_PLAN.md',
    'tests/UNIT_TESTS.md',
    'tests/MULTIPLAYER_TESTS.md',
    'tests/EXPLOIT_TESTS.md',
];

for (const doc of requiredDocs) {
    const fullPath = path.join(__dirname, '..', doc);
    assert(fs.existsSync(fullPath), `Documentation exists: ${doc}`);
}

// 2. Verify Shared Modules & Exports
const sharedModules = [
    'src/ReplicatedStorage/Shared/Constants.lua',
    'src/ReplicatedStorage/Shared/Config.lua',
    'src/ReplicatedStorage/Shared/Types.lua',
    'src/ReplicatedStorage/Shared/Utility.lua',
    'src/ReplicatedStorage/Shared/Network.lua',
];

for (const mod of sharedModules) {
    const fullPath = path.join(__dirname, '..', mod);
    assert(fs.existsSync(fullPath), `Shared module exists: ${mod}`);
    const content = fs.readFileSync(fullPath, 'utf8');
    assert(content.includes('return'), `Module ${mod} exports a return table`);
}

// 3. Verify Server Services & Lifecycle Contract
const requiredServices = [
    'DataService',
    'AnalyticsService',
    'EconomyService',
    'InventoryService',
    'ChallengeService',
    'PurchaseService',
    'TaskService',
    'DisasterService',
    'RoundService',
];

for (const sName of requiredServices) {
    const file = path.join(__dirname, '..', 'src/ServerScriptService/Services', `${sName}.lua`);
    assert(fs.existsSync(file), `Service exists: ${sName}.lua`);
    const content = fs.readFileSync(file, 'utf8');
    assert(content.includes(':Init(') || content.includes('.Init ='), `Service ${sName} defines Init() lifecycle`);
    assert(content.includes(':Start(') || content.includes('.Start ='), `Service ${sName} defines Start() lifecycle`);
    assert(content.includes(`return ${sName}`), `Service ${sName} returns service table`);
}

// 4. Verify 6 Disaster Modules & Disaster Contract
const disasterModules = [
    'RunawayCarts',
    'Blackout',
    'AngryCustomer',
    'ProductAvalanche',
    'SoapApocalypse',
    'ManagerMadness',
];

for (const dName of disasterModules) {
    const file = path.join(__dirname, '..', 'src/ServerStorage/DisasterModules', `${dName}.lua`);
    assert(fs.existsSync(file), `Disaster module exists: ${dName}.lua`);
    const content = fs.readFileSync(file, 'utf8');
    assert(content.includes('.CanStart'), `Disaster ${dName} implements CanStart()`);
    assert(content.includes('.Start'), `Disaster ${dName} implements Start()`);
    assert(content.includes('.Stop'), `Disaster ${dName} implements Stop()`);
    assert(content.includes(`return ${dName}`), `Disaster ${dName} returns module table`);
}

// 5. Verify Client Controllers & Lifecycle Contract
const clientControllers = [
    'UIController',
    'InputController',
    'InteractionController',
    'CameraController',
    'EffectsController',
];

for (const cName of clientControllers) {
    const file = path.join(__dirname, '..', 'src/StarterPlayer/StarterPlayerScripts/Controllers', `${cName}.lua`);
    assert(fs.existsSync(file), `Controller exists: ${cName}.lua`);
    const content = fs.readFileSync(file, 'utf8');
    assert(content.includes(':Init(') || content.includes('.Init ='), `Controller ${cName} defines Init() lifecycle`);
    assert(content.includes(':Start(') || content.includes('.Start ='), `Controller ${cName} defines Start() lifecycle`);
    assert(content.includes(`return ${cName}`), `Controller ${cName} returns controller table`);
}

// 6. Verify Server and Client Bootstraps
const serverBootstrap = path.join(__dirname, '..', 'src/ServerScriptService/Bootstrap.server.lua');
assert(fs.existsSync(serverBootstrap), 'Server Bootstrap exists');
const clientBootstrap = path.join(__dirname, '..', 'src/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua');
assert(fs.existsSync(clientBootstrap), 'Client Bootstrap exists');

// 7. Verify Balanced Block Delimiters in All Lua Files
function scanDir(dir, list = []) {
    for (const item of fs.readdirSync(dir)) {
        const full = path.join(dir, item);
        if (fs.statSync(full).isDirectory()) {
            scanDir(full, list);
        } else if (item.endsWith('.lua')) {
            list.push(full);
        }
    }
    return list;
}

const allLuaFiles = scanDir(path.join(__dirname, '..', 'src'));
console.log(`\nInspecting syntax delimiter balance across ${allLuaFiles.length} Luau files...`);

for (const filePath of allLuaFiles) {
    const rel = path.relative(path.join(__dirname, '..'), filePath);
    const text = fs.readFileSync(filePath, 'utf8');
    
    // Count paren, brace, and bracket balance
    let parens = 0, braces = 0, brackets = 0;
    let inString = false, stringChar = '';
    
    for (let i = 0; i < text.length; i++) {
        const ch = text[i];
        if (inString) {
            if (ch === stringChar && text[i - 1] !== '\\') {
                inString = false;
            }
        } else {
            if (ch === '"' || ch === "'") {
                inString = true;
                stringChar = ch;
            } else if (ch === '(') parens++;
            else if (ch === ')') parens--;
            else if (ch === '{') braces++;
            else if (ch === '}') braces--;
            else if (ch === '[') brackets++;
            else if (ch === ']') brackets--;
        }
    }
    
    assert(parens === 0, `${rel} has balanced parentheses`);
    assert(braces === 0, `${rel} has balanced curly braces`);
    assert(brackets === 0, `${rel} has balanced square brackets`);
}

// 8. Rojo Place Compilation Test
console.log('\nTesting Rojo place compilation...');
try {
    const outputPlace = path.join(__dirname, '..', 'build_test.rbxlx');
    execSync(`./bin/rojo build -o "${outputPlace}"`, { cwd: path.join(__dirname, '..') });
    assert(fs.existsSync(outputPlace) && fs.statSync(outputPlace).size > 1000, `Rojo compiled valid .rbxlx place (${fs.statSync(outputPlace).size} bytes)`);
    fs.unlinkSync(outputPlace);
} catch (err) {
    assert(false, `Rojo build failed: ${err.message}`);
}

console.log(`\n=== Validation Finished: ${passed} Passed, ${errors} Errors ===`);
if (errors > 0) {
    process.exit(1);
}
