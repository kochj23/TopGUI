//
//  AISystemAnalyzer.swift
//  TopGUI
//
//  AI-powered system performance analysis
//  Supports Ollama, MLX Toolkit, and TinyLLM by Jason Cox
//  Author: Jordan Koch
//  Date: 2025-01-17
//
//  THIRD-PARTY ATTRIBUTION:
//  - TinyLLM by Jason Cox (https://github.com/jasonacox/TinyLLM)
//

import Foundation
import SwiftUI

/// AI-powered system performance analyzer
@MainActor
class AISystemAnalyzer: ObservableObject {
    @Published var isAnalyzing = false
    @Published var performanceInsights: String = ""
    @Published var detectedAnomalies: [SystemAnomaly] = []
    @Published var optimizationAdvice: [OptimizationAdvice] = []
    @Published var systemHealthScore: Int = 0
    @Published var lastError: String?

    private let aiBackend = AIBackendManager.shared
    private var baselineData: SystemBaseline?

    // MARK: - Feature 1: AI Performance Insights

    /// Generate natural language performance insights
    func analyzeSystemPerformance(
        cpuUsage: Double,
        memoryUsage: Double,
        memoryPressure: String,
        loadAverages: (one: Double, five: Double, fifteen: Double),
        topProcesses: [(name: String, cpu: Double, memory: Double)],
        diskUsage: [(name: String, used: Double, total: Double)],
        networkStats: (download: Double, upload: Double)
    ) async -> String {
        guard aiBackend.isOllamaAvailable || aiBackend.isTinyLLMAvailable || aiBackend.isTinyChatAvailable || aiBackend.isOpenWebUIAvailable else {
            return generateBasicInsights(cpu: cpuUsage, memory: memoryUsage, pressure: memoryPressure)
        }

        isAnalyzing = true
        defer { isAnalyzing = false }

        let context = buildSystemContext(
            cpuUsage: cpuUsage,
            memoryUsage: memoryUsage,
            memoryPressure: memoryPressure,
            loadAverages: loadAverages,
            topProcesses: topProcesses,
            diskUsage: diskUsage,
            networkStats: networkStats
        )

        let prompt = """
        Analyze this Mac's system performance and explain in 3-4 sentences what's happening and why.
        Be specific, mention actual processes and numbers, focus on issues if any.

        SYSTEM DATA:
        \(context)

        Provide clear, actionable insights in plain language.
        """

        do {
            let insights = try await aiBackend.generate(
                prompt: prompt,
                systemPrompt: "You are a macOS performance expert. Explain system performance in simple, clear language.",
                temperature: 0.4,
                maxTokens: 300
            )

            await MainActor.run {
                self.performanceInsights = insights
            }

            return insights
        } catch {
            lastError = error.localizedDescription
            return generateBasicInsights(cpu: cpuUsage, memory: memoryUsage, pressure: memoryPressure)
        }
    }

    private func buildSystemContext(
        cpuUsage: Double,
        memoryUsage: Double,
        memoryPressure: String,
        loadAverages: (Double, Double, Double),
        topProcesses: [(String, Double, Double)],
        diskUsage: [(String, Double, Double)],
        networkStats: (Double, Double)
    ) -> String {
        var context = """
        CPU Usage: \(String(format: "%.1f", cpuUsage))%
        Memory Usage: \(String(format: "%.1f", memoryUsage))%
        Memory Pressure: \(memoryPressure)
        Load Averages: \(String(format: "%.2f", loadAverages.0)), \(String(format: "%.2f", loadAverages.1)), \(String(format: "%.2f", loadAverages.2))

        Top CPU Processes:
        """

        for (name, cpu, _) in topProcesses.prefix(5) {
            context += "\n- \(name): \(String(format: "%.1f", cpu))%"
        }

        context += "\n\nTop Memory Processes:"
        for (name, _, memory) in topProcesses.prefix(5) {
            context += "\n- \(name): \(String(format: "%.1f", memory))%"
        }

        if !diskUsage.isEmpty {
            context += "\n\nDisk Usage:"
            for (name, used, total) in diskUsage.prefix(3) {
                let percent = (used / total) * 100
                context += "\n- \(name): \(String(format: "%.1f", percent))% used"
            }
        }

        context += "\n\nNetwork: ↓\(formatBytes(Int64(networkStats.0)))/s ↑\(formatBytes(Int64(networkStats.1)))/s"

        return context
    }

    private func generateBasicInsights(cpu: Double, memory: Double, pressure: String) -> String {
        if cpu < 30 && memory < 50 && pressure == "Normal" {
            return "System is running smoothly with low resource usage. CPU and memory are well below capacity."
        } else if cpu > 80 {
            return "High CPU usage detected (\(String(format: "%.1f", cpu))%). Check top processes for resource-intensive applications."
        } else if memory > 80 || pressure != "Normal" {
            return "High memory pressure detected. Consider closing unused applications or upgrading RAM."
        } else {
            return "System is under moderate load. Performance is acceptable but could be improved."
        }
    }

    // MARK: - Feature 2: AI Anomaly Detection

    /// Detect unusual system patterns
    func detectAnomalies(currentData: SystemSnapshot, baseline: SystemBaseline?) async -> [SystemAnomaly] {
        guard aiBackend.isOllamaAvailable || aiBackend.isTinyLLMAvailable || aiBackend.isTinyChatAvailable || aiBackend.isOpenWebUIAvailable else {
            return detectBasicAnomalies(currentData: currentData, baseline: baseline)
        }

        isAnalyzing = true
        defer { isAnalyzing = false }

        let context = buildAnomalyContext(current: currentData, baseline: baseline)

        let prompt = """
        Detect anomalies in this system's current performance compared to baseline.
        Look for: unusual CPU spikes, memory leaks, runaway processes, disk pressure, network issues.

        CURRENT VS BASELINE:
        \(context)

        Respond in JSON:
        {
            "anomalies": [
                {
                    "type": "cpu|memory|disk|network|process",
                    "severity": "low|medium|high|critical",
                    "description": "What's unusual",
                    "likelyCause": "Probable cause",
                    "recommendation": "What to do"
                }
            ]
        }
        """

        do {
            let response = try await aiBackend.generate(
                prompt: prompt,
                systemPrompt: "You are a system performance analyst. Detect anomalies and potential issues.",
                temperature: 0.3,
                maxTokens: 600
            )

            if let anomalies = parseAnomalies(response) {
                await MainActor.run {
                    self.detectedAnomalies = anomalies
                }
                return anomalies
            }
        } catch {
            lastError = error.localizedDescription
        }

        return detectBasicAnomalies(currentData: currentData, baseline: baseline)
    }

    private func buildAnomalyContext(current: SystemSnapshot, baseline: SystemBaseline?) -> String {
        var context = """
        CURRENT:
        - CPU: \(String(format: "%.1f", current.cpuUsage))%
        - Memory: \(String(format: "%.1f", current.memoryUsage))%
        - Load: \(String(format: "%.2f", current.loadAverage))
        - Top Process CPU: \(current.topProcess) (\(String(format: "%.1f", current.topProcessCPU))%)
        """

        if let baseline = baseline {
            context += """


            BASELINE (Normal):
            - CPU: \(String(format: "%.1f", baseline.avgCPU))%
            - Memory: \(String(format: "%.1f", baseline.avgMemory))%
            - Load: \(String(format: "%.2f", baseline.avgLoad))

            DEVIATIONS:
            - CPU: \(String(format: "%+.1f", current.cpuUsage - baseline.avgCPU))%
            - Memory: \(String(format: "%+.1f", current.memoryUsage - baseline.avgMemory))%
            - Load: \(String(format: "%+.2f", current.loadAverage - baseline.avgLoad))
            """
        } else {
            context += "\n\n(No baseline data - first analysis)"
        }

        return context
    }

    private func detectBasicAnomalies(currentData: SystemSnapshot, baseline: SystemBaseline?) -> [SystemAnomaly] {
        var anomalies: [SystemAnomaly] = []

        // High CPU anomaly
        if currentData.cpuUsage > 90 {
            anomalies.append(SystemAnomaly(
                type: .cpu,
                severity: .high,
                description: "CPU usage is critically high (\(String(format: "%.1f", currentData.cpuUsage))%)",
                likelyCause: "Process \(currentData.topProcess) using \(String(format: "%.1f", currentData.topProcessCPU))%",
                recommendation: "Consider closing \(currentData.topProcess) or investigating why it's using so much CPU"
            ))
        }

        // High memory anomaly
        if currentData.memoryUsage > 90 {
            anomalies.append(SystemAnomaly(
                type: .memory,
                severity: .high,
                description: "Memory usage is critically high (\(String(format: "%.1f", currentData.memoryUsage))%)",
                likelyCause: "Insufficient RAM for current workload",
                recommendation: "Close unused applications or consider upgrading RAM"
            ))
        }

        // Load average anomaly
        if let baseline = baseline, currentData.loadAverage > baseline.avgLoad * 2 {
            anomalies.append(SystemAnomaly(
                type: .cpu,
                severity: .medium,
                description: "Load average is unusually high (\(String(format: "%.2f", currentData.loadAverage)))",
                likelyCause: "More processes competing for CPU than normal",
                recommendation: "Check for background tasks or stuck processes"
            ))
        }

        return anomalies
    }

    // MARK: - Feature 3: AI Optimization Advice

    /// Generate optimization recommendations
    func generateOptimizationAdvice(currentData: SystemSnapshot) async -> [OptimizationAdvice] {
        let processes = currentData.topProcesses

        guard aiBackend.isOllamaAvailable || aiBackend.isTinyLLMAvailable || aiBackend.isTinyChatAvailable || aiBackend.isOpenWebUIAvailable else {
            return generateBasicAdvice(systemData: currentData, processes: processes)
        }

        isAnalyzing = true
        defer { isAnalyzing = false }

        let context = """
        System Status:
        - CPU: \(String(format: "%.1f", currentData.cpuUsage))%
        - Memory: \(String(format: "%.1f", currentData.memoryUsage))%
        - Load: \(String(format: "%.2f", currentData.loadAverage))

        Top Processes:
        \(processes.prefix(10).map { "\($0.0): CPU \(String(format: "%.1f", $0.1))%, Memory \(String(format: "%.1f", $0.2))%" }.joined(separator: "\n"))
        """

        let prompt = """
        Provide 3-5 specific optimization recommendations for this Mac.
        Focus on actionable steps to improve performance.

        SYSTEM DATA:
        \(context)

        Respond in JSON:
        {
            "advice": [
                {
                    "title": "Short title",
                    "description": "What to do",
                    "impact": "low|medium|high",
                    "difficulty": "easy|medium|hard",
                    "reason": "Why this helps",
                    "action": "Step-by-step instructions"
                }
            ]
        }
        """

        do {
            let response = try await aiBackend.generate(
                prompt: prompt,
                systemPrompt: "You are a macOS optimization expert. Provide specific, actionable performance advice.",
                temperature: 0.5,
                maxTokens: 500
            )

            if let advice = parseOptimizationAdvice(response) {
                await MainActor.run {
                    self.optimizationAdvice = advice
                }
                return advice
            }
        } catch {
            lastError = error.localizedDescription
        }

        return generateBasicAdvice(systemData: currentData, processes: processes)
    }

    private func generateBasicAdvice(systemData: SystemSnapshot, processes: [(String, Double, Double)]) -> [OptimizationAdvice] {
        var advice: [OptimizationAdvice] = []

        if systemData.cpuUsage > 80 {
            let topCPUProcess = processes.max(by: { $0.1 < $1.1 })
            if let process = topCPUProcess {
                advice.append(OptimizationAdvice(
                    title: "Reduce CPU Usage",
                    description: "Close or investigate \(process.0) which is using \(String(format: "%.1f", process.1))% CPU",
                    impact: .high,
                    difficulty: .easy,
                    reason: "High CPU usage causes slowdowns, heat, and battery drain",
                    action: "1. Open Activity Monitor\n2. Find \(process.0)\n3. Select it and click Quit Process"
                ))
            }
        }

        if systemData.memoryUsage > 80 {
            advice.append(OptimizationAdvice(
                title: "Free Up Memory",
                description: "Close unused applications to reduce memory pressure",
                impact: .high,
                difficulty: .easy,
                reason: "High memory usage leads to swap usage and system slowdowns",
                action: "1. Review open applications in Dock\n2. Quit apps you're not using\n3. Restart your Mac if needed"
            ))
        }

        if systemData.loadAverage > 10 {
            advice.append(OptimizationAdvice(
                title: "Reduce System Load",
                description: "Too many processes competing for resources",
                impact: .medium,
                difficulty: .medium,
                reason: "High load average indicates the system is overloaded",
                action: "1. Open Activity Monitor\n2. Sort by CPU usage\n3. Quit non-essential high-CPU processes"
            ))
        }

        if advice.isEmpty {
            advice.append(OptimizationAdvice(
                title: "System Running Well",
                description: "No major optimization needed - system is performing well",
                impact: .low,
                difficulty: .easy,
                reason: "Current resource usage is within normal parameters",
                action: "Keep monitoring your system periodically to maintain good performance"
            ))
        }

        return advice
    }

    // MARK: - Feature 4: AI Q&A Interface

    /// Answer questions about system performance
    func askQuestion(_ question: String, context: String) async -> String {
        guard aiBackend.isOllamaAvailable || aiBackend.isTinyLLMAvailable || aiBackend.isTinyChatAvailable || aiBackend.isOpenWebUIAvailable else {
            return "AI backend not available. Configure Ollama, TinyLLM (by Jason Cox), or MLX in Settings."
        }

        isAnalyzing = true
        defer { isAnalyzing = false }

        let prompt = """
        Answer this question about the Mac's performance:

        SYSTEM DATA:
        \(context)

        QUESTION: \(question)

        Provide a clear, specific answer based on the data above.
        """

        do {
            let answer = try await aiBackend.generate(
                prompt: prompt,
                systemPrompt: "You are a helpful macOS performance assistant.",
                temperature: 0.5,
                maxTokens: 300
            )

            return answer
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }

    // MARK: - Baseline Management

    func updateBaseline(snapshot: SystemSnapshot) {
        if baselineData == nil {
            baselineData = SystemBaseline(
                avgCPU: snapshot.cpuUsage,
                avgMemory: snapshot.memoryUsage,
                avgLoad: snapshot.loadAverage,
                samples: 1
            )
        } else if var baseline = baselineData {
            // Rolling average
            let newSamples = baseline.samples + 1
            baseline.avgCPU = (baseline.avgCPU * Double(baseline.samples) + snapshot.cpuUsage) / Double(newSamples)
            baseline.avgMemory = (baseline.avgMemory * Double(baseline.samples) + snapshot.memoryUsage) / Double(newSamples)
            baseline.avgLoad = (baseline.avgLoad * Double(baseline.samples) + snapshot.loadAverage) / Double(newSamples)
            baseline.samples = newSamples

            baselineData = baseline
        }
    }

    // MARK: - Parsing Helpers

    private func parseAnomalies(_ response: String) -> [SystemAnomaly]? {
        guard let jsonData = extractJSON(from: response)?.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let anomaliesArray = json["anomalies"] as? [[String: Any]] else {
            return nil
        }

        return anomaliesArray.compactMap { dict in
            guard let typeStr = dict["type"] as? String,
                  let severityStr = dict["severity"] as? String,
                  let description = dict["description"] as? String,
                  let cause = dict["likelyCause"] as? String,
                  let recommendation = dict["recommendation"] as? String else {
                return nil
            }

            let type = SystemAnomaly.AnomalyType(rawValue: typeStr) ?? .process
            let severity = SystemAnomaly.AnomalySeverity(rawValue: severityStr) ?? .medium

            return SystemAnomaly(
                type: type,
                severity: severity,
                description: description,
                likelyCause: cause,
                recommendation: recommendation
            )
        }
    }

    private func parseOptimizationAdvice(_ response: String) -> [OptimizationAdvice]? {
        guard let jsonData = extractJSON(from: response)?.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let adviceArray = json["advice"] as? [[String: Any]] else {
            return nil
        }

        return adviceArray.compactMap { dict in
            guard let title = dict["title"] as? String,
                  let description = dict["description"] as? String,
                  let impactStr = dict["impact"] as? String,
                  let difficultyStr = dict["difficulty"] as? String,
                  let reason = dict["reason"] as? String else {
                return nil
            }

            let action = dict["action"] as? String ?? ""
            let impact = OptimizationAdvice.ImpactLevel(rawValue: impactStr) ?? .medium
            let difficulty = OptimizationAdvice.DifficultyLevel(rawValue: difficultyStr) ?? .medium

            return OptimizationAdvice(
                title: title,
                description: description,
                impact: impact,
                difficulty: difficulty,
                reason: reason,
                action: action
            )
        }
    }

    private func extractJSON(from text: String) -> String? {
        if let range = text.range(of: "\\{[\\s\\S]*\\}", options: .regularExpression) {
            return String(text[range])
        }
        return text.hasPrefix("{") ? text : nil
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Data Models

struct SystemSnapshot {
    let cpuUsage: Double
    let memoryUsage: Double
    let memoryTotal: Double
    let memoryPressure: String
    let loadAverages: (Double, Double, Double)
    let topProcesses: [(String, Double, Double)]
    let diskUsage: [(String, Double, Double)]
    let networkStats: (Double, Double)
    let timestamp: Date

    // Computed properties for backward compatibility with existing code
    var loadAverage: Double { loadAverages.0 }
    var topProcess: String { topProcesses.first?.0 ?? "Unknown" }
    var topProcessCPU: Double { topProcesses.first?.1 ?? 0.0 }

    init(
        cpuUsage: Double,
        memoryUsage: Double,
        memoryTotal: Double,
        memoryPressure: String,
        loadAverages: (Double, Double, Double),
        topProcesses: [(String, Double, Double)],
        diskUsage: [(String, Double, Double)],
        networkStats: (Double, Double)
    ) {
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.memoryTotal = memoryTotal
        self.memoryPressure = memoryPressure
        self.loadAverages = loadAverages
        self.topProcesses = topProcesses
        self.diskUsage = diskUsage
        self.networkStats = networkStats
        self.timestamp = Date()
    }

    // Legacy init for backward compatibility
    init(cpu: Double, memory: Double, pressure: String, load: Double, topProcess: String, topCPU: Double) {
        self.cpuUsage = cpu
        self.memoryUsage = memory
        self.memoryTotal = 100.0 // Default
        self.memoryPressure = pressure
        self.loadAverages = (load, load, load)
        self.topProcesses = [(topProcess, topCPU, 0.0)]
        self.diskUsage = []
        self.networkStats = (0, 0)
        self.timestamp = Date()
    }
}

struct SystemBaseline {
    var avgCPU: Double
    var avgMemory: Double
    var avgLoad: Double
    var samples: Int
}

struct SystemAnomaly: Identifiable {
    let id = UUID()
    let type: AnomalyType
    let severity: AnomalySeverity
    let description: String
    let likelyCause: String
    let recommendation: String

    enum AnomalyType: String {
        case cpu = "cpu"
        case memory = "memory"
        case disk = "disk"
        case network = "network"
        case process = "process"

        var icon: String {
            switch self {
            case .cpu: return "cpu"
            case .memory: return "memorychip"
            case .disk: return "internaldrive"
            case .network: return "network"
            case .process: return "app.badge"
            }
        }
    }

    enum AnomalySeverity: String {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"

        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
}

struct OptimizationAdvice: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let impact: ImpactLevel
    let difficulty: DifficultyLevel
    let reason: String
    let action: String

    enum ImpactLevel: String {
        case low = "low"
        case medium = "medium"
        case high = "high"

        var color: Color {
            switch self {
            case .low: return .blue
            case .medium: return .yellow
            case .high: return .red
            }
        }
    }

    enum DifficultyLevel: String {
        case easy = "easy"
        case medium = "medium"
        case hard = "hard"

        var color: Color {
            switch self {
            case .easy: return .green
            case .medium: return .orange
            case .hard: return .red
            }
        }
    }
}
