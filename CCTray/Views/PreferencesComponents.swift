import SwiftUI

// MARK: - Reusable Preference Components

struct PreferenceSectionHeader: View {
    let title: String
    let subtitle: String?
    
    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .tracking(0.1)
                
                Spacer()
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(ClaudeColors.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.bottom, 6)
    }
}

struct PreferenceRow<Content: View>: View {
    let label: String
    let content: Content
    
    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .fontWeight(.medium)
                .frame(minWidth: 120, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PreferenceSection<Content: View>: View {
    let header: String
    let subtitle: String?
    let minWidth: CGFloat?
    let content: Content
    
    init(_ header: String, subtitle: String? = nil, minWidth: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.header = header
        self.subtitle = subtitle
        self.minWidth = minWidth
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PreferenceSectionHeader(header, subtitle: subtitle)
            
            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PreferenceCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct PreferenceToggle: View {
    let label: String
    let description: String?
    @Binding var isOn: Bool
    
    init(_ label: String, description: String? = nil, isOn: Binding<Bool>) {
        self.label = label
        self.description = description
        self._isOn = isOn
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(label, isOn: $isOn)
            
            if let description = description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct PreferencePicker<T: Hashable>: View {
    let label: String
    let description: String?
    @Binding var selection: T
    let options: [(T, String)]
    let style: PickerStyle
    
    init(
        _ label: String,
        selection: Binding<T>,
        options: [(T, String)],
        description: String? = nil,
        style: PickerStyle = .menu
    ) {
        self.label = label
        self.description = description
        self._selection = selection
        self.options = options
        self.style = style
    }
    
    var body: some View {
        PreferenceRow(label) {
            VStack(alignment: .leading, spacing: 4) {
                switch style {
                case .menu:
                    Picker(label, selection: $selection) {
                        ForEach(options, id: \.0) { value, title in
                            Text(title).tag(value)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                case .segmented:
                    Picker(label, selection: $selection) {
                        ForEach(options, id: \.0) { value, title in
                            Text(title).tag(value)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

enum PickerStyle {
    case menu
    case segmented
}

struct PreferenceSlider: View {
    let label: String
    let description: String?
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let formatter: (Double) -> String
    
    init(
        _ label: String,
        description: String? = nil,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 1,
        formatter: @escaping (Double) -> String = { "\(Int($0))" }
    ) {
        self.label = label
        self.description = description
        self._value = value
        self.range = range
        self.step = step
        self.formatter = formatter
    }
    
    var body: some View {
        PreferenceRow(label) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(formatter(value))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(minWidth: 40, alignment: .leading)
                    
                    Slider(value: $value, in: range, step: step)
                        .frame(maxWidth: 200)
                }
                
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct PreferenceStepperField: View {
    let label: String
    let description: String?
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let suffix: String
    
    init(
        _ label: String,
        description: String? = nil,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 1,
        suffix: String = ""
    ) {
        self.label = label
        self.description = description
        self._value = value
        self.range = range
        self.step = step
        self.suffix = suffix
    }
    
    var body: some View {
        PreferenceRow(label) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Stepper("", value: $value, in: range, step: step)
                        .frame(width: 80) // More compact stepper width
                        .accessibilityLabel(label)
                        .accessibilityValue("\(Int(value)) \(suffix)")
                    
                    TextField("", value: $value, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 13, weight: .medium))
                        .onSubmit {
                            // Clamp value to range when user types directly
                            value = max(range.lowerBound, min(range.upperBound, value))
                        }
                        .accessibilityLabel("\(label) value")
                    
                    if !suffix.isEmpty {
                        Text(suffix)
                            .foregroundColor(.secondary)
                            .font(.system(size: 12, weight: .medium))
                    }
                    
                    Spacer()
                }
                
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct PreferenceTimeSlider: View {
    let label: String
    let description: String?
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    let sliderWidth: CGFloat
    
    init(
        _ label: String,
        description: String? = nil,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 1,
        unit: String = "seconds",
        sliderWidth: CGFloat = 120
    ) {
        self.label = label
        self.description = description
        self._value = value
        self.range = range
        self.step = step
        self.unit = unit
        self.sliderWidth = sliderWidth
    }
    
    var body: some View {
        PreferenceRow(label) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 12) {
                    // Text field with prominent unit label
                    HStack(spacing: 4) {
                        TextField("", value: $value, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 50)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 13, weight: .medium))
                            .onSubmit {
                                // Clamp value to range when user types directly
                                value = max(range.lowerBound, min(range.upperBound, value))
                            }
                            .accessibilityLabel("\(label) value")
                        
                        Text(unit)
                            .foregroundColor(.primary)
                            .font(.system(size: 13, weight: .medium))
                    }
                    
                    // Slider for visual feedback and quick adjustment
                    Slider(value: $value, in: range, step: step)
                        .frame(width: sliderWidth)
                        .accessibilityLabel(label)
                        .accessibilityValue("\(Int(value)) \(unit)")
                    
                    // Stepper for precise increments
                    Stepper("", value: $value, in: range, step: step)
                        .frame(width: 80)
                        .accessibilityLabel("\(label) stepper")
                    
                    Spacer()
                }
                
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct PreferenceTextField: View {
    let label: String
    let description: String?
    let placeholder: String
    @Binding var text: String
    
    init(
        _ label: String,
        description: String? = nil,
        placeholder: String = "",
        text: Binding<String>
    ) {
        self.label = label
        self.description = description
        self.placeholder = placeholder
        self._text = text
    }
    
    var body: some View {
        PreferenceRow(label) {
            VStack(alignment: .leading, spacing: 4) {
                TextField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 300)
                
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct PreferenceButton: View {
    let title: String
    let description: String?
    let style: PreferenceButtonStyle
    let action: () -> Void
    
    init(
        _ title: String,
        description: String? = nil,
        style: PreferenceButtonStyle = .bordered,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.style = style
        self.action = action
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            style.apply(to: Button(title, action: action))
            
            if let description = description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

enum PreferenceButtonStyle {
    case bordered
    case borderedProminent
    case plain
    case link
    
    @ViewBuilder
    func apply<Content: View>(to content: Content) -> some View {
        switch self {
        case .bordered:
            content.buttonStyle(.bordered)
        case .borderedProminent:
            content.buttonStyle(.borderedProminent)
        case .plain:
            content.buttonStyle(.plain)
        case .link:
            content.buttonStyle(LinkButtonStyle())
        }
    }
}

// MARK: - Specialized Components

struct ClaudePlanSelector: View {
    @Binding var selectedPlan: ClaudePlan
    @Binding var customLowThreshold: Double
    @Binding var customHighThreshold: Double
    let lowThreshold: Double
    let highThreshold: Double
    @EnvironmentObject var preferences: AppPreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Plan Selection with enhanced visual indicators
            VStack(alignment: .leading, spacing: 8) {
                Text("Claude Plan:")
                    .fontWeight(.medium)
                
                HStack(spacing: 12) {
                    ForEach(ClaudePlan.allCases, id: \.self) { plan in
                        PlanCard(
                            plan: plan,
                            isSelected: selectedPlan == plan,
                            action: { selectedPlan = plan }
                        )
                    }
                }
            }
            
            // Plan Description
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(ClaudeColors.primary)
                    .frame(width: 16)
                
                Text(selectedPlan.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Plan Status and Guidance
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .frame(width: 16)
                    
                    Text("Plan Selection Status")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("✓ Selected Plan: \(selectedPlan.title)")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Text("• Plan selection is manual - ccusage command doesn't provide billing plan information")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• Make sure this matches your actual Claude subscription plan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if selectedPlan != .custom {
                        Text("• If none of the preset plans match, select 'Custom' to configure your own")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.green.opacity(0.05))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
            )
            
            // Plan Identification Helper
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(ClaudeColors.secondary)
                        .frame(width: 16)
                    
                    Text("How to identify your Claude plan:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Check your Claude subscription in your account settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• Pro Plan: $20/month, ~10-40 prompts per 5 hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• Max Plan 5x: $100/month, ~50-200 prompts per 5 hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• Max Plan 20x: $200/month, ~200-800 prompts per 5 hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• API-Based: Pay-per-token pricing, no prompt limits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(ClaudeColors.secondaryBackground)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(ClaudeColors.secondary.opacity(0.2), lineWidth: 1)
            )
            
            // Custom configuration (only shown for custom plan)
            if selectedPlan == .custom {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Custom Plan Configuration:")
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    // Per-token costs configuration
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Token Costs (per 1M tokens)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Input Tokens")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text("$")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("3.0", value: $preferences.customInputTokenCost, format: .number)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 80)
                                    Text("/ 1M tokens")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Output Tokens")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text("$")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("15.0", value: $preferences.customOutputTokenCost, format: .number)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 80)
                                    Text("/ 1M tokens")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(ClaudeColors.background)
                    .cornerRadius(6)
                    
                    // Monthly spend limit
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monthly Spend Limit")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text("$")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("0", value: $preferences.customMonthlySpendLimit, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 100)
                            Text("(0 = unlimited)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(6)
                    
                    // Burn rate thresholds
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Burn Rate Thresholds")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Low Threshold")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    TextField("300", value: $customLowThreshold, format: .number)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 80)
                                    Text("tokens/min")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("High Threshold")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    TextField("700", value: $customHighThreshold, format: .number)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 80)
                                    Text("tokens/min")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(ClaudeColors.secondaryBackground)
                    .cornerRadius(6)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
            
            // Current Thresholds Display
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Thresholds:")
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    ThresholdIndicator(
                        label: "LOW",
                        value: Int(lowThreshold),
                        color: .green,
                        description: "< \(Int(lowThreshold)) tokens/min"
                    )
                    
                    ThresholdIndicator(
                        label: "MED",
                        value: Int(lowThreshold),
                        color: .orange,
                        description: "\(Int(lowThreshold))-\(Int(highThreshold)) tokens/min"
                    )
                    
                    ThresholdIndicator(
                        label: "HIGH",
                        value: Int(highThreshold),
                        color: .red,
                        description: "> \(Int(highThreshold)) tokens/min"
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(ClaudeColors.background)
            .cornerRadius(6)
        }
    }
}

struct PlanCard: View {
    let plan: ClaudePlan
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                if plan != .custom {
                    Text("↓ \(Int(plan.defaultLowThreshold)) | ↑ \(Int(plan.defaultHighThreshold))")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color.gray.opacity(0.1))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ThresholdIndicator: View {
    let label: String
    let value: Int
    let color: Color
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NotificationPermissionView: View {
    @ObservedObject var notificationManager: NotificationManager
    @Binding var enableNotifications: Bool
    @Binding var notificationMinutes: Int
    @Binding var selectedSound: String
    @Binding var notificationPriority: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Permission Status
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .frame(width: 16)
                
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(statusColor)
                
                Spacer()
            }
            
            // Permission Actions
            Group {
                if notificationManager.authorizationStatus == .notDetermined {
                    PreferenceButton(
                        "Enable Notifications",
                        description: "Allow CCTray to send session end notifications",
                        style: .borderedProminent
                    ) {
                        Task {
                            await notificationManager.requestPermission()
                        }
                    }
                } else if notificationManager.authorizationStatus == .denied {
                    PreferenceButton(
                        "Open System Settings",
                        description: "Enable notifications in System Settings → Notifications → CCTray",
                        style: .borderedProminent
                    ) {
                        openSystemPreferences()
                    }
                } else if notificationManager.hasPermission {
                    // Main toggle
                    PreferenceToggle(
                        "Enable Session End Notifications",
                        description: "Get notified before your Claude session ends",
                        isOn: $enableNotifications
                    )
                    
                    // Settings for enabled notifications
                    if enableNotifications {
                        VStack(alignment: .leading, spacing: 8) {
                            PreferencePicker(
                                "Notification Time:",
                                selection: $notificationMinutes,
                                options: [
                                    (5, "5 minutes"),
                                    (10, "10 minutes"),
                                    (15, "15 minutes"),
                                    (20, "20 minutes"),
                                    (30, "30 minutes")
                                ],
                                description: "before session ends"
                            )
                            
                            ModernSoundToggle(
                                "Play Sound",
                                description: "Choose notification sound",
                                selectedSound: $selectedSound
                            )
                            
                            PreferencePicker(
                                "Priority:",
                                selection: $notificationPriority,
                                options: [
                                    ("passive", "Passive"),
                                    ("active", "Active"),
                                    ("timeSensitive", "Time Sensitive"),
                                    ("critical", "Critical")
                                ],
                                description: "notification interruption level"
                            )
                        }
                        .padding(.leading, 20)
                    }
                }
            }
            
            // System availability warning
            if !notificationManager.isNotificationSystemAvailable {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(ClaudeColors.secondary)
                        .frame(width: 16)
                    
                    Text("Notifications may not be available for menu bar apps on this system")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ClaudeColors.secondaryBackground.opacity(2.0))
                .cornerRadius(4)
            }
        }
    }
    
    private var statusIcon: String {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        default:
            return "circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        default:
            return .gray
        }
    }
    
    private var statusText: String {
        switch notificationManager.authorizationStatus {
        case .notDetermined:
            return "Permission not requested"
        case .denied:
            return "Permission denied"
        case .authorized:
            return "Permission granted"
        case .provisional:
            return "Provisional permission"
        case .ephemeral:
            return "Ephemeral permission"
        @unknown default:
            return "Unknown permission status"
        }
    }
    
    private func openSystemPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Modern macOS Enhancements

struct ModernPreferenceSection<Content: View>: View {
    let header: String
    let subtitle: String?
    let content: Content
    
    init(_ header: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.header = header
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PreferenceSectionHeader(header, subtitle: subtitle)
            
            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
            )
        }
    }
}

struct ModernToggle: View {
    let label: String
    let description: String?
    @Binding var isOn: Bool
    
    init(_ label: String, description: String? = nil, isOn: Binding<Bool>) {
        self.label = label
        self.description = description
        self._isOn = isOn
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .fontWeight(.medium)
                    
                    if let description = description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: $isOn)
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            }
        }
        .padding(.vertical, 4)
    }
}

struct ModernButton: View {
    let title: String
    let description: String?
    let style: PreferenceButtonStyle
    let icon: String?
    let action: () -> Void
    
    init(
        _ title: String,
        description: String? = nil,
        style: PreferenceButtonStyle = .bordered,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.style = style
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            style.apply(to: Button(action: action) {
                HStack(spacing: 8) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .frame(width: 16)
                    }
                    
                    Text(title)
                    
                    if style == .borderedProminent {
                        Spacer()
                    }
                }
                .padding(.horizontal, style == .borderedProminent ? 16 : 8)
                .padding(.vertical, style == .borderedProminent ? 8 : 4)
            })
            .controlSize(.regular)
            
            if let description = description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, icon != nil ? 24 : 0)
            }
        }
    }
}

// MARK: - Uniform Grid Layout System

struct UniformGrid<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        Grid(alignment: .topLeading, horizontalSpacing: spacing, verticalSpacing: spacing) {
            content
        }
    }
}

struct UniformPreferenceSection<Content: View>: View {
    let header: String
    let subtitle: String?
    let content: Content
    
    init(_ header: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.header = header
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PreferenceSectionHeader(header, subtitle: subtitle)
            
            VStack(alignment: .leading, spacing: 8) {
                content
                
                // Flexible spacer to ensure consistent height
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(minHeight: 100) // Ensure minimum height for visual consistency
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                    )
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .gridCellColumns(1)
    }
}

struct OptimalPreferenceGrid<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: spacing),
            GridItem(.flexible(), spacing: spacing)
        ], spacing: spacing) {
            content
        }
    }
}

struct FlexiblePreferenceSection<Content: View>: View {
    let header: String
    let subtitle: String?
    let minHeight: CGFloat
    let content: Content
    
    init(_ header: String, subtitle: String? = nil, minHeight: CGFloat = 120, @ViewBuilder content: () -> Content) {
        self.header = header
        self.subtitle = subtitle
        self.minHeight = minHeight
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PreferenceSectionHeader(header, subtitle: subtitle)
            
            VStack(alignment: .leading, spacing: 8) {
                content
                
                // Flexible spacer to maintain minimum height
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(minHeight: minHeight)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - Enhanced Toggle Component

struct ModernPreferenceToggle: View {
    let label: String
    let description: String?
    @Binding var isOn: Bool
    
    init(_ label: String, description: String? = nil, isOn: Binding<Bool>) {
        self.label = label
        self.description = description
        self._isOn = isOn
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if let description = description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Toggle("", isOn: $isOn)
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    .scaleEffect(0.9)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Collapsible Section Components

struct CollapsiblePreferenceSection<Content: View>: View {
    let header: String
    let subtitle: String?
    @Binding var isExpanded: Bool
    let content: Content
    
    init(_ header: String, subtitle: String? = nil, isExpanded: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.header = header
        self.subtitle = subtitle
        self._isExpanded = isExpanded
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with expand/collapse button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(header)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .tracking(0.1)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
            )
            
            // Collapsible content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    content
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    Rectangle()
                        .fill(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8, corners: [.bottomLeft, .bottomRight])
                        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}

struct TabbedPreferenceSection<Content: View>: View {
    let header: String
    let subtitle: String?
    let tabs: [String]
    @Binding var selectedTab: Int
    let content: Content
    
    init(_ header: String, subtitle: String? = nil, tabs: [String], selectedTab: Binding<Int>, @ViewBuilder content: () -> Content) {
        self.header = header
        self.subtitle = subtitle
        self.tabs = tabs
        self._selectedTab = selectedTab
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(header)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .tracking(0.1)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Tab bar
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = index
                        }
                    }) {
                        Text(tab)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(selectedTab == index ? .accentColor : .secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(selectedTab == index ? Color.accentColor.opacity(0.1) : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if index < tabs.count - 1 {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        )
    }
}

struct CompactPreferenceGrid<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(minimum: 200), spacing: spacing),
            GridItem(.flexible(minimum: 200), spacing: spacing)
        ], spacing: spacing) {
            content
        }
    }
}

struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            content
        }
    }
}

// MARK: - Enhanced Notification Components

struct NotificationThresholdGroup: View {
    @Binding var warningThreshold: Double
    @Binding var urgentThreshold: Double
    @Binding var criticalThreshold: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notification Thresholds")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                NotificationThresholdSlider(
                    "Warning",
                    value: $warningThreshold,
                    range: 0...85,
                    color: .orange,
                    description: "First alert when reaching this percentage (0% = disabled)"
                )
                
                NotificationThresholdSlider(
                    "Urgent",
                    value: $urgentThreshold,
                    range: 0...95,
                    color: .red,
                    description: "More frequent alerts at this level (0% = disabled)"
                )
                
                NotificationThresholdSlider(
                    "Critical",
                    value: $criticalThreshold,
                    range: 0...95,
                    color: .purple,
                    description: "Immediate attention required (0% = disabled)"
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

struct NotificationThresholdSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color
    let description: String
    
    init(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, color: Color, description: String) {
        self.label = label
        self._value = value
        self.range = range
        self.color = color
        self.description = description
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(value == 0 ? Color.gray.opacity(0.4) : color)
                    .frame(width: 8, height: 8)
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(value == 0 ? "Disabled" : "\(Int(value))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(value == 0 ? .secondary : .secondary)
                    .frame(minWidth: 50, alignment: .trailing)
            }
            
            Slider(value: $value, in: range, step: 5)
                .accentColor(color)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}

struct NotificationPriorityGroup: View {
    @Binding var warningPriority: String
    @Binding var urgentPriority: String
    @Binding var criticalPriority: String
    
    private let priorityOptions = [
        ("passive", "Passive"),
        ("active", "Active"),
        ("timeSensitive", "Time Sensitive"),
        ("critical", "Critical")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notification Priority")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                CompactPriorityPicker(
                    "Warning",
                    selection: $warningPriority,
                    options: priorityOptions.filter { $0.0 != "critical" },
                    color: .orange
                )
                
                CompactPriorityPicker(
                    "Urgent",
                    selection: $urgentPriority,
                    options: priorityOptions.filter { $0.0 != "critical" },
                    color: .red
                )
                
                CompactPriorityPicker(
                    "Critical",
                    selection: $criticalPriority,
                    options: priorityOptions,
                    color: .purple
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

struct CompactPriorityPicker: View {
    let label: String
    @Binding var selection: String
    let options: [(String, String)]
    let color: Color
    
    init(_ label: String, selection: Binding<String>, options: [(String, String)], color: Color) {
        self.label = label
        self._selection = selection
        self.options = options
        self.color = color
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 60, alignment: .leading)
            
            Picker(label, selection: $selection) {
                ForEach(options, id: \.0) { value, title in
                    Text(title).tag(value)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: 140)
            
            Spacer()
        }
    }
}

// MARK: - Notification Sound Picker

struct NotificationSoundPicker: View {
    let label: String
    let description: String?
    @Binding var selectedSound: String
    @StateObject private var soundManager = SoundManager.shared
    
    init(_ label: String, description: String? = nil, selectedSound: Binding<String>) {
        self.label = label
        self.description = description
        self._selectedSound = selectedSound
    }
    
    var body: some View {
        PreferenceRow(label) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    // Sound picker dropdown
                    Picker(label, selection: $selectedSound) {
                        ForEach(SoundManager.systemSounds, id: \.name) { sound in
                            Text(sound.displayName).tag(sound.name)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: 160)
                    
                    // Preview button
                    Button(action: {
                        soundManager.previewSound(selectedSound)
                    }) {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(BorderedButtonStyle())
                    .controlSize(.small)
                    .help("Preview sound")
                    .disabled(selectedSound.isEmpty)
                    
                    Spacer()
                }
                
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct CompactSoundPicker: View {
    let label: String
    @Binding var selectedSound: String
    @StateObject private var soundManager = SoundManager.shared
    
    init(_ label: String, selectedSound: Binding<String>) {
        self.label = label
        self._selectedSound = selectedSound
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 60, alignment: .leading)
            
            // Sound picker dropdown
            Picker(label, selection: $selectedSound) {
                ForEach(SoundManager.systemSounds, id: \.name) { sound in
                    Text(sound.displayName).tag(sound.name)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: 120)
            
            // Preview button
            Button(action: {
                soundManager.previewSound(selectedSound)
            }) {
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: 10))
            }
            .buttonStyle(BorderedButtonStyle())
            .controlSize(.mini)
            .help("Preview sound")
            .disabled(selectedSound.isEmpty)
            
            Spacer()
        }
    }
}

struct ModernSoundToggle: View {
    let label: String
    let description: String?
    @Binding var selectedSound: String
    @StateObject private var soundManager = SoundManager.shared
    
    private var isSoundEnabled: Bool {
        SoundManager.isSoundEnabled(selectedSound)
    }
    
    private var isSoundEnabledBinding: Binding<Bool> {
        Binding(
            get: { SoundManager.isSoundEnabled(selectedSound) },
            set: { newValue in
                selectedSound = newValue ? "default" : ""
            }
        )
    }
    
    init(_ label: String, description: String? = nil, selectedSound: Binding<String>) {
        self.label = label
        self.description = description
        self._selectedSound = selectedSound
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .fontWeight(.medium)
                    
                    if let description = description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: isSoundEnabledBinding)
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            }
            
            // Sound selection (only shown when enabled)
            if isSoundEnabled {
                HStack(spacing: 8) {
                    Text("Sound:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 50, alignment: .leading)
                    
                    Picker("Sound", selection: $selectedSound) {
                        ForEach(SoundManager.systemSounds, id: \.name) { sound in
                            Text(sound.displayName).tag(sound.name)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: 140)
                    
                    Button(action: {
                        soundManager.previewSound(selectedSound)
                    }) {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(BorderedButtonStyle())
                    .controlSize(.mini)
                    .help("Preview sound")
                    
                    Spacer()
                }
                .padding(.leading, 20)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSoundEnabled)
        .padding(.vertical, 4)
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RectCorner: OptionSet {
    let rawValue: Int
    
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.size.width
        let height = rect.size.height
        
        // Top left
        if corners.contains(.topLeft) {
            path.move(to: CGPoint(x: radius, y: 0))
        } else {
            path.move(to: CGPoint(x: 0, y: 0))
        }
        
        // Top edge and top right
        if corners.contains(.topRight) {
            path.addLine(to: CGPoint(x: width - radius, y: 0))
            path.addArc(center: CGPoint(x: width - radius, y: radius), 
                       radius: radius, 
                       startAngle: Angle(degrees: -90), 
                       endAngle: Angle(degrees: 0), 
                       clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: width, y: 0))
        }
        
        // Right edge and bottom right
        if corners.contains(.bottomRight) {
            path.addLine(to: CGPoint(x: width, y: height - radius))
            path.addArc(center: CGPoint(x: width - radius, y: height - radius), 
                       radius: radius, 
                       startAngle: Angle(degrees: 0), 
                       endAngle: Angle(degrees: 90), 
                       clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: width, y: height))
        }
        
        // Bottom edge and bottom left
        if corners.contains(.bottomLeft) {
            path.addLine(to: CGPoint(x: radius, y: height))
            path.addArc(center: CGPoint(x: radius, y: height - radius), 
                       radius: radius, 
                       startAngle: Angle(degrees: 90), 
                       endAngle: Angle(degrees: 180), 
                       clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: 0, y: height))
        }
        
        // Left edge and close path
        if corners.contains(.topLeft) {
            path.addLine(to: CGPoint(x: 0, y: radius))
            path.addArc(center: CGPoint(x: radius, y: radius), 
                       radius: radius, 
                       startAngle: Angle(degrees: 180), 
                       endAngle: Angle(degrees: 270), 
                       clockwise: false)
        } else {
            path.addLine(to: CGPoint(x: 0, y: 0))
        }
        
        return path
    }
}

// MARK: - Vertical Layout Components

struct VerticalPreferenceSection<Content: View>: View {
    let header: String
    let subtitle: String?
    let content: Content
    
    init(_ header: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.header = header
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PreferenceSectionHeader(header, subtitle: subtitle)
            
            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Icon Preference Toggle Component

struct IconPreferenceToggle: View {
    let label: String
    let description: String?
    let iconType: MetricIconType
    @Binding var isOn: Bool
    @EnvironmentObject var preferences: AppPreferences
    
    init(_ label: String, description: String? = nil, iconType: MetricIconType, isOn: Binding<Bool>) {
        self.label = label
        self.description = description
        self.iconType = iconType
        self._isOn = isOn
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Icon display
                Text(currentIcon)
                    .font(.system(size: 14))
                    .frame(width: 60, alignment: .center)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .fontWeight(.medium)
                    
                    if let description = description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(iconDescription)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                Spacer()
                
                Toggle("", isOn: $isOn)
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            }
        }
        .padding(.vertical, 4)
    }
    
    private var currentIcon: String {
        switch iconType {
        case .cost:
            return preferences.useTextForCost ? "COST" : "$"
        case .burnRate:
            return preferences.useTextForBurnRate ? "BURN" : "🟢🟡🔴"
        case .remainingTime:
            return preferences.useTextForRemainingTime ? "TIME" : "⏱️"
        case .projectedCost:
            return preferences.useTextForProjectedCost ? "PROJ" : "📊"
        case .apiCalls:
            return preferences.useTextForApiCalls ? "API" : "🔄"
        case .sessionsToday:
            return preferences.useTextForSessionsToday ? "SESS" : "S:"
        case .tokenLimit:
            return preferences.useTextForTokenLimit ? "TOK" : "🟢🟡🟠🔴"
        }
    }
    
    private var iconDescription: String {
        switch iconType {
        case .cost:
            return preferences.useTextForCost ? "Displays as \"COST\"" : "Displays as \"$\""
        case .burnRate:
            return preferences.useTextForBurnRate ? "Displays as \"BURN\"" : "Displays with color indicators"
        case .remainingTime:
            return preferences.useTextForRemainingTime ? "Displays as \"TIME\"" : "Displays as \"⏱️\""
        case .projectedCost:
            return preferences.useTextForProjectedCost ? "Displays as \"PROJ\"" : "Displays as \"📊\""
        case .apiCalls:
            return preferences.useTextForApiCalls ? "Displays as \"API\"" : "Displays as \"🔄\""
        case .sessionsToday:
            return preferences.useTextForSessionsToday ? "Displays as \"SESS\"" : "Displays as \"S:\""
        case .tokenLimit:
            return preferences.useTextForTokenLimit ? "Displays as \"TOK\"" : "Displays with color indicators"
        }
    }
}

enum MetricIconType {
    case cost
    case burnRate
    case remainingTime
    case projectedCost
    case apiCalls
    case sessionsToday
    case tokenLimit
}

// MARK: - Layout Helpers

extension View {
    func preferenceTabLayout() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                self
                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    func modernPreferenceStyle() -> some View {
        self
            .font(.system(size: 13))
            .foregroundColor(.primary)
    }
    
    func uniformGridCell() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}