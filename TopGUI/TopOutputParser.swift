//
//  TopOutputParser.swift
//  TopGUI
//
//  Testable parsing logic extracted from TopDataManager.
//  Handles all CLI output parsing for top, vm_stat, df, netstat, iostat, sysctl.
//
//  Created by Jordan Koch on 5/1/2026.
//  Copyright 2026 Jordan Koch. All rights reserved.
//

import Foundation

/// Pure-function parsing helpers that can be unit-tested without Process or MainActor.
struct TopOutputParser {

    // MARK: - Percentage Extraction

    /// Extract a percentage value (e.g. "6.45%") from a string.
    static func extractPercentage(from string: String) -> Double? {
        let pattern = "([0-9]+\\.?[0-9]*)%"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
              let range = Range(match.range(at: 1), in: string) else {
            return nil
        }
        return Double(string[range])
    }

    // MARK: - Number Extraction

    /// Extract the first integer from a string.
    static func extractNumber(from string: String) -> Int? {
        let pattern = "([0-9]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
              let range = Range(match.range(at: 1), in: string) else {
            return nil
        }
        return Int(string[range])
    }

    // MARK: - Memory String Extraction

    /// Extract a memory value like "15G" or "2048M" from a string.
    static func extractMemory(from string: String) -> String? {
        let pattern = "([0-9]+[A-Z]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
              let range = Range(match.range, in: string) else {
            return nil
        }
        return String(string[range])
    }

    // MARK: - Page Count (vm_stat)

    /// Convert a vm_stat page count line to a human-readable memory string.
    /// vm_stat pages are 16 KB each.
    static func extractPageCount(from string: String) -> String {
        let pattern = "([0-9]+)\\.?"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
              let range = Range(match.range(at: 1), in: string) else {
            return "0"
        }
        let num = String(string[range])
        if let pageCount = Int(num) {
            let megabytes = (pageCount * 16384) / 1_048_576
            if megabytes > 1024 {
                return String(format: "%.0f GB", Double(megabytes) / 1024.0)
            } else {
                return "\(megabytes) MB"
            }
        }
        return num
    }

    // MARK: - Size-to-GB Conversion (df output)

    /// Convert size strings like "500G", "1.5T", "256M" to GB as Double.
    static func parseSizeToGB(_ sizeStr: String) -> Double {
        guard !sizeStr.isEmpty else { return 0.0 }
        let numStr = sizeStr.filter { $0.isNumber || $0 == "." }
        guard let num = Double(numStr) else { return 0.0 }

        if sizeStr.contains("T") {
            return num * 1024.0
        } else if sizeStr.contains("G") {
            return num
        } else if sizeStr.contains("M") {
            return num / 1024.0
        } else if sizeStr.contains("K") {
            return num / (1024.0 * 1024.0)
        }
        return num
    }

    // MARK: - Memory-to-GB Conversion

    /// Parse a memory string like "15G", "2048M", "100K" into GB.
    static func parseMemoryToGB(_ memString: String) -> Double {
        guard !memString.isEmpty else { return 0.0 }
        let numStr = memString.filter { $0.isNumber || $0 == "." }
        guard let num = Double(numStr) else { return 0.0 }

        if memString.contains("G") {
            return num
        } else if memString.contains("M") {
            return num / 1024.0
        } else if memString.contains("K") {
            return num / (1024.0 * 1024.0)
        }
        return num
    }

    // MARK: - Process Line Parsing

    /// Parse a single process line from `top` output into a ProcessInfo.
    static func parseProcessLine(_ line: String) -> ProcessInfo? {
        let components = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard components.count >= 12 else { return nil }
        guard let pid = Int(components[0]) else { return nil }

        let command = components[1]
        let cpuUsage = Double(components[2].replacingOccurrences(of: "%", with: "")) ?? 0.0
        let memUsage = Double(components[3].replacingOccurrences(of: "%", with: "")) ?? 0.0
        let time = components[4]
        let threads = Int(components[5]) ?? 0
        let ports = Int(components[6]) ?? 0
        let memRegions = Int(components[7]) ?? 0
        let memPhys = components[8]
        let memVirt = components[9]
        let user = components[10]
        let state = components[11]

        return ProcessInfo(
            pid: pid,
            command: command,
            cpuUsage: cpuUsage,
            memUsage: memUsage,
            time: time,
            threads: threads,
            ports: ports,
            memRegions: memRegions,
            memPhys: memPhys,
            memVirt: memVirt,
            user: user,
            state: state
        )
    }

    // MARK: - CPU Usage Line Parsing

    /// Parse "CPU usage: 6.45% user, 11.29% sys, 82.25% idle" into (user, sys, idle).
    static func parseCPUUsageLine(_ line: String) -> (user: Double, system: Double, idle: Double)? {
        guard line.contains("CPU usage:") else { return nil }
        let components = line.components(separatedBy: ", ")
        var user: Double = 0
        var sys: Double = 0
        var idle: Double = 0
        for component in components {
            if component.contains("user"),  let v = extractPercentage(from: component) { user = v }
            if component.contains("sys"),   let v = extractPercentage(from: component) { sys = v }
            if component.contains("idle"),  let v = extractPercentage(from: component) { idle = v }
        }
        return (user, sys, idle)
    }

    // MARK: - Processes Header Parsing

    /// Parse "Processes: 450 total, 3 running, 447 sleeping, 2345 threads"
    static func parseProcessesLine(_ line: String) -> (total: Int, running: Int, sleeping: Int, threads: Int, stuck: Int)? {
        guard line.contains("Processes:") else { return nil }
        let components = line.components(separatedBy: ", ")
        var total = 0, running = 0, sleeping = 0, threads = 0, stuck = 0
        for component in components {
            if component.contains("total"),    let v = extractNumber(from: component) { total = v }
            if component.contains("running"),  let v = extractNumber(from: component) { running = v }
            if component.contains("sleeping"), let v = extractNumber(from: component) { sleeping = v }
            if component.contains("threads"),  let v = extractNumber(from: component) { threads = v }
            if component.contains("stuck"),    let v = extractNumber(from: component) { stuck = v }
        }
        return (total, running, sleeping, threads, stuck)
    }

    // MARK: - Load Averages Parsing

    /// Parse "Load Avg: 2.34, 2.56, 2.78" into (1min, 5min, 15min).
    static func parseLoadAverages(_ line: String) -> (min1: Double, min5: Double, min15: Double)? {
        let pattern = "Load Avg:\\s*([0-9.]+),\\s*([0-9.]+),\\s*([0-9.]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }
        guard let r1 = Range(match.range(at: 1), in: line),
              let r2 = Range(match.range(at: 2), in: line),
              let r3 = Range(match.range(at: 3), in: line) else { return nil }
        let v1 = Double(line[r1]) ?? 0
        let v2 = Double(line[r2]) ?? 0
        let v3 = Double(line[r3]) ?? 0
        return (v1, v2, v3)
    }

    // MARK: - Swap Usage Parsing

    /// Parse "vm.swapusage: total = 2.50G  used = 1.25G  free = 1.25G  (encrypted)"
    static func parseSwapUsage(_ output: String) -> (total: String, used: String, free: String) {
        var total = ""
        var used = ""
        var free = ""

        if let m = output.range(of: "total = ([0-9.]+[KMGT])", options: .regularExpression) {
            total = String(output[m]).replacingOccurrences(of: "total = ", with: "")
        }
        if let m = output.range(of: "used = ([0-9.]+[KMGT])", options: .regularExpression) {
            used = String(output[m]).replacingOccurrences(of: "used = ", with: "")
        }
        if let m = output.range(of: "free = ([0-9.]+[KMGT])", options: .regularExpression) {
            free = String(output[m]).replacingOccurrences(of: "free = ", with: "")
        }
        return (total, used, free)
    }

    // MARK: - df Output Parsing

    /// Parse a single line from `df -H` output into DiskStats. Returns nil for non-device lines.
    static func parseDfLine(_ line: String) -> DiskStats? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              !trimmed.starts(with: "Filesystem"),
              trimmed.starts(with: "/dev/") else {
            return nil
        }

        let components = trimmed.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard components.count >= 9 else { return nil }

        let filesystem = components[0]
        let totalGB = parseSizeToGB(components[1])
        let usedGB = parseSizeToGB(components[2])
        let availGB = parseSizeToGB(components[3])
        let percent = Double(components[4].replacingOccurrences(of: "%", with: "")) ?? 0.0
        let mountPoint = components[8]
        let volumeName = mountPoint == "/" ? "Macintosh HD" : (mountPoint as NSString).lastPathComponent

        return DiskStats(
            name: volumeName,
            filesystem: filesystem,
            totalGB: totalGB,
            usedGB: usedGB,
            availableGB: availGB,
            percentUsed: percent,
            mountPoint: mountPoint
        )
    }

    // MARK: - iostat Parsing

    /// Parse iostat -d -c 2 output. Returns (totalMBps, totalTPS) from the *second* sample.
    static func parseIOStat(_ output: String) -> (totalMBps: Double, totalTPS: Int) {
        let lines = output.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count >= 4 else { return (0, 0) }

        let dataLine = lines[3]
        let values = dataLine.split(whereSeparator: { $0.isWhitespace }).map { String($0) }

        var totalMBps: Double = 0
        var totalTPS: Int = 0

        var i = 0
        while i + 2 < values.count {
            if let tps = Double(values[i + 1]) { totalTPS += Int(tps) }
            if let mbps = Double(values[i + 2]) { totalMBps += mbps }
            i += 3
        }
        return (totalMBps, totalTPS)
    }

    // MARK: - Disk Throughput Speed Formatting

    /// Format a MB/s value into a human-readable speed string.
    static func formatSpeed(_ mbps: Double) -> String {
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

    // MARK: - Health Score Calculation

    /// Calculate composite health score from CPU, memory, and disk usage.
    /// Returns 0-100 where 100 is perfect health.
    static func calculateHealthScore(totalCPU: Double, memoryPercentage: Double, diskUsages: [Double]) -> Double {
        let cpuScore = max(0, 100 - totalCPU)
        let memScore = max(0, 100 - memoryPercentage)
        let diskScore = diskUsages.isEmpty ? 50.0 : diskUsages.map { 100 - $0 }.reduce(0, +) / Double(diskUsages.count)
        return cpuScore * 0.4 + memScore * 0.3 + diskScore * 0.3
    }

    // MARK: - Swap Value Formatting

    /// Format swap value like "0.00M" to "0 MB" or "2.50G" to "3 GB".
    static func formatSwapValue(_ value: String) -> String {
        guard !value.isEmpty else { return "0 MB" }
        let numStr = value.filter { $0.isNumber || $0 == "." }
        guard let num = Double(numStr) else { return value }

        if value.contains("G") {
            return "\(Int(num)) GB"
        } else if value.contains("M") {
            return "\(Int(num)) MB"
        } else if value.contains("K") {
            return "\(Int(num)) KB"
        }
        return value
    }
}
