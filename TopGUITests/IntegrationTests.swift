//
//  IntegrationTests.swift
//  TopGUITests
//
//  Integration tests: verify that live system command output can be parsed
//  by TopOutputParser without crashing. These tests run the actual binaries
//  (top, vm_stat, df, sysctl, iostat, netstat) and feed their output through
//  the parser to confirm end-to-end correctness.
//
//  Created by Jordan Koch on 5/1/2026.
//  Copyright 2026 Jordan Koch. All rights reserved.
//

import XCTest
@testable import TopGUI

final class IntegrationTests: XCTestCase {

    // MARK: - Helpers

    /// Run a system command and return its stdout as a String.
    private func runCommand(_ path: String, arguments: [String] = []) -> String? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }

    // MARK: - top Output Parsing

    func testParseRealTopOutput() throws {
        // Run top with a single snapshot, limited processes
        guard let output = runCommand("/usr/bin/top", arguments: ["-l", "1", "-n", "5", "-o", "cpu", "-stats", "pid,command,cpu,mem,time,th,ports,mreg,rprvt,vsize,user,state"]) else {
            throw XCTSkip("top command unavailable")
        }

        // Parse CPU usage line
        let lines = output.components(separatedBy: .newlines)
        let cpuLine = lines.first { $0.contains("CPU usage:") }
        XCTAssertNotNil(cpuLine, "top output should contain a CPU usage line")

        if let cpuLine = cpuLine {
            let result = TopOutputParser.parseCPUUsageLine(cpuLine)
            XCTAssertNotNil(result, "Should parse CPU usage from live top output")
            if let r = result {
                XCTAssertGreaterThanOrEqual(r.user, 0.0)
                XCTAssertGreaterThanOrEqual(r.system, 0.0)
                XCTAssertGreaterThanOrEqual(r.idle, 0.0)
                // Sum should be approximately 100
                let sum = r.user + r.system + r.idle
                XCTAssertEqual(sum, 100.0, accuracy: 5.0, "CPU percentages should sum to ~100")
            }
        }

        // Parse process lines
        let processLines = lines.filter { line in
            let t = line.trimmingCharacters(in: .whitespaces)
            guard let first = t.first, first.isNumber else { return false }
            return true
        }
        XCTAssertFalse(processLines.isEmpty, "Should find at least one process line in top output")

        // Verify at least one process parses successfully
        var parsedCount = 0
        for line in processLines {
            if TopOutputParser.parseProcessLine(line.trimmingCharacters(in: .whitespaces)) != nil {
                parsedCount += 1
            }
        }
        XCTAssertGreaterThan(parsedCount, 0, "At least one process should parse from live top output")
    }

    func testParseRealTopLoadAverages() throws {
        guard let output = runCommand("/usr/bin/top", arguments: ["-l", "1", "-n", "0"]) else {
            throw XCTSkip("top command unavailable")
        }

        let lines = output.components(separatedBy: .newlines)
        let loadLine = lines.first { $0.contains("Load Avg:") }
        XCTAssertNotNil(loadLine, "top output should contain Load Avg line")

        if let loadLine = loadLine {
            let result = TopOutputParser.parseLoadAverages(loadLine)
            XCTAssertNotNil(result)
            if let r = result {
                XCTAssertGreaterThanOrEqual(r.min1, 0.0)
                XCTAssertGreaterThanOrEqual(r.min5, 0.0)
                XCTAssertGreaterThanOrEqual(r.min15, 0.0)
            }
        }
    }

    func testParseRealTopProcessesLine() throws {
        guard let output = runCommand("/usr/bin/top", arguments: ["-l", "1", "-n", "0"]) else {
            throw XCTSkip("top command unavailable")
        }

        let lines = output.components(separatedBy: .newlines)
        let processesLine = lines.first { $0.contains("Processes:") && $0.contains("total") }
        XCTAssertNotNil(processesLine)

        if let processesLine = processesLine {
            let result = TopOutputParser.parseProcessesLine(processesLine)
            XCTAssertNotNil(result)
            if let r = result {
                XCTAssertGreaterThan(r.total, 0, "System should have at least one process")
                XCTAssertGreaterThanOrEqual(r.running, 0)
                XCTAssertGreaterThanOrEqual(r.sleeping, 0)
                XCTAssertGreaterThan(r.threads, 0, "System should have at least one thread")
            }
        }
    }

    // MARK: - vm_stat Output Parsing

    func testParseRealVmStat() throws {
        guard let output = runCommand("/usr/bin/vm_stat") else {
            throw XCTSkip("vm_stat command unavailable")
        }

        // vm_stat should contain "Pages active:" among others
        XCTAssertTrue(output.contains("Pages active:"), "vm_stat output should include Pages active")
        XCTAssertTrue(output.contains("Pages free:"), "vm_stat output should include Pages free")

        // Parse a few page counts
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("Pages active:") {
                let result = TopOutputParser.extractPageCount(from: line)
                XCTAssertNotEqual(result, "0", "Active pages should be non-zero on a running system")
            }
        }
    }

    // MARK: - df Output Parsing

    func testParseRealDfOutput() throws {
        guard let output = runCommand("/bin/df", arguments: ["-H"]) else {
            throw XCTSkip("df command unavailable")
        }

        let lines = output.components(separatedBy: .newlines)
        var parsedDisks = 0

        for line in lines {
            if let disk = TopOutputParser.parseDfLine(line) {
                parsedDisks += 1
                XCTAssertFalse(disk.name.isEmpty, "Disk name should not be empty")
                XCTAssertGreaterThan(disk.totalGB, 0, "Total GB should be positive")
                XCTAssertGreaterThanOrEqual(disk.percentUsed, 0)
                XCTAssertLessThanOrEqual(disk.percentUsed, 100)
            }
        }
        XCTAssertGreaterThan(parsedDisks, 0, "Should parse at least one disk from df output")
    }

    // MARK: - sysctl Swap Usage Parsing

    func testParseRealSwapUsage() throws {
        guard let output = runCommand("/usr/sbin/sysctl", arguments: ["vm.swapusage"]) else {
            throw XCTSkip("sysctl command unavailable")
        }

        let result = TopOutputParser.parseSwapUsage(output)
        // Even if swap is 0, the total field should be parseable
        XCTAssertFalse(result.total.isEmpty, "Swap total should be parseable from sysctl output")
    }

    // MARK: - sysctl CPU Core Count

    func testParseRealCPUCoreCount() throws {
        guard let output = runCommand("/usr/sbin/sysctl", arguments: ["-n", "hw.ncpu"]) else {
            throw XCTSkip("sysctl command unavailable")
        }

        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        let cores = Int(trimmed)
        XCTAssertNotNil(cores, "Should parse integer core count from sysctl")
        if let cores = cores {
            XCTAssertGreaterThan(cores, 0, "System must have at least one CPU core")
        }
    }

    // MARK: - iostat Output Parsing

    func testParseRealIOStat() throws {
        guard let output = runCommand("/usr/sbin/iostat", arguments: ["-d", "-c", "2"]) else {
            throw XCTSkip("iostat command unavailable")
        }

        let result = TopOutputParser.parseIOStat(output)
        // On an idle system MB/s can be 0, but TPS should often be > 0
        XCTAssertGreaterThanOrEqual(result.totalMBps, 0.0, "MB/s must be non-negative")
        XCTAssertGreaterThanOrEqual(result.totalTPS, 0, "TPS must be non-negative")
    }

    // MARK: - netstat Output Parsing

    func testNetstatProducesOutput() throws {
        guard let output = runCommand("/usr/sbin/netstat", arguments: ["-ib"]) else {
            throw XCTSkip("netstat command unavailable")
        }

        XCTAssertFalse(output.isEmpty, "netstat -ib should produce output")
        XCTAssertTrue(output.contains("Name"), "netstat output should contain a header with 'Name'")

        // Verify at least one en* interface exists
        let lines = output.components(separatedBy: .newlines)
        let enLines = lines.filter { $0.trimmingCharacters(in: .whitespaces).hasPrefix("en") }
        XCTAssertFalse(enLines.isEmpty, "Should find at least one en* network interface")
    }

    // MARK: - End-to-End Parse Roundtrip

    func testFullTopOutputRoundtrip() throws {
        // Run top, parse everything the app would parse, verify no crashes
        guard let output = runCommand("/usr/bin/top", arguments: ["-l", "1", "-n", "10", "-o", "cpu", "-stats", "pid,command,cpu,mem,time,th,ports,mreg,rprvt,vsize,user,state"]) else {
            throw XCTSkip("top command unavailable")
        }

        let lines = output.components(separatedBy: .newlines)
        var cpuParsed = false
        var memParsed = false
        var loadParsed = false
        var processesParsed = false
        var processLinesParsed = 0

        for line in lines {
            if line.contains("CPU usage:") {
                let _ = TopOutputParser.parseCPUUsageLine(line)
                cpuParsed = true
            }
            if line.contains("PhysMem:") {
                let _ = TopOutputParser.extractMemory(from: line)
                memParsed = true
            }
            if line.contains("Load Avg:") {
                let _ = TopOutputParser.parseLoadAverages(line)
                loadParsed = true
            }
            if line.contains("Processes:") && line.contains("total") {
                let _ = TopOutputParser.parseProcessesLine(line)
                processesParsed = true
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let first = trimmed.first, first.isNumber {
                if TopOutputParser.parseProcessLine(trimmed) != nil {
                    processLinesParsed += 1
                }
            }
        }

        XCTAssertTrue(cpuParsed, "Should have parsed CPU usage")
        XCTAssertTrue(memParsed, "Should have parsed PhysMem")
        XCTAssertTrue(loadParsed, "Should have parsed Load Avg")
        XCTAssertTrue(processesParsed, "Should have parsed Processes header")
        XCTAssertGreaterThan(processLinesParsed, 0, "Should have parsed at least one process line")
    }
}
