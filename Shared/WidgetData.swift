//
//  WidgetData.swift
//  TopGUI
//
//  Data models for the TopGUI system monitor widget
//  Shared between main app and widget extension
//
//  Created by Jordan Koch on 2/4/2026.
//  Copyright 2026 Jordan Koch. All rights reserved.
//

import Foundation

/// Data structure for sharing system stats between the main app and widget
struct WidgetSystemStats: Codable {
    var cpuUsage: Double
    var memoryUsage: Double
    var topProcessName: String
    var topProcessCPU: Double
    var healthScore: Double
    var timestamp: Date

    // Additional details
    var cpuUser: Double
    var cpuSystem: Double
    var cpuIdle: Double
    var memUsedGB: Double
    var memFreeGB: Double
    var memWiredGB: Double
    var gpuUsage: Double
    var processCount: Int
    var runningProcesses: Int
    var loadAvg1min: Double
    var loadAvg5min: Double
    var loadAvg15min: Double

    init() {
        self.cpuUsage = 0.0
        self.memoryUsage = 0.0
        self.topProcessName = "---"
        self.topProcessCPU = 0.0
        self.healthScore = 100.0
        self.timestamp = Date()
        self.cpuUser = 0.0
        self.cpuSystem = 0.0
        self.cpuIdle = 100.0
        self.memUsedGB = 0.0
        self.memFreeGB = 0.0
        self.memWiredGB = 0.0
        self.gpuUsage = 0.0
        self.processCount = 0
        self.runningProcesses = 0
        self.loadAvg1min = 0.0
        self.loadAvg5min = 0.0
        self.loadAvg15min = 0.0
    }

    init(cpuUsage: Double, memoryUsage: Double, topProcessName: String, topProcessCPU: Double, healthScore: Double) {
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.topProcessName = topProcessName
        self.topProcessCPU = topProcessCPU
        self.healthScore = healthScore
        self.timestamp = Date()
        self.cpuUser = 0.0
        self.cpuSystem = 0.0
        self.cpuIdle = 100.0 - cpuUsage
        self.memUsedGB = 0.0
        self.memFreeGB = 0.0
        self.memWiredGB = 0.0
        self.gpuUsage = 0.0
        self.processCount = 0
        self.runningProcesses = 0
        self.loadAvg1min = 0.0
        self.loadAvg5min = 0.0
        self.loadAvg15min = 0.0
    }

    /// Calculate health color based on score
    var healthStatus: HealthStatus {
        switch healthScore {
        case 80...100:
            return .excellent
        case 60..<80:
            return .good
        case 40..<60:
            return .moderate
        case 20..<40:
            return .poor
        default:
            return .critical
        }
    }
}

/// Health status levels for widget display
enum HealthStatus: String, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case moderate = "Moderate"
    case poor = "Poor"
    case critical = "Critical"

    var colorHex: String {
        switch self {
        case .excellent:
            return "00FF9F" // Green
        case .good:
            return "4ADE80" // Light green
        case .moderate:
            return "FBBF24" // Yellow
        case .poor:
            return "F97316" // Orange
        case .critical:
            return "EF4444" // Red
        }
    }
}

/// Timeline entry for widget updates
struct SystemStatsEntry: Codable {
    let date: Date
    let stats: WidgetSystemStats
    let isPlaceholder: Bool

    init(date: Date = Date(), stats: WidgetSystemStats = WidgetSystemStats(), isPlaceholder: Bool = false) {
        self.date = date
        self.stats = stats
        self.isPlaceholder = isPlaceholder
    }
}
