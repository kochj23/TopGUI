//
//  ContentView.swift
//  TopGUI
//
//  CleanMyMac-inspired dashboard with dark blue theme and grid layout
//
//  Created by Jordan Koch on 1/15/2026.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: TopDataManager
    @State private var selectedProcess: ProcessInfo?
    @State private var selectedCard: CardType?
    @State private var searchText = ""
    @State private var sortColumn: SortColumn = .cpu
    @State private var sortAscending = false
    @State private var showingAIInsights = false

    enum CardType: Identifiable {
        case cpu, memory, loadAverages, topCPU, topMemory, swap, states, memoryPressure, cpuInfo, perCore, diskActivity, networkBandwidth, systemHealth

        var id: String {
            switch self {
            case .cpu: return "cpu"
            case .memory: return "memory"
            case .loadAverages: return "load"
            case .topCPU: return "topCPU"
            case .topMemory: return "topMemory"
            case .swap: return "swap"
            case .states: return "states"
            case .memoryPressure: return "memoryPressure"
            case .cpuInfo: return "cpuInfo"
            case .perCore: return "perCore"
            case .diskActivity: return "diskActivity"
            case .networkBandwidth: return "networkBandwidth"
            case .systemHealth: return "systemHealth"
            }
        }
    }

    enum SortColumn {
        case pid, command, cpu, memory, time
    }

    // Grid columns - 4 columns for main stats
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            // Glassmorphic background with floating blobs
            GlassmorphicBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    // Main grid layout - 4 columns
                    LazyVGrid(columns: columns, spacing: 16) {
                        // All stat cards in 4-column grid
                        cpuCard
                        memoryCard
                        loadAveragesCard
                        topCPUProcessesCard

                        topMemoryProcessesCard
                        swapUsageCard
                        processStatesCard
                        memoryPressureCard

                        cpuCoresInfoCard
                        diskActivityCard
                        networkBandwidthCard
                        systemHealthCard
                    }
                    .padding(.horizontal, 20)

                    // Per-Core CPU Grid (full width)
                    perCoreCPUCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
        }
        .sheet(item: $selectedProcess) { process in
            ProcessDetailView(process: process)
                .environmentObject(dataManager)
        }
        .sheet(item: $selectedCard) { cardType in
            CardDetailView(cardType: cardType)
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingAIInsights) {
            AIInsightsView()
                .environmentObject(dataManager)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAIInsights)) { _ in
            showingAIInsights = true
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("TopGUI")
                    .modernHeader(size: .large)

                Text("System Monitor")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(ModernColors.textSecondary)
            }

            Spacer()

            // Status indicators
            HStack(spacing: 12) {
                statusBadge(
                    icon: "cpu",
                    value: "\(dataManager.systemStats.processes)",
                    label: "processes",
                    color: ModernColors.cyan
                )

                statusBadge(
                    icon: "bolt.fill",
                    value: "\(dataManager.systemStats.runningProcesses)",
                    label: "running",
                    color: ModernColors.accentGreen
                )

                Circle()
                    .fill(dataManager.isRunning ? ModernColors.statusLow : ModernColors.statusCritical)
                    .frame(width: 10, height: 10)
                    .shadow(color: dataManager.isRunning ? ModernColors.statusLow : ModernColors.statusCritical, radius: 5)

                // AI Insights Button
                Button {
                    showingAIInsights = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 14))
                        Text("AI Insights")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.cyan.opacity(0.2))
                    )
                    .foregroundColor(.cyan)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func statusBadge(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(ModernColors.textPrimary)

                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(ModernColors.textSecondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: - CPU Card (with GPU)
    private var cpuCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cpu")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernColors.cyan)

                Text("CPU & GPU")
                    .modernHeader(size: .medium)

                Spacer()
            }

            // Two circular dials: CPU and GPU side by side
            HStack(spacing: 20) {
                // CPU Dial
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 8)

                        Circle()
                            .trim(from: 0, to: min(dataManager.systemStats.totalCPU / 100.0, 1.0))
                            .stroke(
                                ModernColors.heatColor(percentage: dataManager.systemStats.totalCPU),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .shadow(color: ModernColors.heatColor(percentage: dataManager.systemStats.totalCPU).opacity(0.6), radius: 6)

                        VStack(spacing: 2) {
                            Text(String(format: "%.0f", dataManager.systemStats.totalCPU))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(ModernColors.textPrimary)

                            Text("CPU")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundColor(ModernColors.textSecondary)
                        }
                    }
                    .frame(width: 80, height: 80)
                }

                // GPU Dial
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 8)

                        Circle()
                            .trim(from: 0, to: min(dataManager.systemStats.gpuUsage / 100.0, 1.0))
                            .stroke(
                                ModernColors.heatColor(percentage: dataManager.systemStats.gpuUsage),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .shadow(color: ModernColors.heatColor(percentage: dataManager.systemStats.gpuUsage).opacity(0.6), radius: 6)

                        VStack(spacing: 2) {
                            Text(String(format: "%.0f", dataManager.systemStats.gpuUsage))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(ModernColors.textPrimary)

                            Text("GPU")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundColor(ModernColors.textSecondary)
                        }
                    }
                    .frame(width: 80, height: 80)
                }

                Spacer()
            }

            Divider().background(Color.white.opacity(0.1))

            VStack(spacing: 6) {
                miniStatRow(label: "User", value: String(format: "%.0f%%", dataManager.systemStats.cpuUser), color: ModernColors.cyan)
                miniStatRow(label: "System", value: String(format: "%.0f%%", dataManager.systemStats.cpuSystem), color: ModernColors.purple)
                miniStatRow(label: "Idle", value: String(format: "%.0f%%", dataManager.systemStats.cpuIdle), color: ModernColors.statusLow)
            }

            Spacer(minLength: 0)
        }
        .frame(height: 220, alignment: .top)
        .glassCard()
        .onTapGesture {
            selectedCard = .cpu
        }
    }

    // MARK: - Memory Card
    private var memoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "memorychip")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernColors.purple)

                Text("Memory")
                    .modernHeader(size: .medium)

                Spacer()

                Text(String(format: "%.0f%%", dataManager.systemStats.memoryUsagePercentage))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(ModernColors.heatColor(percentage: dataManager.systemStats.memoryUsagePercentage))
            }

            // Circular gauge
            HStack {
                CircularGauge(
                    value: dataManager.systemStats.memoryUsagePercentage,
                    color: ModernColors.heatColor(percentage: dataManager.systemStats.memoryUsagePercentage),
                    size: 100,
                    lineWidth: 10,
                    showValue: false
                )

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    miniStatRow(label: "Used", value: dataManager.systemStats.memPhysUsed, color: ModernColors.statusHigh)
                    miniStatRow(label: "Free", value: dataManager.systemStats.memPhysFree, color: ModernColors.statusLow)
                    miniStatRow(label: "Wired", value: dataManager.systemStats.memWired, color: ModernColors.cyan)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: 220, alignment: .top)
        .glassCard()
        .onTapGesture {
            selectedCard = .memory
        }
    }

    // MARK: - Load Averages Card
    private var loadAveragesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernColors.teal)

                Text("Load")
                    .modernHeader(size: .medium)

                Spacer()
            }

            // Three larger dials for load averages
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    CircularGauge(
                        value: dataManager.systemStats.loadPercentage(cores: dataManager.systemStats.cpuCores),
                        color: ModernColors.statusLow,
                        size: 65,
                        lineWidth: 7,
                        showValue: false
                    )
                    Text("1 min")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(ModernColors.textSecondary)
                    Text(String(format: "%.1f", dataManager.systemStats.loadAvg1min))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(ModernColors.statusLow)
                }

                VStack(spacing: 4) {
                    CircularGauge(
                        value: dataManager.systemStats.cpuCores > 0 ? min((dataManager.systemStats.loadAvg5min / Double(dataManager.systemStats.cpuCores)) * 100.0, 100.0) : 0,
                        color: ModernColors.statusMedium,
                        size: 65,
                        lineWidth: 7,
                        showValue: false
                    )
                    Text("5 min")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(ModernColors.textSecondary)
                    Text(String(format: "%.1f", dataManager.systemStats.loadAvg5min))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(ModernColors.statusMedium)
                }

                VStack(spacing: 4) {
                    CircularGauge(
                        value: dataManager.systemStats.cpuCores > 0 ? min((dataManager.systemStats.loadAvg15min / Double(dataManager.systemStats.cpuCores)) * 100.0, 100.0) : 0,
                        color: ModernColors.teal,
                        size: 65,
                        lineWidth: 7,
                        showValue: false
                    )
                    Text("15 min")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(ModernColors.textSecondary)
                    Text(String(format: "%.1f", dataManager.systemStats.loadAvg15min))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(ModernColors.teal)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: 220, alignment: .top)
        .glassCard()
        .onTapGesture {
            selectedCard = .loadAverages
        }
    }

    // MARK: - Top CPU Processes Card
    private var topCPUProcessesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernColors.orange)

                Text("Top CPU")
                    .modernHeader(size: .medium)

                Spacer()
            }

            // Single dial showing % of total CPU capacity used by top 5
            let top5CPU = dataManager.processes.prefix(5).reduce(0.0) { $0 + $1.cpuUsage }
            let totalCapacity = Double(dataManager.systemStats.cpuCores) * 100.0
            let percentOfCapacity = totalCapacity > 0 ? (top5CPU / totalCapacity) * 100.0 : 0
            HStack {
                CircularGauge(
                    value: min(percentOfCapacity, 100.0),
                    color: ModernColors.orange,
                    size: 80,
                    lineWidth: 8,
                    showValue: true,
                    label: "capacity"
                )

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    ForEach(Array(dataManager.processes.prefix(5).enumerated()), id: \.element.id) { index, process in
                        HStack(spacing: 6) {
                            Text(process.command)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(ModernColors.textPrimary)
                                .lineLimit(1)

                            Text(String(format: "%.0f%%", process.cpuUsage))
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(ModernColors.heatColor(percentage: process.cpuUsage))
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: 220, alignment: .top)
        .glassCard()
        .onTapGesture {
            selectedCard = .topCPU
        }
    }

    // MARK: - Top Memory Processes Card
    private var topMemoryProcessesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "memorychip.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernColors.pink)

                Text("Top Memory")
                    .modernHeader(size: .medium)

                Spacer()
            }

            // Single dial showing top 5 vs rest
            let top5Memory = dataManager.processes.sorted { $0.memUsage > $1.memUsage }.prefix(5).reduce(0.0) { $0 + $1.memUsage }
            HStack {
                CircularGauge(
                    value: min(top5Memory, 100.0),
                    color: ModernColors.pink,
                    size: 80,
                    lineWidth: 8,
                    showValue: true,
                    label: "top 5"
                )

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    ForEach(Array(dataManager.processes.sorted { $0.memUsage > $1.memUsage }.prefix(5).enumerated()), id: \.element.id) { index, process in
                        HStack(spacing: 6) {
                            Text(process.command)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(ModernColors.textPrimary)
                                .lineLimit(1)

                            Text(String(format: "%.0f%%", process.memUsage))
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(ModernColors.heatColor(percentage: process.memUsage))
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: 220, alignment: .top)
        .glassCard()
        .onTapGesture {
            selectedCard = .topMemory
        }
    }

    // MARK: - Swap Usage Card
    private var swapUsageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernColors.yellow)

                Text("Swap")
                    .modernHeader(size: .medium)

                Spacer()
            }

            // Dial showing swap usage percentage
            HStack {
                let swapUsedNum = Double(dataManager.systemStats.swapUsed.filter { $0.isNumber || $0 == "." }) ?? 0
                let swapTotalNum = Double(dataManager.systemStats.swapTotal.filter { $0.isNumber || $0 == "." }) ?? 0
                let swapPercent = swapTotalNum > 0 ? (swapUsedNum / swapTotalNum) * 100.0 : 0

                CircularGauge(
                    value: swapPercent,
                    color: ModernColors.heatColor(percentage: swapPercent),
                    size: 80,
                    lineWidth: 8,
                    showValue: true,
                    label: "used"
                )

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    miniStatRow(label: "Used", value: formatSwapValue(dataManager.systemStats.swapUsed), color: ModernColors.statusHigh)
                    miniStatRow(label: "Free", value: formatSwapValue(dataManager.systemStats.swapFree), color: ModernColors.statusLow)
                    miniStatRow(label: "Total", value: formatSwapValue(dataManager.systemStats.swapTotal), color: ModernColors.yellow)
                    if swapTotalNum == 0 {
                        Text("No swap file")
                            .font(.system(size: 9, design: .rounded))
                            .foregroundColor(ModernColors.textTertiary)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: 220, alignment: .top)
        .glassCard()
        .onTapGesture {
            selectedCard = .swap
        }
    }

    // MARK: - Process States Card
    private var processStatesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernColors.accentGreen)

                Text("States")
                    .modernHeader(size: .medium)

                Spacer()
            }

            HStack(spacing: 12) {
                // Circular gauge showing running/sleeping ratio
                let runningPercent = dataManager.systemStats.processes > 0 ? (Double(dataManager.systemStats.runningProcesses) / Double(dataManager.systemStats.processes)) * 100.0 : 0
                CircularGauge(
                    value: runningPercent,
                    color: ModernColors.statusLow,
                    size: 80,
                    lineWidth: 8,
                    showValue: true,
                    label: "running"
                )

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    miniStatRow(label: "Running", value: "\(dataManager.systemStats.runningProcesses)", color: ModernColors.statusLow)
                    miniStatRow(label: "Sleeping", value: "\(dataManager.systemStats.sleeping)", color: ModernColors.cyan)
                    if dataManager.systemStats.stuckProcesses > 0 {
                        miniStatRow(label: "Stuck", value: "\(dataManager.systemStats.stuckProcesses)", color: ModernColors.statusCritical)
                    }
                    miniStatRow(label: "Total", value: "\(dataManager.systemStats.processes)", color: ModernColors.textSecondary)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: 220, alignment: .top)
        .glassCard()
        .onTapGesture {
            selectedCard = .states
        }
    }

    // MARK: - Network Stats Card
    private var networkStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "network")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernColors.cyan)

                Text("Network")
                    .modernHeader(size: .medium)

                Spacer()
            }

            VStack(spacing: 8) {
                miniStatRow(label: "Packets In", value: dataManager.systemStats.networkPacketsIn.isEmpty ? "N/A" : dataManager.systemStats.networkPacketsIn, color: ModernColors.statusLow)
                miniStatRow(label: "Packets Out", value: dataManager.systemStats.networkPacketsOut.isEmpty ? "N/A" : dataManager.systemStats.networkPacketsOut, color: ModernColors.statusHigh)
            }
        }
        .glassCard()
    }

    // MARK: - Disk I/O Card
    private var diskIOCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "internaldrive")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernColors.orange)

                Text("Disk I/O")
                    .modernHeader(size: .medium)

                Spacer()
            }

            VStack(spacing: 8) {
                miniStatRow(label: "Reads", value: dataManager.systemStats.diskReads.isEmpty ? "N/A" : dataManager.systemStats.diskReads, color: ModernColors.cyan)
                miniStatRow(label: "Writes", value: dataManager.systemStats.diskWrites.isEmpty ? "N/A" : dataManager.systemStats.diskWrites, color: ModernColors.purple)
            }
        }
        .glassCard()
    }

    // MARK: - Memory Pressure Card
    private var memoryPressureCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gauge.with.dots.needle.50percent")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernColors.teal)

                Text("Memory Pressure")
                    .modernHeader(size: .medium)

                Spacer()
            }

            // Dial showing memory pressure (active pages percentage)
            HStack {
                let activeNum = Double(dataManager.systemStats.memPagesActive.filter { $0.isNumber }) ?? 0
                let totalPages = activeNum + (Double(dataManager.systemStats.memPagesFree.filter { $0.isNumber }) ?? 0)
                let pressurePercent = totalPages > 0 ? (activeNum / totalPages) * 100.0 : 0

                CircularGauge(
                    value: pressurePercent,
                    color: ModernColors.heatColor(percentage: pressurePercent),
                    size: 80,
                    lineWidth: 8,
                    showValue: false
                )

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    miniStatRow(label: "Active", value: dataManager.systemStats.memPagesActive, color: ModernColors.statusHigh)
                    miniStatRow(label: "Inactive", value: dataManager.systemStats.memPagesInactive, color: ModernColors.cyan)
                    miniStatRow(label: "Wired", value: dataManager.systemStats.memPagesWired, color: ModernColors.purple)
                    miniStatRow(label: "Free", value: dataManager.systemStats.memPagesFree, color: ModernColors.statusLow)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: 220, alignment: .top)
        .glassCard()
        .onTapGesture {
            selectedCard = .memoryPressure
        }
    }

    // MARK: - CPU Cores Info Card
    private var cpuCoresInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernColors.accentBlue)

                Text("CPU Info")
                    .modernHeader(size: .medium)

                Spacer()
            }

            // Dial showing overall system CPU usage
            HStack {
                let systemCPU = dataManager.systemStats.totalCPU

                CircularGauge(
                    value: systemCPU,
                    color: ModernColors.heatColor(percentage: systemCPU),
                    size: 80,
                    lineWidth: 8,
                    showValue: true,
                    label: "system"
                )

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    miniStatRow(label: "Cores", value: "\(dataManager.systemStats.cpuCores)", color: ModernColors.cyan)
                    miniStatRow(label: "Threads", value: "\(dataManager.systemStats.threads)", color: ModernColors.purple)
                    miniStatRow(label: "Processes", value: "\(dataManager.systemStats.processes)", color: ModernColors.purple)
                    miniStatRow(label: "Running", value: "\(dataManager.systemStats.runningProcesses)", color: ModernColors.statusLow)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: 220, alignment: .top)
        .glassCard()
        .onTapGesture {
            selectedCard = .cpuInfo
        }
    }

    // MARK: - Per-Core CPU Grid Card
    private var perCoreCPUCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernColors.cyan)

                Text("Per-Core CPU Usage")
                    .modernHeader(size: .medium)

                Spacer()

                Text("\(dataManager.systemStats.perCoreCPU.count) cores")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(ModernColors.textSecondary)
            }

            // Grid of CPU cores (8 columns for 32 cores)
            let coreColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 8)
            LazyVGrid(columns: coreColumns, spacing: 8) {
                ForEach(Array(dataManager.systemStats.perCoreCPU.enumerated()), id: \.offset) { index, usage in
                    VStack(spacing: 4) {
                        MiniGauge(
                            value: usage,
                            color: ModernColors.heatColor(percentage: usage)
                        )

                        Text("\(index)")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(ModernColors.textTertiary)
                    }
                }
            }
        }
        .glassCard(prominent: true)
        .onTapGesture {
            selectedCard = .perCore
        }
    }

    // MARK: - Disk Usage Card
    private var diskActivityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "internaldrive.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernColors.orange)

                Text("Disk Usage")
                    .modernHeader(size: .medium)

                Spacer()
            }

            if dataManager.systemStats.disks.isEmpty {
                Text("Loading disk data...")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(ModernColors.textSecondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(dataManager.systemStats.disks.prefix(3)) { disk in
                        HStack(spacing: 8) {
                            MiniGauge(
                                value: disk.percentUsed,
                                color: ModernColors.heatColor(percentage: disk.percentUsed)
                            )
                            .id(disk.mountPoint) // Stable ID prevents recreation

                            VStack(alignment: .leading, spacing: 2) {
                                Text(disk.name)
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(ModernColors.textPrimary)
                                    .lineLimit(1)

                                HStack(spacing: 8) {
                                    Text("\(String(format: "%.0f", disk.usedGB)) GB used")
                                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                                        .foregroundColor(ModernColors.statusHigh)

                                    Text("of \(String(format: "%.0f", disk.totalGB)) GB")
                                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                                        .foregroundColor(ModernColors.textSecondary)
                                }
                            }

                            Spacer()

                            Text("\(String(format: "%.0f", disk.percentUsed))%")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(ModernColors.heatColor(percentage: disk.percentUsed))
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: 220, alignment: .top)
        .glassCard()
        .onTapGesture {
            selectedCard = .diskActivity
        }
    }

    // MARK: - Network Bandwidth Card
    private var networkBandwidthCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wifi.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernColors.accentGreen)

                Text("Network")
                    .modernHeader(size: .medium)

                Spacer()
            }

            // Single dial showing combined network usage
            HStack {
                let totalDownload = dataManager.systemStats.networkInterfaces.reduce(0.0) { $0 + $1.downloadMBps }
                let totalUpload = dataManager.systemStats.networkInterfaces.reduce(0.0) { $0 + $1.uploadMBps }
                let totalBandwidth = totalDownload + totalUpload
                let bandwidthPercent = min(totalBandwidth * 10.0, 100.0) // Scale to percentage

                CircularGauge(
                    value: bandwidthPercent,
                    color: ModernColors.accentGreen,
                    size: 80,
                    lineWidth: 8,
                    showValue: false
                )

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    miniStatRow(label: "Download", value: String(format: "%.0f MB/s", totalDownload), color: ModernColors.statusLow)
                    miniStatRow(label: "Upload", value: String(format: "%.0f MB/s", totalUpload), color: ModernColors.statusHigh)
                    miniStatRow(label: "Total", value: String(format: "%.0f MB/s", totalBandwidth), color: ModernColors.accentGreen)
                    miniStatRow(label: "Interfaces", value: "\(dataManager.systemStats.networkInterfaces.count)", color: ModernColors.textSecondary)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: 220, alignment: .top)
        .glassCard()
        .onTapGesture {
            selectedCard = .networkBandwidth
        }
    }

    // MARK: - System Health Card
    private var systemHealthCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernColors.pink)

                Text("System Health")
                    .modernHeader(size: .medium)

                Spacer()
            }

            // Calculate overall health score
            HStack {
                let cpuScore = max(0, 100 - dataManager.systemStats.totalCPU)
                let memScore = max(0, 100 - dataManager.systemStats.memoryUsagePercentage)
                let diskScore = dataManager.systemStats.disks.isEmpty ? 50.0 : dataManager.systemStats.disks.map { 100 - $0.percentUsed }.reduce(0, +) / Double(dataManager.systemStats.disks.count)
                let healthScore = (cpuScore * 0.4 + memScore * 0.3 + diskScore * 0.3)

                CircularGauge(
                    value: healthScore,
                    color: ModernColors.heatColor(percentage: 100 - healthScore),
                    size: 80,
                    lineWidth: 8,
                    showValue: true,
                    label: "health"
                )

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    miniStatRow(label: "CPU", value: String(format: "%.0f%%", cpuScore), color: ModernColors.cyan)
                    miniStatRow(label: "Memory", value: String(format: "%.0f%%", memScore), color: ModernColors.purple)
                    miniStatRow(label: "Disk", value: String(format: "%.0f%%", diskScore), color: ModernColors.orange)
                    miniStatRow(label: "Overall", value: String(format: "%.0f%%", healthScore), color: ModernColors.pink)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: 220, alignment: .top)
        .glassCard()
        .onTapGesture {
            selectedCard = .systemHealth
        }
    }

    // MARK: - Quick Actions Card
    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernColors.yellow)

                Text("Quick Actions")
                    .modernHeader(size: .medium)

                Spacer()
            }

            HStack(spacing: 12) {
                Button(action: {
                    // Kill high CPU process
                    if let topProcess = dataManager.processes.first {
                        dataManager.killProcess(topProcess)
                    }
                }) {
                    HStack {
                        Image(systemName: "flame.fill")
                        Text("Kill High CPU")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ModernButtonStyle(color: ModernColors.statusCritical, style: .filled))

                Button(action: {
                    // Refresh
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ModernButtonStyle(color: ModernColors.cyan, style: .filled))

                Button(action: {
                    // Export (future feature)
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ModernButtonStyle(color: ModernColors.purple, style: .filled))
            }
        }
        .glassCard()
    }

    // MARK: - Process List Card
    private var processListCard: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(ModernColors.textSecondary)
                        .font(.system(size: 14))

                    TextField("Search processes...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(ModernColors.textPrimary)
                        .font(.system(size: 14, design: .rounded))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                )

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(ModernColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)

            // Process table
            ScrollView {
                VStack(spacing: 0) {
                    // Header row
                    processTableHeader
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.05))

                    Divider().background(Color.white.opacity(0.1))

                    // Process rows
                    ForEach(filteredAndSortedProcesses.prefix(20)) { process in
                        processRow(process)
                            .onTapGesture {
                                selectedProcess = process
                            }
                    }
                }
            }
            .frame(height: 400)
        }
        .glassCard(prominent: true)
    }

    private var processTableHeader: some View {
        HStack(spacing: 12) {
            headerButton("PID", column: .pid, width: 60)
            headerButton("Process", column: .command, width: 180)
            Spacer()
            headerButton("CPU", column: .cpu, width: 60)
            headerButton("Memory", column: .memory, width: 70)
            headerButton("Time", column: .time, width: 80)
        }
    }

    private func headerButton(_ title: String, column: SortColumn, width: CGFloat) -> some View {
        Button(action: {
            if sortColumn == column {
                sortAscending.toggle()
            } else {
                sortColumn = column
                sortAscending = false
            }
        }) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(sortColumn == column ? ModernColors.cyan : ModernColors.textSecondary)

                if sortColumn == column {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(ModernColors.cyan)
                }
            }
            .frame(width: width, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func processRow(_ process: ProcessInfo) -> some View {
        HStack(spacing: 12) {
            Text("\(process.pid)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(ModernColors.textSecondary)
                .frame(width: 60, alignment: .leading)

            Text(process.command)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(ModernColors.textPrimary)
                .frame(width: 180, alignment: .leading)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 4) {
                Circle()
                    .fill(ModernColors.heatColor(percentage: process.cpuUsage))
                    .frame(width: 6, height: 6)

                Text(String(format: "%.0f%%", process.cpuUsage))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(ModernColors.heatColor(percentage: process.cpuUsage))
            }
            .frame(width: 60, alignment: .leading)

            HStack(spacing: 4) {
                Circle()
                    .fill(ModernColors.heatColor(percentage: process.memUsage))
                    .frame(width: 6, height: 6)

                Text(String(format: "%.0f%%", process.memUsage))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(ModernColors.heatColor(percentage: process.memUsage))
            }
            .frame(width: 70, alignment: .leading)

            Text(process.time)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(ModernColors.textSecondary)
                .frame(width: 80, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            selectedProcess?.pid == process.pid ?
            Color.white.opacity(0.1) : Color.clear
        )
        .contentShape(Rectangle())
    }

    // MARK: - Helper Functions
    private func formatSwapValue(_ value: String) -> String {
        // Input: "0.00M" or "2.50G"
        // Output: "0 MB" or "3 GB"
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

    // MARK: - Helper Views
    private func miniStatRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(0.6), radius: 3)

            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(ModernColors.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
    }

    private var filteredAndSortedProcesses: [ProcessInfo] {
        var filtered = dataManager.processes

        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.command.localizedCaseInsensitiveContains(searchText) ||
                "\($0.pid)".contains(searchText) ||
                $0.user.localizedCaseInsensitiveContains(searchText)
            }
        }

        filtered.sort { lhs, rhs in
            let result: Bool
            switch sortColumn {
            case .pid:
                result = lhs.pid < rhs.pid
            case .command:
                result = lhs.command < rhs.command
            case .cpu:
                result = lhs.cpuUsage < rhs.cpuUsage
            case .memory:
                result = lhs.memUsage < rhs.memUsage
            case .time:
                result = lhs.time < rhs.time
            }
            return sortAscending ? result : !result
        }

        return filtered
    }
}
