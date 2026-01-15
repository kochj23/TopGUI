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
    @State private var searchText = ""
    @State private var sortColumn: SortColumn = .cpu
    @State private var sortAscending = false

    enum SortColumn {
        case pid, command, cpu, memory, time
    }

    // Grid columns - 3 columns for main stats
    let columns = [
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

                    // Main grid layout
                    LazyVGrid(columns: columns, spacing: 16) {
                        // Row 1: CPU, Memory, Load Averages
                        cpuCard
                        memoryCard
                        loadAveragesCard

                        // Row 2: Top CPU Processes, Top Memory Processes, Swap Usage
                        topCPUProcessesCard
                        topMemoryProcessesCard
                        swapUsageCard

                        // Row 3: Process States, Network Stats, Disk I/O
                        processStatesCard
                        networkStatsCard
                        diskIOCard
                    }
                    .padding(.horizontal, 20)

                    // Quick Actions (full width)
                    quickActionsCard
                        .padding(.horizontal, 20)

                    // Process List (full width)
                    processListCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
            }
        }
        .sheet(item: $selectedProcess) { process in
            ProcessDetailView(process: process)
                .environmentObject(dataManager)
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

    // MARK: - CPU Card
    private var cpuCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cpu")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernColors.cyan)

                Text("CPU")
                    .modernHeader(size: .medium)

                Spacer()

                Text(String(format: "%.1f%%", dataManager.systemStats.totalCPU))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(ModernColors.heatColor(percentage: dataManager.systemStats.totalCPU))
            }

            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: min(dataManager.systemStats.totalCPU / 100.0, 1.0))
                    .stroke(
                        ModernColors.heatColor(percentage: dataManager.systemStats.totalCPU),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: ModernColors.heatColor(percentage: dataManager.systemStats.totalCPU).opacity(0.6), radius: 8)

                VStack(spacing: 2) {
                    Text(String(format: "%.0f", dataManager.systemStats.totalCPU))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(ModernColors.textPrimary)

                    Text("percent")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(ModernColors.textSecondary)
                }
            }
            .frame(height: 100)

            Divider().background(Color.white.opacity(0.1))

            VStack(spacing: 6) {
                miniStatRow(label: "User", value: String(format: "%.1f%%", dataManager.systemStats.cpuUser), color: ModernColors.cyan)
                miniStatRow(label: "System", value: String(format: "%.1f%%", dataManager.systemStats.cpuSystem), color: ModernColors.purple)
                miniStatRow(label: "Idle", value: String(format: "%.1f%%", dataManager.systemStats.cpuIdle), color: ModernColors.statusLow)
            }
        }
        .glassCard()
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
            }

            VStack(spacing: 8) {
                miniStatRow(label: "Used", value: dataManager.systemStats.memPhysUsed, color: ModernColors.statusHigh)
                miniStatRow(label: "Free", value: dataManager.systemStats.memPhysFree, color: ModernColors.statusLow)
                miniStatRow(label: "Wired", value: dataManager.systemStats.memWired, color: ModernColors.cyan)
                if !dataManager.systemStats.memCompressed.isEmpty {
                    miniStatRow(label: "Compressed", value: dataManager.systemStats.memCompressed, color: ModernColors.purple)
                }
            }
        }
        .glassCard()
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

            VStack(spacing: 8) {
                miniStatRow(label: "1 min", value: String(format: "%.2f", dataManager.systemStats.loadAvg1min), color: ModernColors.statusLow)
                miniStatRow(label: "5 min", value: String(format: "%.2f", dataManager.systemStats.loadAvg5min), color: ModernColors.statusMedium)
                miniStatRow(label: "15 min", value: String(format: "%.2f", dataManager.systemStats.loadAvg15min), color: ModernColors.teal)
            }
        }
        .glassCard()
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

            VStack(spacing: 6) {
                ForEach(Array(dataManager.processes.prefix(5).enumerated()), id: \.element.id) { index, process in
                    HStack(spacing: 8) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(ModernColors.textTertiary)
                            .frame(width: 20)

                        Text(process.command)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(ModernColors.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text(String(format: "%.1f%%", process.cpuUsage))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(ModernColors.heatColor(percentage: process.cpuUsage))
                    }
                }
            }
        }
        .glassCard()
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

            VStack(spacing: 6) {
                ForEach(Array(dataManager.processes.sorted { $0.memUsage > $1.memUsage }.prefix(5).enumerated()), id: \.element.id) { index, process in
                    HStack(spacing: 8) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(ModernColors.textTertiary)
                            .frame(width: 20)

                        Text(process.command)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(ModernColors.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text(String(format: "%.1f%%", process.memUsage))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(ModernColors.heatColor(percentage: process.memUsage))
                    }
                }
            }
        }
        .glassCard()
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

            VStack(spacing: 8) {
                miniStatRow(label: "Swapins", value: dataManager.systemStats.swapUsed.isEmpty ? "0M" : dataManager.systemStats.swapUsed, color: ModernColors.statusHigh)
                miniStatRow(label: "Swapouts", value: dataManager.systemStats.swapFree.isEmpty ? "0M" : dataManager.systemStats.swapFree, color: ModernColors.statusLow)
            }
        }
        .glassCard()
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

            VStack(spacing: 8) {
                miniStatRow(label: "Running", value: "\(dataManager.systemStats.runningProcesses)", color: ModernColors.statusLow)
                miniStatRow(label: "Sleeping", value: "\(dataManager.systemStats.sleeping)", color: ModernColors.cyan)
                if dataManager.systemStats.stuckProcesses > 0 {
                    miniStatRow(label: "Stuck", value: "\(dataManager.systemStats.stuckProcesses)", color: ModernColors.statusCritical)
                }
                miniStatRow(label: "Threads", value: "\(dataManager.systemStats.threads)", color: ModernColors.purple)
            }
        }
        .glassCard()
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

                Text(String(format: "%.1f%%", process.cpuUsage))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(ModernColors.heatColor(percentage: process.cpuUsage))
            }
            .frame(width: 60, alignment: .leading)

            HStack(spacing: 4) {
                Circle()
                    .fill(ModernColors.heatColor(percentage: process.memUsage))
                    .frame(width: 6, height: 6)

                Text(String(format: "%.1f%%", process.memUsage))
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
