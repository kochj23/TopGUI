//
//  ProcessInfo.swift
//  TopGUI
//
//  Model for process information parsed from top command
//
//  Created by Jordan Koch on 1/15/2026.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

struct ProcessInfo: Identifiable, Equatable {
    let id = UUID()
    let pid: Int
    let command: String
    let cpuUsage: Double
    let memUsage: Double
    let time: String
    let threads: Int
    let ports: Int
    let memRegions: Int
    let memPhys: String
    let memVirt: String
    let user: String
    let state: String

    static func == (lhs: ProcessInfo, rhs: ProcessInfo) -> Bool {
        lhs.pid == rhs.pid
    }
}

struct DiskStats: Identifiable {
    let id = UUID()
    let name: String // Volume name
    let filesystem: String // /dev/disk1s1
    let totalGB: Double
    let usedGB: Double
    let availableGB: Double
    let percentUsed: Double
    let mountPoint: String
}

struct NetworkInterface: Identifiable {
    let id = UUID()
    let name: String
    let downloadMBps: Double
    let uploadMBps: Double
    let packetsIn: Int
    let packetsOut: Int
}

struct SystemStats {
    var cpuUser: Double = 0.0
    var cpuSystem: Double = 0.0
    var cpuIdle: Double = 0.0
    var threads: Int = 0
    var processes: Int = 0
    var runningProcesses: Int = 0
    var stuckProcesses: Int = 0
    var sleeping: Int = 0
    var memPhysUsed: String = ""
    var memPhysFree: String = ""
    var memWired: String = ""
    var memCompressed: String = ""
    var swapUsed: String = "" // Now: actual swap used from sysctl
    var swapFree: String = "" // Now: actual swap free from sysctl
    var swapTotal: String = "" // Total swap space

    // Load averages
    var loadAvg1min: Double = 0.0
    var loadAvg5min: Double = 0.0
    var loadAvg15min: Double = 0.0

    // Network stats (if available)
    var networkPacketsIn: String = ""
    var networkPacketsOut: String = ""
    var networkDataIn: String = ""
    var networkDataOut: String = ""

    // Disk stats (if available)
    var diskReads: String = ""
    var diskWrites: String = ""

    // CPU core count
    var cpuCores: Int = 0

    // Per-core CPU usage (array of percentages)
    var perCoreCPU: [Double] = []

    // CPU temperature and frequency
    var cpuTemperature: Double = 0.0 // Celsius
    var cpuFrequency: Double = 0.0   // GHz

    // Memory pressure details from vm_stat
    var memPagesActive: String = ""
    var memPagesInactive: String = ""
    var memPagesWired: String = ""
    var memPagesFree: String = ""
    var memPagesSpeculative: String = ""
    var memPagesPurgeable: String = ""
    var memPagesCompressed: String = ""
    var memPageFaults: String = ""
    var memCOW: String = ""
    var memPageins: String = ""
    var memPageouts: String = ""

    // Per-disk statistics
    var disks: [DiskStats] = []

    // Per-interface network bandwidth
    var networkInterfaces: [NetworkInterface] = []

    var totalCPU: Double {
        return cpuUser + cpuSystem
    }

    var cpuIdlePercentage: Double {
        return cpuIdle
    }

    // Calculate memory usage percentage from strings like "15G used" and "1G unused"
    var memoryUsagePercentage: Double {
        let usedGB = parseMemoryToGB(memPhysUsed)
        let freeGB = parseMemoryToGB(memPhysFree)
        let total = usedGB + freeGB
        return total > 0 ? (usedGB / total) * 100.0 : 0.0
    }

    private func parseMemoryToGB(_ memString: String) -> Double {
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

    // Load average as percentage (assume 100% = number of CPU cores)
    func loadPercentage(cores: Int) -> Double {
        let avgLoad = loadAvg1min
        return cores > 0 ? min((avgLoad / Double(cores)) * 100.0, 100.0) : 0.0
    }
}
