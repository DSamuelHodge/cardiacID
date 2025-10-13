//
//
//  HeartIDWatchApp.swift
//  HeartID Watch App
//
//  Consolidated main app entry point - resolves all module conflicts
//

import SwiftUI
import HealthKit

// Import debug logger and type aliases
import Foundation

// Make sure debugLog is available - using the TypeAliases.swift definitions
private let debugLog = DebugLogger.shared

// MARK: - Main App Entry Point

@main
struct HeartID_WatchApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
                .onAppear {
                    debugLog.info("🚀 HeartID Watch App starting")
                    
                    // Initialize app state with timeout protection
                    Task {
                        await appState.initialize()
                    }
                    
                    // Fallback initialization after timeout
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        if !appState.isInitialized {
                            debugLog.warning("⚠️ Forcing initialization due to timeout")
                            appState.forceInitialization()
                        }
                    }
                }
        }
    }
}

// MARK: - App State Management

@MainActor
final class AppState: ObservableObject {
    @Published var isInitialized = false
    @Published var isUserEnrolled = false
    @Published var healthKitAvailable = false
    @Published var errorMessage: String?
    
    // Core services - single instances to avoid conflicts
    let dataManager = DataManager.shared
    let authenticationService = AuthenticationService()
    let healthKitService = HealthKitService()
    
    private var initializationTask: Task<Void, Never>?
    
    init() {
        debugLog.info("🔧 AppState initializing")
    }
    
    func initialize() async {
        guard !isInitialized else { return }
        
        debugLog.info("🔄 Starting app initialization")
        
        // Initialize services in sequence
        await withTaskGroup(of: Void.self) { group in
            // Initialize HealthKit service
            group.addTask {
                await self.initializeHealthKit()
            }
            
            // Initialize data manager
            group.addTask {
                await self.initializeDataManager()
            }
            
            // Initialize authentication service
            group.addTask {
                await self.initializeAuthenticationService()
            }
        }
        
        // Final setup
        await finalizeInitialization()
    }
    
    func forceInitialization() {
        isUserEnrolled = dataManager.isUserEnrolled()
        
        debugLog.warning("⚠️ Forced initialization completed")
    }
    
    private func initializeHealthKit() async {
        healthKitAvailable = HKHealthStore.isHealthDataAvailable()
        
        if healthKitAvailable {
            // Set up service connections
            authenticationService.setHealthKitService(healthKitService)
            
            // Check authorization status
            let result = await healthKitService.ensureAuthorization()
            switch result {
            case .authorized:
                debugLog.health("✅ HealthKit authorized")
            case .denied(let message), .notAvailable(let message):
                debugLog.error("❌ HealthKit issue: \(message)")
                errorMessage = "HealthKit setup required: \(message)"
            }
        } else {
            errorMessage = "HealthKit is not available on this device"
            debugLog.error("❌ HealthKit not available")
        }
    }
    
    private func initializeDataManager() async {
        // Set up service connections
        authenticationService.setDataManager(dataManager)
        
        isUserEnrolled = dataManager.isUserEnrolled()
        
        debugLog.info("✅ DataManager initialized - Enrolled: \(isUserEnrolled)")
    }
    
    private func initializeAuthenticationService() async {
        // Service is ready - connections established in other init methods
        debugLog.auth("✅ AuthenticationService initialized")
    }
    
    private func finalizeInitialization() async {
        // Mark as initialized
        isInitialized = true
        
        debugLog.info("🎯 App initialization completed successfully")
        debugLog.info("📊 Status - Enrolled: \(isUserEnrolled), HealthKit: \(healthKitAvailable)")
    }
}

// MARK: - Main View Router

struct MainView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if !appState.isInitialized {
                LoadingView() as LoadingView
            } else if let error = appState.errorMessage {
                ErrorView(message: error) {
                    // Retry initialization
                    Task {
                        appState.errorMessage = nil
                        await appState.initialize()
                    }
                }
            } else if !appState.isUserEnrolled {
                EnrollView()
                    .environmentObject(appState.authenticationService)
                    .environmentObject(appState.healthKitService)
                    .environmentObject(appState.dataManager)
            } else {
                AuthenticatedAppView()
                    .environmentObject(appState.authenticationService)
                    .environmentObject(appState.healthKitService)
                    .environmentObject(appState.dataManager)
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    @State private var animationPhase = 0
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
                .scaleEffect(animationPhase == 0 ? 1.0 : 1.2)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animationPhase)
            
            Text("HeartID")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Initializing...")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ProgressView()
                .scaleEffect(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            animationPhase = 1
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("Setup Required")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Retry") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Authenticated App View

struct AuthenticatedAppView: View {
    @State private var selectedTab = 1 // Start with Menu tab
    @State private var showingTesting = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Menu Tab (Primary)
            MenuView()
                .tag(1)
            
            // Quick Enroll
            EnrollView()
                .tag(2)
            
            // Quick Authenticate  
            AuthenticateView()
                .tag(3)
                
            // Settings
            SettingsView()
                .tag(4)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Test") {
                    showingTesting = true
                }
                .font(.caption)
            }
        }
        .sheet(isPresented: $showingTesting) {
            FlowTestingView()
        }
    }
}
