import SwiftUI

//
//  AIInsightsView.swift
//  TopGUI
//
//  AI-powered system insights interface with 4 features
//  Author: Jordan Koch
//  Date: 2026-01-21
//

struct AIInsightsView: View {
    @EnvironmentObject var dataManager: TopDataManager
    @StateObject private var aiAnalyzer = AISystemAnalyzer()
    @State private var selectedTab: Tab = .insights
    @State private var showingBackendSettings = false
    @State private var userQuestion = ""
    @State private var qaResponse = ""
    @State private var isProcessingQuestion = false

    enum Tab {
        case insights, anomalies, optimize, qa
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 28))
                    .foregroundColor(.cyan)

                Text("AI System Insights")
                    .font(.title)
                    .bold()

                Spacer()

                // Backend status
                HStack(spacing: 8) {
                    Circle()
                        .fill(AIBackendManager.shared.isOllamaAvailable ? Color.green : Color.red)
                        .frame(width: 8, height: 8)

                    Text(AIBackendManager.shared.activeBackend.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button {
                        showingBackendSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .buttonStyle(.bordered)
                }

                Button("Close") {
                    // Close handled by dismiss environment
                }
                .keyboardShortcut(.escape)
                .buttonStyle(.bordered)
            }
            .padding()

            Divider()

            // Tab Selector
            HStack(spacing: 0) {
                TabButton(title: "💡 Insights", isSelected: selectedTab == .insights) {
                    selectedTab = .insights
                }
                TabButton(title: "🚨 Anomalies", isSelected: selectedTab == .anomalies) {
                    selectedTab = .anomalies
                }
                TabButton(title: "🎯 Optimize", isSelected: selectedTab == .optimize) {
                    selectedTab = .optimize
                }
                TabButton(title: "💬 Ask AI", isSelected: selectedTab == .qa) {
                    selectedTab = .qa
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Divider()

            // Content
            ScrollView {
                Group {
                    switch selectedTab {
                    case .insights:
                        insightsTab
                    case .anomalies:
                        anomaliesTab
                    case .optimize:
                        optimizeTab
                    case .qa:
                        qaTab
                    }
                }
                .padding()
            }
        }
        .frame(width: 800, height: 700)
        .sheet(isPresented: $showingBackendSettings) {
            AIBackendSelectionView()
        }
        .task {
            // Refresh backends when view appears
            await AIBackendManager.shared.refreshAllBackends()

            // Generate initial insights
            await analyzeSystem()
        }
    }

    // MARK: - Insights Tab

    private var insightsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Analysis")
                .font(.title2)
                .bold()

            if aiAnalyzer.isAnalyzing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing system performance with AI...")
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if !aiAnalyzer.performanceInsights.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(aiAnalyzer.performanceInsights)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                        )

                    // System Health Score
                    if aiAnalyzer.systemHealthScore > 0 {
                        HStack {
                            Text("Overall Health Score:")
                                .font(.headline)

                            Spacer()

                            Text("\(aiAnalyzer.systemHealthScore)/100")
                                .font(.title2)
                                .bold()
                                .foregroundColor(healthColor(aiAnalyzer.systemHealthScore))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                }
            } else {
                Text("Click 'Analyze Now' to get AI-powered performance insights")
                    .foregroundColor(.secondary)
                    .padding()
            }

            Button {
                Task {
                    await analyzeSystem()
                }
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Analyze Now")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(aiAnalyzer.isAnalyzing || !AIBackendManager.shared.isOllamaAvailable)

            if let error = aiAnalyzer.lastError {
                Text("⚠️ \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }

    // MARK: - Anomalies Tab

    private var anomaliesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Anomaly Detection")
                .font(.title2)
                .bold()

            if aiAnalyzer.detectedAnomalies.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)

                    Text("No anomalies detected")
                        .font(.headline)

                    Text("Your system is operating within normal parameters")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                ForEach(aiAnalyzer.detectedAnomalies) { anomaly in
                    AnomalyCard(anomaly: anomaly)
                }
            }

            Button {
                Task {
                    await analyzeSystem()
                }
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Scan for Anomalies")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(aiAnalyzer.isAnalyzing)
        }
    }

    // MARK: - Optimize Tab

    private var optimizeTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Optimization Recommendations")
                .font(.title2)
                .bold()

            if aiAnalyzer.optimizationAdvice.isEmpty {
                Text("Run analysis to get AI-powered optimization recommendations")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(Array(aiAnalyzer.optimizationAdvice.enumerated()), id: \.offset) { index, advice in
                    OptimizationCard(advice: advice, number: index + 1)
                }
            }

            Button {
                Task {
                    await analyzeSystem()
                }
            } label: {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("Get Recommendations")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(aiAnalyzer.isAnalyzing)
        }
    }

    // MARK: - Q&A Tab

    private var qaTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ask AI About Your System")
                .font(.title2)
                .bold()

            // Suggested Questions
            Text("Suggested Questions:")
                .font(.headline)
                .padding(.top, 8)

            VStack(spacing: 8) {
                ForEach(suggestedQuestions, id: \.self) { question in
                    Button {
                        userQuestion = question
                        Task {
                            await askQuestion(question)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.cyan)
                            Text(question)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()
                .padding(.vertical, 8)

            // Custom Question
            Text("Or ask your own question:")
                .font(.headline)

            HStack {
                TextField("Ask a question about your system...", text: $userQuestion)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task {
                            await askQuestion(userQuestion)
                        }
                    }

                Button {
                    Task {
                        await askQuestion(userQuestion)
                    }
                } label: {
                    Image(systemName: isProcessingQuestion ? "arrow.circlepath" : "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(userQuestion.isEmpty || isProcessingQuestion)
            }

            // Response
            if !qaResponse.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.cyan)
                        Text("AI Answer:")
                            .font(.headline)
                    }

                    Text(qaResponse)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cyan.opacity(0.1))
                        )
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Helper Methods

    private func analyzeSystem() async {
        // Gather system data from TopDataManager
        let cpuUsage = dataManager.systemStats.cpuUser + dataManager.systemStats.cpuSystem
        let memoryUsagePercent = (100.0 - dataManager.systemStats.cpuIdle) // Rough estimate

        let currentData = SystemSnapshot(
            cpuUsage: cpuUsage,
            memoryUsage: parseMemoryValue(dataManager.systemStats.memPhysUsed),
            memoryTotal: parseMemoryValue(dataManager.systemStats.memPhysUsed) + parseMemoryValue(dataManager.systemStats.memPhysFree),
            memoryPressure: "Normal", // TopGUI doesn't track this directly
            loadAverages: (
                dataManager.systemStats.loadAvg1min,
                dataManager.systemStats.loadAvg5min,
                dataManager.systemStats.loadAvg15min
            ),
            topProcesses: dataManager.processes.prefix(10).map { process in
                (process.command, process.cpuUsage, process.memUsage)
            },
            diskUsage: [], // TopGUI doesn't expose disk usage in this format
            networkStats: (0, 0) // Would need to parse network strings
        )

        // Call all 4 AI features
        async let insights = aiAnalyzer.analyzeSystemPerformance(
            cpuUsage: currentData.cpuUsage,
            memoryUsage: (currentData.memoryUsage / currentData.memoryTotal) * 100,
            memoryPressure: currentData.memoryPressure,
            loadAverages: currentData.loadAverages,
            topProcesses: currentData.topProcesses,
            diskUsage: currentData.diskUsage,
            networkStats: currentData.networkStats
        )

        async let anomalies = aiAnalyzer.detectAnomalies(currentData: currentData, baseline: nil)

        async let optimizations = aiAnalyzer.generateOptimizationAdvice(currentData: currentData)

        // Wait for all to complete
        _ = await insights
        let detectedAnomalies = await anomalies
        let advice = await optimizations

        await MainActor.run {
            aiAnalyzer.detectedAnomalies = detectedAnomalies
            aiAnalyzer.optimizationAdvice = advice
        }
    }

    private func askQuestion(_ question: String) async {
        guard !question.isEmpty else { return }

        isProcessingQuestion = true
        defer { isProcessingQuestion = false }

        // Build context with current system state
        let cpuUsage = dataManager.systemStats.cpuUser + dataManager.systemStats.cpuSystem

        let context = """
        Current System State:
        - CPU: \(String(format: "%.1f", cpuUsage))%
        - Memory Used: \(dataManager.systemStats.memPhysUsed)
        - Memory Free: \(dataManager.systemStats.memPhysFree)
        - Load Averages: \(String(format: "%.2f", dataManager.systemStats.loadAvg1min)), \(String(format: "%.2f", dataManager.systemStats.loadAvg5min)), \(String(format: "%.2f", dataManager.systemStats.loadAvg15min))
        - Top CPU: \(dataManager.processes.prefix(3).map { "\($0.command) (\(String(format: "%.1f", $0.cpuUsage))%)" }.joined(separator: ", "))
        - Top Memory: \(dataManager.processes.sorted(by: { $0.memUsage > $1.memUsage }).prefix(3).map { "\($0.command) (\($0.memPhys))" }.joined(separator: ", "))
        """

        let response = await aiAnalyzer.askQuestion(question, context: context)

        await MainActor.run {
            qaResponse = response
        }
    }

    private func healthColor(_ score: Int) -> Color {
        if score >= 80 {
            return .green
        } else if score >= 60 {
            return .yellow
        } else if score >= 40 {
            return .orange
        } else {
            return .red
        }
    }

    private var suggestedQuestions: [String] {
        [
            "Why is my Mac slow?",
            "What's using all my CPU?",
            "Should I upgrade my RAM?",
            "How do I speed up my Mac?",
            "Is my memory usage normal?"
        ]
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue : Color.clear)
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Anomaly Card

struct AnomalyCard: View {
    let anomaly: SystemAnomaly

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Severity indicator
            Image(systemName: severityIcon)
                .font(.system(size: 32))
                .foregroundColor(severityColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(anomaly.type.rawValue.capitalized)
                        .font(.headline)

                    Spacer()

                    Text(anomaly.severity.rawValue.uppercased())
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(severityColor.opacity(0.2))
                        )
                        .foregroundColor(severityColor)
                }

                Text(anomaly.description)
                    .font(.body)

                if !anomaly.likelyCause.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                        Text("Likely Cause:")
                            .font(.caption)
                            .bold()
                        Text(anomaly.likelyCause)
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                }

                if !anomaly.recommendation.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                        Text("Recommendation:")
                            .font(.caption)
                            .bold()
                        Text(anomaly.recommendation)
                            .font(.caption)
                    }
                    .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(severityColor, lineWidth: 2)
                )
        )
    }

    private var severityIcon: String {
        switch anomaly.severity {
        case .low: return "info.circle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }

    private var severityColor: Color {
        switch anomaly.severity {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Optimization Card

struct OptimizationCard: View {
    let advice: OptimizationAdvice
    let number: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(number).")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.cyan)
                    .frame(width: 30)

                Text(advice.title)
                    .font(.headline)

                Spacer()

                // Impact badge
                HStack(spacing: 4) {
                    Text("Impact:")
                        .font(.caption)
                    Text(advice.impact.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(impactColor.opacity(0.2))
                        )
                        .foregroundColor(impactColor)
                }

                // Difficulty badge
                HStack(spacing: 4) {
                    Text("Difficulty:")
                        .font(.caption)
                    Text(advice.difficulty.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(difficultyColor.opacity(0.2))
                        )
                        .foregroundColor(difficultyColor)
                }
            }

            Text(advice.description)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            if !advice.reason.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Why this helps:")
                            .font(.caption)
                            .bold()
                        Text(advice.reason)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if !advice.action.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("How to do it:")
                            .font(.caption)
                            .bold()
                        Text(advice.action)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }

    private var impactColor: Color {
        switch advice.impact {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        }
    }

    private var difficultyColor: Color {
        switch advice.difficulty {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .red
        }
    }
}

// MARK: - Supporting Types
// (SystemSnapshot is defined in AISystemAnalyzer.swift)

// MARK: - Preview

#Preview {
    AIInsightsView()
        .environmentObject(TopDataManager())
}

// MARK: - Helper to parse memory strings

private func parseMemoryValue(_ memString: String) -> Double {
    // Parse strings like "8.2G", "1024M", etc.
    let scanner = Scanner(string: memString)
    var value: Double = 0

    if scanner.scanDouble(&value) {
        let unit = String(memString.suffix(1)).uppercased()

        switch unit {
        case "G":
            return value
        case "M":
            return value / 1024.0
        case "K":
            return value / (1024.0 * 1024.0)
        default:
            return value
        }
    }

    return 0
}
