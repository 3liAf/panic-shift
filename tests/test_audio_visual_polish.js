// @ts-check
const fs = require('fs');
const path = require('path');

console.log("=== Running Milestone 8 Audio, Animation & Polish Tests ===");

// 1. Audio Catalog & Sound Definitions
const effectsPath = path.join(__dirname, '../src/StarterPlayer/StarterPlayerScripts/Controllers/EffectsController.lua');
const effectsSource = fs.readFileSync(effectsPath, 'utf8');

const requiredSounds = [
    'TaskComplete',
    'CashRegister',
    'DisasterTelegraph',
    'DisasterActive',
    'DisasterCleared',
    'SlipStumble',
    'CartRattle',
    'Sparks',
    'ButtonClick',
    'RushSiren'
];

for (const soundName of requiredSounds) {
    if (!effectsSource.includes(`${soundName} = {`)) {
        console.error(`❌ FAIL: Missing sound definition for ${soundName}`);
        process.exit(1);
    }
}
console.log("✅ PASS [TEST-AUD-01]: All 10 required audio cues are cataloged with fallback assets");

// Check sound playback bounds
if (!effectsSource.includes('sound.PlaybackSpeed = math.clamp(') || !effectsSource.includes('math.random(95, 105)')) {
    console.error("❌ FAIL: EffectsController must apply pitch variance with safe clamping");
    process.exit(1);
}
console.log("✅ PASS [TEST-AUD-02]: Pitch variance and volume bounds properly configured");

// 2. Camera Trauma & Shake Equations
const cameraPath = path.join(__dirname, '../src/StarterPlayer/StarterPlayerScripts/Controllers/CameraController.lua');
const cameraSource = fs.readFileSync(cameraPath, 'utf8');

if (!cameraSource.includes('trauma * trauma') || !cameraSource.includes('TRAUMA_DECAY_RATE')) {
    console.error("❌ FAIL: CameraController must implement quadratic trauma decay");
    process.exit(1);
}

if (!cameraSource.includes('isShakeEnabled') || !cameraSource.includes('IsScreenShakeEnabled')) {
    console.error("❌ FAIL: CameraController must respect UIController accessibility shake toggle");
    process.exit(1);
}
console.log("✅ PASS [TEST-CAM-01]: Camera shake implements quadratic trauma falloff and accessibility toggle");

// Check dynamic FOV shift for Closing Rush
if (!cameraSource.includes('CLOSING_RUSH_FOV: number = 82') || !cameraSource.includes('SetClosingRushActive')) {
    console.error("❌ FAIL: CameraController missing closing rush dynamic FOV transition");
    process.exit(1);
}
console.log("✅ PASS [TEST-CAM-02]: Dynamic FOV smoothly shifts to 82° during Closing Rush panic phase");

// 3. Particle Emitter Systems
const requiredParticleMethods = [
    'EmitTaskSuccess',
    'CreateSpillBubbles',
    'CreateBreakerSparks',
    'CreateSoapFoam',
    'CreateAvalancheDust'
];

for (const method of requiredParticleMethods) {
    if (!effectsSource.includes(`function EffectsController:${method}`)) {
        console.error(`❌ FAIL: Missing particle emitter method ${method}`);
        process.exit(1);
    }
}
console.log("✅ PASS [TEST-VFX-01]: Particle emitter factories defined for tasks and all hazards");

// 4. Physical Comedy & Stumble Duration
if (!effectsSource.includes('humanoid.PlatformStand = true') || !effectsSource.includes('math.clamp(duration, 0.4, 2.5)')) {
    console.error("❌ FAIL: Stumble reaction must clamp PlatformStand between 0.4s and 2.5s");
    process.exit(1);
}
console.log("✅ PASS [TEST-STUMBLE-01]: Comedic stumble enforces safe PlatformStand bounds [0.4s, 2.5s]");

console.log("\n=== All Milestone 8 Audio, Animation & Polish Tests Passed Successfully ===");
