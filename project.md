# Project: GrossUp

## Purpose
Help users compute either the gross income required to achieve a desired net amount, or the spendable (net) amount from a total (gross) amount, after deductions.

## User Experience
- **Dual-mode layout**: Swipeable pages for Gross mode (net → gross) and Net mode (gross → net).
- **Adaptive glassmorphic styling**: Automatically follows system color scheme (light/dark):
  - **Dark mode**: Dark gradient background with translucent material cards, subtle white strokes
  - **Light mode**: Soft gray-blue gradient background with frosted glass cards, Apple-inspired glassmorphism aesthetic
- Inputs at top, fees list in middle, results at bottom on each page.
- **Real-time calculation**: No Calculate button; results update instantly as users type.
- Currency input formats as currency while typing (digit entry = cents).
- **Inline validation**: Errors appear below the fees section, not as modal alerts.
- **Fee presets**: Quick-add chips let users add common fees (Tithe 10%, Local Tax 20%, Federal Tax 30%, Platform 3%) with a single tap.
- **Results emphasis**: Result values are displayed in a large 44pt bold blue font. A "You keep X% / Fees Y%" breakdown appears when inputs are valid.
- **Bottom mode switch**: Glass-style segmented control at the bottom with direction icons and "Net" / "Gross" labels. Tapping switches modes; swiping also switches modes and updates the toggle.
- **Edge-to-edge layout**: Content should avoid extra top/bottom bars; spacing should feel intentional, not like safe-area padding.
- **Full-height behavior**: The layout should stay full-height on device, even when the keyboard is visible.
- **System preference integration**: App respects iOS appearance settings—if user has Light mode enabled, app shows light glassmorphic UI; if Dark mode, shows dark glassmorphic UI.

## Core Requirements
- Modes:
  - **Gross mode**: Input "I want to spend" (net), output "Amount I need" (gross)
  - **Net mode**: Input "Total amount" (gross), output "Spendable amount" (net)
- Inputs:
  - Currency amount (numeric, shared digit storage per mode)
  - Fee percentages (user-added rows, shared across modes)
- Fee Rows:
  - Unlimited fees with optional names
  - Start with a single blank fee row
  - No pre-named fees or default percentages
  - Quick-add presets available (Tithe 10%, Local Tax 20%, Federal Tax 30%, Platform 3%)
- Calculation:
  - Total deductions = sum of fee percentages
  - Gross mode: `gross = net / (1 - totalDeductions/100)`
  - Net mode: `net = gross * (1 - totalDeductions/100)`
  - Calculation runs in real-time as inputs change
- Labels (Gross mode):
  - I want to spend
  - Taxes and fees
  - Total Deductions
  - Amount I need
- Labels (Net mode):
  - Total amount
  - Taxes and fees
  - Total Deductions
  - Spendable amount

## Tax Fetching
- Not included in the simplified redesign.

## Validation & Errors
- Amount to spend must be greater than 0.
- Percentages must be between 0 and 100.
- Total deductions must be less than 100.
- Display inline validation messages (not modal alerts).

## Acceptance Criteria
- App builds on iOS 17+ with no external dependencies.
- Swipeable dual-mode layout with adaptive glassmorphic styling.
- Automatically follows system appearance (Light/Dark mode).
- Bottom mode switch syncs with swipe gestures.
- Calculation and validation behave correctly for typical inputs in both modes.
- Results update in real-time without a Calculate button.
- Light mode features Apple-inspired frosted glass aesthetic with soft gradients.
- Dark mode retains the original dark glass aesthetic.

## Manual Test Script

### Gross Mode
1. Enter amount to spend `$10.00` -> result shows "—" until fees are valid.
2. Add fee `25` -> result updates instantly to show gross > $10.00 (should be ~$13.33).
3. Verify "You keep 75% / Fees 25%" breakdown appears.
4. Tap "Tax 20%" preset -> new fee row added with "Tax" and "20".
5. Add another fee row and leave it blank -> no error shown, blank rows are ignored.
6. Set a fee to `101` -> inline error "Percentages must be 0–100" appears.
7. Set total deductions to `100` or more -> inline error "Total fees must be under 100%" appears.
8. Remove all fee rows -> one blank row remains.
9. Clear the amount field -> result shows "—".

### Net Mode
10. Swipe left or tap "Net" in the bottom toggle to switch to Net mode.
11. Enter total amount `$100.00` with fee `25` -> result shows spendable amount of $75.00.
12. Verify "You keep 75% / Fees 25%" breakdown appears.
13. Validation errors work the same as Gross mode.

### Mode Switching
14. Swipe between modes -> bottom toggle updates to reflect current mode.
15. Tap bottom toggle -> page swipes to corresponding mode.
16. Fees are shared between modes; changes in one mode reflect in the other.

### Light/Dark Mode
17. With device in Dark mode (Settings > Display & Brightness), app shows dark glass styling with dark gradient background.
18. With device in Light mode, app shows light glass styling with soft gray-blue gradient background.
19. Switch device appearance while app is running -> UI updates immediately to match new appearance.
20. All text, icons, and controls remain readable and appropriately contrasted in both modes.
