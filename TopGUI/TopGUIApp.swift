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
                .frame(minWidth: 1400, minHeight: 1000)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
