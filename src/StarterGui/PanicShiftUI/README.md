# PanicShiftUI Specification

This directory holds the ScreenGui assets and Roact / standard UI templates for the PANIC SHIFT interface.

## UI Components Overview

1. **ShiftHUD (Screen 2):**
   - **Top Center:** Shift Clock (`03:00`), Quota Progress Bar (`12/25`).
   - **Top Right:** Wallet Balance (`Store Credits`), Current Player Level & XP bar.
   - **Center Screen:** Objective Callout & Proximity Interaction Prompt (`[E] Hold to Restock`).

2. **DisasterAlertBanner (Screen 3):**
   - **Header:** Hazard Warning Banner with pulsating red/yellow caution borders.
   - **Subtext:** Actionable survival advice (e.g., *"Runaway Carts! Seek higher ground or duck into aisles!"*).
   - **Audio / Screen FX:** Warning siren chime and subtle camera vibration.

3. **ResultsScreen (Screen 4):**
   - **Shift Outcome:** Large *"SHIFT COMPLETED!"* or *"UNDER QUOTA — SHIFT FAILED!"* title.
   - **Summary Card:** Breakdown of quota completed, total credits earned, bonus XP, and MVP Employee badge.
   - **Next Round Timer:** Countdown to next shift.

4. **CosmeticShopModal:**
   - Grid list of hats, uniforms, and equipment skins with prices and equip buttons.
