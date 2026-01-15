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
    var swapUsed: String = ""
    var swapFree: String = ""

    var totalCPU: Double {
        return cpuUser + cpuSystem
    }

    var cpuIdlePercentage: Double {
        return cpuIdle
    }
}
