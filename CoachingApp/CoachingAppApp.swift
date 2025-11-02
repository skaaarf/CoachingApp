//
//  CoachingAppApp.swift
//  CoachingApp
//
//  Created by Ushiku Ryotaro on 2025/11/01.
//

import SwiftUI
import FirebaseCore

@main
struct CoachingAppApp: App {
    @StateObject private var authManager = AuthenticationManager()

    init() {
        // Firebase の初期化
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
            } else {
                LoginView(authManager: authManager)
            }
        }
    }
}
