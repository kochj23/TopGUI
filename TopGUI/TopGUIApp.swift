//
//  TopGUIApp.swift
//  TopGUI
//
//  Created by Jordan Koch on 1/15/2026.
//  Copyright (c) 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

@main
struct TopGUIApp: App {
    @StateObject private var dataManager = TopDataManager()

    /// True when running inside XCTest host -- skip heavy startup work.
    static let isTesting: Bool = {
        Foundation.ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
        Foundation.ProcessInfo.processInfo.environment["XCTestSessionIdentifier"] != nil ||
        NSClassFromString("XCTestCase") != nil
    }()

    init() {
        guard !Self.isTesting else { return }
        NovaAPIServer.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            if Self.isTesting {
                Color.clear.frame(width: 1, height: 1)
            } else {
                ContentView()
                    .environmentObject(dataManager)
                    .frame(minWidth: 1600, minHeight: 900)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandMenu("Actions") {
                Button("Kill High CPU Process") {
                    if let topProcess = dataManager.processes.first {
                        dataManager.killProcess(topProcess)
                    }
                }
                .keyboardShortcut("k", modifiers: [.command])

                Divider()

                Button("Refresh Now") {
                    dataManager.stopMonitoring()
                    dataManager.startMonitoring()
                }
                .keyboardShortcut("r", modifiers: [.command])

                Divider()

                Button("Export Data...") {
                    // Placeholder for future export feature
                }
                .keyboardShortcut("e", modifiers: [.command])
                .disabled(true)
            }

            CommandMenu("AI") {
                Button("Show AI Insights...") {
                    // Trigger AI Insights sheet
                    NotificationCenter.default.post(name: .showAIInsights, object: nil)
                }
                .keyboardShortcut("i", modifiers: [.command])

                Divider()

                Button("AI Backend Settings...") {
                    NotificationCenter.default.post(name: .showAIBackendSettings, object: nil)
                }
                .keyboardShortcut("b", modifiers: [.command, .shift])

                Divider()

                Button("Refresh AI Backends") {
                    Task {
                        await AIBackendManager.shared.refreshAllBackends()
                    }
                }
            }
        }
    }
}
