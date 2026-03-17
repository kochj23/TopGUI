//
//  TopGUIWidget.swift
//  TopGUI Widget
//
//  WidgetKit extension for TopGUI system monitor
//  Shows CPU, Memory, Top Process, and System Health at a glance
//
//  Created by Jordan Koch on 2/4/2026.
//  Copyright 2026 Jordan Koch. All rights reserved.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct TopGUITimelineProvider: TimelineProvider {

    typealias Entry = TopGUIWidgetEntry

    func placeholder(in context: Context) -> TopGUIWidgetEntry {
        TopGUIWidgetEntry(
            date: Date(),
            stats: WidgetSystemStats(
                cpuUsage: 25.0,
                memoryUsage: 60.0,
                topProcessName: "Safari",
                topProcessCPU: 12.5,
                healthScore: 85.0
            ),
            isPlaceholder: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TopGUIWidgetEntry) -> Void) {
        let stats = SharedDataManager.shared.loadStats()
        let entry = TopGUIWidgetEntry(date: Date(), stats: stats, isPlaceholder: false)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TopGUIWidgetEntry>) -> Void) {
        let stats = SharedDataManager.shared.loadStats()
        let entry = TopGUIWidgetEntry(date: Date(), stats: stats, isPlaceholder: false)

        // Update every 5 minutes (widget updates are rate-limited by system)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Entry

struct TopGUIWidgetEntry: TimelineEntry {
    let date: Date
    let stats: WidgetSystemStats
    let isPlaceholder: Bool
}

// MARK: - Widget Views

struct TopGUIWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: TopGUIWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: TopGUIWidgetEntry

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "0A1628"),
                    Color(hex: "162544")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                // Header
                HStack {
                    Image(systemName: "cpu")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "00D4FF"))

                    Text("TopGUI")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    // Health indicator
                    Circle()
                        .fill(Color(hex: entry.stats.healthStatus.colorHex))
                        .frame(width: 8, height: 8)
                        .shadow(color: Color(hex: entry.stats.healthStatus.colorHex), radius: 4)
                }

                Spacer()

                // CPU Gauge
                HStack(spacing: 12) {
                    WidgetGauge(
                        value: entry.stats.cpuUsage,
                        color: heatColor(percentage: entry.stats.cpuUsage),
                        label: "CPU",
                        size: 50
                    )

                    WidgetGauge(
                        value: entry.stats.memoryUsage,
                        color: heatColor(percentage: entry.stats.memoryUsage),
                        label: "MEM",
                        size: 50
                    )
                }

                Spacer()

                // Health Score
                HStack {
                    Text("Health:")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "94A3B8"))

                    Text("\(Int(entry.stats.healthScore))%")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: entry.stats.healthStatus.colorHex))
                }
            }
            .padding(12)
        }
        .containerBackground(for: .widget) {
            Color(hex: "0A1628")
        }
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: TopGUIWidgetEntry

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "0A1628"),
                    Color(hex: "162544")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 16) {
                // Left side: Gauges
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "cpu")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: "00D4FF"))

                        Text("TopGUI")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Spacer()
                    }

                    HStack(spacing: 16) {
                        WidgetGauge(
                            value: entry.stats.cpuUsage,
                            color: heatColor(percentage: entry.stats.cpuUsage),
                            label: "CPU",
                            size: 60
                        )

                        WidgetGauge(
                            value: entry.stats.memoryUsage,
                            color: heatColor(percentage: entry.stats.memoryUsage),
                            label: "MEM",
                            size: 60
                        )
                    }
                }

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1)

                // Right side: Details
                VStack(alignment: .leading, spacing: 8) {
                    // Top Process
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Top Process")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "94A3B8"))

                        HStack {
                            Text(entry.stats.topProcessName)
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Spacer()

                            Text(String(format: "%.0f%%", entry.stats.topProcessCPU))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(heatColor(percentage: entry.stats.topProcessCPU))
                        }
                    }

                    Divider().background(Color.white.opacity(0.1))

                    // System Health
                    VStack(alignment: .leading, spacing: 2) {
                        Text("System Health")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "94A3B8"))

                        HStack {
                            Text(entry.stats.healthStatus.rawValue)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(hex: entry.stats.healthStatus.colorHex))

                            Spacer()

                            Text("\(Int(entry.stats.healthScore))%")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: entry.stats.healthStatus.colorHex))
                        }
                    }

                    // Updated time
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 8))
                            .foregroundColor(Color(hex: "64748B"))

                        Text(SharedDataManager.shared.dataAgeString())
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "64748B"))
                    }
                }
            }
            .padding(14)
        }
        .containerBackground(for: .widget) {
            Color(hex: "0A1628")
        }
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let entry: TopGUIWidgetEntry

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "0A1628"),
                    Color(hex: "162544")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "cpu")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "00D4FF"))

                    Text("TopGUI")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("System Monitor")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "94A3B8"))

                    Spacer()

                    // Health indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: entry.stats.healthStatus.colorHex))
                            .frame(width: 8, height: 8)
                            .shadow(color: Color(hex: entry.stats.healthStatus.colorHex), radius: 4)

                        Text(entry.stats.healthStatus.rawValue)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: entry.stats.healthStatus.colorHex))
                    }
                }

                Divider().background(Color.white.opacity(0.1))

                // Main gauges row
                HStack(spacing: 20) {
                    WidgetGauge(
                        value: entry.stats.cpuUsage,
                        color: heatColor(percentage: entry.stats.cpuUsage),
                        label: "CPU",
                        size: 70
                    )

                    WidgetGauge(
                        value: entry.stats.memoryUsage,
                        color: heatColor(percentage: entry.stats.memoryUsage),
                        label: "Memory",
                        size: 70
                    )

                    WidgetGauge(
                        value: entry.stats.gpuUsage,
                        color: heatColor(percentage: entry.stats.gpuUsage),
                        label: "GPU",
                        size: 70
                    )

                    WidgetGauge(
                        value: entry.stats.healthScore,
                        color: Color(hex: entry.stats.healthStatus.colorHex),
                        label: "Health",
                        size: 70
                    )
                }

                Divider().background(Color.white.opacity(0.1))

                // Details grid
                HStack(spacing: 16) {
                    // CPU Details
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CPU Details")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "00D4FF"))

                        StatRow(label: "User", value: String(format: "%.0f%%", entry.stats.cpuUser), color: Color(hex: "00D4FF"))
                        StatRow(label: "System", value: String(format: "%.0f%%", entry.stats.cpuSystem), color: Color(hex: "A855F7"))
                        StatRow(label: "Idle", value: String(format: "%.0f%%", entry.stats.cpuIdle), color: Color(hex: "00FF9F"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Memory Details
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Memory Details")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "A855F7"))

                        StatRow(label: "Used", value: String(format: "%.1f GB", entry.stats.memUsedGB), color: Color(hex: "F97316"))
                        StatRow(label: "Free", value: String(format: "%.1f GB", entry.stats.memFreeGB), color: Color(hex: "00FF9F"))
                        StatRow(label: "Wired", value: String(format: "%.1f GB", entry.stats.memWiredGB), color: Color(hex: "00D4FF"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider().background(Color.white.opacity(0.1))

                // Bottom row
                HStack {
                    // Top Process
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Top Process")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "94A3B8"))

                        HStack {
                            Text(entry.stats.topProcessName)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text(String(format: "%.0f%%", entry.stats.topProcessCPU))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(heatColor(percentage: entry.stats.topProcessCPU))
                        }
                    }

                    Spacer()

                    // System Info
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 8) {
                            Label("\(entry.stats.processCount)", systemImage: "cpu")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(Color(hex: "94A3B8"))

                            Label("\(entry.stats.runningProcesses) running", systemImage: "bolt.fill")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(Color(hex: "00FF9F"))
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 9))
                                .foregroundColor(Color(hex: "64748B"))

                            Text("Updated \(SharedDataManager.shared.dataAgeString())")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundColor(Color(hex: "64748B"))
                        }
                    }
                }
            }
            .padding(16)
        }
        .containerBackground(for: .widget) {
            Color(hex: "0A1628")
        }
    }
}

// MARK: - Helper Views

struct WidgetGauge: View {
    let value: Double
    let color: Color
    let label: String
    let size: CGFloat

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: size * 0.1)

                Circle()
                    .trim(from: 0, to: min(value / 100.0, 1.0))
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color.opacity(0.6), radius: 4)

                Text(String(format: "%.0f", value))
                    .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(width: size, height: size)

            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "94A3B8"))
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 5, height: 5)

            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "94A3B8"))

            Spacer()

            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Heat Color Function

func heatColor(percentage: Double) -> Color {
    switch percentage {
    case 0..<30:
        return Color(hex: "00FF9F") // Green
    case 30..<60:
        return Color(hex: "FBBF24") // Yellow
    case 60..<80:
        return Color(hex: "F97316") // Orange
    default:
        return Color(hex: "EF4444") // Red
    }
}

// MARK: - Widget Configuration

@main
struct TopGUIWidget: Widget {
    let kind: String = "TopGUIWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TopGUITimelineProvider()) { entry in
            TopGUIWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("TopGUI Monitor")
        .description("Real-time system stats: CPU, Memory, and Health.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

// MARK: - Preview Provider

#Preview("Small", as: .systemSmall) {
    TopGUIWidget()
} timeline: {
    TopGUIWidgetEntry(
        date: Date(),
        stats: WidgetSystemStats(
            cpuUsage: 35.0,
            memoryUsage: 68.0,
            topProcessName: "Safari",
            topProcessCPU: 15.2,
            healthScore: 82.0
        ),
        isPlaceholder: false
    )
}

#Preview("Medium", as: .systemMedium) {
    TopGUIWidget()
} timeline: {
    TopGUIWidgetEntry(
        date: Date(),
        stats: WidgetSystemStats(
            cpuUsage: 45.0,
            memoryUsage: 72.0,
            topProcessName: "Xcode",
            topProcessCPU: 28.5,
            healthScore: 65.0
        ),
        isPlaceholder: false
    )
}

#Preview("Large", as: .systemLarge) {
    TopGUIWidget()
} timeline: {
    TopGUIWidgetEntry(
        date: Date(),
        stats: WidgetSystemStats(
            cpuUsage: 55.0,
            memoryUsage: 80.0,
            topProcessName: "kernel_task",
            topProcessCPU: 35.0,
            healthScore: 48.0
        ),
        isPlaceholder: false
    )
}
