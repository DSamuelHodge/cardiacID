//
//  HeartIDWatchApp.swift
//  HeartID Watch App
//
//  Main app entry point with dependency injection
//

import SwiftUI

@main
struct HeartID_WatchApp: App {
    @StateObject private var authenticationService = AuthenticationService()
    @StateObject private var healthKitService = HealthKitService()
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var backgroundTaskService = BackgroundTaskService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authenticationService)
                .environmentObject(healthKitService)
                .environmentObject(dataManager)
                .environmentObject(backgroundTaskService)
                .onAppear {
                    // Link services
                    authenticationService.setDataManager(dataManager)
                    authenticationService.setHealthKitService(healthKitService)
                    
                    // Request HealthKit authorization
                    healthKitService.requestAuthorization()
                }
        }
    }
}

// MARK: - Background Task Service

/// Service for managing background authentication tasks
class BackgroundTaskService: ObservableObject {
    @Published var isBackgroundTaskActive = false
    @Published var lastBackgroundCheck: Date?
    
    private var backgroundTimer: Timer?
    
    func startBackgroundTasks() {
        // This would implement actual background processing
        // For now, it's a placeholder
        isBackgroundTaskActive = true
        lastBackgroundCheck = Date()
        
        print("🔄 Background task service started")
    }
    
    func stopBackgroundTasks() {
        backgroundTimer?.invalidate()
        backgroundTimer = nil
        isBackgroundTaskActive = false
        
        print("⏹️ Background task service stopped")
    }
}