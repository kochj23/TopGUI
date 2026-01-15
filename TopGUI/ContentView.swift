//
//  ContentView.swift
//  TopGUI
//
//  Main dashboard with LCARS-inspired design
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
            // Black background
            LCARSColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // Main dashboard
                HStack(spacing: 20) {
                    // Left panel: System stats
                    VStack(spacing: 20) {
                        cpuPanel
                        memoryPanel
                    }
                    .frame(width: 350)

                    // Right panel: Process list
                    processListPanel
                }
                .padding(20)
            }
        }
        .sheet(item: $selectedProcess) { process in
            ProcessDetailView(process: process)
                .environmentObject(dataManager)
        }
    }

    private var header: some View {
        HStack {
            Text("TOP GUI")
                .lcarsHeader(color: LCARSColors.orange)

            Spacer()

            // System overview
            HStack(spacing: 20) {
                Text("PROCESSES: \(dataManager.systemStats.processes)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(LCARSColors.blue)

                Text("THREADS: \(dataManager.systemStats.threads)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(LCARSColors.violet)

                Text("RUNNING: \(dataManager.systemStats.runningProcesses)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(LCARSColors.yellow)
            }

            Spacer()

            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(dataManager.isRunning ? LCARSColors.statusLow : LCARSColors.red)
                    .frame(width: 12, height: 12)
                    .shadow(color: dataManager.isRunning ? LCARSColors.statusLow : LCARSColors.red, radius: 5)

                Text(dataManager.isRunning ? "ONLINE" : "OFFLINE")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(LCARSColors.textSecondary)
            }
        }
        .padding()
        .background(LCARSColors.panelBackground)
    }

    private var cpuPanel: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("CPU STATUS")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(LCARSColors.blue)
                .textCase(.uppercase)

            // CPU usage bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("TOTAL")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(LCARSColors.textSecondary)
                    Spacer()
                    Text(String(format: "%.1f%%", dataManager.systemStats.totalCPU))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(LCARSColors.heatColor(percentage: dataManager.systemStats.totalCPU))
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.3))

                        // Fill
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        LCARSColors.heatColor(percentage: dataManager.systemStats.totalCPU),
                                        LCARSColors.heatColor(percentage: dataManager.systemStats.totalCPU).opacity(0.7)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(min(dataManager.systemStats.totalCPU / 100.0, 1.0)))
                            .shadow(color: LCARSColors.heatColor(percentage: dataManager.systemStats.totalCPU), radius: 5)
                    }
                }
                .frame(height: 30)
            }

            Divider()
                .background(LCARSColors.blue.opacity(0.3))

            // Breakdown
            VStack(spacing: 8) {
                statRow(label: "USER", value: String(format: "%.1f%%", dataManager.systemStats.cpuUser), color: LCARSColors.orange)
                statRow(label: "SYSTEM", value: String(format: "%.1f%%", dataManager.systemStats.cpuSystem), color: LCARSColors.red)
                statRow(label: "IDLE", value: String(format: "%.1f%%", dataManager.systemStats.cpuIdle), color: LCARSColors.statusLow)
            }
        }
        .lcarsPanel(color: LCARSColors.blue)
    }

    private var memoryPanel: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("MEMORY STATUS")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(LCARSColors.violet)
                .textCase(.uppercase)

            VStack(spacing: 8) {
                statRow(label: "USED", value: dataManager.systemStats.memPhysUsed, color: LCARSColors.orange)
                statRow(label: "FREE", value: dataManager.systemStats.memPhysFree, color: LCARSColors.statusLow)
                statRow(label: "WIRED", value: dataManager.systemStats.memWired, color: LCARSColors.yellow)
                if !dataManager.systemStats.memCompressed.isEmpty {
                    statRow(label: "COMPRESSED", value: dataManager.systemStats.memCompressed, color: LCARSColors.blue)
                }
            }
        }
        .lcarsPanel(color: LCARSColors.violet)
    }

    private func statRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(LCARSColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
    }

    private var processListPanel: some View {
        VStack(spacing: 0) {
            // Search and controls
            HStack {
                TextField("SEARCH PROCESSES...", text: $searchText)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(LCARSColors.orange, lineWidth: 2)
                            )
                    )
                    .foregroundColor(LCARSColors.textPrimary)
                    .font(.system(size: 14, design: .monospaced))

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(LCARSColors.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 10)

            // Process table
            ScrollView {
                VStack(spacing: 0) {
                    // Header row
                    processTableHeader

                    // Process rows
                    ForEach(filteredAndSortedProcesses) { process in
                        processRow(process)
                            .onTapGesture {
                                selectedProcess = process
                            }
                    }
                }
            }
        }
        .lcarsPanel(color: LCARSColors.orange)
    }

    private var processTableHeader: some View {
        HStack(spacing: 10) {
            headerButton("PID", column: .pid, width: 60)
            headerButton("COMMAND", column: .command, width: 200)
            headerButton("CPU %", column: .cpu, width: 80)
            headerButton("MEM %", column: .memory, width: 80)
            headerButton("TIME", column: .time, width: 100)
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color.black.opacity(0.5))
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
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(sortColumn == column ? LCARSColors.yellow : LCARSColors.textSecondary)

                if sortColumn == column {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8))
                        .foregroundColor(LCARSColors.yellow)
                }
            }
            .frame(width: width, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func processRow(_ process: ProcessInfo) -> some View {
        HStack(spacing: 10) {
            Text("\(process.pid)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(LCARSColors.textPrimary)
                .frame(width: 60, alignment: .leading)

            Text(process.command)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(LCARSColors.textPrimary)
                .frame(width: 200, alignment: .leading)
                .lineLimit(1)

            Text(String(format: "%.1f", process.cpuUsage))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(LCARSColors.heatColor(percentage: process.cpuUsage))
                .frame(width: 80, alignment: .leading)

            Text(String(format: "%.1f", process.memUsage))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(LCARSColors.heatColor(percentage: process.memUsage))
                .frame(width: 80, alignment: .leading)

            Text(process.time)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(LCARSColors.textSecondary)
                .frame(width: 100, alignment: .leading)

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(selectedProcess?.pid == process.pid ? LCARSColors.blue.opacity(0.2) : Color.clear)
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
