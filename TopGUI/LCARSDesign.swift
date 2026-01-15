//
//  LCARSDesign.swift
//  TopGUI
//
//  LCARS (Library Computer Access/Retrieval System) inspired design
//  Star Trek TNG aesthetic with colorful panels and rounded corners
//
//  Created by Jordan Koch on 1/15/2026.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct LCARSColors {
    // Primary LCARS palette
    static let orange = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let violet = Color(red: 0.8, green: 0.6, blue: 1.0)
    static let blue = Color(red: 0.4, green: 0.6, blue: 1.0)
    static let red = Color(red: 1.0, green: 0.3, blue: 0.3)
    static let yellow = Color(red: 1.0, green: 0.8, blue: 0.2)
    static let pink = Color(red: 1.0, green: 0.5, blue: 0.8)
    static let tan = Color(red: 1.0, green: 0.7, blue: 0.5)

    // Status colors for heat maps
    static let statusLow = Color(red: 0.3, green: 0.8, blue: 0.4)
    static let statusMedium = yellow
    static let statusHigh = orange
    static let statusCritical = red

    // Background colors
    static let background = Color(red: 0.0, green: 0.0, blue: 0.0)
    static let panelBackground = Color(red: 0.1, green: 0.1, blue: 0.15)
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.7, green: 0.7, blue: 0.8)

    // Get color for percentage (heat map)
    static func heatColor(percentage: Double) -> Color {
        switch percentage {
        case 0..<25:
            return statusLow
        case 25..<50:
            return statusMedium
        case 50..<75:
            return statusHigh
        default:
            return statusCritical
        }
    }
}

// LCARS panel styling
struct LCARSPanel: ViewModifier {
    let color: Color
    let glowing: Bool

    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(LCARSColors.panelBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(color, lineWidth: 3)
                    )
                    .shadow(color: glowing ? color.opacity(0.6) : .clear, radius: 10)
            )
    }
}

extension View {
    func lcarsPanel(color: Color = LCARSColors.orange, glowing: Bool = true) -> some View {
        modifier(LCARSPanel(color: color, glowing: glowing))
    }
}

// LCARS button style
struct LCARSButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(configuration.isPressed ? color.opacity(0.6) : color)
            )
            .foregroundColor(.black)
            .fontWeight(.bold)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .shadow(color: color.opacity(0.5), radius: configuration.isPressed ? 2 : 5)
    }
}

// LCARS header text
struct LCARSHeader: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.system(size: 24, weight: .black, design: .rounded))
            .foregroundColor(color)
            .textCase(.uppercase)
    }
}

extension View {
    func lcarsHeader(color: Color = LCARSColors.orange) -> some View {
        modifier(LCARSHeader(color: color))
    }
}
