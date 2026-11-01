# PANIC SHIFT — Game Design Document (GDD)

**Tagline:** One store. One shift. Absolutely everything goes wrong.  
**Genre:** Multiplayer Comedy-Survival / Social Party Simulator  
**Target Audience:** Roblox players aged 9–25 who enjoy high-energy co-op (Overcooked, Lethal Company, Slap Battles).  

---

## 1. Core Vision & Pillars

1. **Immediate Comprehension (The 5-Second Rule):**  
   Every player immediately understands their objective: *“Work in the supermarket, fulfill orders, don't get obliterated by the disasters.”*
2. **Organic Slapstick Comedy:**  
   Players don't just fail; they fail *hilariously*. Ragdolling across freshly mopped detergent, being chased by a colossal coupon-waving customer, or watching a wall of canned beans collapse over a teammate creates viral clip moments.
3. **Cooperative Synergy without High Friction:**  
   No permanent player elimination. When a player slips or gets tackled, teammates can help them up in 1.5 seconds or complete their dropped order.
4. **Snappy Replayability:**  
   Short 4-minute shifts mean quick dopamine hits, immediate rewards, and constant “one more round” momentum.

---

## 2. Shift Structure & Round Phases

| Phase | Duration | Core Objective | Audio / Visual Mood |
| :--- | :--- | :--- | :--- |
| **1. Lobby** | Variable (15s if ready) | Gear up, equip aprons/hats, vote or view next shift modifiers. | Cheerful elevator musak, bright warm lobby lights. |
| **2. Preparation** | 30 seconds | Teleport to aisles, grab mops and stock boxes, review team quota. | Upbeat shift briefing jingle, morning supermarket chimes. |
| **3. Main Shift** | 3 minutes | Complete tasks as quota rises; random disasters strike every 35s. | Energetic supermarket groove; sirens & alarms during disasters. |
| **4. Closing Rush** | 45 seconds | Double task point value, remaining quota rush, heightened hazard speed. | Fast-paced high-tempo percussion, flashing yellow warning lights. |
| **5. Results** | 15 seconds | Paycheck breakdown, XP bar fill, MVP spotlight, funny awards. | Victory celebratory fanfare or sad trombone whistle. |
| **6. Reset** | 5 seconds | Map cleanup, despawn temporary props, return players to lobby. | Fade-to-black wipe. |

---

## 3. Core Task Mechanics

### A. Restock the Shelves
- **Location:** Stockroom pallet $\rightarrow$ Marked Empty Shelf.
- **Workflow:** Player presses [E] / Tap at the stockroom to hoist a box over their head. Player carries it to a glowing yellow shelf marker and holds interaction for 1.2s.
- **Reward:** 10 Credits, 15 XP, +1 Quota.
- **Comedy Factor:** Carrying a tall box restricts forward vision slightly; colliding with carts knocks the box away.

### B. Clean the Spill
- **Location:** Randomly generated liquid puddle (Juice, Detergent, Tomato Sauce).
- **Workflow:** Player equips mop tool, interacts with spill puddle for 2.0s.
- **Reward:** 12 Credits, 18 XP, +1 Quota.
- **Hazard Risk:** If uncleaned for 45s, the spill doubles in radius and causes anyone sprinting over it to slip and slide 20 studs into shelves.

### C. Deliver an Order
- **Location:** Bakery / Deli / Produce counter $\rightarrow$ Register checkout conveyer belt.
- **Workflow:** Order ticket appears on store announcement board (e.g., "Order #4: 2x Apples, 1x Milk"). Player retrieves items and places them on Register 1 or 2 before the 60s order timer expires.
- **Reward:** 20 Credits, 25 XP, +2 Quota.
- **Teamwork Dynamic:** One player tosses items from behind the deli counter to a runner in the aisle.

### D. Repair Store Equipment
- **Location:** Sparking Freezer unit, Jammed Register, or Breaker Box.
- **Workflow:** Mini-interaction: Player triggers a 3-step sequence (Quick-Time Event: Press 1-2-3 or tap matching colored wires).
- **Reward:** 25 Credits, 30 XP, +2 Quota.

---

## 4. Disaster Director & Catalog

The Disaster Director evaluates store conditions every 35–45 seconds.

### Disaster 1: Runaway Shopping Carts
- **Telegraph (5s):** Loud rattling wheels over PA system, red flashing arrows on aisle floors.
- **Effect (25s):** 6 rogue shopping carts rocket through aisles at high velocity bouncing off walls.
- **Counterplay:** Dodge into alcoves or jump onto display tables. Directing a cart into a designated cart corral grants a bonus 15 credits.

### Disaster 2: Blackout
- **Telegraph (3s):** Lights flicker, manager sigh over radio: *"Who touched the fuse box?!"*
- **Effect (30s):** Store plunges into near-total darkness. Flashlights auto-equip. Emergency red safety lights illuminate aisles.
- **Counterplay:** Players must locate 2 designated breaker boxes across the store and complete a 2-second repair to restore normal power early.

### Disaster 3: The Angry Customer ("The Mega-Karen")
- **Telegraph (5s):** Heavy stomping footsteps, screen shake, PA alert: *"Manager requested on Aisle 3 immediately!"*
- **Effect (35s):** An oversized 12-foot cartoon character wearing sunglasses and wielding a coupon book stomps around targeting whichever player is carrying the highest-value order.
- **Counterplay:** Run! Teammates can throw cabbage heads or honk horns to distract the customer and pull aggro. Getting hit results in a 2-second comedic sit-down stun.

### Disaster 4: Product Avalanche
- **Telegraph (4s):** Creaking metal sounds, dust particles raining from ceiling, warning decal on floor.
- **Effect (20s):** An entire aisle shelf collapses, sending 50 giant cereal boxes and soup cans bouncing everywhere.
- **Counterplay:** Leap clear of the impact zone! Afterwards, players can quickly shovel products back for extra bonus credits.

### Disaster 5: Soap Apocalypse
- **Telegraph (4s):** Bubbles start floating through the vents, soapy foam covers floors.
- **Effect (25s):** 60% of floor tiles become super-frictionless ($0.01$ friction). Movement physics turn into continuous ice skating.
- **Counterplay:** Slide through aisles to navigate quickly, grab onto support pillars to stop, or deploy "Caution: Wet Floor" safety cones to create safe traction zones.

### Disaster 6: Manager Madness
- **Telegraph (3s):** Chime chime chime over PA! Manager voice: *"Attention valued associates! New store policy effective right now!"*
- **Effect (30s):** A bizarre temporary constraint is enforced:
  - *Constraint A:* "No sprinting! Walk with dignity!" (Speed capped at 10 studs/s; sprinting triggers comical squawk sound).
  - *Constraint B:* "Cartoons only! Walk backwards to checkout!"
  - *Constraint C:* "Price check! All items must be carried with both hands (no jumping)!"
- **Reward:** Complying associates earn double credits during this window.

---

## 5. Player Progression & Economy

### Currencies
- **Store Credits (Soft Currency):** Earned through completing tasks, surviving shifts, returning runaway carts, and daily login streaks.
- **Experience Points (XP):** Levels up the player, unlocking prestige badges, employee ranks, and shop item eligibility.

### Employee Ranks
1. Level 1: Cart Wrangler (Default)
2. Level 5: Shelf Stacker
3. Level 10: Cashier Specialist
4. Level 20: Assistant to the Regional Manager
5. Level 50: Store Legend (Golden Nameplate & Apron)

### Cosmetic Shop Catalog
- **Headwear:** Paper Bag Mask (150 C), Traffic Cone Hat (1,200 C), Cereal Box Helmet (600 C), Manager Visor (800 C).
- **Uniforms:** Classic Blue Apron (Default), Golden Apron (750 C), Hazmat Suit (1,800 C), Retail Tuxedo (2,500 C).
- **Emotes:** Dramatic Slip Fall (500 C), Sweep Dance (750 C), Panic Scream (300 C).
- **Equipment Skins:** Golden Mop, Neon Shopping Cart, Cardboard Box Deluxe.
