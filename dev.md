# Development Guidelines

## Scope
- This repo contains a minimal iOS 17+ SwiftUI app named "GrossUp."
- Files are kept flat in the repo root until an Xcode project is created.

## Code Style
- Swift 5.9+ (iOS 17), SwiftUI only, no external dependencies.
- Prefer small, readable types and computed properties over complex state.
- Use `@State` for view-local state; avoid global singletons.
- Use dark glass-style UI: dark gradient background with material cards tuned for dark mode.

## UI Conventions
- Layout: Swipeable `TabView` with page style (no dots) containing two modes.
- **Dual-mode UI**: Gross mode (net → gross) and Net mode (gross → net), switchable via swipe or bottom toggle.
- Input order: Amount input -> taxes/fees -> results (no Calculate button).
- **Real-time calculation**: Results update instantly as the user types or modifies fees.
- Fees are user-added rows with optional names; no default fee names. Fees are shared across modes.
- **Fee presets**: Quick-add chips (e.g., Tithe 10%, Local Tax 20%, Federal Tax 30%, Platform 3%) append new fee rows.
- **Inline validation**: Validation messages appear below the fees section instead of modal alerts.
- **Bottom mode switch**: Glass-style segmented control at the bottom with icons and "Net" / "Gross" labels. No top buttons.
- Buttons: `.tint(.blue)` and `.buttonStyle(.borderedProminent)` sparingly.
- Avoid animations unless explicitly requested.
- **Adaptive Glassmorphic Design**: Use `AppTheme` struct that adapts to system color scheme:
  - Dark mode: `.ultraThinMaterial` with 0.5 opacity, subtle white strokes, dark gradient background
  - Light mode: `.regularMaterial` with 0.8 opacity, brighter white strokes, soft gray-blue gradient background (Apple-inspired glassmorphism)
- **Glass Card Style**: 24pt corner radius, soft shadow, and subtle stroke overlay. Use `adaptiveGlassCard(theme:)` modifier.
- **Typography**: Use large, bold titles for key values; clear hierarchy for labels. Result values use 44pt bold font for emphasis.
- **Color scheme**: Follows system preferences automatically via `@Environment(\.colorScheme)`. No forced color scheme.
- **Edge-to-edge layout**: Avoid extra safe-area padding that creates top/bottom bars; keep spacing intentional.
- **ScrollView layout**: Zero scroll-content margins and ignore keyboard safe-area when full-height layout is required.

## Data & Validation
- Percent inputs are treated as 0-100 (e.g., 20 = 20%).
- Amount inputs must be greater than 0.
- Total deductions must be less than 100%.
- Invalid input triggers an inline validation message (not a modal alert).
- Currency input auto-formats as currency from digit entry (cents).
- **Calculations**:
  - Gross mode: `gross = net / (1 - totalDeductions/100)`
  - Net mode: `net = gross * (1 - totalDeductions/100)`

## Networking
- No networking is required for the core calculator flow.

## Testing
- Provide a minimal `XCTestCase` file with tests for:
  - Gross income calculation
  - Net income calculation
  - Validation bounds (invalid deductions, zero/negative amounts)
- Tests may require Xcode project wiring; document any module name changes.
