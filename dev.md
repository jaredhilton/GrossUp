# Development Guidelines

## Scope
- This repo contains a minimal iOS 26+ SwiftUI app named "GrossUp."
- Files are kept flat in the repo root until an Xcode project is created.

## Code Style
- Swift 6.0+ (iOS 26), SwiftUI only, no external dependencies.
- Prefer small, readable types and computed properties over complex state.
- Use `@State` for view-local state; avoid global singletons.
- Use Apple's native Liquid Glass design system for translucent, dynamic UI.

## UI Conventions
- Layout: Swipeable `TabView` with page style (no dots) containing two modes.
- **Dual-mode UI**: Gross mode (net → gross) and Net mode (gross → net), switchable via swipe or bottom toggle.
- Input order: Amount input (fixed at top) -> taxes/fees -> results (no Calculate button).
- **Real-time calculation**: Results update instantly as the user types or modifies fees.
- Fees are user-added rows with optional names; no default fee names. Fees are shared across modes.
- **Fee presets**: Quick-add chips (e.g., Tithe 10%, Local Tax 20%, Federal Tax 30%, Platform 3%) append new fee rows.
- **Inline validation**: Validation messages appear below the fees section instead of modal alerts.
- **Bottom mode switch**: Native `Picker` with `.pickerStyle(.segmented)` for automatic Liquid Glass styling. No custom glass implementations for standard controls.
- Buttons: Use `.buttonStyle(.glass)` or `.buttonStyle(.glassProminent)` for Liquid Glass buttons. Avoid manual `.glassEffect()` on buttons.
- Avoid animations unless explicitly requested.
- **Liquid Glass Design (iOS 26)**: Follow Apple's adoption guidelines:
  - Wrap entire view hierarchy in `GlassEffectContainer` for coordinated rendering and performance
  - **Use native controls**: Standard SwiftUI controls (Picker, Button, Toggle, Slider) automatically adopt Liquid Glass
  - **Button styles**: Use `.buttonStyle(.glass)` instead of manual `.glassEffect()` on buttons
  - **Avoid layering**: Never layer Liquid Glass elements on top of each other (causes visual artifacts)
  - **Custom glass cards**: Use `.glassEffect(in: .rect(cornerRadius:))` only for custom container views (not controls)
  - **Glass variants for custom elements**:
    - `.glassEffect(.regular.interactive())` for touch-responsive custom elements
    - `.glassEffect(.regular.tint(.blue))` for accent-colored glass
    - `.glassEffect(.regular.tint(.orange))` for warning/validation states
  - **Shapes**: `.rect(cornerRadius:)`, `.circle`, `.capsule`
  - Content scrolls behind fixed glass elements for true translucency
  - Avoid overusing Liquid Glass effects—use sparingly for navigation layer only
- **Typography**: Use large, bold titles for key values; clear hierarchy for labels. Result values use 44pt bold font for emphasis.
- **Color scheme**: Follows system preferences automatically via `@Environment(\.colorScheme)`. Manual toggle available.
- **Edge-to-edge layout**: Avoid extra safe-area padding that creates top/bottom bars; keep spacing intentional.
- **ScrollView layout**: Zero scroll-content margins and ignore keyboard safe-area when full-height layout is required.
- **Fixed Input Card**: Input field is fixed at top with glass effect; content scrolls behind it.

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

## CI/CD & Deployment

### Local Build & Upload
```bash
# Build only (no upload)
./scripts/build-and-upload.sh --skip-upload

# Build and upload to App Store Connect
./scripts/build-and-upload.sh
```

**Configuration:** Copy `.env.example` to `.env` and fill in your App Store Connect API credentials.

### GitHub Actions (Automated)
The workflow in `.github/workflows/build-and-deploy.yml` automatically builds and uploads to App Store Connect when you push a version tag.

**To release a new version:**
```bash
git tag v1.2.0
git push origin v1.2.0
```

**Versioning:**
- **Marketing Version**: Extracted from git tag (`v1.2.0` → `1.2.0`)
- **Build Number**: Auto-increments using GitHub Actions run number

**Required GitHub Secrets:**
| Secret | Description |
|--------|-------------|
| `APP_STORE_CONNECT_API_KEY_ID` | API Key ID from App Store Connect |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID from App Store Connect |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Base64-encoded `.p8` key file |

**To get API credentials:**
1. Go to [App Store Connect](https://appstoreconnect.apple.com) → Users and Access → Integrations → App Store Connect API
2. Generate or use existing API key
3. Note the Key ID and Issuer ID
4. Download the `.p8` file and base64 encode it: `base64 -i AuthKey_XXXX.p8 | pbcopy`

### Project Configuration
- **Bundle ID**: `com.jaredhilton.GrossUp`
- **Team ID**: `S863LZ43ZG`
- **Deployment Target**: iOS 26.0
- **Code Signing**: Automatic (managed via App Store Connect API key)
