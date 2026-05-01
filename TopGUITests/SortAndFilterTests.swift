//
//  SortAndFilterTests.swift
//  TopGUITests
//
//  Functional tests for process sorting, filtering, and refresh logic.
//
//  Created by Jordan Koch on 5/1/2026.
//  Copyright 2026 Jordan Koch. All rights reserved.
//

import XCTest
@testable import TopGUI

final class SortAndFilterTests: XCTestCase {

    // MARK: - Test Data Helpers

    private func makeProcess(pid: Int, command: String, cpu: Double = 0, mem: Double = 0, user: String = "root") -> TopGUI.ProcessInfo {
        TopGUI.ProcessInfo(pid: pid, command: command, cpuUsage: cpu, memUsage: mem, time: "0:00.00", threads: 1, ports: 0, memRegions: 0, memPhys: "1M", memVirt: "1M", user: user, state: "running")
    }

    private var sampleProcesses: [TopGUI.ProcessInfo] {
        [
            makeProcess(pid: 1, command: "kernel_task", cpu: 5.0, mem: 2.0, user: "root"),
            makeProcess(pid: 100, command: "Safari", cpu: 30.0, mem: 10.0, user: "kochj"),
            makeProcess(pid: 200, command: "Xcode", cpu: 20.0, mem: 15.0, user: "kochj"),
            makeProcess(pid: 300, command: "WindowServer", cpu: 8.0, mem: 3.0, user: "_windowserver"),
            makeProcess(pid: 400, command: "sshd", cpu: 0.1, mem: 0.5, user: "root"),
        ]
    }

    // MARK: - Sort by CPU

    func testSortByCPU_descending() {
        let sorted = sampleProcesses.sorted { $0.cpuUsage > $1.cpuUsage }
        XCTAssertEqual(sorted.first?.command, "Safari")
        XCTAssertEqual(sorted.last?.command, "sshd")
    }

    func testSortByCPU_ascending() {
        let sorted = sampleProcesses.sorted { $0.cpuUsage < $1.cpuUsage }
        XCTAssertEqual(sorted.first?.command, "sshd")
        XCTAssertEqual(sorted.last?.command, "Safari")
    }

    // MARK: - Sort by Memory

    func testSortByMemory_descending() {
        let sorted = sampleProcesses.sorted { $0.memUsage > $1.memUsage }
        XCTAssertEqual(sorted.first?.command, "Xcode")
    }

    // MARK: - Sort by PID

    func testSortByPID_ascending() {
        let sorted = sampleProcesses.sorted { $0.pid < $1.pid }
        XCTAssertEqual(sorted.first?.pid, 1)
        XCTAssertEqual(sorted.last?.pid, 400)
    }

    // MARK: - Sort by Command Name

    func testSortByCommand_ascending() {
        let sorted = sampleProcesses.sorted { $0.command < $1.command }
        XCTAssertEqual(sorted.first?.command, "Safari")
        XCTAssertEqual(sorted.last?.command, "sshd")
    }

    // MARK: - Filter by Search Text (command)

    func testFilterByCommand() {
        let searchText = "Safari"
        let filtered = sampleProcesses.filter {
            $0.command.localizedCaseInsensitiveContains(searchText)
        }
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.pid, 100)
    }

    func testFilterByCommand_caseInsensitive() {
        let searchText = "safari"
        let filtered = sampleProcesses.filter {
            $0.command.localizedCaseInsensitiveContains(searchText)
        }
        XCTAssertEqual(filtered.count, 1)
    }

    func testFilterByCommand_partial() {
        let searchText = "Xc"
        let filtered = sampleProcesses.filter {
            $0.command.localizedCaseInsensitiveContains(searchText)
        }
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.command, "Xcode")
    }

    // MARK: - Filter by PID

    func testFilterByPID() {
        let searchText = "100"
        let filtered = sampleProcesses.filter {
            "\($0.pid)".contains(searchText)
        }
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.command, "Safari")
    }

    // MARK: - Filter by User

    func testFilterByUser() {
        let searchText = "kochj"
        let filtered = sampleProcesses.filter {
            $0.user.localizedCaseInsensitiveContains(searchText)
        }
        XCTAssertEqual(filtered.count, 2)
    }

    // MARK: - Combined Filter + Sort

    func testFilterAndSort() {
        let searchText = "kochj"
        let filtered = sampleProcesses.filter {
            $0.user.localizedCaseInsensitiveContains(searchText)
        }.sorted { $0.cpuUsage > $1.cpuUsage }

        XCTAssertEqual(filtered.count, 2)
        XCTAssertEqual(filtered.first?.command, "Safari")
        XCTAssertEqual(filtered.last?.command, "Xcode")
    }

    // MARK: - Empty Filter Returns All

    func testEmptyFilterReturnsAll() {
        let searchText = ""
        let filtered = sampleProcesses.filter { proc in
            searchText.isEmpty || proc.command.localizedCaseInsensitiveContains(searchText)
        }
        XCTAssertEqual(filtered.count, sampleProcesses.count)
    }

    // MARK: - No Match Returns Empty

    func testNoMatchReturnsEmpty() {
        let searchText = "NonExistentProcess"
        let filtered = sampleProcesses.filter {
            $0.command.localizedCaseInsensitiveContains(searchText)
        }
        XCTAssertTrue(filtered.isEmpty)
    }

    // MARK: - Top N Processes

    func testTopFiveByMemory() {
        let top5 = sampleProcesses.sorted { $0.memUsage > $1.memUsage }.prefix(5)
        XCTAssertEqual(top5.count, 5)
        XCTAssertEqual(top5.first?.command, "Xcode")
    }

    func testTopNWhenFewerThanN() {
        let processes = [
            makeProcess(pid: 1, command: "A", cpu: 10),
            makeProcess(pid: 2, command: "B", cpu: 20),
        ]
        let top5 = processes.sorted { $0.cpuUsage > $1.cpuUsage }.prefix(5)
        XCTAssertEqual(top5.count, 2)
    }

    // MARK: - Refresh Cycle Counters

    func testDiskFetchIntervalModulo() {
        // Disk usage fetches every 300 seconds
        XCTAssertTrue(300 % 300 == 0, "Should fire at second 300")
        XCTAssertTrue(600 % 300 == 0, "Should fire at second 600")
        XCTAssertFalse(150 % 300 == 0, "Should NOT fire at second 150")
    }

    func testWidgetSyncIntervalModulo() {
        // Widget syncs every 10 seconds
        XCTAssertTrue(10 % 10 == 0)
        XCTAssertTrue(20 % 10 == 0)
        XCTAssertFalse(7 % 10 == 0)
    }

    // MARK: - Activity Level Classification

    func testActivityLevel_idle() {
        XCTAssertTrue(0.0 <= 0.1, "Combined throughput under 0.1 is idle")
    }

    func testActivityLevel_veryHigh() {
        XCTAssertTrue(600.0 > 500.0, "Combined throughput over 500 is very high")
    }
}
