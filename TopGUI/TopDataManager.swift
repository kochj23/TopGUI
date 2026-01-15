//
//  TopDataManager.swift
//  TopGUI
//
//  Manages real-time data from the top command
//
//  Created by Jordan Koch on 1/15/2026.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import Combine

class TopDataManager: ObservableObject {
    @Published var processes: [ProcessInfo] = []
    @Published var systemStats = SystemStats()
    @Published var isRunning = false
    @Published var errorMessage: String?

    private var updateTimer: Timer?
    private var topProcess: Process?

    init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        guard !isRunning else { return }
        isRunning = true

        // Update every second for real-time data
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.fetchTopData()
        }

        // Initial fetch
        fetchTopData()
    }

    func stopMonitoring() {
        updateTimer?.invalidate()
        updateTimer = nil
        topProcess?.terminate()
        topProcess = nil
        isRunning = false
    }

    private func fetchTopData() {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/top")
        process.arguments = ["-l", "1", "-n", "30", "-stats", "pid,command,cpu,mem,time,th,ports,mreg,rprvt,vsize,user,state"]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                parseTopOutput(output)
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Error running top: \(error.localizedDescription)"
            }
        }
    }

    private func parseTopOutput(_ output: String) {
        let lines = output.components(separatedBy: .newlines)
        var parsedProcesses: [ProcessInfo] = []
        var stats = SystemStats()

        for line in lines {
            // Parse system stats from header
            if line.contains("CPU usage:") {
                // Format: "CPU usage: 6.45% user, 11.29% sys, 82.25% idle"
                let components = line.components(separatedBy: ", ")
                for component in components {
                    if component.contains("user") {
                        if let value = extractPercentage(from: component) {
                            stats.cpuUser = value
                        }
                    } else if component.contains("sys") {
                        if let value = extractPercentage(from: component) {
                            stats.cpuSystem = value
                        }
                    } else if component.contains("idle") {
                        if let value = extractPercentage(from: component) {
                            stats.cpuIdle = value
                        }
                    }
                }
            } else if line.contains("PhysMem:") {
                // Format: "PhysMem: 15G used (2048M wired), 1234M unused."
                let components = line.components(separatedBy: ", ")
                for component in components {
                    if component.contains("used") && !component.contains("unused") {
                        stats.memPhysUsed = extractMemory(from: component) ?? ""
                    } else if component.contains("unused") {
                        stats.memPhysFree = extractMemory(from: component) ?? ""
                    } else if component.contains("wired") {
                        stats.memWired = extractMemory(from: component) ?? ""
                    } else if component.contains("compressed") {
                        stats.memCompressed = extractMemory(from: component) ?? ""
                    }
                }
            } else if line.contains("Processes:") {
                // Format: "Processes: 450 total, 3 running, 447 sleeping, 2345 threads"
                let components = line.components(separatedBy: ", ")
                for component in components {
                    if component.contains("total") {
                        if let value = extractNumber(from: component) {
                            stats.processes = value
                        }
                    } else if component.contains("running") {
                        if let value = extractNumber(from: component) {
                            stats.runningProcesses = value
                        }
                    } else if component.contains("sleeping") {
                        if let value = extractNumber(from: component) {
                            stats.sleeping = value
                        }
                    } else if component.contains("threads") {
                        if let value = extractNumber(from: component) {
                            stats.threads = value
                        }
                    } else if component.contains("stuck") {
                        if let value = extractNumber(from: component) {
                            stats.stuckProcesses = value
                        }
                    }
                }
            } else if line.contains("Load Avg:") {
                // Format: "Load Avg: 2.34, 2.56, 2.78"
                let pattern = "Load Avg:\\s*([0-9.]+),\\s*([0-9.]+),\\s*([0-9.]+)"
                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                    if let range1 = Range(match.range(at: 1), in: line) {
                        stats.loadAvg1min = Double(line[range1]) ?? 0.0
                    }
                    if let range2 = Range(match.range(at: 2), in: line) {
                        stats.loadAvg5min = Double(line[range2]) ?? 0.0
                    }
                    if let range3 = Range(match.range(at: 3), in: line) {
                        stats.loadAvg15min = Double(line[range3]) ?? 0.0
                    }
                }
            } else if line.contains("VM:") {
                // Format: "VM: 1234M vsize, 567M framework vsize, 89M swapins, 12M swapouts"
                let components = line.components(separatedBy: ", ")
                for component in components {
                    if component.contains("swapins") {
                        stats.swapUsed = extractMemory(from: component) ?? ""
                    } else if component.contains("swapouts") {
                        stats.swapFree = extractMemory(from: component) ?? ""
                    }
                }
            } else if line.contains("Networks:") {
                // Format: "Networks: packets: 1234/5678 in, 2345/6789 out"
                if line.contains("packets:") {
                    let components = line.components(separatedBy: " ")
                    for (index, component) in components.enumerated() {
                        if component == "packets:" && index + 1 < components.count {
                            let packets = components[index + 1]
                            let parts = packets.split(separator: "/")
                            if parts.count >= 2 {
                                stats.networkPacketsIn = String(parts[0])
                                stats.networkPacketsOut = String(parts[1])
                            }
                        }
                    }
                }
            } else if line.contains("Disks:") {
                // Format: "Disks: 1234/567M read, 2345/678M written"
                let components = line.components(separatedBy: ", ")
                for component in components {
                    if component.contains("read") {
                        stats.diskReads = extractMemory(from: component) ?? ""
                    } else if component.contains("written") {
                        stats.diskWrites = extractMemory(from: component) ?? ""
                    }
                }
            }

            // Parse process lines (skip headers and empty lines)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty,
                  !trimmed.starts(with: "PID"),
                  !trimmed.starts(with: "Processes:"),
                  !trimmed.starts(with: "Load Avg:"),
                  !trimmed.starts(with: "CPU usage:"),
                  !trimmed.starts(with: "SharedLibs:"),
                  !trimmed.starts(with: "MemRegions:"),
                  !trimmed.starts(with: "PhysMem:"),
                  !trimmed.starts(with: "VM:"),
                  !trimmed.starts(with: "Networks:"),
                  !trimmed.starts(with: "Disks:"),
                  let firstChar = trimmed.first,
                  firstChar.isNumber else {
                continue
            }

            if let process = parseProcessLine(trimmed) {
                parsedProcesses.append(process)
            }
        }

        // Update on main thread
        DispatchQueue.main.async {
            self.processes = parsedProcesses.sorted { $0.cpuUsage > $1.cpuUsage }
            self.systemStats = stats
            self.errorMessage = nil
        }
    }

    private func parseProcessLine(_ line: String) -> ProcessInfo? {
        // Split by whitespace, but be careful with command names that might have spaces
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

    private func extractPercentage(from string: String) -> Double? {
        let pattern = "([0-9]+\\.?[0-9]*)%"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
              let range = Range(match.range(at: 1), in: string) else {
            return nil
        }
        return Double(string[range])
    }

    private func extractNumber(from string: String) -> Int? {
        let pattern = "([0-9]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
              let range = Range(match.range(at: 1), in: string) else {
            return nil
        }
        return Int(string[range])
    }

    private func extractMemory(from string: String) -> String? {
        let pattern = "([0-9]+[A-Z]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
              let range = Range(match.range, in: string) else {
            return nil
        }
        return String(string[range])
    }

    // Process management functions
    func killProcess(_ process: ProcessInfo) {
        let killProcess = Process()
        killProcess.executableURL = URL(fileURLWithPath: "/bin/kill")
        killProcess.arguments = ["-9", "\(process.pid)"]

        do {
            try killProcess.run()
            killProcess.waitUntilExit()

            // Refresh data after killing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.fetchTopData()
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to kill process \(process.pid): \(error.localizedDescription)"
            }
        }
    }

    func changeProcessPriority(_ process: ProcessInfo, nice: Int) {
        let reniceProcess = Process()
        reniceProcess.executableURL = URL(fileURLWithPath: "/usr/bin/renice")
        reniceProcess.arguments = ["\(nice)", "\(process.pid)"]

        do {
            try reniceProcess.run()
            reniceProcess.waitUntilExit()

            // Refresh data
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.fetchTopData()
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to change priority for process \(process.pid): \(error.localizedDescription)"
            }
        }
    }
}
