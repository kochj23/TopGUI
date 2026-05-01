//
//  ProcessModelTests.swift
//  TopGUITests
//
//  Unit tests for data models: TopGUI.ProcessInfo, SystemStats, DiskStats, NetworkInterface,
//  WidgetSystemStats, HealthStatus.
//
//  Created by Jordan Koch on 5/1/2026.
//  Copyright 2026 Jordan Koch. All rights reserved.
//

import XCTest
@testable import TopGUI

final class ProcessModelTests: XCTestCase {

    // MARK: - ProcessInfo

    func testProcessInfoEquality_samePID() {
        let a = TopGUI.ProcessInfo(pid: 100, command: "A", cpuUsage: 1, memUsage: 1, time: "0:00", threads: 1, ports: 0, memRegions: 0, memPhys: "1M", memVirt: "1M", user: "root", state: "running")
        let b = TopGUI.ProcessInfo(pid: 100, command: "B", cpuUsage: 99, memUsage: 99, time: "9:99", threads: 9, ports: 9, memRegions: 9, memPhys: "9G", memVirt: "9G", user: "user", state: "sleeping")
        XCTAssertEqual(a, b, "ProcessInfo equality is based on PID only")
    }

    func testProcessInfoEquality_differentPID() {
        let a = TopGUI.ProcessInfo(pid: 100, command: "A", cpuUsage: 0, memUsage: 0, time: "", threads: 0, ports: 0, memRegions: 0, memPhys: "", memVirt: "", user: "", state: "")
        let b = TopGUI.ProcessInfo(pid: 200, command: "A", cpuUsage: 0, memUsage: 0, time: "", threads: 0, ports: 0, memRegions: 0, memPhys: "", memVirt: "", user: "", state: "")
        XCTAssertNotEqual(a, b)
    }

    func testProcessInfoIdentifiable() {
        let proc = TopGUI.ProcessInfo(pid: 1, command: "test", cpuUsage: 0, memUsage: 0, time: "", threads: 0, ports: 0, memRegions: 0, memPhys: "", memVirt: "", user: "", state: "")
        XCTAssertNotNil(proc.id, "ProcessInfo should have a UUID id for Identifiable conformance")
    }

    // MARK: - SystemStats

    func testSystemStatsTotalCPU() {
        var stats = SystemStats()
        stats.cpuUser = 10.0
        stats.cpuSystem = 5.0
        XCTAssertEqual(stats.totalCPU, 15.0)
    }

    func testSystemStatsTotalCPU_zero() {
        let stats = SystemStats()
        XCTAssertEqual(stats.totalCPU, 0.0)
    }

    func testSystemStatsMemoryPercentage_withValues() {
        var stats = SystemStats()
        stats.memPhysUsed = "12G"
        stats.memPhysFree = "4G"
        // 12 / (12 + 4) * 100 = 75%
        XCTAssertEqual(stats.memoryUsagePercentage, 75.0, accuracy: 0.1)
    }

    func testSystemStatsMemoryPercentage_megabytes() {
        var stats = SystemStats()
        stats.memPhysUsed = "3072M"  // 3 GB
        stats.memPhysFree = "1024M"  // 1 GB
        // 3 / (3 + 1) * 100 = 75%
        XCTAssertEqual(stats.memoryUsagePercentage, 75.0, accuracy: 0.1)
    }

    func testSystemStatsMemoryPercentage_empty() {
        let stats = SystemStats()
        XCTAssertEqual(stats.memoryUsagePercentage, 0.0)
    }

    func testSystemStatsLoadPercentage() {
        var stats = SystemStats()
        stats.loadAvg1min = 8.0
        // 8 / 16 * 100 = 50%
        XCTAssertEqual(stats.loadPercentage(cores: 16), 50.0, accuracy: 0.1)
    }

    func testSystemStatsLoadPercentage_overloaded() {
        var stats = SystemStats()
        stats.loadAvg1min = 64.0
        // Caps at 100%
        XCTAssertEqual(stats.loadPercentage(cores: 16), 100.0)
    }

    func testSystemStatsLoadPercentage_zeroCores() {
        var stats = SystemStats()
        stats.loadAvg1min = 5.0
        XCTAssertEqual(stats.loadPercentage(cores: 0), 0.0)
    }

    func testSystemStatsDefaultValues() {
        let stats = SystemStats()
        XCTAssertEqual(stats.cpuUser, 0.0)
        XCTAssertEqual(stats.cpuSystem, 0.0)
        XCTAssertEqual(stats.cpuIdle, 0.0)
        XCTAssertEqual(stats.threads, 0)
        XCTAssertEqual(stats.processes, 0)
        XCTAssertTrue(stats.disks.isEmpty)
        XCTAssertTrue(stats.networkInterfaces.isEmpty)
        XCTAssertTrue(stats.perCoreCPU.isEmpty)
        XCTAssertEqual(stats.gpuUsage, 0.0)
    }

    // MARK: - WidgetSystemStats

    func testWidgetSystemStatsDefaultInit() {
        let stats = WidgetSystemStats()
        XCTAssertEqual(stats.cpuUsage, 0.0)
        XCTAssertEqual(stats.memoryUsage, 0.0)
        XCTAssertEqual(stats.topProcessName, "---")
        XCTAssertEqual(stats.healthScore, 100.0)
    }

    func testWidgetSystemStatsConvenienceInit() {
        let stats = WidgetSystemStats(cpuUsage: 50, memoryUsage: 75, topProcessName: "Safari", topProcessCPU: 30, healthScore: 60)
        XCTAssertEqual(stats.cpuUsage, 50.0)
        XCTAssertEqual(stats.memoryUsage, 75.0)
        XCTAssertEqual(stats.topProcessName, "Safari")
        XCTAssertEqual(stats.cpuIdle, 50.0) // 100 - cpuUsage
    }

    func testWidgetSystemStatsCodable() throws {
        let original = WidgetSystemStats(cpuUsage: 45.5, memoryUsage: 80.2, topProcessName: "Xcode", topProcessCPU: 20.0, healthScore: 70.0)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(WidgetSystemStats.self, from: data)

        XCTAssertEqual(decoded.cpuUsage, 45.5, accuracy: 0.01)
        XCTAssertEqual(decoded.memoryUsage, 80.2, accuracy: 0.01)
        XCTAssertEqual(decoded.topProcessName, "Xcode")
    }

    // MARK: - HealthStatus

    func testHealthStatus_excellent() {
        let stats = WidgetSystemStats(cpuUsage: 0, memoryUsage: 0, topProcessName: "", topProcessCPU: 0, healthScore: 85)
        XCTAssertEqual(stats.healthStatus, .excellent)
    }

    func testHealthStatus_good() {
        let stats = WidgetSystemStats(cpuUsage: 0, memoryUsage: 0, topProcessName: "", topProcessCPU: 0, healthScore: 65)
        XCTAssertEqual(stats.healthStatus, .good)
    }

    func testHealthStatus_moderate() {
        let stats = WidgetSystemStats(cpuUsage: 0, memoryUsage: 0, topProcessName: "", topProcessCPU: 0, healthScore: 50)
        XCTAssertEqual(stats.healthStatus, .moderate)
    }

    func testHealthStatus_poor() {
        let stats = WidgetSystemStats(cpuUsage: 0, memoryUsage: 0, topProcessName: "", topProcessCPU: 0, healthScore: 30)
        XCTAssertEqual(stats.healthStatus, .poor)
    }

    func testHealthStatus_critical() {
        let stats = WidgetSystemStats(cpuUsage: 0, memoryUsage: 0, topProcessName: "", topProcessCPU: 0, healthScore: 10)
        XCTAssertEqual(stats.healthStatus, .critical)
    }

    func testHealthStatusColorHex() {
        XCTAssertEqual(HealthStatus.excellent.colorHex, "00FF9F")
        XCTAssertEqual(HealthStatus.critical.colorHex, "EF4444")
    }

    // MARK: - DiskStats

    func testDiskStatsIdentifiable() {
        let disk = DiskStats(name: "Macintosh HD", filesystem: "/dev/disk1s1", totalGB: 500, usedGB: 250, availableGB: 250, percentUsed: 50, mountPoint: "/")
        XCTAssertNotNil(disk.id)
    }

    // MARK: - NetworkInterface

    func testNetworkInterfaceIdentifiable() {
        let iface = NetworkInterface(name: "en0", downloadMBps: 10.0, uploadMBps: 5.0, packetsIn: 1000, packetsOut: 500)
        XCTAssertNotNil(iface.id)
        XCTAssertEqual(iface.name, "en0")
        XCTAssertEqual(iface.downloadMBps, 10.0)
    }

    // MARK: - SystemStatsEntry

    func testSystemStatsEntryCodable() throws {
        let entry = SystemStatsEntry(date: Date(), stats: WidgetSystemStats(), isPlaceholder: true)
        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(SystemStatsEntry.self, from: data)
        XCTAssertTrue(decoded.isPlaceholder)
    }
}
