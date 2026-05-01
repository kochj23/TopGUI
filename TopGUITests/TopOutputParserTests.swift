//
//  TopOutputParserTests.swift
//  TopGUITests
//
//  Unit tests for CLI output parsing logic.
//
//  Created by Jordan Koch on 5/1/2026.
//  Copyright 2026 Jordan Koch. All rights reserved.
//

import XCTest
@testable import TopGUI

final class TopOutputParserTests: XCTestCase {

    // MARK: - extractPercentage

    func testExtractPercentage_standardValue() {
        XCTAssertEqual(TopOutputParser.extractPercentage(from: "6.45% user"), 6.45)
    }

    func testExtractPercentage_integerValue() {
        XCTAssertEqual(TopOutputParser.extractPercentage(from: "82% idle"), 82.0)
    }

    func testExtractPercentage_zeroPercent() {
        XCTAssertEqual(TopOutputParser.extractPercentage(from: "0.0% sys"), 0.0)
    }

    func testExtractPercentage_hundredPercent() {
        XCTAssertEqual(TopOutputParser.extractPercentage(from: "100.0% idle"), 100.0)
    }

    func testExtractPercentage_noMatch() {
        XCTAssertNil(TopOutputParser.extractPercentage(from: "no percentage here"))
    }

    func testExtractPercentage_emptyString() {
        XCTAssertNil(TopOutputParser.extractPercentage(from: ""))
    }

    // MARK: - extractNumber

    func testExtractNumber_simpleInteger() {
        XCTAssertEqual(TopOutputParser.extractNumber(from: "450 total"), 450)
    }

    func testExtractNumber_multipleNumbers_returnsFirst() {
        XCTAssertEqual(TopOutputParser.extractNumber(from: "3 running, 447 sleeping"), 3)
    }

    func testExtractNumber_noMatch() {
        XCTAssertNil(TopOutputParser.extractNumber(from: "no numbers"))
    }

    func testExtractNumber_zero() {
        XCTAssertEqual(TopOutputParser.extractNumber(from: "0 stuck"), 0)
    }

    // MARK: - extractMemory

    func testExtractMemory_gigabytes() {
        XCTAssertEqual(TopOutputParser.extractMemory(from: "PhysMem: 15G used"), "15G")
    }

    func testExtractMemory_megabytes() {
        XCTAssertEqual(TopOutputParser.extractMemory(from: "2048M wired"), "2048M")
    }

    func testExtractMemory_kilobytes() {
        XCTAssertEqual(TopOutputParser.extractMemory(from: "512K unused"), "512K")
    }

    func testExtractMemory_noMatch() {
        XCTAssertNil(TopOutputParser.extractMemory(from: "no memory info"))
    }

    // MARK: - extractPageCount

    func testExtractPageCount_largePagesGB() {
        // 1,000,000 pages * 16384 bytes / 1048576 = 15625 MB => "15 GB"
        let result = TopOutputParser.extractPageCount(from: "Pages active:        1000000.")
        XCTAssertEqual(result, "15 GB")
    }

    func testExtractPageCount_smallPagesMB() {
        // 1000 pages * 16384 / 1048576 = 15 MB
        let result = TopOutputParser.extractPageCount(from: "Pages free:          1000.")
        XCTAssertEqual(result, "15 MB")
    }

    func testExtractPageCount_zeroPages() {
        let result = TopOutputParser.extractPageCount(from: "Pageouts:            0.")
        XCTAssertEqual(result, "0 MB")
    }

    func testExtractPageCount_noMatch() {
        let result = TopOutputParser.extractPageCount(from: "no pages")
        XCTAssertEqual(result, "0")
    }

    // MARK: - parseSizeToGB

    func testParseSizeToGB_terabytes() {
        XCTAssertEqual(TopOutputParser.parseSizeToGB("2.0T"), 2048.0, accuracy: 0.01)
    }

    func testParseSizeToGB_gigabytes() {
        XCTAssertEqual(TopOutputParser.parseSizeToGB("500G"), 500.0, accuracy: 0.01)
    }

    func testParseSizeToGB_megabytes() {
        XCTAssertEqual(TopOutputParser.parseSizeToGB("512M"), 0.5, accuracy: 0.01)
    }

    func testParseSizeToGB_kilobytes() {
        let result = TopOutputParser.parseSizeToGB("1048576K")
        XCTAssertEqual(result, 1.0, accuracy: 0.01)
    }

    func testParseSizeToGB_emptyString() {
        XCTAssertEqual(TopOutputParser.parseSizeToGB(""), 0.0)
    }

    func testParseSizeToGB_noUnit() {
        XCTAssertEqual(TopOutputParser.parseSizeToGB("100"), 100.0, accuracy: 0.01)
    }

    // MARK: - parseMemoryToGB

    func testParseMemoryToGB_gigabytes() {
        XCTAssertEqual(TopOutputParser.parseMemoryToGB("15G"), 15.0, accuracy: 0.01)
    }

    func testParseMemoryToGB_megabytes() {
        XCTAssertEqual(TopOutputParser.parseMemoryToGB("2048M"), 2.0, accuracy: 0.01)
    }

    func testParseMemoryToGB_emptyString() {
        XCTAssertEqual(TopOutputParser.parseMemoryToGB(""), 0.0)
    }

    // MARK: - parseProcessLine

    func testParseProcessLine_validLine() {
        let line = "1234 Safari 12.5 3.2 10:05.32 15 200 50 512M 2G root running"
        let proc = TopOutputParser.parseProcessLine(line)
        XCTAssertNotNil(proc)
        XCTAssertEqual(proc?.pid, 1234)
        XCTAssertEqual(proc?.command, "Safari")
        XCTAssertEqual(proc?.cpuUsage, 12.5)
        XCTAssertEqual(proc?.memUsage, 3.2)
        XCTAssertEqual(proc?.time, "10:05.32")
        XCTAssertEqual(proc?.threads, 15)
        XCTAssertEqual(proc?.ports, 200)
        XCTAssertEqual(proc?.memRegions, 50)
        XCTAssertEqual(proc?.memPhys, "512M")
        XCTAssertEqual(proc?.memVirt, "2G")
        XCTAssertEqual(proc?.user, "root")
        XCTAssertEqual(proc?.state, "running")
    }

    func testParseProcessLine_tooFewColumns() {
        let line = "1234 Safari 12.5"
        XCTAssertNil(TopOutputParser.parseProcessLine(line))
    }

    func testParseProcessLine_invalidPID() {
        let line = "abc Safari 12.5 3.2 10:05.32 15 200 50 512M 2G root running"
        XCTAssertNil(TopOutputParser.parseProcessLine(line))
    }

    func testParseProcessLine_zeroCPU() {
        let line = "999 kernel_task 0.0 0.0 100:00.00 1 0 0 1M 1M root sleeping"
        let proc = TopOutputParser.parseProcessLine(line)
        XCTAssertNotNil(proc)
        XCTAssertEqual(proc?.cpuUsage, 0.0)
    }

    func testParseProcessLine_percentSignInCPU() {
        let line = "100 node 55.3% 1.2% 05:00.00 10 5 20 100M 500M kochj running"
        let proc = TopOutputParser.parseProcessLine(line)
        XCTAssertNotNil(proc)
        XCTAssertEqual(proc?.cpuUsage, 55.3)
        XCTAssertEqual(proc?.memUsage, 1.2)
    }

    // MARK: - parseCPUUsageLine

    func testParseCPUUsageLine_standard() {
        let line = "CPU usage: 6.45% user, 11.29% sys, 82.25% idle"
        let result = TopOutputParser.parseCPUUsageLine(line)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.user, 6.45)
        XCTAssertEqual(result?.system, 11.29)
        XCTAssertEqual(result?.idle, 82.25)
    }

    func testParseCPUUsageLine_allZero() {
        let line = "CPU usage: 0.0% user, 0.0% sys, 100.0% idle"
        let result = TopOutputParser.parseCPUUsageLine(line)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.user, 0.0)
        XCTAssertEqual(result?.idle, 100.0)
    }

    func testParseCPUUsageLine_nonCPULine() {
        XCTAssertNil(TopOutputParser.parseCPUUsageLine("PhysMem: 15G used"))
    }

    // MARK: - parseProcessesLine

    func testParseProcessesLine_standard() {
        let line = "Processes: 450 total, 3 running, 447 sleeping, 2345 threads"
        let result = TopOutputParser.parseProcessesLine(line)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.total, 450)
        XCTAssertEqual(result?.running, 3)
        XCTAssertEqual(result?.sleeping, 447)
        XCTAssertEqual(result?.threads, 2345)
    }

    func testParseProcessesLine_withStuck() {
        let line = "Processes: 500 total, 5 running, 2 stuck, 493 sleeping, 3000 threads"
        let result = TopOutputParser.parseProcessesLine(line)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.stuck, 2)
    }

    func testParseProcessesLine_nonProcessLine() {
        XCTAssertNil(TopOutputParser.parseProcessesLine("CPU usage: 10% user"))
    }

    // MARK: - parseLoadAverages

    func testParseLoadAverages_standard() {
        let line = "Load Avg: 2.34, 2.56, 2.78"
        let result = TopOutputParser.parseLoadAverages(line)
        XCTAssertNotNil(result)
        guard let r = result else { return }
        XCTAssertEqual(r.min1, 2.34, accuracy: 0.001)
        XCTAssertEqual(r.min5, 2.56, accuracy: 0.001)
        XCTAssertEqual(r.min15, 2.78, accuracy: 0.001)
    }

    func testParseLoadAverages_zero() {
        let line = "Load Avg: 0.00, 0.00, 0.00"
        let result = TopOutputParser.parseLoadAverages(line)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.min1, 0.0)
    }

    func testParseLoadAverages_highLoad() {
        let line = "Load Avg: 32.50, 28.10, 25.00"
        let result = TopOutputParser.parseLoadAverages(line)
        XCTAssertNotNil(result)
        guard let r = result else { return }
        XCTAssertEqual(r.min1, 32.5, accuracy: 0.01)
    }

    func testParseLoadAverages_nonLoadLine() {
        XCTAssertNil(TopOutputParser.parseLoadAverages("Processes: 450 total"))
    }

    // MARK: - parseSwapUsage

    func testParseSwapUsage_standard() {
        let output = "vm.swapusage: total = 2.50G  used = 1.25G  free = 1.25G  (encrypted)"
        let result = TopOutputParser.parseSwapUsage(output)
        XCTAssertEqual(result.total, "2.50G")
        XCTAssertEqual(result.used, "1.25G")
        XCTAssertEqual(result.free, "1.25G")
    }

    func testParseSwapUsage_zeroSwap() {
        let output = "vm.swapusage: total = 0.00M  used = 0.00M  free = 0.00M"
        let result = TopOutputParser.parseSwapUsage(output)
        XCTAssertEqual(result.total, "0.00M")
        XCTAssertEqual(result.used, "0.00M")
        XCTAssertEqual(result.free, "0.00M")
    }

    func testParseSwapUsage_noMatch() {
        let output = "garbage data"
        let result = TopOutputParser.parseSwapUsage(output)
        XCTAssertEqual(result.total, "")
        XCTAssertEqual(result.used, "")
        XCTAssertEqual(result.free, "")
    }

    // MARK: - parseDfLine

    func testParseDfLine_standardVolume() {
        let line = "/dev/disk3s1s1   2.0T   1.5T   500G    76%    12345  1234567 95%   /"
        let disk = TopOutputParser.parseDfLine(line)
        XCTAssertNotNil(disk)
        guard let d = disk else { return }
        XCTAssertEqual(d.name, "Macintosh HD")
        XCTAssertEqual(d.filesystem, "/dev/disk3s1s1")
        XCTAssertEqual(d.totalGB, 2048.0, accuracy: 0.1)
        XCTAssertEqual(d.percentUsed, 76.0)
        XCTAssertEqual(d.mountPoint, "/")
    }

    func testParseDfLine_namedVolume() {
        let line = "/dev/disk4s1    4.0T   2.0T   2.0T    50%     5000   500000 80%   /Volumes/Data"
        let disk = TopOutputParser.parseDfLine(line)
        XCTAssertNotNil(disk)
        XCTAssertEqual(disk?.name, "Data")
        XCTAssertEqual(disk?.mountPoint, "/Volumes/Data")
    }

    func testParseDfLine_headerLine() {
        let line = "Filesystem   Size   Used  Avail  Capacity  iused   ifree  %iused  Mounted on"
        XCTAssertNil(TopOutputParser.parseDfLine(line))
    }

    func testParseDfLine_emptyLine() {
        XCTAssertNil(TopOutputParser.parseDfLine(""))
    }

    func testParseDfLine_nonDeviceLine() {
        XCTAssertNil(TopOutputParser.parseDfLine("map auto_home   0Bi    0Bi   0Bi   100%   0   0  -   /System/Volumes/Data/home"))
    }

    // MARK: - parseIOStat

    func testParseIOStat_standardOutput() {
        let output = "              disk0               disk4\n    KB/t  tps  MB/s     KB/t  tps  MB/s\n   13.21  447  5.77    30.85    0  0.00\n    4.49  202  0.89     0.00    0  0.00"
        let result = TopOutputParser.parseIOStat(output)
        XCTAssertEqual(result.totalMBps, 0.89, accuracy: 0.01)
        XCTAssertEqual(result.totalTPS, 202)
    }

    func testParseIOStat_insufficientLines() {
        let output = "disk0\nKB/t tps MB/s"
        let result = TopOutputParser.parseIOStat(output)
        XCTAssertEqual(result.totalMBps, 0)
        XCTAssertEqual(result.totalTPS, 0)
    }

    // MARK: - formatSpeed

    func testFormatSpeed_gigabytesPerSecond() {
        XCTAssertEqual(TopOutputParser.formatSpeed(1500.0), "1.5 GB/s")
    }

    func testFormatSpeed_megabytesPerSecond() {
        XCTAssertEqual(TopOutputParser.formatSpeed(50.0), "50.0 MB/s")
    }

    func testFormatSpeed_kilobytesPerSecond() {
        XCTAssertEqual(TopOutputParser.formatSpeed(0.5), "512 KB/s")
    }

    func testFormatSpeed_zero() {
        XCTAssertEqual(TopOutputParser.formatSpeed(0.0), "0 KB/s")
    }

    // MARK: - calculateHealthScore

    func testCalculateHealthScore_perfectHealth() {
        let score = TopOutputParser.calculateHealthScore(totalCPU: 0, memoryPercentage: 0, diskUsages: [0])
        XCTAssertEqual(score, 100.0, accuracy: 0.01)
    }

    func testCalculateHealthScore_fullyLoaded() {
        let score = TopOutputParser.calculateHealthScore(totalCPU: 100, memoryPercentage: 100, diskUsages: [100])
        XCTAssertEqual(score, 0.0, accuracy: 0.01)
    }

    func testCalculateHealthScore_noDisks() {
        // No disks defaults to 50% disk score
        let score = TopOutputParser.calculateHealthScore(totalCPU: 50, memoryPercentage: 50, diskUsages: [])
        let expected = 50.0 * 0.4 + 50.0 * 0.3 + 50.0 * 0.3
        XCTAssertEqual(score, expected, accuracy: 0.01)
    }

    func testCalculateHealthScore_multipleDisks() {
        let score = TopOutputParser.calculateHealthScore(totalCPU: 20, memoryPercentage: 60, diskUsages: [50, 80])
        let cpuScore = 80.0
        let memScore = 40.0
        let diskScore = ((100 - 50) + (100 - 80)) / 2.0 // 35
        let expected = cpuScore * 0.4 + memScore * 0.3 + diskScore * 0.3
        XCTAssertEqual(score, expected, accuracy: 0.01)
    }

    // MARK: - formatSwapValue

    func testFormatSwapValue_gigabytes() {
        XCTAssertEqual(TopOutputParser.formatSwapValue("2.50G"), "2 GB")
    }

    func testFormatSwapValue_megabytes() {
        XCTAssertEqual(TopOutputParser.formatSwapValue("512M"), "512 MB")
    }

    func testFormatSwapValue_zeroMegabytes() {
        XCTAssertEqual(TopOutputParser.formatSwapValue("0.00M"), "0 MB")
    }

    func testFormatSwapValue_emptyString() {
        XCTAssertEqual(TopOutputParser.formatSwapValue(""), "0 MB")
    }
}
