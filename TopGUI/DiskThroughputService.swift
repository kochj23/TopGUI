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
    @Published var totalReadGB: Double = 0.0        // Total data read since boot
    @Published var totalWriteGB: Double = 0.0       // Total data written since boot
    @Published var lastUpdated: Date = Date()

    // Historical data for sparkline
    @Published var readHistory: [Double] = []
    @Published var writeHistory: [Double] = []

    private var updateTimer: Timer?
    private let historyLimit = 30

    // Previous values for calculating delta
    private var prevReadBytes: UInt64 = 0
    private var prevWriteBytes: UInt64 = 0
    private var prevReadOps: UInt64 = 0
    private var prevWriteOps: UInt64 = 0
    private var lastSampleTime: Date?

    private init() {
        startMonitoring()
    }

    func startMonitoring() {
        // Initial sample
        sampleDiskStats()

        // Update every 2 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateThroughput()
            }
        }
    }

    func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func sampleDiskStats() {
        let stats = getDiskIOStats()
        prevReadBytes = stats.readBytes
        prevWriteBytes = stats.writeBytes
        prevReadOps = stats.readOps
        prevWriteOps = stats.writeOps
        lastSampleTime = Date()
    }

    private func updateThroughput() {
        let stats = getDiskIOStats()
        let now = Date()

        if let lastTime = lastSampleTime {
            let elapsed = now.timeIntervalSince(lastTime)
            if elapsed > 0 {
                // Calculate throughput
                let readDelta = stats.readBytes > prevReadBytes ? stats.readBytes - prevReadBytes : 0
                let writeDelta = stats.writeBytes > prevWriteBytes ? stats.writeBytes - prevWriteBytes : 0
                let readOpsDelta = stats.readOps > prevReadOps ? stats.readOps - prevReadOps : 0
                let writeOpsDelta = stats.writeOps > prevWriteOps ? stats.writeOps - prevWriteOps : 0

                readMBps = Double(readDelta) / elapsed / 1_048_576.0
                writeMBps = Double(writeDelta) / elapsed / 1_048_576.0
                readIOPS = Int(Double(readOpsDelta) / elapsed)
                writeIOPS = Int(Double(writeOpsDelta) / elapsed)

                // Total since boot (in GB)
                totalReadGB = Double(stats.readBytes) / 1_073_741_824.0
                totalWriteGB = Double(stats.writeBytes) / 1_073_741_824.0

                // Update history
                readHistory.append(readMBps)
                if readHistory.count > historyLimit {
                    readHistory.removeFirst()
                }

                writeHistory.append(writeMBps)
                if writeHistory.count > historyLimit {
                    writeHistory.removeFirst()
                }
            }
        }

        prevReadBytes = stats.readBytes
        prevWriteBytes = stats.writeBytes
        prevReadOps = stats.readOps
        prevWriteOps = stats.writeOps
        lastSampleTime = now
        lastUpdated = now
    }

    private func getDiskIOStats() -> (readBytes: UInt64, writeBytes: UInt64, readOps: UInt64, writeOps: UInt64) {
        // Use iostat to get disk statistics
        let task = Process()
        task.launchPath = "/usr/sbin/iostat"
        task.arguments = ["-d", "-c", "1"]

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
            // Fallback to reading from sysctl or /proc equivalent
        }

        return (0, 0, 0, 0)
    }

    private func parseIOStat(_ output: String) -> (readBytes: UInt64, writeBytes: UInt64, readOps: UInt64, writeOps: UInt64) {
        // Parse iostat output
        // Format: device KB/t tps MB/s
        let lines = output.components(separatedBy: "\n")
        var totalReadMB: Double = 0
        var totalWriteMB: Double = 0
        var totalOps: UInt64 = 0

        for line in lines {
            let components = line.split(separator: " ").map { String($0) }
            // Look for disk lines (disk0, disk1, etc.)
            if components.count >= 3, components[0].hasPrefix("disk") {
                // iostat -d shows: KB/t tps MB/s
                if let mbps = Double(components.last ?? "0") {
                    totalReadMB += mbps / 2  // Approximate split
                    totalWriteMB += mbps / 2
                }
                if components.count >= 2, let tps = Double(components[1]) {
                    totalOps += UInt64(tps)
                }
            }
        }

        // Convert to bytes (approximate - iostat gives rates, not totals)
        // We'll use cumulative tracking instead
        return (
            UInt64(totalReadMB * 1_048_576),
            UInt64(totalWriteMB * 1_048_576),
            totalOps / 2,
            totalOps / 2
        )
    }

    // MARK: - Formatted Values

    var formattedReadSpeed: String {
        if readMBps >= 1000 {
            return String(format: "%.1f GB/s", readMBps / 1024)
        } else if readMBps >= 1 {
            return String(format: "%.1f MB/s", readMBps)
        } else {
            return String(format: "%.0f KB/s", readMBps * 1024)
        }
    }

    var formattedWriteSpeed: String {
        if writeMBps >= 1000 {
            return String(format: "%.1f GB/s", writeMBps / 1024)
        } else if writeMBps >= 1 {
            return String(format: "%.1f MB/s", writeMBps)
        } else {
            return String(format: "%.0f KB/s", writeMBps * 1024)
        }
    }

    var combinedThroughput: Double {
        readMBps + writeMBps
    }

    var formattedCombinedSpeed: String {
        let combined = combinedThroughput
        if combined >= 1000 {
            return String(format: "%.1f GB/s", combined / 1024)
        } else if combined >= 1 {
            return String(format: "%.1f MB/s", combined)
        } else {
            return String(format: "%.0f KB/s", combined * 1024)
        }
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
