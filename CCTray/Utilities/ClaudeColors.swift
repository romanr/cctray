import SwiftUI
import AppKit

struct ClaudeColors {
    /// Claude Code orange color - using a simple, direct approach that works in menu bars
    static let orange = Color.orange
    
    /// Alternative bright orange that should be more visible
    static let brightOrange = Color.red // Testing with red to see if color works at all
    
    /// Claude Code orange color for light mode
    static let orangeLight = Color(red: 1.0, green: 0.55, blue: 0.0)
    
    /// Claude Code orange color for dark mode (slightly brighter)
    static let orangeDark = Color(red: 1.0, green: 0.6, blue: 0.1)
}