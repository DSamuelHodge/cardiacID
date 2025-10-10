import SwiftUI

struct CardiacIDWatchApp: App {
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
        }
    }
}

