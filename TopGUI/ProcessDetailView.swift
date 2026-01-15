//
//  ProcessDetailView.swift
//  TopGUI
//
//  Detailed view for individual processes with LCARS styling
//
//  Created by Jordan Koch on 1/15/2026.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

struct ProcessDetailView: View {
    @EnvironmentObject var dataManager: TopDataManager
    @Environment(\.dismiss) var dismiss

    let process: ProcessInfo
    @State private var showKillConfirmation = false
    @State private var niceValue = 0

    var body: some View {
        ZStack {
            LCARSColors.background
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                header

                // Process details
                ScrollView {
                    VStack(spacing: 20) {
                        // Basic info
                        infoPanel

                        // Resource usage
                        resourcePanel

                        // Memory info
                        memoryPanel

                        // Control panel
                        controlPanel
                    }
                    .padding()
                }
            }
        }
        .frame(width: 700, height: 600)
        .alert("Kill Process?", isPresented: $showKillConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Kill", role: .destructive) {
                dataManager.killProcess(process)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to kill process \(process.pid) (\(process.command))? This action cannot be undone.")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("PROCESS DETAILS")
                    .lcarsHeader(color: LCARSColors.orange)

                Text(process.command)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(LCARSColors.blue)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(LCARSColors.red)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(LCARSColors.panelBackground)
    }

    private var infoPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BASIC INFORMATION")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(LCARSColors.blue)
                .textCase(.uppercase)

            Divider()
                .background(LCARSColors.blue.opacity(0.3))

            detailRow(label: "PROCESS ID", value: "\(process.pid)")
            detailRow(label: "COMMAND", value: process.command)
            detailRow(label: "USER", value: process.user)
            detailRow(label: "STATE", value: process.state)
            detailRow(label: "TIME", value: process.time)
        }
        .lcarsPanel(color: LCARSColors.blue)
    }

    private var resourcePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RESOURCE USAGE")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(LCARSColors.orange)
                .textCase(.uppercase)

            Divider()
                .background(LCARSColors.orange.opacity(0.3))

            // CPU usage with heat map
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("CPU USAGE")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(LCARSColors.textSecondary)
                    Spacer()
                    Text(String(format: "%.1f%%", process.cpuUsage))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(LCARSColors.heatColor(percentage: process.cpuUsage))
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.3))

                        RoundedRectangle(cornerRadius: 10)
                            .fill(LCARSColors.heatColor(percentage: process.cpuUsage))
                            .frame(width: geometry.size.width * CGFloat(min(process.cpuUsage / 100.0, 1.0)))
                            .shadow(color: LCARSColors.heatColor(percentage: process.cpuUsage), radius: 5)
                    }
                }
                .frame(height: 20)
            }

            // Memory usage with heat map
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("MEMORY USAGE")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(LCARSColors.textSecondary)
                    Spacer()
                    Text(String(format: "%.1f%%", process.memUsage))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(LCARSColors.heatColor(percentage: process.memUsage))
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.3))

                        RoundedRectangle(cornerRadius: 10)
                            .fill(LCARSColors.heatColor(percentage: process.memUsage))
                            .frame(width: geometry.size.width * CGFloat(min(process.memUsage / 100.0, 1.0)))
                            .shadow(color: LCARSColors.heatColor(percentage: process.memUsage), radius: 5)
                    }
                }
                .frame(height: 20)
            }

            detailRow(label: "THREADS", value: "\(process.threads)")
            detailRow(label: "PORTS", value: "\(process.ports)")
        }
        .lcarsPanel(color: LCARSColors.orange)
    }

    private var memoryPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MEMORY DETAILS")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(LCARSColors.violet)
                .textCase(.uppercase)

            Divider()
                .background(LCARSColors.violet.opacity(0.3))

            detailRow(label: "PHYSICAL", value: process.memPhys)
            detailRow(label: "VIRTUAL", value: process.memVirt)
            detailRow(label: "REGIONS", value: "\(process.memRegions)")
        }
        .lcarsPanel(color: LCARSColors.violet)
    }

    private var controlPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PROCESS CONTROL")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(LCARSColors.yellow)
                .textCase(.uppercase)

            Divider()
                .background(LCARSColors.yellow.opacity(0.3))

            // Priority control
            HStack {
                Text("PRIORITY (NICE)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(LCARSColors.textSecondary)

                Spacer()

                HStack(spacing: 10) {
                    Button("-") {
                        niceValue = max(-20, niceValue - 1)
                    }
                    .buttonStyle(LCARSButtonStyle(color: LCARSColors.blue))

                    Text("\(niceValue)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(LCARSColors.textPrimary)
                        .frame(width: 40)

                    Button("+") {
                        niceValue = min(20, niceValue + 1)
                    }
                    .buttonStyle(LCARSButtonStyle(color: LCARSColors.blue))

                    Button("APPLY") {
                        dataManager.changeProcessPriority(process, nice: niceValue)
                    }
                    .buttonStyle(LCARSButtonStyle(color: LCARSColors.yellow))
                }
            }

            Divider()
                .background(LCARSColors.yellow.opacity(0.3))

            // Kill button
            Button(action: { showKillConfirmation = true }) {
                HStack {
                    Image(systemName: "xmark.octagon.fill")
                    Text("TERMINATE PROCESS")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(LCARSButtonStyle(color: LCARSColors.red))
        }
        .lcarsPanel(color: LCARSColors.yellow)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(LCARSColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(LCARSColors.textPrimary)
        }
    }
}
