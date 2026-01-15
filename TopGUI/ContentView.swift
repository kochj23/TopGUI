//
//  ContentView.swift
//  TopGUI
//
//  Modern glassmorphic dashboard with purple gradients
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

    var body: some View {
        ZStack {
            // Glassmorphic background with floating blobs
            GlassmorphicBackground()

            VStack(spacing: 20) {
                // Header
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                // Main content
                HStack(spacing: 20) {
                    // Left sidebar: System stats
                    VStack(spacing: 20) {
                        cpuPanel
                        memoryPanel
                        systemInfoPanel
                    }
                    .frame(width: 320)

                    // Right panel: Process list
                    processListPanel
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .sheet(item: $selectedProcess) { process in
            ProcessDetailView(process: process)
                .environmentObject(dataManager)
        }
    }

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

            // Status indicator
            HStack(spacing: 12) {
                // Process count
                statusBadge(
                    icon: "cpu",
                    value: "\(dataManager.systemStats.processes)",
                    label: "processes",
                    color: ModernColors.accentBlue
                )

                // Running count
                statusBadge(
                    icon: "bolt.fill",
                    value: "\(dataManager.systemStats.runningProcesses)",
                    label: "running",
                    color: ModernColors.accentGreen
                )

                // Status indicator
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
                .fill(Color.white.opacity(0.1))
        )
    }

    private var cpuPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "cpu")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ModernColors.accent)

                Text("CPU Usage")
                    .modernHeader(size: .medium)

                Spacer()

                Text(String(format: "%.1f%%", dataManager.systemStats.totalCPU))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(ModernColors.heatColor(percentage: dataManager.systemStats.totalCPU))
            }

            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: min(dataManager.systemStats.totalCPU / 100.0, 1.0))
                    .stroke(
                        AngularGradient(
                            colors: [
                                ModernColors.statusLow,
                                ModernColors.statusMedium,
                                ModernColors.statusHigh,
                                ModernColors.statusCritical
                            ],
                            center: .center,
                            angle: .degrees(0)
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: ModernColors.heatColor(percentage: dataManager.systemStats.totalCPU).opacity(0.6), radius: 8)

                VStack(spacing: 4) {
                    Text(String(format: "%.0f", dataManager.systemStats.totalCPU))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(ModernColors.textPrimary)

                    Text("percent")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(ModernColors.textSecondary)
                }
            }
            .frame(height: 140)
            .padding(.vertical, 8)

            Divider()
                .background(Color.white.opacity(0.2))

            // Breakdown
            VStack(spacing: 10) {
                statRow(
                    label: "User",
                    value: String(format: "%.1f%%", dataManager.systemStats.cpuUser),
                    color: ModernColors.accentBlue
                )
                statRow(
                    label: "System",
                    value: String(format: "%.1f%%", dataManager.systemStats.cpuSystem),
                    color: ModernColors.accent
                )
                statRow(
                    label: "Idle",
                    value: String(format: "%.1f%%", dataManager.systemStats.cpuIdle),
                    color: ModernColors.statusLow
                )
            }
        }
        .glassCard()
    }

    private var memoryPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "memorychip")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ModernColors.accentOrange)

                Text("Memory")
                    .modernHeader(size: .medium)

                Spacer()
            }

            VStack(spacing: 10) {
                statRow(
                    label: "Used",
                    value: dataManager.systemStats.memPhysUsed,
                    color: ModernColors.statusHigh
                )
                statRow(
                    label: "Free",
                    value: dataManager.systemStats.memPhysFree,
                    color: ModernColors.statusLow
                )
                statRow(
                    label: "Wired",
                    value: dataManager.systemStats.memWired,
                    color: ModernColors.accentBlue
                )
                if !dataManager.systemStats.memCompressed.isEmpty {
                    statRow(
                        label: "Compressed",
                        value: dataManager.systemStats.memCompressed,
                        color: ModernColors.accent
                    )
                }
            }
        }
        .glassCard()
    }

    private var systemInfoPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernColors.accentGreen)

                Text("System")
                    .modernHeader(size: .small)
            }

            VStack(spacing: 8) {
                HStack {
                    Text("Threads")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(ModernColors.textSecondary)
                    Spacer()
                    Text("\(dataManager.systemStats.threads)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(ModernColors.textPrimary)
                }

                HStack {
                    Text("Sleeping")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(ModernColors.textSecondary)
                    Spacer()
                    Text("\(dataManager.systemStats.sleeping)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(ModernColors.textPrimary)
                }
            }
        }
        .glassCard()
    }

    private func statRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.6), radius: 4)

            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(ModernColors.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
    }

    private var processListPanel: some View {
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
                        .fill(Color.white.opacity(0.1))
                )

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(ModernColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 16)

            // Process table
            VStack(spacing: 0) {
                // Header
                processTableHeader
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))

                Divider()
                    .background(Color.white.opacity(0.1))

                // Process rows
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredAndSortedProcesses) { process in
                            processRow(process)
                                .onTapGesture {
                                    selectedProcess = process
                                }
                        }
                    }
                }
            }
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
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(sortColumn == column ? ModernColors.accent : ModernColors.textSecondary)

                if sortColumn == column {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(ModernColors.accent)
                }
            }
            .frame(width: width, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func processRow(_ process: ProcessInfo) -> some View {
        HStack(spacing: 12) {
            Text("\(process.pid)")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(ModernColors.textSecondary)
                .frame(width: 60, alignment: .leading)

            Text(process.command)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(ModernColors.textPrimary)
                .frame(width: 180, alignment: .leading)
                .lineLimit(1)

            Spacer()

            // CPU badge
            HStack(spacing: 4) {
                Circle()
                    .fill(ModernColors.heatColor(percentage: process.cpuUsage))
                    .frame(width: 6, height: 6)

                Text(String(format: "%.1f%%", process.cpuUsage))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(ModernColors.heatColor(percentage: process.cpuUsage))
            }
            .frame(width: 60, alignment: .leading)

            // Memory badge
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

    private var filteredAndSortedProcesses: [ProcessInfo] {
        var filtered = dataManager.processes

        // Filter by search
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.command.localizedCaseInsensitiveContains(searchText) ||
                "\($0.pid)".contains(searchText) ||
                $0.user.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Sort
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
