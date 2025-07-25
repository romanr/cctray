import SwiftUI

struct LegendView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("CCTray Legend")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(.bottom, 10)
            
            // Legend content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Current Session Metrics
                    LegendSection(title: "Current Session Metrics") {
                        LegendTableItem(icon: "$", title: "Cost", description: "Shows current session cost in USD")
                        LegendTableItem(icon: "🟢🟡🔴", title: "Burn Rate", description: "Shows LOW/MODERATE/HIGH burn rate with colored indicators")
                        LegendTableItem(icon: "⏱️", title: "Remaining Time", description: "Shows estimated time remaining in current session")
                        LegendTableItem(icon: "🔄", title: "API Calls", description: "Shows number of API calls made in current session")
                    }
                    
                    // Projected Metrics
                    LegendSection(title: "Projected Metrics") {
                        LegendTableItem(icon: "📊", title: "Projected Cost", description: "Shows projected total session cost based on current usage")
                        LegendTableItem(icon: "📈", title: "Tokens Used", description: "Shows total tokens consumed in current session")
                    }
                    
                    // Daily Tracking
                    LegendSection(title: "Daily Tracking") {
                        LegendTableItem(icon: "S:", title: "Sessions Today", description: "Shows number of Claude sessions started today")
                    }
                    
                    // Token Limits
                    LegendSection(title: "Token Limits") {
                        LegendTableItem(icon: "🟢🟡🟠🔴", title: "Token Limit", description: "Shows token usage percentage with colored indicators")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Token Limit Color Indicators:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 20) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("🟢")
                                        Text("Normal")
                                            .font(.caption)
                                    }
                                    HStack {
                                        Text("🟡")
                                        Text("Warning")
                                            .font(.caption)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("🟠")
                                        Text("Urgent")
                                            .font(.caption)
                                    }
                                    HStack {
                                        Text("🔴")
                                        Text("Critical")
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        .padding(.leading, 16)
                        .padding(.top, 8)
                    }
                    
                    // Burn Rate Details
                    LegendSection(title: "Burn Rate Details") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Burn rate categorization:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("🟢")
                                    Text("LOW")
                                        .fontWeight(.medium)
                                    Text("- Below configured low threshold")
                                        .foregroundColor(.secondary)
                                }
                                .font(.caption)
                                
                                HStack {
                                    Text("🟡")
                                    Text("MODERATE")
                                        .fontWeight(.medium)
                                    Text("- Between low and high thresholds")
                                        .foregroundColor(.secondary)
                                }
                                .font(.caption)
                                
                                HStack {
                                    Text("🔴")
                                    Text("HIGH")
                                        .fontWeight(.medium)
                                    Text("- Above configured high threshold")
                                        .foregroundColor(.secondary)
                                }
                                .font(.caption)
                            }
                        }
                        .padding(.leading, 16)
                    }
                    
                    // Additional Info
                    LegendSection(title: "Additional Information") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Metrics update every 5 seconds by default")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("• Display rotates between different metrics automatically")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("• Configure thresholds and display preferences in Settings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(width: 500, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct LegendSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            content
        }
        .padding(.vertical, 8)
    }
}

struct LegendItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.system(size: 16))
                .frame(minWidth: 30, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

struct LegendTableItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Icon display - matching IconPreferenceToggle layout
                Text(icon)
                    .font(.system(size: 14))
                    .frame(width: 60, alignment: .center)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .fontWeight(.medium)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LegendView()
}
