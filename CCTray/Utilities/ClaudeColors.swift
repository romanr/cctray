import SwiftUI
import AppKit

struct ClaudeColors {
    // MARK: - Primary Orange Colors
    
    /// Primary orange color for the app
    static let primary = Color(red: 1.0, green: 0.6, blue: 0.0)
    
    /// Main orange color - using system orange as base
    static let orange = Color.orange
    
    /// Bright orange for high visibility elements
    static let brightOrange = Color(red: 1.0, green: 0.55, blue: 0.0)
    
    /// Light orange for subtle backgrounds
    static let orangeLight = Color(red: 1.0, green: 0.75, blue: 0.3)
    
    /// Dark orange for emphasis and dark mode
    static let orangeDark = Color(red: 0.9, green: 0.5, blue: 0.0)
    
    // MARK: - Semantic Colors Based on Orange
    
    /// Orange-based accent color for interactive elements
    static let accent = Color(red: 1.0, green: 0.6, blue: 0.0)
    
    /// Orange tint for backgrounds and subtle elements
    static let background = Color(red: 1.0, green: 0.6, blue: 0.0).opacity(0.05)
    
    /// Orange for primary buttons and actions
    static let primaryAction = Color(red: 1.0, green: 0.6, blue: 0.0)
    
    /// Orange for chart primary data
    static let chartPrimary = Color(red: 1.0, green: 0.6, blue: 0.0)
    
    /// Orange for progress indicators
    static let progress = Color(red: 1.0, green: 0.6, blue: 0.0)
    
    // MARK: - Secondary Light Blue Colors
    
    /// Secondary light blue color for the app
    static let secondary = Color(red: 0.4, green: 0.7, blue: 1.0)
    
    /// Light blue for secondary actions
    static let secondaryAction = Color(red: 0.4, green: 0.7, blue: 1.0)
    
    /// Light blue for secondary chart data
    static let chartSecondary = Color(red: 0.4, green: 0.7, blue: 1.0)
    
    /// Light blue for secondary progress indicators
    static let progressSecondary = Color(red: 0.4, green: 0.7, blue: 1.0)
    
    /// Light blue tint for subtle backgrounds
    static let secondaryBackground = Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.05)
    
    /// Bright light blue for emphasis
    static let secondaryBright = Color(red: 0.3, green: 0.6, blue: 1.0)
    
    /// Light variant for very subtle elements
    static let secondaryLight = Color(red: 0.6, green: 0.8, blue: 1.0)
    
    // MARK: - Supporting Colors (maintain semantic meaning)
    
    /// Success color - keeping green for positive states
    static let success = Color.green
    
    /// Warning color - using orange variant for warnings
    static let warning = Color(red: 1.0, green: 0.65, blue: 0.0)
    
    /// Error color - keeping red for errors
    static let error = Color.red
    
    /// Info color - using orange variant for information
    static let info = Color(red: 1.0, green: 0.7, blue: 0.2)
}

// MARK: - NSColor Extensions for AppKit Components

extension ClaudeColors {
    /// NSColor versions for AppKit components like IconCreator
    struct NSColors {
        /// Primary orange color for AppKit
        static let primary = NSColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
        
        /// Main orange color for AppKit
        static let orange = NSColor.orange
        
        /// Bright orange for AppKit
        static let brightOrange = NSColor(red: 1.0, green: 0.55, blue: 0.0, alpha: 1.0)
        
        /// Light orange for AppKit
        static let orangeLight = NSColor(red: 1.0, green: 0.75, blue: 0.3, alpha: 1.0)
        
        /// Dark orange for AppKit
        static let orangeDark = NSColor(red: 0.9, green: 0.5, blue: 0.0, alpha: 1.0)
        
        /// Warning color for AppKit
        static let warning = NSColor(red: 1.0, green: 0.65, blue: 0.0, alpha: 1.0)
        
        /// Error color for AppKit
        static let error = NSColor.red
        
        /// Success color for AppKit
        static let success = NSColor.green
        
        // MARK: - Secondary Light Blue Colors for AppKit
        
        /// Secondary light blue color for AppKit
        static let secondary = NSColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
        
        /// Light blue for secondary actions in AppKit
        static let secondaryAction = NSColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
        
        /// Bright light blue for AppKit
        static let secondaryBright = NSColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0)
        
        /// Light variant for AppKit
        static let secondaryLight = NSColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0)
    }
}