//
//  ModernDesign.swift
//  TopGUI
//
//  Extreme glassmorphic design with floating colorful blobs
//  Inspired by iOS design and modern dashboard aesthetics
//
//  Created by Jordan Koch on 1/15/2026.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct ModernColors {
    // Light blue gradient background
    static let gradientStart = Color(red: 0.6, green: 0.85, blue: 1.0)  // Light sky blue
    static let gradientMid = Color(red: 0.7, green: 0.88, blue: 1.0)    // Lighter blue
    static let gradientEnd = Color(red: 0.8, green: 0.92, blue: 1.0)    // Very light blue

    // Playful accent colors
    static let orange = Color(red: 1.0, green: 0.65, blue: 0.3)         // Warm orange
    static let yellow = Color(red: 1.0, green: 0.85, blue: 0.4)         // Sunny yellow
    static let pink = Color(red: 1.0, green: 0.45, blue: 0.55)          // Coral pink
    static let lightBlue = Color(red: 0.4, green: 0.75, blue: 1.0)      // Sky blue
    static let mint = Color(red: 0.5, green: 0.9, blue: 0.75)           // Mint green
    static let accent = Color(red: 1.0, green: 0.65, blue: 0.3)         // Orange (for compatibility)
    static let accentBlue = Color(red: 0.4, green: 0.75, blue: 1.0)     // Sky blue
    static let accentGreen = Color(red: 0.5, green: 0.9, blue: 0.75)    // Mint
    static let accentOrange = Color(red: 1.0, green: 0.65, blue: 0.3)   // Orange

    // Background blob colors
    static let blobOrange = Color(red: 1.0, green: 0.65, blue: 0.3)
    static let blobYellow = Color(red: 1.0, green: 0.85, blue: 0.4)
    static let blobPink = Color(red: 1.0, green: 0.5, blue: 0.6)
    static let blobPurple = Color(red: 0.8, green: 0.6, blue: 1.0)

    // Status colors for heat maps (softer)
    static let statusLow = Color(red: 0.5, green: 0.9, blue: 0.75)      // Mint
    static let statusMedium = Color(red: 1.0, green: 0.85, blue: 0.4)   // Yellow
    static let statusHigh = Color(red: 1.0, green: 0.65, blue: 0.3)     // Orange
    static let statusCritical = Color(red: 1.0, green: 0.45, blue: 0.55) // Pink/Red

    // Text colors (dark for light background)
    static let textPrimary = Color(red: 0.15, green: 0.15, blue: 0.2)   // Dark gray
    static let textSecondary = Color(red: 0.4, green: 0.4, blue: 0.5)   // Medium gray
    static let textTertiary = Color(red: 0.6, green: 0.6, blue: 0.65)   // Light gray

    // Glass card colors (even more translucent)
    static let glassBackground = Color.white.opacity(0.25)
    static let glassBorder = Color.white.opacity(0.5)

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

// Extreme glassmorphic card with heavy blur
struct GlassCard: ViewModifier {
    let prominent: Bool

    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(ModernColors.glassBackground)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                            .opacity(0.9)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(ModernColors.glassBorder, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                    .shadow(color: Color.white.opacity(0.8), radius: 1, x: -1, y: -1)
            )
    }
}

extension View {
    func glassCard(prominent: Bool = false) -> some View {
        modifier(GlassCard(prominent: prominent))
    }
}

// Modern button style with glass effect
struct ModernButtonStyle: ButtonStyle {
    let color: Color
    let style: ButtonStyleType

    enum ButtonStyleType {
        case filled
        case outlined
        case destructive
        case glass
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Group {
                    if style == .glass {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.3))
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                            )
                    } else if style == .filled || style == .destructive {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(configuration.isPressed ? color.opacity(0.8) : color)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color, lineWidth: 2)
                    }
                }
            )
            .foregroundColor(style == .outlined ? color : (style == .glass ? ModernColors.textPrimary : .white))
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .shadow(color: color.opacity(0.3), radius: configuration.isPressed ? 5 : 8)
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
            case .large: return 32
            case .medium: return 22
            case .small: return 18
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

// Floating background blob
struct FloatingBlob: View {
    let color: Color
    let size: CGFloat
    let x: CGFloat
    let y: CGFloat
    let animation: Animation

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [color, color.opacity(0.6)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .blur(radius: 50)
            .offset(x: x, y: y)
    }
}

// Background with floating blobs
struct GlassmorphicBackground: View {
    @State private var animateBlobs = false

    var body: some View {
        ZStack {
            // Base gradient
            ModernColors.backgroundGradient
                .ignoresSafeArea()

            // Large floating blobs
            FloatingBlob(
                color: ModernColors.blobOrange,
                size: 400,
                x: animateBlobs ? -100 : -150,
                y: animateBlobs ? -200 : -250,
                animation: .easeInOut(duration: 8).repeatForever(autoreverses: true)
            )

            FloatingBlob(
                color: ModernColors.blobYellow,
                size: 350,
                x: animateBlobs ? 150 : 100,
                y: animateBlobs ? -150 : -100,
                animation: .easeInOut(duration: 7).repeatForever(autoreverses: true)
            )

            FloatingBlob(
                color: ModernColors.blobPink,
                size: 450,
                x: animateBlobs ? 100 : 150,
                y: animateBlobs ? 300 : 350,
                animation: .easeInOut(duration: 9).repeatForever(autoreverses: true)
            )

            FloatingBlob(
                color: ModernColors.blobPurple,
                size: 300,
                x: animateBlobs ? -200 : -150,
                y: animateBlobs ? 250 : 300,
                animation: .easeInOut(duration: 10).repeatForever(autoreverses: true)
            )

            FloatingBlob(
                color: ModernColors.blobOrange.opacity(0.7),
                size: 250,
                x: animateBlobs ? 200 : 250,
                y: animateBlobs ? 100 : 50,
                animation: .easeInOut(duration: 6).repeatForever(autoreverses: true)
            )
        }
        .onAppear {
            withAnimation {
                animateBlobs = true
            }
        }
    }
}

// Hexagonal shape for heat map (kept for compatibility)
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
