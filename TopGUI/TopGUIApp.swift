//
//  TopGUIApp.swift
//  TopGUI
//
//  Created by Jordan Koch on 1/15/2026.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI

@main
struct TopGUIApp: App {
    @StateObject private var dataManager = TopDataManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .frame(minWidth: 1600, minHeight: 900)
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
        }
    }
}
