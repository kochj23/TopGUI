//
//  DiskThroughputService.swift
//  TopGUI
//
//  Monitors disk I/O throughput (read/write speeds)
//  Created by Jordan Koch on 2026-02-02.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import Combine

@MainActor
class DiskThroughputService: ObservableObject {
    static let shared = DiskThroughputService()

    @Published var readMBps: Double = 0.0           // Read speed MB/s
    @Published var writeMBps: Double = 0.0          // Write speed MB/s
    @Published var readIOPS: Int = 0                // Read operations per second
    @Published var writeIOPS: Int = 0               // Write operations per second
    @Published var totalReadGB: Double = 0.0        // Total data read this session
    @Published var totalWriteGB: Double = 0.0       // Total data written this session
    @Published var lastUpdated: Date = Date()

    // Historical data for sparkline
    @Published var readHistory: [Double] = []
    @Published var writeHistory: [Double] = []

    private var updateTimer: Timer?
    private let historyLimit = 30

    private init() {
        guard NSClassFromString("XCTestCase") == nil else { return }
        startMonitoring()
    }

    func startMonitoring() {
        // Update every 2 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateThroughput()
            }
        }

        // Initial update
        updateThroughput()
    }

    func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func updateThroughput() {
        let stats = getDiskIOStats()

        // iostat gives us combined throughput - estimate read/write split
        // Typically system I/O is ~60% reads, ~40% writes
        let totalMBps = stats.totalMBps
        let totalTPS = stats.totalTPS

        readMBps = totalMBps * 0.6
        writeMBps = totalMBps * 0.4
        readIOPS = Int(Double(totalTPS) * 0.6)
        writeIOPS = Int(Double(totalTPS) * 0.4)

        // Accumulate session totals (every 2 seconds)
        totalReadGB += (readMBps * 2.0) / 1024.0
        totalWriteGB += (writeMBps * 2.0) / 1024.0

        // Update history
        readHistory.append(readMBps)
        if readHistory.count > historyLimit {
            readHistory.removeFirst()
        }

        writeHistory.append(writeMBps)
        if writeHistory.count > historyLimit {
            writeHistory.removeFirst()
        }

        lastUpdated = Date()
    }

    private func getDiskIOStats() -> (totalMBps: Double, totalTPS: Int) {
        // Use iostat to get current disk statistics
        // -d = disk stats only, -c 2 = 2 samples (use second for current rate)
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/iostat")
        task.arguments = ["-d", "-c", "2"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return parseIOStat(output)
            }
        } catch {
            print("iostat error: \(error)")
        }

        return (0, 0)
    }

    private func parseIOStat(_ output: String) -> (totalMBps: Double, totalTPS: Int) {
        // iostat -d -c 2 output format:
        //               disk0               disk4   ...
        //     KB/t  tps  MB/s     KB/t  tps  MB/s   ...
        //    13.21  447  5.77    30.85    0  0.00   ... (average since boot)
        //     4.49  202  0.89     0.00    0  0.00   ... (current interval - USE THIS)

        let lines = output.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        // We need at least 4 lines: disk names, column headers, first sample, second sample
        guard lines.count >= 4 else {
            return (0, 0)
        }

        // Use the last data line (current interval, index 3)
        let dataLine = lines[3]

        // Split by whitespace and filter empty strings
        let values = dataLine.split(whereSeparator: { $0.isWhitespace }).map { String($0) }

        var totalMBps: Double = 0
        var totalTPS: Int = 0

        // Each disk has 3 values: KB/t, tps, MB/s
        // Process in groups of 3
        var i = 0
        while i + 2 < values.count {
            // tps is at position i+1
            if let tps = Double(values[i + 1]) {
                totalTPS += Int(tps)
            }
            // MB/s is at position i+2
            if let mbps = Double(values[i + 2]) {
                totalMBps += mbps
            }
            i += 3
        }

        return (totalMBps, totalTPS)
    }

    // MARK: - Formatted Values

    var formattedReadSpeed: String {
        formatSpeed(readMBps)
    }

    var formattedWriteSpeed: String {
        formatSpeed(writeMBps)
    }

    private func formatSpeed(_ mbps: Double) -> String {
        if mbps >= 1000 {
            return String(format: "%.1f GB/s", mbps / 1024)
        } else if mbps >= 1 {
            return String(format: "%.1f MB/s", mbps)
        } else if mbps >= 0.001 {
            return String(format: "%.0f KB/s", mbps * 1024)
        } else {
            return "0 KB/s"
        }
    }

    var combinedThroughput: Double {
        readMBps + writeMBps
    }

    var formattedCombinedSpeed: String {
        formatSpeed(combinedThroughput)
    }

    var activityLevel: ActivityLevel {
        let combined = combinedThroughput
        if combined > 500 {
            return .veryHigh
        } else if combined > 100 {
            return .high
        } else if combined > 10 {
            return .moderate
        } else if combined > 0.1 {
            return .low
        } else {
            return .idle
        }
    }

    enum ActivityLevel {
        case idle, low, moderate, high, veryHigh

        var color: String {
            switch self {
            case .idle: return "8E8E93"      // Gray
            case .low: return "00D26A"       // Green
            case .moderate: return "FFB800"  // Yellow
            case .high: return "FF6B00"      // Orange
            case .veryHigh: return "FF3B30"  // Red
            }
        }

        var label: String {
            switch self {
            case .idle: return "Idle"
            case .low: return "Low"
            case .moderate: return "Moderate"
            case .high: return "High"
            case .veryHigh: return "Very High"
            }
        }
    }
}
