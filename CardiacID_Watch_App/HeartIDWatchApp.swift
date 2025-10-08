//
//  HeartIDWatchApp.swift
//  HeartID Watch App
//
//  Main app entry point with dependency injection
//

import SwiftUI

struct HeartIDWatchApp: App {
    // Core Services (Singletons)
    @StateObject private var authenticationService = AuthenticationService()
    @StateObject private var healthKitService = HealthKitService()
    @StateObject private var dataManager = DataManager()
    @StateObject private var backgroundTaskService = BackgroundTaskService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authenticationService)
                .environmentObject(healthKitService)
                .environmentObject(dataManager)
                .environmentObject(backgroundTaskService)
                .onAppear {
                    initializeApp()
                }
        }
    }
    
    private func initializeApp() {
        print("🚀 HeartID Watch App initializing...")
        
        // Connect data manager to authentication service
        authenticationService.setDataManager(dataManager)
        
        // Validate data integrity
        if !dataManager.validateDataIntegrity() {
            print("⚠️ Data integrity check failed - clearing corrupted data")
            dataManager.clearAllData()
        }
        
        // Request HealthKit authorization early if not already done
        if !healthKitService.isAuthorized {
            healthKitService.requestAuthorization()
        }
        
        print("✅ HeartID Watch App initialization complete")
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