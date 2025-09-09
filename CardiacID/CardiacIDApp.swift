//
//  CardiacIDApp.swift
//  CardiacID
//
//  Created by Jim Locke on 9/9/25.
//

import SwiftUI
import CoreData
import HealthKit
import Combine

@main
struct CardiacIDApp: App {
    // Services and controllers
    let persistenceController = PersistenceController.shared
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var watchConnectivity = WatchConnectivityService.shared
    @StateObject private var authViewModel = AuthViewModel()
    
    // Launch state
    @State private var isShowingLaunchScreen = true
    
    // Track scene phase changes
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authViewModel.isAuthenticated {
                    // Main app content
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(authViewModel)
                        .environmentObject(authManager)
                        .environmentObject(watchConnectivity)
                        .transition(.opacity)
                } else {
                    // Login screen
                    LoginView()
                        .environmentObject(authViewModel)
                        .environmentObject(authManager)
                        .environmentObject(watchConnectivity)
                        .transition(.opacity)
                }
                
                // Launch screen overlay
                if isShowingLaunchScreen {
                    LaunchScreen()
                        .transition(.opacity)
                        .zIndex(2)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: authViewModel.isAuthenticated)
            .animation(.easeInOut(duration: 0.5), value: isShowingLaunchScreen)
            .onAppear {
                debugLog.info("HeartID Mobile app launched")
                
                // Start watch connectivity service
                // Watch connectivity is automatically activated
                debugLog.watch("Watch connectivity service initialized")
                
                // Setup health store if needed
                authManager.setupHealthStore()
                debugLog.health("HealthKit store setup completed")
                
                // Dismiss the launch screen after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    isShowingLaunchScreen = false
                    debugLog.info("Launch screen dismissed")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh data when app enters foreground
                if authViewModel.isAuthenticated {
                    authManager.refreshAuthenticationStatus()
                    // Check watch connection status
                    print("Watch is reachable: \(watchConnectivity.isReachable)")
                }
            }
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                // App became active, refresh data
                if authViewModel.isAuthenticated && !isShowingLaunchScreen {
                    authManager.refreshAuthenticationStatus()
                }
            } else if scenePhase == .background {
                // App entered background, perform cleanup
                do {
                    try persistenceController.container.viewContext.save()
                } catch {
                    debugLog.error("Failed to save Core Data context", error: error)
                }
            }
        }
    }
    
    private func requestHealthKitPermissions() {
        Task {
            _ = await authManager.requestHealthKitPermissions()
        }
    }
}
