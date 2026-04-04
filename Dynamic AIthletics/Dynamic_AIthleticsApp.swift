//
//  Dynamic_AIthleticsApp.swift
//  Dynamic AIthletics
//
//  App entry point. Configures the SwiftData model container
//  and injects it into the view hierarchy.
//

import SwiftUI
import SwiftData

@main
struct Dynamic_AIthleticsApp: App {
    var sharedModelContainer: ModelContainer = ModelContainerFactory.makeContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
