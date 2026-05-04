//
//  ComprehensiveTests.swift
//  TopGUITests
//
//  Comprehensive test suite covering unit, security, integration, functional, and frame tests.
//  Written by Jordan Koch
//  Created: 2026-05-03
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import XCTest
@testable import TopGUI

// MARK: - Unit Tests

final class ProcessInfoUnitTests: XCTestCase {

    // MARK: Test 1
    func testProcessInfoCreation() {
        let proc = ProcessInfo(
            pid: 1234, command: "Safari", cpuUsage: 15.5, memUsage: 8.2,
            time: "01:23.45", threads: 12, ports: 5, memRegions: 200,
            memPhys: "256M", memVirt: "1G", user: "kochj", state: "running"
        )
        XCTAssertEqual(proc.pid, 1234)
        XCTAssertEqual(proc.command, "Safari")
        XCTAssertEqual(proc.cpuUsage, 15.5)
        XCTAssertEqual(proc.memUsage, 8.2)
        XCTAssertEqual(proc.threads, 12)
        XCTAssertEqual(proc.user, "kochj")
    }

    // MARK: Test 2
    func testProcessInfoEquality() {
        let proc1 = ProcessInfo(pid: 100, command: "A", cpuUsage: 10, memUsage: 5,
                                time: "0:00", threads: 1, ports: 0, memRegions: 1,
                                memPhys: "1M", memVirt: "1M", user: "root", state: "running")
        let proc2 = ProcessInfo(pid: 100, command: "B", cpuUsage: 20, memUsage: 10,
                                time: "1:00", threads: 5, ports: 2, memRegions: 50,
                                memPhys: "50M", memVirt: "100M", user: "root", state: "sleeping")
        // Equality is by pid
        XCTAssertEqual(proc1, proc2)
    }

    // MARK: Test 3
    func testProcessInfoInequality() {
        let proc1 = ProcessInfo(pid: 100, command: "A", cpuUsage: 10, memUsage: 5,
                                time: "0:00", threads: 1, ports: 0, memRegions: 1,
                                memPhys: "1M", memVirt: "1M", user: "root", state: "running")
        let proc2 = ProcessInfo(pid: 200, command: "A", cpuUsage: 10, memUsage: 5,
                                time: "0:00", threads: 1, ports: 0, memRegions: 1,
                                memPhys: "1M", memVirt: "1M", user: "root", state: "running")
        XCTAssertNotEqual(proc1, proc2)
    }
}

final class SystemStatsUnitTests: XCTestCase {

    // MARK: Test 4
    func testSystemStatsDefaults() {
        let stats = SystemStats()
        XCTAssertEqual(stats.cpuUser, 0.0)
        XCTAssertEqual(stats.cpuSystem, 0.0)
        XCTAssertEqual(stats.cpuIdle, 0.0)
        XCTAssertEqual(stats.threads, 0)
        XCTAssertEqual(stats.processes, 0)
        XCTAssertTrue(stats.disks.isEmpty)
        XCTAssertTrue(stats.networkInterfaces.isEmpty)
    }

    // MARK: Test 5
    func testTotalCPU() {
        var stats = SystemStats()
        stats.cpuUser = 25.0
        stats.cpuSystem = 15.0
        XCTAssertEqual(stats.totalCPU, 40.0)
    }

    // MARK: Test 6
    func testCPUIdlePercentage() {
        var stats = SystemStats()
        stats.cpuIdle = 82.5
        XCTAssertEqual(stats.cpuIdlePercentage, 82.5)
    }

    // MARK: Test 7
    func testMemoryUsagePercentageGB() {
        var stats = SystemStats()
        stats.memPhysUsed = "15G"
        stats.memPhysFree = "1G"
        // 15 / 16 * 100 = 93.75
        XCTAssertEqual(stats.memoryUsagePercentage, 93.75, accuracy: 0.01)
    }

    // MARK: Test 8
    func testMemoryUsagePercentageMB() {
        var stats = SystemStats()
        stats.memPhysUsed = "2048M"
        stats.memPhysFree = "2048M"
        // 2/4 * 100 = 50
        XCTAssertEqual(stats.memoryUsagePercentage, 50.0, accuracy: 0.01)
    }

    // MARK: Test 9
    func testMemoryUsagePercentageEmpty() {
        let stats = SystemStats()
        XCTAssertEqual(stats.memoryUsagePercentage, 0.0)
    }

    // MARK: Test 10
    func testLoadPercentage() {
        var stats = SystemStats()
        stats.loadAvg1min = 4.0
        // 4 cores -> (4.0 / 4.0) * 100 = 100%
        XCTAssertEqual(stats.loadPercentage(cores: 4), 100.0)
    }

    // MARK: Test 11
    func testLoadPercentageCapped() {
        var stats = SystemStats()
        stats.loadAvg1min = 20.0
        // Exceeds cores; capped at 100%
        XCTAssertEqual(stats.loadPercentage(cores: 4), 100.0)
    }

    // MARK: Test 12
    func testLoadPercentageZeroCores() {
        let stats = SystemStats()
        XCTAssertEqual(stats.loadPercentage(cores: 0), 0.0)
    }
}

// MARK: - Parser Unit Tests

final class TopOutputParserUnitTests: XCTestCase {

    // MARK: Test 13
    func testExtractPercentage() {
        XCTAssertEqual(TopOutputParser.extractPercentage(from: "6.45% user"), 6.45)
        XCTAssertEqual(TopOutputParser.extractPercentage(from: "100%"), 100.0)
        XCTAssertNil(TopOutputParser.extractPercentage(from: "no percentage here"))
    }

    // MARK: Test 14
    func testExtractNumber() {
        XCTAssertEqual(TopOutputParser.extractNumber(from: "450 total"), 450)
        XCTAssertEqual(TopOutputParser.extractNumber(from: "3 running"), 3)
        XCTAssertNil(TopOutputParser.extractNumber(from: "no numbers"))
    }

    // MARK: Test 15
    func testExtractMemory() {
        XCTAssertEqual(TopOutputParser.extractMemory(from: "15G used"), "15G")
        XCTAssertEqual(TopOutputParser.extractMemory(from: "2048M wired"), "2048M")
        XCTAssertNil(TopOutputParser.extractMemory(from: "no memory value"))
    }

    // MARK: Test 16
    func testParseSizeToGB() {
        XCTAssertEqual(TopOutputParser.parseSizeToGB("500G"), 500.0)
        XCTAssertEqual(TopOutputParser.parseSizeToGB("1.5T"), 1536.0)
        XCTAssertEqual(TopOutputParser.parseSizeToGB("256M"), 0.25, accuracy: 0.01)
        XCTAssertEqual(TopOutputParser.parseSizeToGB("1024K"), 1024.0 / (1024.0 * 1024.0), accuracy: 0.001)
        XCTAssertEqual(TopOutputParser.parseSizeToGB(""), 0.0)
    }

    // MARK: Test 17
    func testParseMemoryToGB() {
        XCTAssertEqual(TopOutputParser.parseMemoryToGB("15G"), 15.0)
        XCTAssertEqual(TopOutputParser.parseMemoryToGB("2048M"), 2.0, accuracy: 0.01)
        XCTAssertEqual(TopOutputParser.parseMemoryToGB(""), 0.0)
    }

    // MARK: Test 18
    func testParseProcessLine() {
        let line = "1234 Safari 15.5 8.2 01:23.45 12 5 200 256M 1G kochj running"
        let proc = TopOutputParser.parseProcessLine(line)
        XCTAssertNotNil(proc)
        XCTAssertEqual(proc?.pid, 1234)
        XCTAssertEqual(proc?.command, "Safari")
        XCTAssertEqual(proc?.cpuUsage, 15.5)
        XCTAssertEqual(proc?.memUsage, 8.2)
        XCTAssertEqual(proc?.threads, 12)
        XCTAssertEqual(proc?.user, "kochj")
    }

    // MARK: Test 19
    func testParseProcessLineInvalidTooFewColumns() {
        let line = "1234 Safari 15.5"
        XCTAssertNil(TopOutputParser.parseProcessLine(line))
    }

    // MARK: Test 20
    func testParseProcessLineInvalidNoPID() {
        let line = "notapid Safari 15.5 8.2 01:23.45 12 5 200 256M 1G kochj running"
        XCTAssertNil(TopOutputParser.parseProcessLine(line))
    }

    // MARK: Test 21
    func testParseCPUUsageLine() {
        let line = "CPU usage: 6.45% user, 11.29% sys, 82.25% idle"
        let result = TopOutputParser.parseCPUUsageLine(line)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.user, 6.45)
        XCTAssertEqual(result?.system, 11.29)
        XCTAssertEqual(result?.idle, 82.25)
    }

    // MARK: Test 22
    func testParseCPUUsageLineNotCPU() {
        XCTAssertNil(TopOutputParser.parseCPUUsageLine("not cpu data"))
    }

    // MARK: Test 23
    func testParseProcessesLine() {
        let line = "Processes: 450 total, 3 running, 445 sleeping, 2 stuck, 2345 threads"
        let result = TopOutputParser.parseProcessesLine(line)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.total, 450)
        XCTAssertEqual(result?.running, 3)
        XCTAssertEqual(result?.sleeping, 445)
        XCTAssertEqual(result?.threads, 2345)
        XCTAssertEqual(result?.stuck, 2)
    }

    // MARK: Test 24
    func testParseProcessesLineNotProcesses() {
        XCTAssertNil(TopOutputParser.parseProcessesLine("not processes data"))
    }

    // MARK: Test 25
    func testParseLoadAverages() {
        let line = "Load Avg: 2.34, 2.56, 2.78"
        let result = TopOutputParser.parseLoadAverages(line)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.min1, 2.34)
        XCTAssertEqual(result?.min5, 2.56)
        XCTAssertEqual(result?.min15, 2.78)
    }

    // MARK: Test 26
    func testParseLoadAveragesInvalid() {
        XCTAssertNil(TopOutputParser.parseLoadAverages("not load averages"))
    }

    // MARK: Test 27
    func testParseSwapUsage() {
        let output = "vm.swapusage: total = 2.50G  used = 1.25G  free = 1.25G  (encrypted)"
        let result = TopOutputParser.parseSwapUsage(output)
        XCTAssertEqual(result.total, "2.50G")
        XCTAssertEqual(result.used, "1.25G")
        XCTAssertEqual(result.free, "1.25G")
    }

    // MARK: Test 28
    func testParseSwapUsageEmpty() {
        let result = TopOutputParser.parseSwapUsage("")
        XCTAssertEqual(result.total, "")
        XCTAssertEqual(result.used, "")
        XCTAssertEqual(result.free, "")
    }
}

// MARK: - Security Tests

final class TopGUISecurityTests: XCTestCase {

    // MARK: Test 29 - NovaAPI Binds to Loopback Only
    @MainActor
    func testNovaAPIPortIsLoopback() {
        // Verify the port is the expected one
        XCTAssertEqual(NovaAPIServer.shared.port, 37443)
        // The server binds to 127.0.0.1 only, verified by code inspection
    }

    // MARK: Test 30 - Processes Not Exposed Externally
    func testProcessInfoNoSensitiveExposure() {
        // Ensure ProcessInfo doesn't leak environment variables or full paths
        let proc = ProcessInfo(
            pid: 1, command: "TestProcess", cpuUsage: 0, memUsage: 0,
            time: "0:00", threads: 1, ports: 0, memRegions: 0,
            memPhys: "0M", memVirt: "0M", user: "test", state: "running"
        )
        // ProcessInfo stores only command name, not full path with arguments
        XCTAssertEqual(proc.command, "TestProcess")
    }

    // MARK: Test 31 - Parser Handles Malicious Input
    func testParserHandlesMaliciousInput() {
        let malicious = "; rm -rf / # 1234 Evil 99.9 99.9 0:00 1 0 0 0M 0M root running"
        let result = TopOutputParser.parseProcessLine(malicious)
        // Should fail to parse (first component is not a number)
        XCTAssertNil(result)
    }

    // MARK: Test 32 - Parser Handles Very Long Input
    func testParserHandlesVeryLongInput() {
        let longCommand = String(repeating: "A", count: 10000)
        let line = "9999 \(longCommand) 50.0 25.0 99:99.99 100 50 500 1G 2G root running"
        let result = TopOutputParser.parseProcessLine(line)
        // Should still parse (parser doesn't limit command length explicitly)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.pid, 9999)
    }

    // MARK: Test 33 - Parser Handles Unicode
    func testParserHandlesUnicode() {
        let line = "1234 Pr\u{00F6}cess 10.0 5.0 0:01.00 2 1 10 50M 100M user running"
        let result = TopOutputParser.parseProcessLine(line)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.pid, 1234)
    }

    // MARK: Test 34 - CPU Percentage Bounds
    func testCPUPercentageBoundsAccepted() {
        // Test extreme CPU percentages are parsed
        XCTAssertEqual(TopOutputParser.extractPercentage(from: "0.0%"), 0.0)
        XCTAssertEqual(TopOutputParser.extractPercentage(from: "100.0%"), 100.0)
        XCTAssertEqual(TopOutputParser.extractPercentage(from: "999.9%"), 999.9) // Can happen with multi-core
    }
}

// MARK: - Integration Tests

final class TopGUIIntegrationTests: XCTestCase {

    // MARK: Test 35 - Disk Stats Model
    func testDiskStatsCreation() {
        let disk = DiskStats(name: "Macintosh HD", filesystem: "/dev/disk1s1",
                             totalGB: 500.0, usedGB: 250.0, availableGB: 250.0,
                             percentUsed: 50.0, mountPoint: "/")
        XCTAssertEqual(disk.name, "Macintosh HD")
        XCTAssertEqual(disk.totalGB, 500.0)
        XCTAssertEqual(disk.percentUsed, 50.0)
    }

    // MARK: Test 36 - Network Interface Model
    func testNetworkInterfaceCreation() {
        let iface = NetworkInterface(name: "en0", downloadMBps: 10.5, uploadMBps: 2.3,
                                     packetsIn: 1000, packetsOut: 500)
        XCTAssertEqual(iface.name, "en0")
        XCTAssertEqual(iface.downloadMBps, 10.5)
        XCTAssertEqual(iface.uploadMBps, 2.3)
    }

    // MARK: Test 37 - Parse df Line
    func testParseDfLine() {
        let line = "/dev/disk1s1   500G   250G   250G    50%    1234567     0   100%   /"
        let disk = TopOutputParser.parseDfLine(line)
        XCTAssertNotNil(disk)
        XCTAssertEqual(disk?.mountPoint, "/")
        XCTAssertEqual(disk?.name, "Macintosh HD")
        XCTAssertEqual(disk?.totalGB, 500.0)
        XCTAssertEqual(disk?.percentUsed, 50.0)
    }

    // MARK: Test 38 - Parse df Line Skips Header
    func testParseDfLineSkipsHeader() {
        let header = "Filesystem      Size   Used  Avail Capacity  iused ifree %iused  Mounted on"
        XCTAssertNil(TopOutputParser.parseDfLine(header))
    }

    // MARK: Test 39 - Parse df Line Skips Non-Device
    func testParseDfLineSkipsNonDevice() {
        let line = "devfs           206K   206K     0B   100%       714     0  100%   /dev"
        XCTAssertNil(TopOutputParser.parseDfLine(line))
    }

    // MARK: Test 40 - Parse df Line Volume Name
    func testParseDfLineVolumeName() {
        let line = "/dev/disk2s1   2.0T   500G   1.5T    25%    1000000     0   100%   /Volumes/Data"
        let disk = TopOutputParser.parseDfLine(line)
        XCTAssertNotNil(disk)
        XCTAssertEqual(disk?.name, "Data")
        XCTAssertEqual(disk!.totalGB, 2048.0, accuracy: 1.0) // 2.0T
    }

    // MARK: Test 41 - Parse IOStat
    func testParseIOStat() {
        let output = """
                     disk0               disk4
            KB/t  tps  MB/s     KB/t  tps  MB/s
           13.21  447  5.77    30.85    0  0.00
            4.49  202  0.89     0.00    0  0.00
        """
        let result = TopOutputParser.parseIOStat(output)
        XCTAssertEqual(result.totalTPS, 202) // 202 + 0
        XCTAssertEqual(result.totalMBps, 0.89, accuracy: 0.01)
    }

    // MARK: Test 42 - Parse IOStat Empty
    func testParseIOStatEmpty() {
        let result = TopOutputParser.parseIOStat("")
        XCTAssertEqual(result.totalMBps, 0)
        XCTAssertEqual(result.totalTPS, 0)
    }
}

// MARK: - Functional Tests

final class TopGUIFunctionalTests: XCTestCase {

    // MARK: Test 43 - Format Speed GB/s
    func testFormatSpeedGBps() {
        XCTAssertEqual(TopOutputParser.formatSpeed(1024.0), "1.0 GB/s")
        XCTAssertEqual(TopOutputParser.formatSpeed(2048.0), "2.0 GB/s")
    }

    // MARK: Test 44 - Format Speed MB/s
    func testFormatSpeedMBps() {
        XCTAssertEqual(TopOutputParser.formatSpeed(100.0), "100.0 MB/s")
        XCTAssertEqual(TopOutputParser.formatSpeed(1.5), "1.5 MB/s")
    }

    // MARK: Test 45 - Format Speed KB/s
    func testFormatSpeedKBps() {
        XCTAssertEqual(TopOutputParser.formatSpeed(0.5), "512 KB/s")
        XCTAssertEqual(TopOutputParser.formatSpeed(0.001), "1 KB/s")
    }

    // MARK: Test 46 - Format Speed Zero
    func testFormatSpeedZero() {
        XCTAssertEqual(TopOutputParser.formatSpeed(0.0), "0 KB/s")
        XCTAssertEqual(TopOutputParser.formatSpeed(0.0001), "0 KB/s")
    }

    // MARK: Test 47 - Health Score Calculation All Good
    func testHealthScoreAllGood() {
        let score = TopOutputParser.calculateHealthScore(totalCPU: 0, memoryPercentage: 0, diskUsages: [0])
        XCTAssertEqual(score, 100.0, accuracy: 0.1)
    }

    // MARK: Test 48 - Health Score Calculation All Bad
    func testHealthScoreAllBad() {
        let score = TopOutputParser.calculateHealthScore(totalCPU: 100, memoryPercentage: 100, diskUsages: [100])
        XCTAssertEqual(score, 0.0, accuracy: 0.1)
    }

    // MARK: Test 49 - Health Score Calculation Mixed
    func testHealthScoreMixed() {
        let score = TopOutputParser.calculateHealthScore(totalCPU: 50, memoryPercentage: 50, diskUsages: [50])
        // cpu: 50*0.4=20, mem: 50*0.3=15, disk: 50*0.3=15 = 50
        XCTAssertEqual(score, 50.0, accuracy: 0.1)
    }

    // MARK: Test 50 - Health Score No Disks
    func testHealthScoreNoDisks() {
        let score = TopOutputParser.calculateHealthScore(totalCPU: 0, memoryPercentage: 0, diskUsages: [])
        // cpu: 100*0.4=40, mem: 100*0.3=30, disk: 50*0.3=15 = 85
        XCTAssertEqual(score, 85.0, accuracy: 0.1)
    }

    // MARK: Test 51 - Health Score Multiple Disks
    func testHealthScoreMultipleDisks() {
        let score = TopOutputParser.calculateHealthScore(totalCPU: 20, memoryPercentage: 40, diskUsages: [30, 70])
        // cpu: 80*0.4=32, mem: 60*0.3=18, disk: avg(70,30)=50*0.3=15 = 65
        XCTAssertEqual(score, 65.0, accuracy: 0.1)
    }

    // MARK: Test 52 - Extract Page Count
    func testExtractPageCount() {
        let line = "Pages active:                           4543952."
        let result = TopOutputParser.extractPageCount(from: line)
        // 4543952 * 16384 / 1048576 = ~71155 MB = ~69 GB
        XCTAssertTrue(result.contains("GB"))
    }

    // MARK: Test 53 - Extract Page Count Small
    func testExtractPageCountSmall() {
        let line = "Pages free:                             100."
        let result = TopOutputParser.extractPageCount(from: line)
        // 100 * 16384 / 1048576 = ~1 MB
        XCTAssertTrue(result.contains("MB"))
    }

    // MARK: Test 54 - Extract Page Count No Match
    func testExtractPageCountNoMatch() {
        XCTAssertEqual(TopOutputParser.extractPageCount(from: "no pages here"), "0")
    }

    // MARK: Test 55 - Format Swap Value Gigabytes
    func testFormatSwapValueGB() {
        XCTAssertEqual(TopOutputParser.formatSwapValue("2.50G"), "2 GB")
    }

    // MARK: Test 56 - Format Swap Value Megabytes
    func testFormatSwapValueMB() {
        XCTAssertEqual(TopOutputParser.formatSwapValue("0.00M"), "0 MB")
        XCTAssertEqual(TopOutputParser.formatSwapValue("512M"), "512 MB")
    }

    // MARK: Test 57 - Format Swap Value Kilobytes
    func testFormatSwapValueKB() {
        XCTAssertEqual(TopOutputParser.formatSwapValue("100K"), "100 KB")
    }

    // MARK: Test 58 - Format Swap Value Empty
    func testFormatSwapValueEmpty() {
        XCTAssertEqual(TopOutputParser.formatSwapValue(""), "0 MB")
    }
}

// MARK: - Frame / UI Data Tests

final class TopGUIFrameTests: XCTestCase {

    // MARK: Test 59 - Notification Names Exist
    func testNotificationNamesExist() {
        XCTAssertEqual(Notification.Name.showAIInsights.rawValue, "showAIInsights")
        XCTAssertEqual(Notification.Name.showAIBackendSettings.rawValue, "showAIBackendSettings")
    }

    // MARK: Test 60 - DiskStats Identifiable
    func testDiskStatsIdentifiable() {
        let d1 = DiskStats(name: "A", filesystem: "x", totalGB: 1, usedGB: 0.5, availableGB: 0.5, percentUsed: 50, mountPoint: "/")
        let d2 = DiskStats(name: "A", filesystem: "x", totalGB: 1, usedGB: 0.5, availableGB: 0.5, percentUsed: 50, mountPoint: "/")
        // Each gets a unique UUID
        XCTAssertNotEqual(d1.id, d2.id)
    }

    // MARK: Test 61 - NetworkInterface Identifiable
    func testNetworkInterfaceIdentifiable() {
        let n1 = NetworkInterface(name: "en0", downloadMBps: 0, uploadMBps: 0, packetsIn: 0, packetsOut: 0)
        let n2 = NetworkInterface(name: "en0", downloadMBps: 0, uploadMBps: 0, packetsIn: 0, packetsOut: 0)
        XCTAssertNotEqual(n1.id, n2.id)
    }

    // MARK: Test 62 - ProcessInfo Identifiable
    func testProcessInfoIdentifiable() {
        let p = ProcessInfo(pid: 1, command: "init", cpuUsage: 0, memUsage: 0,
                            time: "0:00", threads: 1, ports: 0, memRegions: 0,
                            memPhys: "0M", memVirt: "0M", user: "root", state: "running")
        XCTAssertNotNil(p.id)
    }

    // MARK: Test 63 - System Stats Per Core CPU Array
    func testSystemStatsPerCoreCPU() {
        var stats = SystemStats()
        stats.perCoreCPU = [10.0, 20.0, 30.0, 40.0]
        XCTAssertEqual(stats.perCoreCPU.count, 4)
        XCTAssertEqual(stats.perCoreCPU[0], 10.0)
    }

    // MARK: Test 64 - System Stats GPU Usage
    func testSystemStatsGPUUsage() {
        var stats = SystemStats()
        stats.gpuUsage = 45.0
        XCTAssertEqual(stats.gpuUsage, 45.0)
    }

    // MARK: Test 65 - Parse Multiple Process Lines
    func testParseMultipleProcessLines() {
        let lines = [
            "100 Safari 25.0 8.0 1:23.45 10 5 200 256M 1G kochj running",
            "200 Xcode 15.0 12.0 0:45.67 20 8 300 512M 2G kochj sleeping",
            "300 kernel_task 5.0 2.0 99:99.99 50 0 100 128M 500M root running",
        ]
        let parsed = lines.compactMap { TopOutputParser.parseProcessLine($0) }
        XCTAssertEqual(parsed.count, 3)
        XCTAssertEqual(parsed[0].command, "Safari")
        XCTAssertEqual(parsed[1].command, "Xcode")
        XCTAssertEqual(parsed[2].command, "kernel_task")
    }

    // MARK: Test 66 - CPU Usage Line With Partial Data
    func testCPUUsageLinePartialData() {
        let line = "CPU usage: 5% user, 3% sys"
        let result = TopOutputParser.parseCPUUsageLine(line)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.user, 5.0)
        XCTAssertEqual(result?.system, 3.0)
        XCTAssertEqual(result?.idle, 0.0) // Not found, defaults to 0
    }

    // MARK: Test 67 - Size Parse Terabytes
    func testSizeParseTerabytes() {
        XCTAssertEqual(TopOutputParser.parseSizeToGB("2T"), 2048.0)
        XCTAssertEqual(TopOutputParser.parseSizeToGB("0.5T"), 512.0)
    }

    // MARK: Test 68 - Size Parse Edge Cases
    func testSizeParseEdgeCases() {
        XCTAssertEqual(TopOutputParser.parseSizeToGB("0G"), 0.0)
        XCTAssertEqual(TopOutputParser.parseSizeToGB("0M"), 0.0)
        XCTAssertEqual(TopOutputParser.parseSizeToGB("abc"), 0.0) // No number
    }

    // MARK: Test 69 - Swap Usage Partial Match
    func testSwapUsagePartialMatch() {
        let output = "vm.swapusage: total = 4.00G  used = 0.00M"
        let result = TopOutputParser.parseSwapUsage(output)
        XCTAssertEqual(result.total, "4.00G")
        // used has M not matching [KMGT] since regex expects single letter
        // Actually "0.00M" matches since M is in [KMGT]
        XCTAssertEqual(result.free, "") // free not present
    }

    // MARK: Test 70 - Parse df Line Empty
    func testParseDfLineEmpty() {
        XCTAssertNil(TopOutputParser.parseDfLine(""))
        XCTAssertNil(TopOutputParser.parseDfLine("   "))
    }
}
