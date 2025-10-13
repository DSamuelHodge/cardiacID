//
//
//  HeartIDWatchApp.swift
//  HeartID Watch App
//
//  Consolidated main app entry point - resolves all module conflicts
//

import SwiftUI
import HealthKit

// MARK: - Main App Entry Point

@main
struct HeartID_WatchApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(appState)
                .onAppear {
                    AppLogger.log("🚀 HeartID Watch App starting", category: .general)
                    
                    // Initialize app state with timeout protection
                    Task {
                        await appState.initialize()
                    }
                    
                    // Fallback initialization after timeout
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        if !appState.isInitialized {
                            AppLogger.log("⚠️ Forcing initialization due to timeout", category: .general)
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
        AppLogger.log("🔧 AppState initializing", category: .general)
    }
    
    func initialize() async {
        guard !isInitialized else { return }
        
        AppLogger.log("🔄 Starting app initialization", category: .general)
        
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
        isInitialized = true
        healthKitAvailable = HKHealthStore.isHealthDataAvailable()
        isUserEnrolled = dataManager.isUserEnrolled
        
        AppLogger.log("⚠️ Forced initialization completed", category: .general)
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
                AppLogger.log("✅ HealthKit authorized", category: .healthkit)
            case .denied(let message), .notAvailable(let message):
                AppLogger.log("❌ HealthKit issue: \(message)", category: .healthkit)
                errorMessage = "HealthKit setup required: \(message)"
            }
        } else {
            errorMessage = "HealthKit is not available on this device"
            AppLogger.log("❌ HealthKit not available", category: .healthkit)
        }
    }
    
    private func initializeDataManager() async {
        // Set up service connections
        authenticationService.setDataManager(dataManager)
        
        // Load user enrollment status
        isUserEnrolled = dataManager.isUserEnrolled
        
        AppLogger.log("✅ DataManager initialized - Enrolled: \(isUserEnrolled)", category: .general)
    }
    
    private func initializeAuthenticationService() async {
        // Service is ready - connections established in other init methods
        AppLogger.log("✅ AuthenticationService initialized", category: .authentication)
    }
    
    private func finalizeInitialization() async {
        // Mark as initialized
        isInitialized = true
        
        AppLogger.log("🎯 App initialization completed successfully", category: .general)
        AppLogger.log("📊 Status - Enrolled: \(isUserEnrolled), HealthKit: \(healthKitAvailable)", category: .general)
    }
}

// MARK: - Main View Router

struct MainView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if !appState.isInitialized {
                LoadingView()
            } else if let error = appState.errorMessage {
                ErrorView(message: error) {
                    // Retry initialization
                    Task {
                        appState.errorMessage = nil
                        await appState.initialize()
                    }
                }
            } else if !appState.isUserEnrolled {
                EnrollmentFlowView(
                    isEnrolled: .constant(appState.isUserEnrolled),
                    showEnrollment: .constant(true),
                    onEnrollmentComplete: {
                        appState.isUserEnrolled = true
                        appState.dataManager.setUserEnrolled(true)
                    }
                )
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
    }
}
    
    func initialize() async {
        print("🚀 Starting app initialization...")
        
        // Check enrollment status first (fast operation)
        isUserEnrolled = dataManager.isUserEnrolled
        print("📊 User enrolled: \(isUserEnrolled)")
        
        // Check HealthKit availability (non-blocking)
        healthKitAvailable = HKHealthStore.isHealthDataAvailable()
        print("🏥 HealthKit available: \(healthKitAvailable)")
        
        // Request HealthKit authorization asynchronously if needed (non-blocking)
        if healthKitAvailable && !isUserEnrolled {
            print("🔐 Requesting HealthKit authorization...")
            Task {
                await requestHealthKitAuthorization()
            }
        }
        
        print("✅ App initialization complete")
        isInitialized = true
    }
    
    private func requestHealthKitAuthorization() async {
        print("🔐 Starting HealthKit authorization...")
        
        // Use the existing HealthKitService instead of creating a new HKHealthStore
        // Add timeout to prevent hanging
        let success = await withTimeout(seconds: 10) {
            await self.healthKitService.requestAuthorization()
        }
        
        if success != true {
            print("⚠️ HealthKit authorization failed or timed out")
            errorMessage = "HealthKit authorization failed"
        } else {
            print("✅ HealthKit authorization successful")
        }
    }
    
    // Helper function for timeout
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> T) async -> T? {
        return await withTaskGroup(of: T?.self) { group in
            group.addTask {
                await operation()
            }
            
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return nil
            }
            
            let result = await group.next()
            group.cancelAll()
            return result ?? nil
        }
    }
}

// MARK: - Main View

struct MainView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if !appState.isInitialized {
                // Show loading screen while initializing
                LoadingView()
            } else if let error = appState.errorMessage {
                // Show error state
                ErrorView(message: error)
            } else if !appState.isUserEnrolled {
                // Show enrollment flow
                EnrollmentFlowView(
                    isEnrolled: $appState.isUserEnrolled,
                    showEnrollment: .constant(true),
                    onEnrollmentComplete: {
                        appState.isUserEnrolled = true
                    }
                )
                .environmentObject(appState.authenticationService)
                .environmentObject(appState.healthKitService)
                .environmentObject(appState.dataManager)
            } else {
                // Show main app
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
        ScrollView {
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
                
                Spacer(minLength: 50)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .padding()
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
    
    var body: some View {
        ScrollView {
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
                    // Retry initialization
                    Task {
                        await AppState().initialize()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Spacer(minLength: 50)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Enrollment View

struct EnrollmentView: View {
    @EnvironmentObject var appState: AppState
    @State private var isEnrolling = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                Text("Welcome to HeartID")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text("Set up your biometric authentication")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button("Start Setup") {
                    isEnrolling = true
                    // Start enrollment process
                }
                .buttonStyle(.borderedProminent)
                .disabled(isEnrolling)
                
                Spacer(minLength: 50)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Authenticated App View

struct AuthenticatedAppView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 1 // Start with Menu tab
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Landing Tab
            LandingTabView()
                .tag(0)
            
            // Menu Tab (Primary)
            MenuView()
                .tag(1)
            
            // Enroll Tab
            EnrollView()
                .tag(2)
            
            // Authenticate Tab
            AuthenticateView()
                .tag(3)
            
            // Settings Tab
            SettingsView()
                .tag(4)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
}

// MARK: - Landing Tab View

struct LandingTabView: View {
    @State private var showContent = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // HeartID Logo/Icon
                Image(systemName: "heart.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                    .scaleEffect(showContent ? 1.0 : 0.8)
                    .animation(.easeInOut(duration: 0.5), value: showContent)
                
                Text("HeartID V0.4")
                    .font(.system(size: 24))
                    .fontWeight(.bold)
                    .opacity(showContent ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.5).delay(0.2), value: showContent)
                
                Text("Biometric Authentication")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .opacity(showContent ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.5).delay(0.4), value: showContent)
                
                Spacer(minLength: 50)
                
                // Status indicator
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.green)
                    
                    Text("Ready")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.5).delay(0.6), value: showContent)
                
                Spacer(minLength: 50)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            showContent = true
        }
    }
}