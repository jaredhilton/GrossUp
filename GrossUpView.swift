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

// MARK: - Theme Colors (simplified for Liquid Glass)
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
    
    // Validation error color
    var validationError: Color {
        .orange
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
        GlassEffectContainer {
            ZStack(alignment: .top) {
                // Swipeable calculator content (fees and results only)
                VStack(spacing: 0) {
                    TabView(selection: $selectedMode) {
                        calcContent(mode: .gross)
                            .tag(CalcMode.gross)
                        
                        calcContent(mode: .net)
                            .tag(CalcMode.net)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Bottom bar with buttons and toggle
                    bottomBar
                        .padding(.bottom, 8)
                }
                
                // Fixed glass input card at top (content scrolls behind)
                inputCard(mode: selectedMode)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            }
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
    
    // MARK: - Bottom Bar (matches iOS 26 Liquid Glass tab bar sizing)
    private var bottomBar: some View {
        HStack(spacing: 12) {
            // Left section - theme toggle with native Liquid Glass circular button
            Button(action: { toggleColorScheme() }) {
                Image(systemName: effectiveColorScheme == .dark ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 18, weight: .medium))
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            
            // Mode switch (center) - native segmented control with glass
            modeSwitch
                .fixedSize()
            
            // Right section - clear button with native Liquid Glass circular button
            Button(action: { clearCalculator(mode: selectedMode) }) {
                Text("C")
                    .font(.system(size: 20, weight: .semibold))
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .controlSize(.large)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Input Card (fixed at top)
    @ViewBuilder
    private func inputCard(mode: CalcMode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(mode.inputLabel)
                .font(.headline)
                .foregroundStyle(theme.secondaryText)
            
            CurrencyTextField(
                digits: mode == .gross ? $grossModeDigits : $netModeDigits,
                placeholder: "$0.00",
                colorScheme: effectiveColorScheme
            )
            .frame(height: 44)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.blue.opacity(0.02))
                }
        }
        .glassEffect(in: .rect(cornerRadius: 24))
    }
    
    // MARK: - Calc Content (swipeable)
    @ViewBuilder
    private func calcContent(mode: CalcMode) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                feesSection

                resultsSection(mode: mode)
            }
            .padding(.horizontal, 12)
            .padding(.top, 130) // Space for fixed input card above
            .padding(.bottom, 80)
        }
        .scrollIndicators(.hidden)
        .scrollEdgeEffectStyle(.soft, for: .top) // Maintains legibility under fixed input card
    }
    
    // MARK: - Fees Section
    private var feesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Taxes and fees")
                    .font(.headline)
                    .foregroundStyle(theme.secondaryText)
                Spacer()
            }
            
            // Fee Presets and Add Fee button - inline horizontal row with native Liquid Glass
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Circular Add Fee button with native glass (blue tint)
                    Button(action: addFee) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .controlSize(.regular)
                    .tint(.blue)
                    
                    // Fee preset chips with native glass capsule style
                    ForEach(feePresets) { preset in
                        Button(action: { addPreset(preset) }) {
                            Text("\(preset.name) \(preset.percent)%")
                                .font(.subheadline)
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.capsule)
                    }
                }
                .padding(.vertical, 4)
            }

            // Fee rows
            VStack(spacing: 0) {
                ForEach($fees) { $fee in
                    HStack(spacing: 12) {
                        TextField("Fee name", text: $fee.name)
                            .textFieldStyle(.plain)
                            .font(.body)
                            .foregroundStyle(theme.primaryText)

                        HStack(spacing: 4) {
                            TextField("0", text: $fee.percentText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 50)
                                .font(.system(.body, weight: .semibold))
                                .foregroundStyle(theme.primaryText)
                            Text("%")
                                .foregroundStyle(theme.mutedText)
                        }
                        
                        Button(action: { removeFee(fee) }) {
                            Image(systemName: "minus")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .controlSize(.small)
                        .tint(.blue)
                    }
                    .padding(.vertical, 12)
                    .padding(.trailing, 8) // Room for glass effect expansion
                }
            }
            
            // Inline validation - orange tinted glass for visibility
            if let error = calculationResult.validationError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text(error)
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassEffect(.regular.tint(.orange), in: .capsule)
            }
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 24))
    }
    
    // MARK: - Results Section
    @ViewBuilder
    private func resultsSection(mode: CalcMode) -> some View {
        VStack(spacing: 20) {
            if calculationResult.isValid {
                HStack {
                    Text("You keep \(formatPercent(100 - calculationResult.totalDeductions))")
                        .font(.subheadline)
                        .foregroundStyle(theme.tertiaryText)
                    Text("•")
                        .foregroundStyle(theme.veryMutedText)
                    Text("Fees \(formatPercent(calculationResult.totalDeductions))")
                        .font(.subheadline)
                        .foregroundStyle(theme.tertiaryText)
                    Spacer()
                }
            }
            
            HStack {
                Text("Total Deductions")
                    .font(.subheadline)
                    .foregroundStyle(theme.tertiaryText)
                Spacer()
                Text(calculationResult.isValid ? formatPercent(calculationResult.totalDeductions) : "—")
                    .font(.system(.title3, weight: .semibold))
                    .foregroundStyle(theme.primaryText)
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.outputLabel)
                        .font(.headline)
                        .foregroundStyle(theme.tertiaryText)
                    Text(calculationResult.resultText)
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(theme.accentColor)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                Spacer()
            }
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 24))
    }
    
    // MARK: - Mode Switch (native Liquid Glass segmented control)
    private var modeSwitch: some View {
        Picker("Mode", selection: $selectedMode) {
            ForEach(CalcMode.allCases, id: \.rawValue) { mode in
                Label(mode.displayName, systemImage: mode.iconName)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
        .labelsHidden()
        .glassEffect(.regular.interactive(), in: .capsule)
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
