//
//  SharedDataManager.swift
//  TopGUI Widget
//
//  Manages data sharing between the main app and widget via App Group
//
//  Created by Jordan Koch on 2/4/2026.
//  Copyright 2026 Jordan Koch. All rights reserved.
//

import Foundation

/// Shared data manager for App Group communication between main app and widget
class SharedDataManager {

    /// Shared instance for singleton access
    static let shared = SharedDataManager()

    /// App Group identifier - must match in both app and widget entitlements
    static let appGroupIdentifier = "group.com.jkoch.topgui"

    /// Key for storing system stats in shared UserDefaults
    private static let statsKey = "widget_system_stats"

    /// Shared UserDefaults instance for App Group
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: SharedDataManager.appGroupIdentifier)
    }

    /// Shared container URL for file-based sharing
    private var sharedContainerURL: URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedDataManager.appGroupIdentifier)
    }

    private init() {}

    // MARK: - Write Stats (called from main app)

    /// Save system stats to shared storage for widget access
    /// - Parameter stats: The current system stats to share
    func saveStats(_ stats: WidgetSystemStats) {
        guard let defaults = sharedDefaults else {
            print("TopGUI Widget: Failed to access shared UserDefaults")
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(stats)
            defaults.set(data, forKey: SharedDataManager.statsKey)
            defaults.synchronize()

            // Also save to file for redundancy
            saveStatsToFile(stats)

            #if DEBUG
            print("TopGUI Widget: Saved stats - CPU: \(stats.cpuUsage)%, Memory: \(stats.memoryUsage)%")
            #endif
        } catch {
            print("TopGUI Widget: Failed to encode stats: \(error)")
        }
    }

    // MARK: - Read Stats (called from widget)

    /// Load system stats from shared storage
    /// - Returns: The latest system stats, or default values if unavailable
    func loadStats() -> WidgetSystemStats {
        // Try UserDefaults first
        if let defaults = sharedDefaults,
           let data = defaults.data(forKey: SharedDataManager.statsKey) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let stats = try decoder.decode(WidgetSystemStats.self, from: data)
                return stats
            } catch {
                print("TopGUI Widget: Failed to decode stats from UserDefaults: \(error)")
            }
        }

        // Fall back to file storage
        if let stats = loadStatsFromFile() {
            return stats
        }

        // Return default placeholder stats
        return WidgetSystemStats()
    }

    // MARK: - File-based Storage (backup method)

    private func saveStatsToFile(_ stats: WidgetSystemStats) {
        guard let containerURL = sharedContainerURL else { return }

        let fileURL = containerURL.appendingPathComponent("widget_stats.json")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(stats)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("TopGUI Widget: Failed to save stats to file: \(error)")
        }
    }

    private func loadStatsFromFile() -> WidgetSystemStats? {
        guard let containerURL = sharedContainerURL else { return nil }

        let fileURL = containerURL.appendingPathComponent("widget_stats.json")

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(WidgetSystemStats.self, from: data)
        } catch {
            print("TopGUI Widget: Failed to load stats from file: \(error)")
            return nil
        }
    }

    // MARK: - Data Freshness

    /// Check if the cached stats are still fresh (less than 5 minutes old)
    func isDataFresh() -> Bool {
        let stats = loadStats()
        let age = Date().timeIntervalSince(stats.timestamp)
        return age < 300 // 5 minutes
    }

    /// Get the age of the cached data in a human-readable format
    func dataAgeString() -> String {
        let stats = loadStats()
        let age = Date().timeIntervalSince(stats.timestamp)

        if age < 60 {
            return "Just now"
        } else if age < 3600 {
            let minutes = Int(age / 60)
            return "\(minutes)m ago"
        } else {
            let hours = Int(age / 3600)
            return "\(hours)h ago"
        }
    }

    // MARK: - Clear Data

    /// Clear all cached widget data
    func clearStats() {
        sharedDefaults?.removeObject(forKey: SharedDataManager.statsKey)
        sharedDefaults?.synchronize()

        // Also remove file
        if let containerURL = sharedContainerURL {
            let fileURL = containerURL.appendingPathComponent("widget_stats.json")
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
}
