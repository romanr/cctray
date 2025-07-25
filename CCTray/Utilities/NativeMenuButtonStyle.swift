//
//  NativeMenuButtonStyle.swift
//  CCTray
//
//  Created by Robert Goniszewski on 16/07/2025.
//

import SwiftUI

struct NativeMenuButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13))
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColour(configuration: configuration))
            )
            .onHover { hovering in
                isHovered = hovering
            }
            .animation(.easeInOut(duration: 0.1), value: isHovered)
            .animation(.easeInOut(duration: 0.1), value: isFocused)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private func backgroundColour(configuration: Configuration) -> Color {
        if configuration.isPressed {
            return Color(NSColor.controlAccentColor).opacity(0.3)
        } else if isFocused {
            return Color(NSColor.controlAccentColor).opacity(0.2)
        } else if isHovered {
            return Color(NSColor.controlAccentColor).opacity(0.1)
        } else {
            return Color.clear
        }
    }
}

// Custom modifier for menu items
struct MenuItemModifier: ViewModifier {
    let isDisabled: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isDisabled ? 0.5 : 1.0)
            .allowsHitTesting(!isDisabled)
    }
}

extension View {
    func menuItemStyle(disabled: Bool = false) -> some View {
        self
            .buttonStyle(NativeMenuButtonStyle())
            .modifier(MenuItemModifier(isDisabled: disabled))
    }
}