import AppKit
import SwiftUI

struct IconCreator {
    static func createCustomIcon(size: CGSize = CGSize(width: 18, height: 18)) -> NSImage {
        let image = NSImage(size: size)
        
        image.lockFocus()
        defer { image.unlockFocus() }
        
        // Orange background with rounded corners
        let backgroundColor = NSColor.orange
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
        let backgroundColor = NSColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)
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
}