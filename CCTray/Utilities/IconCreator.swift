import AppKit
import SwiftUI

/// Icon state representing different usage conditions
enum IconState {
    case normal        // Green - normal usage
    case warning       // Yellow - approaching limits
    case critical      // Red - at or near limits
    case error         // Gray - error state
    case info          // Light blue - informational/loading state
}

/// Position for dot indicator on the icon
enum DotPosition: String, CaseIterable, Codable {
    case bottomRight = "bottomRight"
    case bottomLeft = "bottomLeft"
    case topRight = "topRight"
    case topLeft = "topLeft"
    
    var title: String {
        switch self {
        case .bottomRight:
            return "Bottom Right"
        case .bottomLeft:
            return "Bottom Left"
        case .topRight:
            return "Top Right"
        case .topLeft:
            return "Top Left"
        }
    }
}

/// Style of progress indicator
enum ProgressIndicatorStyle: String, CaseIterable, Codable {
    case circularArc = "circularArc"
    case bottomRightDot = "bottomRightDot"
    
    var title: String {
        switch self {
        case .circularArc:
            return "Circular Arc"
        case .bottomRightDot:
            return "Bottom Right Dot"
        }
    }
    
    var description: String {
        switch self {
        case .circularArc:
            return "Progress shown as arc around entire icon"
        case .bottomRightDot:
            return "Progress shown as dot at bottom-right corner"
        }
    }
}

/// Utility for creating programmatic icons with dynamic states and visual indicators
/// Enhanced to support color-coded states, progress indicators, and animations
struct IconCreator {
    static func createCustomIcon(size: CGSize = CGSize(width: 18, height: 18)) -> NSImage {
        let image = NSImage(size: size)
        
        image.lockFocus()
        defer { image.unlockFocus() }
        
        // Orange background with rounded corners
        let backgroundColor = ClaudeColors.NSColors.orange
        backgroundColor.setFill()
        
        let backgroundRect = NSRect(origin: .zero, size: size)
        let backgroundPath = NSBezierPath(roundedRect: backgroundRect, xRadius: 3, yRadius: 3)
        backgroundPath.fill()
        
        // White "C" letter
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size.height * 0.67, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        
        let letter = NSAttributedString(string: "C", attributes: attributes)
        let letterSize = letter.size()
        
        // Center the letter in the icon
        let letterRect = NSRect(
            x: (size.width - letterSize.width) / 2,
            y: (size.height - letterSize.height) / 2,
            width: letterSize.width,
            height: letterSize.height
        )
        
        letter.draw(in: letterRect)
        
        return image
    }
    
    static func createCustomIconForDarkMode(size: CGSize = CGSize(width: 18, height: 18)) -> NSImage {
        let image = NSImage(size: size)
        
        image.lockFocus()
        defer { image.unlockFocus() }
        
        // Slightly darker orange for dark mode
        let backgroundColor = ClaudeColors.NSColors.primary
        backgroundColor.setFill()
        
        let backgroundRect = NSRect(origin: .zero, size: size)
        let backgroundPath = NSBezierPath(roundedRect: backgroundRect, xRadius: 3, yRadius: 3)
        backgroundPath.fill()
        
        // White "C" letter
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size.height * 0.67, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        
        let letter = NSAttributedString(string: "C", attributes: attributes)
        let letterSize = letter.size()
        
        // Center the letter in the icon
        let letterRect = NSRect(
            x: (size.width - letterSize.width) / 2,
            y: (size.height - letterSize.height) / 2,
            width: letterSize.width,
            height: letterSize.height
        )
        
        letter.draw(in: letterRect)
        
        return image
    }
    
    static func createAdaptiveIcon(size: CGSize = CGSize(width: 18, height: 18)) -> NSImage {
        let lightIcon = createCustomIcon(size: size)
        let darkIcon = createCustomIconForDarkMode(size: size)
        
        let adaptiveImage = NSImage(size: size)
        adaptiveImage.addRepresentation(lightIcon.representations.first!)
        
        // Add dark mode representation
        if let darkRep = darkIcon.representations.first {
            darkRep.setValue(NSAppearance(named: .darkAqua), forKey: "appearance")
            adaptiveImage.addRepresentation(darkRep)
        }
        
        return adaptiveImage
    }
    
    // MARK: - PNG-Based Enhanced Icons
    
    /// Creates an icon using the original PNG "c" icon with color tinting and enhancements
    static func createPNGBasedIcon(
        state: IconState,
        progressPercent: Double = 0.0,
        showProgress: Bool = false,
        size: CGSize = CGSize(width: 18, height: 18)
    ) -> NSImage {
        guard let baseIcon = loadPNGIcon(size: size) else {
            // Fallback to programmatic icon if PNG loading fails
            return createDynamicIcon(state: state, progressPercent: progressPercent, showProgress: showProgress, size: size)
        }
        
        let image = NSImage(size: size)
        
        image.lockFocus()
        defer { image.unlockFocus() }
        
        // Draw the base PNG with color tint
        let tintedIcon = applyColorTint(to: baseIcon, state: state)
        let drawRect = NSRect(origin: .zero, size: size)
        tintedIcon.draw(in: drawRect)
        
        // Draw progress indicator if enabled
        if showProgress && progressPercent > 0 {
            drawProgressIndicator(
                in: drawRect,
                progress: progressPercent,
                size: size
            )
        }
        
        return image
    }
    
    /// Creates a pulsing version of the PNG-based icon
    static func createPNGBasedPulsingIcon(
        state: IconState,
        progressPercent: Double = 0.0,
        showProgress: Bool = false,
        pulsePhase: Double = 0.0,
        size: CGSize = CGSize(width: 18, height: 18)
    ) -> NSImage {
        guard let baseIcon = loadPNGIcon(size: size) else {
            // Fallback to programmatic pulsing icon if PNG loading fails
            return createPulsingIcon(state: state, progressPercent: progressPercent, showProgress: showProgress, pulsePhase: pulsePhase, size: size)
        }
        
        let image = NSImage(size: size)
        
        image.lockFocus()
        defer { image.unlockFocus() }
        
        // Calculate pulse intensity (0.6 to 1.0)
        let pulseIntensity = 0.6 + 0.4 * (1.0 + sin(pulsePhase)) / 2.0
        
        // Draw the base PNG with color tint and pulse effect
        let tintedIcon = applyColorTint(to: baseIcon, state: state, pulseIntensity: pulseIntensity)
        let drawRect = NSRect(origin: .zero, size: size)
        tintedIcon.draw(in: drawRect)
        
        // Draw progress indicator if enabled
        if showProgress && progressPercent > 0 {
            drawProgressIndicator(
                in: drawRect,
                progress: progressPercent,
                size: size
            )
        }
        
        return image
    }
    
    /// Creates an icon using the original PNG \"c\" icon with a dot indicator (no color tinting)
    static func createPNGBasedIconWithDotIndicator(
        state: IconState,
        progressPercent: Double = 0.0,
        showProgress: Bool = false,
        dotPosition: DotPosition = .bottomRight,
        size: CGSize = CGSize(width: 18, height: 18)
    ) -> NSImage {
        guard let baseIcon = loadPNGIcon(size: size) else {
            // Fallback to programmatic icon if PNG loading fails
            return createDynamicIcon(state: state, progressPercent: progressPercent, showProgress: showProgress, size: size)
        }
        
        let image = NSImage(size: size)
        
        image.lockFocus()
        defer { image.unlockFocus() }
        
        // Draw the base PNG without any tinting to preserve original appearance
        let drawRect = NSRect(origin: .zero, size: size)
        baseIcon.draw(in: drawRect)
        
        // Draw dot indicator showing state and progress
        drawDotIndicator(
            in: drawRect,
            progress: showProgress ? progressPercent : 0.0,
            position: dotPosition,
            state: state,
            size: size,
            pulseIntensity: 1.0
        )
        
        return image
    }
    
    /// Creates a pulsing version of the PNG-based icon with dot indicator
    static func createPNGBasedPulsingIconWithDotIndicator(
        state: IconState,
        progressPercent: Double = 0.0,
        showProgress: Bool = false,
        pulsePhase: Double = 0.0,
        dotPosition: DotPosition = .bottomRight,
        size: CGSize = CGSize(width: 18, height: 18)
    ) -> NSImage {
        guard let baseIcon = loadPNGIcon(size: size) else {
            // Fallback to programmatic pulsing icon if PNG loading fails
            return createPulsingIcon(state: state, progressPercent: progressPercent, showProgress: showProgress, pulsePhase: pulsePhase, size: size)
        }
        
        let image = NSImage(size: size)
        
        image.lockFocus()
        defer { image.unlockFocus() }
        
        // Draw the base PNG without any tinting to preserve original appearance
        let drawRect = NSRect(origin: .zero, size: size)
        baseIcon.draw(in: drawRect)
        
        // Calculate pulse intensity (0.6 to 1.0)
        let pulseIntensity = 0.6 + 0.4 * (1.0 + sin(pulsePhase)) / 2.0
        
        // Draw dot indicator with pulsing effect
        drawDotIndicator(
            in: drawRect,
            progress: showProgress ? progressPercent : 0.0,
            position: dotPosition,
            state: state,
            size: size,
            pulseIntensity: pulseIntensity
        )
        
        return image
    }
    
    // MARK: - Enhanced Dynamic Icons (Programmatic Fallback)
    
    /// Creates an icon with dynamic state coloring and optional progress indicator
    static func createDynamicIcon(
        state: IconState,
        progressPercent: Double = 0.0,
        showProgress: Bool = false,
        size: CGSize = CGSize(width: 18, height: 18)
    ) -> NSImage {
        let image = NSImage(size: size)
        
        image.lockFocus()
        defer { image.unlockFocus() }
        
        // Get color based on state
        let backgroundColor = colorForState(state)
        backgroundColor.setFill()
        
        // Draw background with rounded corners
        let backgroundRect = NSRect(origin: .zero, size: size)
        let backgroundPath = NSBezierPath(roundedRect: backgroundRect, xRadius: 3, yRadius: 3)
        backgroundPath.fill()
        
        // Draw progress indicator if enabled
        if showProgress && progressPercent > 0 {
            drawProgressIndicator(
                in: backgroundRect,
                progress: progressPercent,
                size: size
            )
        }
        
        // Draw "C" letter
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size.height * 0.67, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        
        let letter = NSAttributedString(string: "C", attributes: attributes)
        let letterSize = letter.size()
        
        let letterRect = NSRect(
            x: (size.width - letterSize.width) / 2,
            y: (size.height - letterSize.height) / 2,
            width: letterSize.width,
            height: letterSize.height
        )
        
        letter.draw(in: letterRect)
        
        return image
    }
    
    /// Creates an animated icon for pulsing effect
    static func createPulsingIcon(
        state: IconState,
        progressPercent: Double = 0.0,
        showProgress: Bool = false,
        pulsePhase: Double = 0.0,
        size: CGSize = CGSize(width: 18, height: 18)
    ) -> NSImage {
        let image = NSImage(size: size)
        
        image.lockFocus()
        defer { image.unlockFocus() }
        
        // Calculate pulse intensity (0.6 to 1.0)
        let pulseIntensity = 0.6 + 0.4 * (1.0 + sin(pulsePhase)) / 2.0
        
        // Get base color and adjust for pulse
        let baseColor = colorForState(state)
        let pulseColor = NSColor(
            red: baseColor.redComponent * pulseIntensity,
            green: baseColor.greenComponent * pulseIntensity,
            blue: baseColor.blueComponent * pulseIntensity,
            alpha: baseColor.alphaComponent
        )
        
        pulseColor.setFill()
        
        // Draw background with rounded corners
        let backgroundRect = NSRect(origin: .zero, size: size)
        let backgroundPath = NSBezierPath(roundedRect: backgroundRect, xRadius: 3, yRadius: 3)
        backgroundPath.fill()
        
        // Draw progress indicator if enabled
        if showProgress && progressPercent > 0 {
            drawProgressIndicator(
                in: backgroundRect,
                progress: progressPercent,
                size: size
            )
        }
        
        // Draw "C" letter
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: size.height * 0.67, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        
        let letter = NSAttributedString(string: "C", attributes: attributes)
        let letterSize = letter.size()
        
        let letterRect = NSRect(
            x: (size.width - letterSize.width) / 2,
            y: (size.height - letterSize.height) / 2,
            width: letterSize.width,
            height: letterSize.height
        )
        
        letter.draw(in: letterRect)
        
        return image
    }
    
    // MARK: - PNG Helper Methods
    
    /// Loads the original PNG "c" icon at the specified size
    private static func loadPNGIcon(size: CGSize) -> NSImage? {
        guard let originalIcon = NSImage(named: "c") else {
            return nil
        }
        
        // Resize the icon to the requested size
        let resizedIcon = NSImage(size: size)
        resizedIcon.lockFocus()
        defer { resizedIcon.unlockFocus() }
        
        originalIcon.draw(in: NSRect(origin: .zero, size: size))
        
        return resizedIcon
    }
    
    /// Applies color tinting to the PNG icon based on the current state
    private static func applyColorTint(to icon: NSImage, state: IconState, pulseIntensity: Double = 1.0) -> NSImage {
        let tintedIcon = NSImage(size: icon.size)
        
        tintedIcon.lockFocus()
        defer { tintedIcon.unlockFocus() }
        
        // Draw the original icon
        icon.draw(in: NSRect(origin: .zero, size: icon.size))
        
        // Get the appropriate tint color for the state
        let tintColor = tintColorForState(state, pulseIntensity: pulseIntensity)
        
        // Apply color tint using multiply blend mode
        let rect = NSRect(origin: .zero, size: icon.size)
        let tintPath = NSBezierPath(rect: rect)
        
        // Set tint color and draw with multiply blend mode
        tintColor.setFill()
        let graphicsContext = NSGraphicsContext.current
        graphicsContext?.saveGraphicsState()
        graphicsContext?.compositingOperation = .multiply
        tintPath.fill()
        graphicsContext?.restoreGraphicsState()
        
        // Add a subtle overlay for better visibility
        let overlayColor = tintColor.withAlphaComponent(0.3)
        overlayColor.setFill()
        graphicsContext?.saveGraphicsState()
        graphicsContext?.compositingOperation = .sourceOver
        tintPath.fill()
        graphicsContext?.restoreGraphicsState()
        
        return tintedIcon
    }
    
    /// Returns the appropriate tint color for the given icon state
    private static func tintColorForState(_ state: IconState, pulseIntensity: Double = 1.0) -> NSColor {
        let baseColor: NSColor
        
        switch state {
        case .normal:
            baseColor = NSColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0)  // Green
        case .warning:
            baseColor = ClaudeColors.NSColors.primary  // Orange/Yellow
        case .critical:
            baseColor = NSColor(red: 0.9, green: 0.0, blue: 0.0, alpha: 1.0)  // Red
        case .error:
            baseColor = NSColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)  // Gray
        case .info:
            baseColor = ClaudeColors.NSColors.secondary  // Light blue
        }
        
        // Apply pulse intensity if specified
        if pulseIntensity != 1.0 {
            return NSColor(
                red: baseColor.redComponent * pulseIntensity,
                green: baseColor.greenComponent * pulseIntensity,
                blue: baseColor.blueComponent * pulseIntensity,
                alpha: baseColor.alphaComponent
            )
        }
        
        return baseColor
    }
    
    // MARK: - Dot Indicator Helper Methods
    
    /// Draws a dot indicator at the specified position showing progress and state
    private static func drawDotIndicator(
        in rect: NSRect,
        progress: Double,
        position: DotPosition,
        state: IconState,
        size: CGSize,
        pulseIntensity: Double = 1.0
    ) {
        let dotRadius: CGFloat = min(size.width, size.height) * 0.17  // 17% of icon size
        let padding: CGFloat = 1.0
        
        let dotCenter = calculateDotCenter(
            for: position,
            in: rect,
            dotRadius: dotRadius,
            padding: padding
        )
        
        let dotRect = NSRect(
            x: dotCenter.x - dotRadius,
            y: dotCenter.y - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        )
        
        // Draw dot background (semi-transparent black)
        let backgroundPath = NSBezierPath(ovalIn: dotRect)
        NSColor.black.withAlphaComponent(0.2).setFill()
        backgroundPath.fill()
        
        // Draw progress arc within dot (if progress > 0)
        if progress > 0 {
            let progressColor = colorForDotProgress(state: state, pulseIntensity: pulseIntensity)
            let progressPath = NSBezierPath()
            
            progressPath.appendArc(
                withCenter: dotCenter,
                radius: dotRadius - 1,
                startAngle: 90,
                endAngle: 90 - (360 * progress)
            )
            
            progressColor.setStroke()
            progressPath.lineWidth = 2.0
            progressPath.stroke()
        } else {
            // Draw solid dot when no progress to show
            let dotColor = colorForDotProgress(state: state, pulseIntensity: pulseIntensity)
            dotColor.setFill()
            backgroundPath.fill()
        }
        
        // Draw dot border for definition
        NSColor.white.setStroke()
        backgroundPath.lineWidth = 1.0
        backgroundPath.stroke()
    }
    
    /// Calculates the center point for a dot at the specified position
    private static func calculateDotCenter(
        for position: DotPosition,
        in rect: NSRect,
        dotRadius: CGFloat,
        padding: CGFloat
    ) -> NSPoint {
        switch position {
        case .bottomRight:
            return NSPoint(
                x: rect.maxX - dotRadius - padding,
                y: rect.minY + dotRadius + padding
            )
        case .bottomLeft:
            return NSPoint(
                x: rect.minX + dotRadius + padding,
                y: rect.minY + dotRadius + padding
            )
        case .topRight:
            return NSPoint(
                x: rect.maxX - dotRadius - padding,
                y: rect.maxY - dotRadius - padding
            )
        case .topLeft:
            return NSPoint(
                x: rect.minX + dotRadius + padding,
                y: rect.maxY - dotRadius - padding
            )
        }
    }
    
    /// Returns the appropriate color for the dot progress indicator
    private static func colorForDotProgress(state: IconState, pulseIntensity: Double = 1.0) -> NSColor {
        let baseColor: NSColor
        
        switch state {
        case .normal:
            baseColor = NSColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0)  // Green
        case .warning:
            baseColor = ClaudeColors.NSColors.primary  // Orange
        case .critical:
            baseColor = NSColor(red: 0.9, green: 0.0, blue: 0.0, alpha: 1.0)  // Red
        case .error:
            baseColor = NSColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)  // Gray
        case .info:
            baseColor = ClaudeColors.NSColors.secondary  // Light blue
        }
        
        // Apply pulse intensity if specified
        if pulseIntensity != 1.0 {
            return NSColor(
                red: baseColor.redComponent * pulseIntensity,
                green: baseColor.greenComponent * pulseIntensity,
                blue: baseColor.blueComponent * pulseIntensity,
                alpha: baseColor.alphaComponent
            )
        }
        
        return baseColor
    }
    
    // MARK: - Helper Methods
    
    /// Returns the appropriate color for the given icon state (for programmatic icons)
    private static func colorForState(_ state: IconState) -> NSColor {
        switch state {
        case .normal:
            return NSColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 1.0)  // Green
        case .warning:
            return ClaudeColors.NSColors.primary  // Orange
        case .critical:
            return NSColor(red: 0.9, green: 0.0, blue: 0.0, alpha: 1.0)  // Red
        case .error:
            return NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)  // Gray
        case .info:
            return ClaudeColors.NSColors.secondary  // Light blue
        }
    }
    
    /// Draws a progress indicator arc around the icon
    private static func drawProgressIndicator(
        in rect: NSRect,
        progress: Double,
        size: CGSize
    ) {
        let center = NSPoint(x: rect.midX, y: rect.midY)
        let radius = min(size.width, size.height) / 2 - 1
        let startAngle: CGFloat = 90  // Start at top
        let endAngle: CGFloat = startAngle - (360 * progress)  // Clockwise
        
        let progressPath = NSBezierPath()
        progressPath.appendArc(
            withCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle
        )
        
        // Draw progress arc
        NSColor.white.setStroke()
        progressPath.lineWidth = 1.5
        progressPath.stroke()
    }
}