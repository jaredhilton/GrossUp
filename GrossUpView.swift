import SwiftUI
import UIKit

private let currencyInputFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD"
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2
    return formatter
}()

private func normalizeDigits(_ digits: String) -> String {
    let trimmed = digits.drop(while: { $0 == "0" })
    return trimmed.isEmpty ? "" : String(trimmed)
}

private func formatCurrencyFromDigits(_ digits: String) -> String {
    let normalized = normalizeDigits(digits)
    guard !normalized.isEmpty else { return "" }
    let cents = Double(normalized) ?? 0
    return currencyInputFormatter.string(from: NSNumber(value: cents / 100)) ?? ""
}

// MARK: - Adaptive Theme Colors
struct AppTheme {
    let colorScheme: ColorScheme
    
    // Background gradients
    var backgroundGradient: [Color] {
        switch colorScheme {
        case .dark:
            return [
                Color(red: 0.08, green: 0.08, blue: 0.12),
                Color(red: 0.05, green: 0.05, blue: 0.08),
                Color.black
            ]
        case .light:
            return [
                Color(red: 0.95, green: 0.95, blue: 0.97),
                Color(red: 0.90, green: 0.92, blue: 0.96),
                Color(red: 0.85, green: 0.88, blue: 0.94)
            ]
        @unknown default:
            return [Color.black]
        }
    }
    
    // Primary text color
    var primaryText: Color {
        colorScheme == .dark ? .white : Color(red: 0.1, green: 0.1, blue: 0.15)
    }
    
    // Secondary text color
    var secondaryText: Color {
        colorScheme == .dark ? .white.opacity(0.8) : Color(red: 0.3, green: 0.3, blue: 0.35)
    }
    
    // Tertiary text color
    var tertiaryText: Color {
        colorScheme == .dark ? .white.opacity(0.6) : Color(red: 0.45, green: 0.45, blue: 0.5)
    }
    
    // Muted text color
    var mutedText: Color {
        colorScheme == .dark ? .white.opacity(0.5) : Color(red: 0.6, green: 0.6, blue: 0.65)
    }
    
    // Very muted text/icons
    var veryMutedText: Color {
        colorScheme == .dark ? .white.opacity(0.4) : Color(red: 0.7, green: 0.7, blue: 0.75)
    }
    
    // Glass card background
    var glassBackground: Material {
        colorScheme == .dark ? .ultraThinMaterial : .regularMaterial
    }
    
    var glassBackgroundOpacity: Double {
        colorScheme == .dark ? 0.5 : 0.8
    }
    
    // Glass card stroke
    var glassStroke: Color {
        colorScheme == .dark ? .white.opacity(0.15) : .white.opacity(0.6)
    }
    
    // Glass card shadow
    var glassShadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.08)
    }
    
    // Button/chip background
    var chipBackground: Color {
        colorScheme == .dark ? .white.opacity(0.1) : .white.opacity(0.7)
    }
    
    // Button/chip text
    var chipText: Color {
        colorScheme == .dark ? .white.opacity(0.7) : Color(red: 0.3, green: 0.3, blue: 0.4)
    }
    
    // Add fee button background
    var addButtonBackground: Color {
        colorScheme == .dark ? .blue.opacity(0.2) : .blue.opacity(0.1)
    }
    
    // Divider color
    var divider: Color {
        colorScheme == .dark ? .white.opacity(0.2) : .black.opacity(0.1)
    }
    
    // Mode switch selected background
    var modeSwitchSelected: Color {
        colorScheme == .dark ? .white.opacity(0.15) : .white.opacity(0.9)
    }
    
    // Mode switch background
    var modeSwitchBackground: Material {
        colorScheme == .dark ? .ultraThinMaterial : .regularMaterial
    }
    
    var modeSwitchBackgroundOpacity: Double {
        colorScheme == .dark ? 0.5 : 0.7
    }
    
    // Mode switch stroke
    var modeSwitchStroke: Color {
        colorScheme == .dark ? .white.opacity(0.2) : .white.opacity(0.5)
    }
    
    // Mode switch selected text
    var modeSwitchSelectedText: Color {
        colorScheme == .dark ? .white : Color(red: 0.15, green: 0.15, blue: 0.2)
    }
    
    // Mode switch unselected text
    var modeSwitchUnselectedText: Color {
        colorScheme == .dark ? .white.opacity(0.5) : Color(red: 0.5, green: 0.5, blue: 0.55)
    }
    
    // Validation error color
    var validationError: Color {
        colorScheme == .dark ? .orange : .orange
    }
    
    // Accent color for results
    var accentColor: Color {
        .blue
    }
}

// MARK: - Fee Presets
struct FeePreset: Identifiable {
    let id = UUID()
    let name: String
    let percent: String
}

private let feePresets: [FeePreset] = [
    FeePreset(name: "Tithe", percent: "10"),
    FeePreset(name: "Local Tax", percent: "20"),
    FeePreset(name: "Federal Tax", percent: "30"),
    FeePreset(name: "Platform", percent: "3")
]

// MARK: - Calc Mode
enum CalcMode: Int, CaseIterable {
    case gross = 0
    case net = 1
    
    var inputLabel: String {
        switch self {
        case .gross: return "I want to spend"
        case .net: return "Total amount"
        }
    }
    
    var outputLabel: String {
        switch self {
        case .gross: return "Amount I need"
        case .net: return "Spendable amount"
        }
    }
    
    var iconName: String {
        switch self {
        case .gross: return "arrow.up.right"
        case .net: return "arrow.down.right"
        }
    }
    
    var displayName: String {
        switch self {
        case .gross: return "Gross"
        case .net: return "Net"
        }
    }
}

struct GrossUpView: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var colorSchemeOverride: ColorScheme?
    @State private var selectedMode: CalcMode = .gross
    @State private var grossModeDigits = ""
    @State private var netModeDigits = ""
    @State private var fees: [FeeItem] = [
        FeeItem(name: "", percentText: "")
    ]
    
    private var effectiveColorScheme: ColorScheme {
        colorSchemeOverride ?? systemColorScheme
    }
    
    private var theme: AppTheme {
        AppTheme(colorScheme: effectiveColorScheme)
    }
    
    private var currentDigits: Binding<String> {
        selectedMode == .gross ? $grossModeDigits : $netModeDigits
    }
    
    private var calculationResult: CalculationResult {
        recalculate()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Fixed header (title only)
            Text(selectedMode.inputLabel)
                .font(.system(.largeTitle, weight: .bold))
                .foregroundColor(theme.primaryText)
                .animation(.easeInOut(duration: 0.2), value: selectedMode)
                .padding(.top, 8)
            
            // Swipeable calculator content only
            TabView(selection: $selectedMode) {
                calcContent(mode: .gross)
                    .tag(CalcMode.gross)
                
                calcContent(mode: .net)
                    .tag(CalcMode.net)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Bottom bar with buttons and toggle
            bottomBar
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
        .background {
            LinearGradient(
                colors: theme.backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .preferredColorScheme(colorSchemeOverride)
    }
    
    // MARK: - Bottom Bar
    private var bottomBar: some View {
        HStack(spacing: 0) {
            // Left section - theme toggle centered
            Button(action: { toggleColorScheme() }) {
                Image(systemName: effectiveColorScheme == .dark ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.secondaryText)
                    .frame(width: 44, height: 44)
                    .background(theme.glassBackground.opacity(theme.glassBackgroundOpacity))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(theme.glassStroke, lineWidth: 1)
                    )
                    .shadow(color: theme.glassShadowColor, radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            
            // Mode switch (fixed width)
            modeSwitch
            
            // Right section - clear button centered
            Button(action: { clearCalculator(mode: selectedMode) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.secondaryText)
                    .frame(width: 44, height: 44)
                    .background(theme.glassBackground.opacity(theme.glassBackgroundOpacity))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(theme.glassStroke, lineWidth: 1)
                    )
                    .shadow(color: theme.glassShadowColor, radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Calc Content (swipeable)
    @ViewBuilder
    private func calcContent(mode: CalcMode) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                VStack(spacing: 16) {
                    CurrencyTextField(
                        digits: mode == .gross ? $grossModeDigits : $netModeDigits,
                        placeholder: "$0.00",
                        colorScheme: effectiveColorScheme
                    )
                    .frame(height: 44)
                }
                .frame(maxWidth: .infinity)
                .adaptiveGlassCard(theme: theme)

                feesSection
                    .adaptiveGlassCard(theme: theme)

                resultsSection(mode: mode)
                    .adaptiveGlassCard(theme: theme)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 80)
        }
        .scrollIndicators(.hidden)
    }
    
    // MARK: - Fees Section
    private var feesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Taxes and fees")
                    .font(.headline)
                    .foregroundColor(theme.secondaryText)
                Spacer()
            }
            
            // Fee Presets
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(feePresets) { preset in
                        Button(action: { addPreset(preset) }) {
                            Text("\(preset.name) \(preset.percent)%")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(theme.chipBackground)
                                .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(theme.chipText)
                    }
                }
            }

            // Fee rows
            VStack(spacing: 0) {
                ForEach($fees) { $fee in
                    HStack(spacing: 12) {
                        TextField("Fee name", text: $fee.name)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .foregroundColor(theme.primaryText)

                        HStack(spacing: 4) {
                            TextField("0", text: $fee.percentText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 50)
                                .font(.system(.body, weight: .semibold))
                                .foregroundColor(theme.primaryText)
                            Text("%")
                                .foregroundColor(theme.mutedText)
                        }
                        
                        Button(action: { removeFee(fee) }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(theme.veryMutedText)
                                .font(.system(size: 20))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 12)
                }
            }

            // Add Fee button
            Button(action: addFee) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Fee")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(theme.addButtonBackground)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .foregroundColor(.blue)
            
            // Inline validation
            if let error = calculationResult.validationError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                }
                .foregroundColor(theme.validationError)
            }
        }
    }
    
    // MARK: - Results Section
    @ViewBuilder
    private func resultsSection(mode: CalcMode) -> some View {
        VStack(spacing: 20) {
            if calculationResult.isValid {
                HStack {
                    Text("You keep \(formatPercent(100 - calculationResult.totalDeductions))")
                        .font(.subheadline)
                        .foregroundColor(theme.tertiaryText)
                    Text("•")
                        .foregroundColor(theme.veryMutedText)
                    Text("Fees \(formatPercent(calculationResult.totalDeductions))")
                        .font(.subheadline)
                        .foregroundColor(theme.tertiaryText)
                    Spacer()
                }
            }
            
            HStack {
                Text("Total Deductions")
                    .font(.subheadline)
                    .foregroundColor(theme.tertiaryText)
                Spacer()
                Text(calculationResult.isValid ? formatPercent(calculationResult.totalDeductions) : "—")
                    .font(.system(.title3, weight: .semibold))
                    .foregroundColor(theme.primaryText)
            }

            Divider()
                .background(theme.divider)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.outputLabel)
                        .font(.headline)
                        .foregroundColor(theme.tertiaryText)
                    Text(calculationResult.resultText)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(theme.accentColor)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                Spacer()
            }
        }
    }
    
    // MARK: - Mode Switch
    private var modeSwitch: some View {
        let padding: CGFloat = 3
        let totalWidth: CGFloat = 160
        let totalHeight: CGFloat = 44
        let segmentWidth = (totalWidth - padding * 2) / 2
        let indicatorHeight = totalHeight - padding * 2
        
        return ZStack {
            // Sliding indicator
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.modeSwitchSelected)
                .frame(width: segmentWidth, height: indicatorHeight)
                .offset(x: selectedMode == .gross ? -segmentWidth / 2 : segmentWidth / 2)
                .animation(.easeInOut(duration: 0.25), value: selectedMode)
            
            // Buttons
            HStack(spacing: 0) {
                ForEach(CalcMode.allCases, id: \.rawValue) { mode in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedMode = mode
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: mode.iconName)
                                .font(.system(size: 12, weight: .medium))
                            Text(mode.displayName)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(selectedMode == mode ? theme.modeSwitchSelectedText : theme.modeSwitchUnselectedText)
                        .frame(maxWidth: .infinity)
                        .frame(height: indicatorHeight)
                        .animation(.easeInOut(duration: 0.15), value: selectedMode)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(padding)
        }
        .frame(width: totalWidth, height: totalHeight)
        .background(theme.modeSwitchBackground.opacity(theme.modeSwitchBackgroundOpacity))
        .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(theme.modeSwitchStroke, lineWidth: 1)
        )
        .shadow(color: theme.glassShadowColor.opacity(0.15), radius: 6, x: 0, y: 2)
    }

    // MARK: - Calculation
    private func recalculate() -> CalculationResult {
        let inputDigits = selectedMode == .gross ? grossModeDigits : netModeDigits
        let inputValue = digitsToValue(inputDigits)
        
        guard inputValue > 0 else {
            return CalculationResult(resultText: "—", totalDeductions: 0, isValid: false, validationError: nil)
        }

        let normalizedFees = fees.compactMap { fee -> FeeItem? in
            let trimmedName = fee.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedPercent = fee.percentText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedName.isEmpty && trimmedPercent.isEmpty { return nil }
            return FeeItem(name: trimmedName, percentText: trimmedPercent)
        }

        var total = 0.0
        for fee in normalizedFees {
            guard !fee.percentText.isEmpty else {
                return CalculationResult(resultText: "—", totalDeductions: 0, isValid: false, validationError: "Enter a percentage for each fee")
            }
            guard let percent = Double(fee.percentText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                return CalculationResult(resultText: "—", totalDeductions: 0, isValid: false, validationError: "Invalid percentage")
            }
            if percent < 0 || percent > 100 {
                return CalculationResult(resultText: "—", totalDeductions: 0, isValid: false, validationError: "Percentages must be 0–100")
            }
            total += percent
        }

        if total >= 100 {
            return CalculationResult(resultText: "—", totalDeductions: total, isValid: false, validationError: "Total fees must be under 100%")
        }

        let result: Double?
        switch selectedMode {
        case .gross:
            result = GrossUpMath.gross(net: inputValue, totalDeductions: total)
        case .net:
            result = GrossUpMath.net(gross: inputValue, totalDeductions: total)
        }
        
        guard let resultValue = result else {
            return CalculationResult(resultText: "—", totalDeductions: total, isValid: false, validationError: nil)
        }
        
        return CalculationResult(resultText: formatCurrency(resultValue), totalDeductions: total, isValid: true, validationError: nil)
    }

    private func digitsToValue(_ digits: String) -> Double {
        let normalized = normalizeDigits(digits)
        let cents = Double(normalized) ?? 0
        return cents / 100
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func formatPercent(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f%%", value)
        }
        return String(format: "%.1f%%", value)
    }

    private func addFee() {
        fees.append(FeeItem(name: "", percentText: ""))
    }
    
    private func addPreset(_ preset: FeePreset) {
        fees.append(FeeItem(name: preset.name, percentText: preset.percent))
    }

    private func removeFee(_ fee: FeeItem) {
        guard let index = fees.firstIndex(where: { $0.id == fee.id }) else { return }
        fees.remove(at: index)
        if fees.isEmpty {
            fees.append(FeeItem(name: "", percentText: ""))
        }
    }
    
    private func clearCalculator(mode: CalcMode) {
        switch mode {
        case .gross:
            grossModeDigits = ""
        case .net:
            netModeDigits = ""
        }
        fees = [FeeItem(name: "", percentText: "")]
    }
    
    private func toggleColorScheme() {
        colorSchemeOverride = effectiveColorScheme == .dark ? .light : .dark
    }
}

// MARK: - Types
struct CalculationResult {
    let resultText: String
    let totalDeductions: Double
    let isValid: Bool
    let validationError: String?
}

struct DarkGlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(.ultraThinMaterial.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
    }
}

struct AdaptiveGlassCard: ViewModifier {
    let theme: AppTheme
    
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(theme.glassBackground.opacity(theme.glassBackgroundOpacity))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: theme.glassShadowColor, radius: 15, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(theme.glassStroke, lineWidth: 1)
            )
    }
}

extension View {
    func darkGlassCard() -> some View {
        modifier(DarkGlassCard())
    }
    
    // Keep old modifier for compatibility
    func glassCard() -> some View {
        modifier(DarkGlassCard())
    }
    
    func adaptiveGlassCard(theme: AppTheme) -> some View {
        modifier(AdaptiveGlassCard(theme: theme))
    }
}

struct FeeItem: Identifiable {
    let id = UUID()
    var name: String
    var percentText: String
}

struct GrossUpMath {
    static func gross(net: Double, totalDeductions: Double) -> Double? {
        guard net > 0 else { return nil }
        guard totalDeductions >= 0, totalDeductions < 100 else { return nil }
        return net / (1 - totalDeductions / 100)
    }
    
    static func net(gross: Double, totalDeductions: Double) -> Double? {
        guard gross > 0 else { return nil }
        guard totalDeductions >= 0, totalDeductions < 100 else { return nil }
        return gross * (1 - totalDeductions / 100)
    }
}

#Preview {
    GrossUpView()
}

struct CurrencyTextField: UIViewRepresentable {
    @Binding var digits: String
    var placeholder: String
    var colorScheme: ColorScheme

    func makeCoordinator() -> Coordinator {
        Coordinator(digits: $digits)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.keyboardType = .numberPad
        textField.placeholder = placeholder
        textField.font = UIFont.systemFont(ofSize: 34, weight: .semibold)
        textField.textAlignment = .center
        textField.delegate = context.coordinator
        textField.borderStyle = .none
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        applyColors(to: textField)
        
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        let formatted = formatCurrencyFromDigits(digits)
        if uiView.text != formatted {
            uiView.text = formatted
        }
        
        applyColors(to: uiView)
    }
    
    private func applyColors(to textField: UITextField) {
        let isDark = colorScheme == .dark
        
        if isDark {
            textField.textColor = .white
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.4)]
            )
        } else {
            textField.textColor = UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
            textField.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: UIColor(red: 0.6, green: 0.6, blue: 0.65, alpha: 1.0)]
            )
        }
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var digits: String

        init(digits: Binding<String>) {
            _digits = digits
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let current = textField.text ?? ""
            guard let textRange = Range(range, in: current) else { return false }
            let updated = current.replacingCharacters(in: textRange, with: string)
            let newDigits = updated.filter { $0.isNumber }
            let normalized = normalizeDigits(newDigits)
            digits = normalized
            textField.text = formatCurrencyFromDigits(normalized)
            let end = textField.endOfDocument
            textField.selectedTextRange = textField.textRange(from: end, to: end)
            return false
        }
    }
}
