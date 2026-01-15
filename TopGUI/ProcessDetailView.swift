//
//  ProcessDetailView.swift
//  TopGUI
//
//  Process detail view with modern glassmorphic styling
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
            // Glassmorphic background with floating blobs
            GlassmorphicBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    header

                    // Info cards
                    VStack(spacing: 16) {
                        basicInfoCard
                        resourceUsageCard
                        memoryInfoCard
                        controlCard
                    }
                    .padding(20)
                }
            }
        }
        .frame(width: 600, height: 700)
        .alert("Terminate Process?", isPresented: $showKillConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Terminate", role: .destructive) {
                dataManager.killProcess(process)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to terminate process \(process.pid) (\(process.command))? This action cannot be undone.")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Process Details")
                    .modernHeader(size: .large)

                Text(process.command)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(ModernColors.accent)
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

    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(ModernColors.accentBlue)

                Text("Basic Information")
                    .modernHeader(size: .medium)
            }

            Divider()
                .background(Color.white.opacity(0.2))

            VStack(spacing: 12) {
                detailRow(label: "Process ID", value: "\(process.pid)")
                detailRow(label: "Command", value: process.command)
                detailRow(label: "User", value: process.user)
                detailRow(label: "State", value: process.state)
                detailRow(label: "Time", value: process.time)
            }
        }
        .glassCard()
    }

    private var resourceUsageCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gauge.high")
                    .font(.system(size: 18))
                    .foregroundColor(ModernColors.accent)

                Text("Resource Usage")
                    .modernHeader(size: .medium)
            }

            Divider()
                .background(Color.white.opacity(0.2))

            // CPU usage
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("CPU Usage")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(ModernColors.textSecondary)

                    Spacer()

                    Text(String(format: "%.1f%%", process.cpuUsage))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(ModernColors.heatColor(percentage: process.cpuUsage))
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))

                        // Progress
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        ModernColors.heatColor(percentage: process.cpuUsage),
                                        ModernColors.heatColor(percentage: process.cpuUsage).opacity(0.7)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(min(process.cpuUsage / 100.0, 1.0)))
                            .shadow(color: ModernColors.heatColor(percentage: process.cpuUsage).opacity(0.6), radius: 8)
                    }
                }
                .frame(height: 24)
            }

            // Memory usage
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Memory Usage")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(ModernColors.textSecondary)

                    Spacer()

                    Text(String(format: "%.1f%%", process.memUsage))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(ModernColors.heatColor(percentage: process.memUsage))
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))

                        // Progress
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        ModernColors.heatColor(percentage: process.memUsage),
                                        ModernColors.heatColor(percentage: process.memUsage).opacity(0.7)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(min(process.memUsage / 100.0, 1.0)))
                            .shadow(color: ModernColors.heatColor(percentage: process.memUsage).opacity(0.6), radius: 8)
                    }
                }
                .frame(height: 24)
            }

            HStack(spacing: 20) {
                statBadge(label: "Threads", value: "\(process.threads)", color: ModernColors.accentBlue)
                statBadge(label: "Ports", value: "\(process.ports)", color: ModernColors.accentGreen)
            }
        }
        .glassCard()
    }

    private var memoryInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "memorychip.fill")
                    .font(.system(size: 18))
                    .foregroundColor(ModernColors.accentOrange)

                Text("Memory Details")
                    .modernHeader(size: .medium)
            }

            Divider()
                .background(Color.white.opacity(0.2))

            VStack(spacing: 12) {
                detailRow(label: "Physical Memory", value: process.memPhys)
                detailRow(label: "Virtual Memory", value: process.memVirt)
                detailRow(label: "Memory Regions", value: "\(process.memRegions)")
            }
        }
        .glassCard()
    }

    private var controlCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18))
                    .foregroundColor(ModernColors.accentGreen)

                Text("Process Control")
                    .modernHeader(size: .medium)
            }

            Divider()
                .background(Color.white.opacity(0.2))

            // Priority control
            VStack(alignment: .leading, spacing: 12) {
                Text("Priority (Nice Value)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(ModernColors.textSecondary)

                HStack(spacing: 12) {
                    Button(action: { niceValue = max(-20, niceValue - 1) }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 24))
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.accentBlue, style: .filled))

                    Text("\(niceValue)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(ModernColors.textPrimary)
                        .frame(minWidth: 50)

                    Button(action: { niceValue = min(20, niceValue + 1) }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.accentBlue, style: .filled))

                    Spacer()

                    Button(action: {
                        dataManager.changeProcessPriority(process, nice: niceValue)
                    }) {
                        Text("Apply")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .buttonStyle(ModernButtonStyle(color: ModernColors.accent, style: .filled))
                }
            }

            Divider()
                .background(Color.white.opacity(0.2))

            // Terminate button
            Button(action: { showKillConfirmation = true }) {
                HStack {
                    Image(systemName: "xmark.octagon.fill")
                        .font(.system(size: 16))

                    Text("Terminate Process")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(ModernButtonStyle(color: ModernColors.statusCritical, style: .destructive))
        }
        .glassCard()
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(ModernColors.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(ModernColors.textPrimary)
        }
    }

    private func statBadge(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(ModernColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}
