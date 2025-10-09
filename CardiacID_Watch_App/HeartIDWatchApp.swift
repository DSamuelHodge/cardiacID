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
