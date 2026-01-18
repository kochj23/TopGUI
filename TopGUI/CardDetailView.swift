//
//  CardDetailView.swift
//  TopGUI
//
//  Detailed views for each stat card
//
//  Created by Jordan Koch on 1/15/2026.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct CardDetailView: View {
    @EnvironmentObject var dataManager: TopDataManager
    @Environment(\.dismiss) var dismiss
    let cardType: ContentView.CardType

    var body: some View {
        ZStack {
            GlassmorphicBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    header

                    // Detail content based on card type
                    detailContent
                        .padding(20)
                }
            }
        }
        .frame(width: 800, height: 700)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(cardTitle)
                    .modernHeader(size: .large)

                Text(cardSubtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(ModernColors.textSecondary)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(ModernColors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
    }

    @ViewBuilder
    private var detailContent: some View {
        switch cardType {
        case .cpu:
            cpuDetailView
        case .memory:
            memoryDetailView
        case .loadAverages:
            loadAveragesDetailView
        case .topCPU:
            topCPUDetailView
        case .topMemory:
            topMemoryDetailView
        case .swap:
            swapDetailView
        case .states:
            statesDetailView
        case .memoryPressure:
            memoryPressureDetailView
        case .cpuInfo:
            cpuInfoDetailView
        case .perCore:
            perCoreDetailView
        case .diskActivity:
            diskActivityDetailView
        case .networkBandwidth:
            networkBandwidthDetailView
        case .systemHealth:
            systemHealthDetailView
        }
    }

    private var cardTitle: String {
        switch cardType {
        case .cpu: return "CPU & GPU Usage Details"
        case .memory: return "Memory Details"
        case .loadAverages: return "Load Averages"
        case .topCPU: return "Top CPU Processes"
        case .topMemory: return "Top Memory Processes"
        case .swap: return "Swap Activity"
        case .states: return "Process States"
        case .memoryPressure: return "Memory Pressure"
        case .cpuInfo: return "CPU Information"
        case .perCore: return "Per-Core CPU Usage"
        case .diskActivity: return "Disk Usage"
        case .networkBandwidth: return "Network Bandwidth"
        case .systemHealth: return "System Health"
        }
    }

    private var cardSubtitle: String {
        switch cardType {
        case .cpu: return "Real-time CPU and GPU statistics"
        case .memory: return "Physical memory breakdown"
        case .loadAverages: return "System load over time"
        case .topCPU: return "Most CPU-intensive processes"
        case .topMemory: return "Most memory-intensive processes"
        case .swap: return "Virtual memory paging"
        case .states: return "Process state breakdown"
        case .memoryPressure: return "Detailed memory pressure analysis"
        case .cpuInfo: return "CPU architecture and configuration"
        case .perCore: return "Individual core utilization"
        case .diskActivity: return "Disk space usage"
        case .networkBandwidth: return "Combined network bandwidth"
        case .systemHealth: return "Overall system health score"
        }
    }

    // MARK: - CPU & GPU Detail View
    private var cpuDetailView: some View {
        VStack(spacing: 16) {
            // CPU and GPU Gauges Side by Side
            HStack(spacing: 30) {
                // CPU Gauge
                VStack(spacing: 12) {
                    CircularGauge(
                        value: dataManager.systemStats.totalCPU,
                        color: ModernColors.heatColor(percentage: dataManager.systemStats.totalCPU),
                        size: 150,
                        lineWidth: 15,
                        showValue: true,
                        label: "CPU"
                    )

                    Text("Central Processing Unit")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(ModernColors.textSecondary)
                }

                // GPU Gauge
                VStack(spacing: 12) {
                    CircularGauge(
                        value: dataManager.systemStats.gpuUsage,
                        color: ModernColors.heatColor(percentage: dataManager.systemStats.gpuUsage),
                        size: 150,
                        lineWidth: 15,
                        showValue: true,
                        label: "GPU"
                    )

                    Text("Graphics Processing Unit")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(ModernColors.textSecondary)
                }
            }
            .glassCard()

            // CPU Details
            VStack(alignment: .leading, spacing: 12) {
                Text("CPU Breakdown")
                    .modernHeader(size: .small)

                detailRow(label: "User CPU", value: String(format: "%.1f%%", dataManager.systemStats.cpuUser), color: ModernColors.cyan)
                detailRow(label: "System CPU", value: String(format: "%.1f%%", dataManager.systemStats.cpuSystem), color: ModernColors.purple)
                detailRow(label: "Idle", value: String(format: "%.1f%%", dataManager.systemStats.cpuIdle), color: ModernColors.statusLow)
                detailRow(label: "Total Cores", value: "\(dataManager.systemStats.cpuCores)", color: ModernColors.textSecondary)
            }
            .glassCard()

            // GPU Details
            VStack(alignment: .leading, spacing: 12) {
                Text("GPU Usage")
                    .modernHeader(size: .small)

                detailRow(label: "GPU Utilization", value: String(format: "%.1f%%", dataManager.systemStats.gpuUsage), color: ModernColors.heatColor(percentage: dataManager.systemStats.gpuUsage))

                Text("GPU usage is measured from IOAccelerator performance statistics. High GPU usage occurs during graphics-intensive tasks like video playback, gaming, or 3D rendering.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(ModernColors.textSecondary)
                    .padding(.top, 4)
            }
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text("About CPU & GPU")
                    .modernHeader(size: .small)

                Text("User CPU represents time spent executing user applications. System CPU represents time spent in the kernel. GPU handles graphics rendering, video decoding, and parallel computations.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(ModernColors.textSecondary)
            }
            .glassCard()
        }
    }

    // MARK: - Memory Detail View
    private var memoryDetailView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                CircularGauge(
                    value: dataManager.systemStats.memoryUsagePercentage,
                    color: ModernColors.heatColor(percentage: dataManager.systemStats.memoryUsagePercentage),
                    size: 150,
                    lineWidth: 15,
                    showValue: true,
                    label: "used"
                )

                VStack(alignment: .leading, spacing: 12) {
                    detailRow(label: "Physical Used", value: dataManager.systemStats.memPhysUsed, color: ModernColors.statusHigh)
                    detailRow(label: "Physical Free", value: dataManager.systemStats.memPhysFree, color: ModernColors.statusLow)
                    detailRow(label: "Wired", value: dataManager.systemStats.memWired, color: ModernColors.cyan)
                    detailRow(label: "Compressed", value: dataManager.systemStats.memCompressed, color: ModernColors.purple)
                }
            }
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text("Memory Types")
                    .modernHeader(size: .small)

                Text("Wired memory is locked and cannot be paged out. Compressed memory is data compressed to save space. Free memory is immediately available.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(ModernColors.textSecondary)
            }
            .glassCard()
        }
    }

    // MARK: - Load Averages Detail View
    private var loadAveragesDetailView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                VStack(spacing: 12) {
                    CircularGauge(
                        value: dataManager.systemStats.loadPercentage(cores: dataManager.systemStats.cpuCores),
                        color: ModernColors.statusLow,
                        size: 100,
                        lineWidth: 12,
                        showValue: true,
                        label: "1 min"
                    )
                    Text(String(format: "%.1f", dataManager.systemStats.loadAvg1min))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(ModernColors.statusLow)
                }

                VStack(spacing: 12) {
                    CircularGauge(
                        value: dataManager.systemStats.cpuCores > 0 ? min((dataManager.systemStats.loadAvg5min / Double(dataManager.systemStats.cpuCores)) * 100.0, 100.0) : 0,
                        color: ModernColors.statusMedium,
                        size: 100,
                        lineWidth: 12,
                        showValue: true,
                        label: "5 min"
                    )
                    Text(String(format: "%.1f", dataManager.systemStats.loadAvg5min))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(ModernColors.statusMedium)
                }

                VStack(spacing: 12) {
                    CircularGauge(
                        value: dataManager.systemStats.cpuCores > 0 ? min((dataManager.systemStats.loadAvg15min / Double(dataManager.systemStats.cpuCores)) * 100.0, 100.0) : 0,
                        color: ModernColors.teal,
                        size: 100,
                        lineWidth: 12,
                        showValue: true,
                        label: "15 min"
                    )
                    Text(String(format: "%.1f", dataManager.systemStats.loadAvg15min))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(ModernColors.teal)
                }
            }
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text("About Load Averages")
                    .modernHeader(size: .small)

                Text("Load average represents the number of processes waiting for CPU time. On a \(dataManager.systemStats.cpuCores)-core system, a load of \(dataManager.systemStats.cpuCores).0 means full utilization. Load > core count indicates processes are queued.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(ModernColors.textSecondary)
            }
            .glassCard()
        }
    }

    // MARK: - Top CPU Detail View
    private var topCPUDetailView: some View {
        VStack(spacing: 16) {
            let top5Total = dataManager.processes.prefix(5).reduce(0.0) { $0 + $1.cpuUsage }

            HStack(spacing: 20) {
                CircularGauge(
                    value: min(top5Total, 100.0),
                    color: ModernColors.orange,
                    size: 150,
                    lineWidth: 15,
                    showValue: true,
                    label: "top 5"
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Top 10 CPU Processes")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(ModernColors.textSecondary)

                    ForEach(Array(dataManager.processes.prefix(10).enumerated()), id: \.element.id) { index, process in
                        HStack {
                            Text("\(index + 1).")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(ModernColors.textTertiary)
                                .frame(width: 30, alignment: .trailing)

                            Text(process.command)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(ModernColors.textPrimary)

                            Spacer()

                            Text(String(format: "%.1f%%", process.cpuUsage))
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(ModernColors.heatColor(percentage: process.cpuUsage))
                        }
                    }
                }
            }
            .glassCard()
        }
    }

    // MARK: - Top Memory Detail View
    private var topMemoryDetailView: some View {
        VStack(spacing: 16) {
            let top5Total = dataManager.processes.sorted { $0.memUsage > $1.memUsage }.prefix(5).reduce(0.0) { $0 + $1.memUsage }

            HStack(spacing: 20) {
                CircularGauge(
                    value: min(top5Total, 100.0),
                    color: ModernColors.pink,
                    size: 150,
                    lineWidth: 15,
                    showValue: true,
                    label: "top 5"
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Top 10 Memory Processes")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(ModernColors.textSecondary)

                    ForEach(Array(dataManager.processes.sorted { $0.memUsage > $1.memUsage }.prefix(10).enumerated()), id: \.element.id) { index, process in
                        HStack {
                            Text("\(index + 1).")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(ModernColors.textTertiary)
                                .frame(width: 30, alignment: .trailing)

                            Text(process.command)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(ModernColors.textPrimary)

                            Spacer()

                            Text(String(format: "%.1f%%", process.memUsage))
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(ModernColors.heatColor(percentage: process.memUsage))
                        }
                    }
                }
            }
            .glassCard()
        }
    }

    // MARK: - Swap Detail View
    private var swapDetailView: some View {
        VStack(spacing: 16) {
            let swapinNum = Double(dataManager.systemStats.swapUsed.filter { $0.isNumber }) ?? 0
            let swapoutNum = Double(dataManager.systemStats.swapFree.filter { $0.isNumber }) ?? 0
            let swapTotal = swapinNum + swapoutNum
            let swapPercent = swapTotal > 0 ? (swapinNum / swapTotal) * 100.0 : 0

            HStack(spacing: 20) {
                CircularGauge(
                    value: swapPercent,
                    color: ModernColors.yellow,
                    size: 150,
                    lineWidth: 15,
                    showValue: true,
                    label: "swapins"
                )

                VStack(alignment: .leading, spacing: 12) {
                    detailRow(label: "Swapins", value: dataManager.systemStats.swapUsed.isEmpty ? "0M" : dataManager.systemStats.swapUsed, color: ModernColors.statusHigh)
                    detailRow(label: "Swapouts", value: dataManager.systemStats.swapFree.isEmpty ? "0M" : dataManager.systemStats.swapFree, color: ModernColors.statusLow)
                    detailRow(label: "Total", value: String(format: "%.0fM", swapTotal), color: ModernColors.yellow)
                }
            }
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text("About Swap")
                    .modernHeader(size: .small)

                Text("Swapins occur when memory is paged in from disk. Swapouts occur when memory is paged out to disk. High swap activity indicates memory pressure.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(ModernColors.textSecondary)
            }
            .glassCard()
        }
    }

    // MARK: - States Detail View
    private var statesDetailView: some View {
        VStack(spacing: 16) {
            let runningPercent = dataManager.systemStats.processes > 0 ? (Double(dataManager.systemStats.runningProcesses) / Double(dataManager.systemStats.processes)) * 100.0 : 0

            HStack(spacing: 20) {
                CircularGauge(
                    value: runningPercent,
                    color: ModernColors.statusLow,
                    size: 150,
                    lineWidth: 15,
                    showValue: true,
                    label: "running"
                )

                VStack(alignment: .leading, spacing: 12) {
                    detailRow(label: "Total Processes", value: "\(dataManager.systemStats.processes)", color: ModernColors.textPrimary)
                    detailRow(label: "Running", value: "\(dataManager.systemStats.runningProcesses)", color: ModernColors.statusLow)
                    detailRow(label: "Sleeping", value: "\(dataManager.systemStats.sleeping)", color: ModernColors.cyan)
                    detailRow(label: "Stuck", value: "\(dataManager.systemStats.stuckProcesses)", color: ModernColors.statusCritical)
                    detailRow(label: "Total Threads", value: "\(dataManager.systemStats.threads)", color: ModernColors.purple)
                }
            }
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text("Process States")
                    .modernHeader(size: .small)

                Text("Running processes are actively executing. Sleeping processes are waiting for events. Stuck processes are unresponsive.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(ModernColors.textSecondary)
            }
            .glassCard()
        }
    }

    // MARK: - Memory Pressure Detail View
    private var memoryPressureDetailView: some View {
        VStack(spacing: 16) {
            let activeNum = Double(dataManager.systemStats.memPagesActive.filter { $0.isNumber }) ?? 0
            let totalPages = activeNum + (Double(dataManager.systemStats.memPagesFree.filter { $0.isNumber }) ?? 0)
            let pressurePercent = totalPages > 0 ? (activeNum / totalPages) * 100.0 : 0

            HStack(spacing: 20) {
                CircularGauge(
                    value: pressurePercent,
                    color: ModernColors.heatColor(percentage: pressurePercent),
                    size: 150,
                    lineWidth: 15,
                    showValue: true,
                    label: "pressure"
                )

                VStack(alignment: .leading, spacing: 8) {
                    detailRow(label: "Active Pages", value: dataManager.systemStats.memPagesActive, color: ModernColors.statusHigh)
                    detailRow(label: "Inactive Pages", value: dataManager.systemStats.memPagesInactive, color: ModernColors.cyan)
                    detailRow(label: "Wired Pages", value: dataManager.systemStats.memPagesWired, color: ModernColors.purple)
                    detailRow(label: "Free Pages", value: dataManager.systemStats.memPagesFree, color: ModernColors.statusLow)
                    detailRow(label: "Speculative", value: dataManager.systemStats.memPagesSpeculative, color: ModernColors.teal)
                    detailRow(label: "Purgeable", value: dataManager.systemStats.memPagesPurgeable, color: ModernColors.yellow)
                }
            }
            .glassCard()

            VStack(alignment: .leading, spacing: 8) {
                detailRow(label: "Compressed", value: dataManager.systemStats.memPagesCompressed, color: ModernColors.purple)
                detailRow(label: "Page Faults", value: dataManager.systemStats.memPageFaults, color: ModernColors.orange)
                detailRow(label: "Copy-on-Write", value: dataManager.systemStats.memCOW, color: ModernColors.cyan)
                detailRow(label: "Pageins", value: dataManager.systemStats.memPageins, color: ModernColors.statusLow)
                detailRow(label: "Pageouts", value: dataManager.systemStats.memPageouts, color: ModernColors.statusHigh)
            }
            .glassCard()
        }
    }

    // MARK: - CPU Info Detail View
    private var cpuInfoDetailView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                let threadPercent = dataManager.systemStats.cpuCores > 0 ? min((Double(dataManager.systemStats.threads) / Double(dataManager.systemStats.cpuCores * 100)) * 100.0, 100.0) : 0

                CircularGauge(
                    value: threadPercent,
                    color: ModernColors.accentBlue,
                    size: 150,
                    lineWidth: 15,
                    showValue: false
                )

                VStack(alignment: .leading, spacing: 12) {
                    detailRow(label: "CPU Cores", value: "\(dataManager.systemStats.cpuCores)", color: ModernColors.cyan)
                    detailRow(label: "Total Threads", value: "\(dataManager.systemStats.threads)", color: ModernColors.purple)
                    detailRow(label: "Threads per Core", value: String(format: "%.1f", Double(dataManager.systemStats.threads) / Double(max(dataManager.systemStats.cpuCores, 1))), color: ModernColors.textSecondary)
                }
            }
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text("CPU Architecture")
                    .modernHeader(size: .small)

                Text("Your system has \(dataManager.systemStats.cpuCores) CPU cores with \(dataManager.systemStats.threads) total threads running.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(ModernColors.textSecondary)
            }
            .glassCard()
        }
    }

    // MARK: - Per-Core Detail View
    private var perCoreDetailView: some View {
        VStack(spacing: 16) {
            Text("All \(dataManager.systemStats.perCoreCPU.count) CPU Cores")
                .modernHeader(size: .medium)

            let coreColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 8)
            LazyVGrid(columns: coreColumns, spacing: 12) {
                ForEach(Array(dataManager.systemStats.perCoreCPU.enumerated()), id: \.offset) { index, usage in
                    VStack(spacing: 6) {
                        CircularGauge(
                            value: usage,
                            color: ModernColors.heatColor(percentage: usage),
                            size: 60,
                            lineWidth: 6,
                            showValue: true,
                            label: nil
                        )

                        Text("Core \(index)")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(ModernColors.textSecondary)
                    }
                }
            }
            .glassCard()
        }
    }

    // MARK: - Disk Usage Detail View
    private var diskActivityDetailView: some View {
        VStack(spacing: 16) {
            ForEach(dataManager.systemStats.disks) { disk in
                HStack(spacing: 20) {
                    CircularGauge(
                        value: disk.percentUsed,
                        color: ModernColors.heatColor(percentage: disk.percentUsed),
                        size: 120,
                        lineWidth: 14,
                        showValue: true,
                        label: "full"
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text(disk.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(ModernColors.textPrimary)

                        detailRow(label: "Total Space", value: String(format: "%.0f GB", disk.totalGB), color: ModernColors.textPrimary)
                        detailRow(label: "Used", value: String(format: "%.0f GB", disk.usedGB), color: ModernColors.statusHigh)
                        detailRow(label: "Available", value: String(format: "%.0f GB", disk.availableGB), color: ModernColors.statusLow)
                        detailRow(label: "Mount Point", value: disk.mountPoint, color: ModernColors.textSecondary)
                        detailRow(label: "Filesystem", value: disk.filesystem, color: ModernColors.textTertiary)
                    }
                }
                .glassCard()
            }
        }
    }

    // MARK: - Network Bandwidth Detail View
    private var networkBandwidthDetailView: some View {
        VStack(spacing: 16) {
            ForEach(dataManager.systemStats.networkInterfaces) { interface in
                VStack(alignment: .leading, spacing: 12) {
                    Text(interface.name.uppercased())
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(ModernColors.cyan)

                    HStack(spacing: 20) {
                        VStack(spacing: 8) {
                            CircularGauge(
                                value: min(interface.downloadMBps * 10, 100.0),
                                color: ModernColors.statusLow,
                                size: 80,
                                lineWidth: 10,
                                showValue: false
                            )
                            Text("Download")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(ModernColors.textSecondary)
                            Text(String(format: "%.1f MB/s", interface.downloadMBps))
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(ModernColors.statusLow)
                        }

                        VStack(spacing: 8) {
                            CircularGauge(
                                value: min(interface.uploadMBps * 10, 100.0),
                                color: ModernColors.statusHigh,
                                size: 80,
                                lineWidth: 10,
                                showValue: false
                            )
                            Text("Upload")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(ModernColors.textSecondary)
                            Text(String(format: "%.1f MB/s", interface.uploadMBps))
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(ModernColors.statusHigh)
                        }
                    }

                    Divider().background(Color.white.opacity(0.2))

                    HStack {
                        detailRow(label: "Packets In", value: "\(interface.packetsIn)", color: ModernColors.statusLow)
                        Spacer()
                        detailRow(label: "Packets Out", value: "\(interface.packetsOut)", color: ModernColors.statusHigh)
                    }
                }
                .glassCard()
            }
        }
    }

    // MARK: - System Health Detail View
    private var systemHealthDetailView: some View {
        VStack(spacing: 16) {
            let cpuScore = max(0, 100 - dataManager.systemStats.totalCPU)
            let memScore = max(0, 100 - dataManager.systemStats.memoryUsagePercentage)
            let diskScore = dataManager.systemStats.disks.isEmpty ? 50.0 : dataManager.systemStats.disks.map { 100 - $0.percentUsed }.reduce(0, +) / Double(dataManager.systemStats.disks.count)
            let healthScore = (cpuScore * 0.4 + memScore * 0.3 + diskScore * 0.3)

            HStack(spacing: 20) {
                CircularGauge(
                    value: healthScore,
                    color: ModernColors.heatColor(percentage: 100 - healthScore),
                    size: 150,
                    lineWidth: 15,
                    showValue: true,
                    label: "health"
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Health Components")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(ModernColors.textSecondary)

                    detailRow(label: "CPU Health", value: String(format: "%.0f%%", cpuScore), color: ModernColors.cyan)
                    detailRow(label: "Memory Health", value: String(format: "%.0f%%", memScore), color: ModernColors.purple)
                    detailRow(label: "Disk Health", value: String(format: "%.0f%%", diskScore), color: ModernColors.orange)
                    detailRow(label: "Overall Score", value: String(format: "%.0f%%", healthScore), color: ModernColors.pink)
                }
            }
            .glassCard()

            VStack(alignment: .leading, spacing: 12) {
                Text("About System Health")
                    .modernHeader(size: .small)

                Text("System health is calculated from CPU usage (40%), memory usage (30%), and available disk space (30%). Higher scores indicate a healthier system with more available resources.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(ModernColors.textSecondary)
            }
            .glassCard()
        }
    }

    // MARK: - Helper Views
    private func detailRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(ModernColors.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(color)
        }
    }
}
