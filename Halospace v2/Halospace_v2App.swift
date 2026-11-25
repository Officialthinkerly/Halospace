//
//  Halospace_v2App.swift
//  Halospace v2
//
//  Created by David Obe on 25/11/2026.
//

import SwiftUI

@main
struct Halospace_v2App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
