//
//  ModernDesign.swift
//  TopGUI
//
//  Modern glassmorphic design with purple gradients
//  Inspired by macOS Ventura and contemporary dashboard aesthetics
//
//  Created by Jordan Koch on 1/15/2026.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct ModernColors {
    // Gradient colors for background
    static let gradientStart = Color(red: 0.4, green: 0.15, blue: 0.7) // Deep purple
    static let gradientMid = Color(red: 0.5, green: 0.2, blue: 0.8)    // Purple
    static let gradientEnd = Color(red: 0.7, green: 0.3, blue: 0.9)    // Light purple

    // Accent colors
    static let accent = Color(red: 0.9, green: 0.4, blue: 0.7)         // Pink
    static let accentBlue = Color(red: 0.3, green: 0.6, blue: 1.0)     // Blue
    static let accentGreen = Color(red: 0.4, green: 0.8, blue: 0.5)    // Green
    static let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.3)   // Orange

    // Status colors for heat maps
    static let statusLow = Color(red: 0.4, green: 0.8, blue: 0.5)      // Green
    static let statusMedium = Color(red: 1.0, green: 0.8, blue: 0.3)   // Yellow
    static let statusHigh = Color(red: 1.0, green: 0.6, blue: 0.3)     // Orange
    static let statusCritical = Color(red: 1.0, green: 0.3, blue: 0.4) // Red

    // Text colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)

    // Glass card colors
    static let glassBackground = Color.white.opacity(0.1)
    static let glassBorder = Color.white.opacity(0.2)

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

    // Background gradient
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientMid, gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// Glassmorphic card styling
struct GlassCard: ViewModifier {
    let prominent: Bool

    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(ModernColors.glassBackground)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(ModernColors.glassBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(prominent ? 0.3 : 0.15), radius: prominent ? 20 : 10, y: prominent ? 10 : 5)
            )
    }
}

extension View {
    func glassCard(prominent: Bool = false) -> some View {
        modifier(GlassCard(prominent: prominent))
    }
}

// Modern button style
struct ModernButtonStyle: ButtonStyle {
    let color: Color
    let style: ButtonStyleType

    enum ButtonStyleType {
        case filled
        case outlined
        case destructive
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if style == .filled || style == .destructive {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(configuration.isPressed ? color.opacity(0.7) : color)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color, lineWidth: 2)
                    }
                }
            )
            .foregroundColor(style == .outlined ? color : .white)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .shadow(color: color.opacity(0.4), radius: configuration.isPressed ? 5 : 10)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// Modern header text
struct ModernHeader: ViewModifier {
    let size: HeaderSize

    enum HeaderSize {
        case large, medium, small

        var fontSize: CGFloat {
            switch self {
            case .large: return 28
            case .medium: return 20
            case .small: return 16
            }
        }
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: size.fontSize, weight: .bold, design: .rounded))
            .foregroundColor(ModernColors.textPrimary)
    }
}

extension View {
    func modernHeader(size: ModernHeader.HeaderSize = .large) -> some View {
        modifier(ModernHeader(size: size))
    }
}

// Hexagonal shape for heat map
struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        var path = Path()
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 2
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}
