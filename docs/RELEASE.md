# PANIC SHIFT: Survive the Night — Release Documentation & Publishing Guide

**Document ID:** PS-REL-001  
**Version:** 1.0.0 (Production Release Baseline)  
**Target Platform:** Roblox (Desktop, Mobile, Tablet, Console)  
**Engine:** Roblox Studio + Luau (Rojo Managed)  

---

## 1. Storefront Metadata & Copy

### 1.1 Game Title & Tagline
- **Title:** `PANIC SHIFT: Survive the Night 🛒💥`
- **Short Tagline:** *One store. One shift. Absolutely everything goes wrong.*

### 1.2 Experience Description (Roblox Web & App)
```text
🛒 WELCOME TO PANIC SHIFT!
Can you survive the most chaotic supermarket shift of your life?

Work together with up to 12 employees to restock shelves, mop spills, pack grocery deliveries, and fix faulty electrical panels before your shift ends!

⚠️ BUT THERE'S A CATCH...
Every 30 seconds, disaster strikes the store:
🛒 Speeding shopping carts careen through the aisles!
⚡ The power cuts out — find the breaker boxes before pitch black!
😡 The Karen Customer demands the manager and starts tackling anyone nearby!
📦 Aisle 2 shelves collapse into an avalanche of cereal and beans!
🧼 Friction vanishes as the floor turns into an ice rink of soap!
📢 The Store Manager announces unhinged emergency workplace rules!

⭐ HOW TO PLAY:
1. 📦 COMPLETE TASKS: Find glowing task stations around the store and interact.
2. ⚠️ SURVIVE HAZARDS: Follow the warning sirens when a disaster triggers!
3. ⏱️ HIT THE QUOTA: Double points activate during the frantic 45-second CLOSING RUSH!
4. 💰 GET PAID: Earn Store Credits, level up, and unlock hilarious uniforms and hats!

🎮 CONTROLS:
• PC: [WASD] Move | [E] Interact / Complete Task | [Shift] Sprint
• Mobile: Virtual Joystick + Action Touch Button
• Gamepad: [Left Stick] Move | [Button X] Interact | [L2] Sprint

👍 Thumbs up and Favorite if you survived your shift!
Created with strict server authority, 60 FPS physics, and zero lag.
```

---

## 2. Onboarding & First-Time User Experience (FTUE)

### 2.1 The "5-Second Rule" Tutorial Script
When a first-time player joins the Breakroom Lobby, an interactive 3-card tutorial prompt introduces the core gameplay:

* **Slide 1: YOUR SHIFT OBJECTIVE**
  > *"Welcome to Mart-Panic! Your team has a collective Store Quota. Complete tasks around the supermarket to earn Quota points and increase your paycheck."*
  > *Visual: Highlight of the top Quota bar and Restock shelf.*

* **Slide 2: DISASTER PROTOCOL**
  > *"Supermarket hazards strike without warning. When the top siren sounds, drop what you're doing: dodge speeding carts, repair breakers during blackouts, and run from furious customers!"*
  > *Visual: Highlight of the hazard alert banner.*

* **Slide 3: CLOSING RUSH & PAYDAY**
  > *"In the final 45 seconds of each shift, Closing Rush begins — all task points count DOUBLE! Hit the target quota to earn bonus Store Credits and level up in the Breakroom Shop."*
  > *Visual: Highlight of the Shop drawer button and paycheck results modal.*

---

## 3. Creative Asset Briefs (Marketing & Icons)

### 3.1 Experience Icon (512 x 512 px)
- **Primary Subject:** High-energy comedic action shot of a Roblox employee wearing a bright blue apron and a traffic cone hat slipping backwards into a pile of canned beans.
- **Background:** High-contrast supermarket aisle with dynamic yellow hazard stripes, a runaway shopping cart caught mid-air, and flashing red emergency strobe lights.
- **Typography:** Bold, angled, chunky comic-style text reading **PANIC SHIFT** with a yellow caution tape texture and drop shadow.
- **Color Palette:** Saturated Royal Blue (`#2B54D4`), Safety Amber (`#FFB800`), Danger Red (`#E02E2E`), Clean White highlights.

### 3.2 Thumbnail 1: "The Supermarket Hazard" (1920 x 1080 px)
- **Scene:** 3 players cooperating frantically. Player 1 is desperately holding a mop on a slippery soap surface; Player 2 is fleeing from a giant comical angry customer NPC waving a receipt; Player 3 is holding a product box diving over a runaway cart.
- **Lighting:** Warm interior retail lighting dramatically split by emergency red siren rotating beacons.

### 3.3 Thumbnail 2: "Closing Rush Frenzy" (1920 x 1080 px)
- **Scene:** Wide-angle dramatic perspective of Checkouts 1 through 4 during Closing Rush. Neon signs flashing "2X POINTS ACTIVE". Digital timer overhead reads `00:18`.
- **Characters:** Multiple employees leaping over cash registers carrying grocery sacks, high-fiving, with sparkle particle confetti erupting.

### 3.4 Thumbnail 3: "Breakroom Drip & Customization" (1920 x 1080 px)
- **Scene:** The staff breakroom displaying character customization. Characters posing with Paper Bag Hats, Cereal Box Helmets, Golden Aprons, and Hazmat Suits.

---

## 4. Production Publishing Checklist

### 4.1 Roblox Studio Place Settings
- [x] **Basic Info:** Name and description populated.
- [x] **Avatar Configuration:** Set to **R15** standard avatar scaling. Enable player collision groups.
- [x] **Security Settings:**
  - [x] **Enable Studio Access to API Services:** `TRUE` (Required for live DataStoreService testing).
  - [x] **Allow Third Party Purchases:** `FALSE` (Enforces internal catalog security).
  - [x] **Allow Third Party Teleports:** `FALSE`.
- [x] **Places & Server Sizing:**
  - [x] **Maximum Player Count:** 12 Players.
  - [x] **Server Fill Mode:** "Roblox will optimize fill" (ensures active lobbies).
- [x] **Device Compatibility:**
  - [x] Desktop / Laptop (PC / Mac)
  - [x] Mobile Phones (iOS / Android)
  - [x] Tablets (iPad / Android Tablet)
  - [x] Console (PlayStation / Xbox with gamepad mapping)

### 4.2 DataStore & Economy Protection
- [x] Schema versioning enabled (v1 with automatic migration).
- [x] Session locking / anti-corruption overwrite prevention active.
- [x] Authoritative server currency mutations (Zero client remote trust).
- [x] Token-bucket rate limiting applied to all network remotes.

---

## 5. Rojo Build Instructions

To compile the standalone production place file from source:
```bash
./bin/rojo build -o PanicShift_Release.rbxlx
```

To publish directly to Roblox via Rojo (with auth cookie configured):
```bash
./bin/rojo upload --asset_id <YOUR_UNIVERSE_ID>
```
